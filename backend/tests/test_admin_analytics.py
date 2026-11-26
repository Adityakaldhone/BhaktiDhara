import asyncio
import os
import tempfile
from datetime import datetime, timedelta, timezone

os.environ["DB_PATH"] = os.path.join(tempfile.mkdtemp(), "admin_test.db")

from fastapi.testclient import TestClient  # noqa: E402

from app import database, main  # noqa: E402


def run(coro):
    return asyncio.get_event_loop().run_until_complete(coro)


def setup_module(_):
    asyncio.set_event_loop(asyncio.new_event_loop())
    run(database.init_db())
    run(database.record_device_ping(
        device_id="dev-paid-1",
        platform="android",
        app_version="1.0.4",
        locale="mr",
        is_vip=True,
        user_name="Aarav Joshi",
        city="Pune",
        state="Maharashtra",
        country="India",
        device_model="Pixel 8",
        os_version="Android 15",
    ))
    run(database.record_device_ping(
        device_id="dev-free-1",
        platform="ios",
        app_version="1.0.4",
        locale="hi",
        is_vip=False,
        user_name="Meera Sharma",
        city="Jaipur",
        state="Rajasthan",
        country="India",
        device_model="iPhone 15",
        os_version="iOS 18",
    ))
    run(database.record_subscription(
        device_id="dev-paid-1",
        product_id="bhaktidhara_annual_399",
        purchase_token="tok-annual-1",
        order_id="GPA.1001",
        platform="android",
        is_trial=False,
    ))
    run(database.record_subscription(
        device_id="dev-free-1",
        product_id="bhaktidhara_monthly_51",
        purchase_token="tok-trial-1",
        order_id="GPA.1002",
        platform="ios",
        is_trial=True,
    ))
    now = datetime.now(timezone.utc).isoformat()
    run(database.record_events("dev-paid-1", [
        {"name": "paywall_view", "props": {"item": "subscription_sheet"}, "ts": now},
        {"name": "plan_select", "props": {"item": "bhaktidhara_annual_399"}, "ts": now},
        {"name": "subscribe_tap", "props": {"item": "bhaktidhara_annual_399"}, "ts": now},
        {"name": "subscription_purchase_start", "props": {"item": "bhaktidhara_annual_399"}, "ts": now},
        {"name": "aarti_open", "props": {"item": "ganpati_sukhakarta"}, "ts": now},
        {"name": "jaap_mala_complete", "props": {"item": "om_namah_shivaya"}, "ts": now},
        {"name": "mandir_ritual", "props": {"item": "Lord Shiva", "ritual": "diya"}, "ts": now},
    ]))


def test_admin_overview_includes_lifecycle_heatmap_and_mrr():
    client = TestClient(main.app)
    headers = {"X-Admin-Secret": main.ADMIN_SECRET}

    resp = client.get("/api/v1/admin/overview?days=30", headers=headers)
    assert resp.status_code == 200
    data = resp.json()

    assert data["kpis"]["total_installs"] == 2
    assert data["kpis"]["active_paid_subs"] == 1
    assert data["kpis"]["active_trial_subs"] == 1
    assert data["kpis"]["active_revenue_inr"] == 399
    assert data["kpis"]["mrr_inr"] > 0
    assert "lifecycle" in data
    assert len(data["weekday_hourly"]) == 7
    assert len(data["weekday_hourly"][0]) == 24
    assert "device_models" in data["breakdowns"]
    assert "Pixel 8" in data["breakdowns"]["device_models"]
    assert len(data["insights"]) >= 1


def test_admin_revenue_endpoint():
    client = TestClient(main.app)
    headers = {"X-Admin-Secret": main.ADMIN_SECRET}

    resp = client.get("/api/v1/admin/revenue?days=30", headers=headers)
    assert resp.status_code == 200
    data = resp.json()

    assert data["kpis"]["paid_subscriptions"] == 1
    assert data["kpis"]["trial_subscriptions"] == 1
    assert data["kpis"]["active_revenue_inr"] == 399
    assert 390 <= data["kpis"]["arr_inr"] <= 405
    assert data["funnel"]["paywall_views"] == 1
    assert data["funnel"]["activations"] >= 1
    assert len(data["by_plan"]) == 4
    assert len(data["subscriptions"]) == 2


