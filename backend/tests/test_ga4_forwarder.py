import asyncio
import os
import tempfile

os.environ["DB_PATH"] = os.path.join(tempfile.mkdtemp(), "test.db")

import aiosqlite  # noqa: E402

from app import database, ga4_forwarder  # noqa: E402


def run(coro):
    return asyncio.get_event_loop().run_until_complete(coro)


def setup_module(_):
    asyncio.set_event_loop(asyncio.new_event_loop())
    run(database.init_db())
    run(database.save_app_instance_id("dev1", "a1b2c3d4e5f60718293a4b5c6d7e8f90", "android"))
    run(database.record_subscription("dev1", "bhaktidhara_annual_399", "tok-1", order_id="GPA.1234-5678"))


def test_renewal_is_forwarded_with_exact_inr_value(monkeypatch):
    sent = []

    async def fake_send(payload):
        sent.append(payload)
        return True

    monkeypatch.setattr(ga4_forwarder, "GA4_API_SECRET", "secret")
    monkeypatch.setattr(ga4_forwarder, "send_to_ga4", fake_send)

    notification = {"notificationType": 2, "purchaseToken": "tok-1"}
    assert run(ga4_forwarder.handle_subscription_notification(notification, "msg-1")) == "forwarded"

    assert len(sent) == 1
    payload = sent[0]
    assert payload["app_instance_id"] == "a1b2c3d4e5f60718293a4b5c6d7e8f90"
    params = payload["events"][0]["params"]
    assert payload["events"][0]["name"] == "purchase"
    assert params["value"] == 399.0 and isinstance(params["value"], float)
    assert params["currency"] == "INR"
    assert params["transaction_id"].startswith("GPA.1234-5678:")

    # Pub/Sub redelivery of the same message must not double-count revenue.
    assert run(ga4_forwarder.handle_subscription_notification(notification, "msg-1")) == "duplicate"
    assert len(sent) == 1


def test_initial_purchase_is_not_forwarded():
    notification = {"notificationType": 4, "purchaseToken": "tok-1"}
    assert run(ga4_forwarder.handle_subscription_notification(notification, "msg-2")) == "ignored"


def test_renewal_extends_entitlement_without_secret(monkeypatch):
    monkeypatch.setattr(ga4_forwarder, "GA4_API_SECRET", "")
    notification = {"notificationType": 2, "purchaseToken": "tok-1"}
    status = run(ga4_forwarder.handle_subscription_notification(notification, "msg-3", 4_102_444_800_000))
    assert status == "renewed_not_forwarded"

    async def expiry():
        async with aiosqlite.connect(database.DB_PATH) as db:
            async with db.execute("SELECT expires_at FROM subscriptions WHERE purchase_token = 'tok-1'") as cur:
                return (await cur.fetchone())[0]

    assert run(expiry()).startswith("2101-01-01")  # 2100-01-01 + 365 days


def test_webhook_forwards_pubsub_renewal(monkeypatch):
    import base64
    import json

    from fastapi.testclient import TestClient
    from app import main

    sent = []

    async def fake_send(payload):
        sent.append(payload)
        return True

    monkeypatch.setattr(main, "RTDN_PUSH_TOKEN", "")
    monkeypatch.setattr(ga4_forwarder, "GA4_API_SECRET", "secret")
    monkeypatch.setattr(ga4_forwarder, "send_to_ga4", fake_send)
    rtdn = {
        "packageName": "com.kaldhone.bhaktidhara",
        "eventTimeMillis": "1700000000000",
        "subscriptionNotification": {"version": "1.0", "notificationType": 2, "purchaseToken": "tok-1"},
    }
    body = {"message": {"messageId": "pubsub-42", "data": base64.b64encode(json.dumps(rtdn).encode()).decode()}}

    resp = TestClient(main.app).post("/api/v1/subscription/webhook", json=body)
    assert resp.json() == {"status": "ok"}
    assert len(sent) == 1 and sent[0]["events"][0]["params"]["value"] == 399.0


def test_webhook_rejects_missing_auth_when_token_configured(monkeypatch):
    from fastapi.testclient import TestClient
    from app import main

    monkeypatch.setattr(main, "RTDN_PUSH_TOKEN", "push-secret")
    client = TestClient(main.app)
    assert client.post("/api/v1/subscription/webhook", json={}).status_code == 403
    assert client.post("/api/v1/subscription/webhook?auth=push-secret", json={}).status_code == 200