def test_admin_trends_and_retention_endpoints():
    client = TestClient(main.app)
    headers = {"X-Admin-Secret": main.ADMIN_SECRET}

    tr = client.get("/api/v1/admin/trends?days=30", headers=headers)
    assert tr.status_code == 200
    tr_data = tr.json()
    assert tr_data["summary"]["malas_curr"] >= 1
    assert len(tr_data["feature_momentum"]) >= 1
    assert len(tr_data["content"]["aartis"]) >= 1

    rt = client.get("/api/v1/admin/retention?weeks=4", headers=headers)
    assert rt.status_code == 200
    rt_data = rt.json()
    assert len(rt_data["curve"]) == 5
    assert "1 day" in rt_data["active_days_buckets"]


def test_user_detail_includes_subscriptions_and_dashboard_html():
    client = TestClient(main.app)
    headers = {"X-Admin-Secret": main.ADMIN_SECRET}

    u = client.get("/api/v1/admin/users/dev-paid-1", headers=headers)
    assert u.status_code == 200
    assert len(u.json()["subscriptions"]) == 1

    html = client.get("/admin")
    assert html.status_code == 200
    assert "view-revenue" in html.text
    assert "view-trends" in html.text
    assert "notify-eta-input" in html.text


def test_deity_request_two_stage_ack_and_live_notify():
    client = TestClient(main.app)
    headers = {"X-Admin-Secret": main.ADMIN_SECRET}

    req_resp = client.post(
        "/api/v1/deity-request",
        data={"deviceId": "dev-paid-1", "deityName": "मोरखडी Siddheshwar", "lang": "mr", "source": "aarti_search"},
    )
    assert req_resp.status_code == 200

    list_resp = client.get("/api/v1/admin/deity-requests?days=30", headers=headers)
    assert list_resp.status_code == 200
    items = list_resp.json()["requests"]
    target = next(r for r in items if r["deityName"] == "मोरखडी Siddheshwar")
    assert target["acked"] is False
    assert target["notified"] is False

    # Stage 1: Acknowledge with ETA
    ack_resp = client.post(
        f"/api/v1/admin/deity-requests/{target['id']}/notify",
        headers=headers,
        json={
            "title": "🙏 मोरखडी Siddheshwar — विनंती मिळाली!",
            "body": "आम्ही २४ तास मध्ये तुमची आरती अपडेट करत आहोत.",
            "stage": "ack",
            "eta": "24 hours",
            "route": "",
        },
    )
    assert ack_resp.status_code == 200
    assert ack_resp.json()["stage"] == "ack"
    assert ack_resp.json()["eta"] == "24 hours"

    after_ack = next(
        r for r in client.get("/api/v1/admin/deity-requests?days=30", headers=headers).json()["requests"]
        if r["id"] == target["id"]
    )
    assert after_ack["acked"] is True
    assert after_ack["ackEta"] == "24 hours"
    assert after_ack["notified"] is False

    # Verify in-app inbox message was created
    inbox = client.get("/api/v1/notifications?deviceId=dev-paid-1").json()["notifications"]
    assert any("मोरखडी Siddheshwar" in n["title"] for n in inbox)

    # Stage 2: Notify when live
    live_resp = client.post(
        f"/api/v1/admin/deity-requests/{target['id']}/notify",
        headers=headers,
        json={
            "title": "मोरखडी Siddheshwar जोडली गेली आहे!",
            "body": "आत्ताच पाहा.",
            "stage": "live",
            "route": "deity",
            "deityKey": "Siddheshwar",
        },
    )
    assert live_resp.status_code == 200
    assert live_resp.json()["stage"] == "live"

    after_live = next(
        r for r in client.get("/api/v1/admin/deity-requests?days=30", headers=headers).json()["requests"]
        if r["id"] == target["id"]
    )
    assert after_live["acked"] is True
    assert after_live["notified"] is True
