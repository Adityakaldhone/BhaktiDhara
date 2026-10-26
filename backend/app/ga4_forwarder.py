"""Forwards Google Play subscription renewals to GA4 via the Measurement Protocol.

The app logs the first charge itself (`purchase` / `trial_start`). Renewals and
trial→paid conversions are charged by Play while the app may be closed, so the
RTDN webhook reports them here as `purchase` events for the device's GA4
`app_instance_id`, letting Google Ads tROAS see that revenue.

Env:
  GA4_API_SECRET        GA4 → Admin → Data streams → Android → Measurement Protocol API secrets
  GA4_FIREBASE_APP_ID   Firebase Android app ID (defaults to the BhaktiDhara app)
  GA4_MP_DEBUG=1        send to the validation endpoint instead (nothing is recorded)

Validate the setup without recording data:
  GA4_API_SECRET=... python -m app.ga4_forwarder <app_instance_id>
"""
import hashlib
import json
import logging
import os
import sys
import time
from datetime import datetime, timezone
from typing import Any, Dict, Optional

import httpx

from app.database import (
    PLAN_PRICES_INR,
    claim_rtdn_message,
    get_subscription_by_token,
    renew_subscription_by_token,
)

logger = logging.getLogger(__name__)

GA4_API_SECRET = os.getenv("GA4_API_SECRET", "")
GA4_FIREBASE_APP_ID = os.getenv("GA4_FIREBASE_APP_ID", "1:72583369850:android:d6506f510ce6a02dd9d7c3")
GA4_MP_DEBUG = os.getenv("GA4_MP_DEBUG", "") == "1"

# RTDN notificationType values that mean Play just charged the user.
# A free trial converting to paid arrives as SUBSCRIPTION_RENEWED.
# SUBSCRIPTION_PURCHASED (4) is skipped: the app already logged that charge.
SUBSCRIPTION_RECOVERED = 1
SUBSCRIPTION_RENEWED = 2
REVENUE_NOTIFICATION_TYPES = {SUBSCRIPTION_RECOVERED, SUBSCRIPTION_RENEWED}

# GA4 rejects backdated events older than 72 hours.
_MAX_BACKDATE_MICROS = 72 * 3600 * 1_000_000


def _endpoint() -> str:
    path = "debug/mp/collect" if GA4_MP_DEBUG else "mp/collect"
    return (
        f"https://www.google-analytics.com/{path}"
        f"?firebase_app_id={GA4_FIREBASE_APP_ID}&api_secret={GA4_API_SECRET}"
    )


def build_purchase_payload(
    app_instance_id: str,
    product_id: str,
    value: float,
    transaction_id: str,
    notification_type: int,
    event_time_ms: Optional[int] = None,
) -> Dict[str, Any]:
    payload: Dict[str, Any] = {
        "app_instance_id": app_instance_id,
        "events": [{
            "name": "purchase",
            "params": {
                "value": float(value),
                "currency": "INR",
                "transaction_id": transaction_id,
                "purchase_type": "recovered" if notification_type == SUBSCRIPTION_RECOVERED else "renewal",
                "items": [{
                    "item_id": product_id,
                    "item_name": product_id,
                    "item_category": "subscription",
                    "price": float(value),
                    "quantity": 1,
                }],
            },
        }],
    }
    if event_time_ms:
        micros = event_time_ms * 1000
        if time.time() * 1_000_000 - micros < _MAX_BACKDATE_MICROS:
            payload["timestamp_micros"] = micros
    return payload


async def send_to_ga4(payload: Dict[str, Any]) -> bool:
    async with httpx.AsyncClient(timeout=10.0) as client:
        resp = await client.post(_endpoint(), json=payload)
    if GA4_MP_DEBUG:
        logger.info("GA4 MP validation: %s", resp.text)
    return 200 <= resp.status_code < 300


async def handle_subscription_notification(
    notification: Dict[str, Any],
    message_key: str,
    event_time_ms: Optional[int] = None,
) -> str:
    """Processes one RTDN subscriptionNotification. Returns a short status for logging."""
    notification_type = notification.get("notificationType")
    token = notification.get("purchaseToken")
    if notification_type not in REVENUE_NOTIFICATION_TYPES or not token:
        return "ignored"
    if not await claim_rtdn_message(message_key):
        return "duplicate"

    sub = await get_subscription_by_token(token)
    if not sub:
        return "unknown_token"

    renewed_at = (
        datetime.fromtimestamp(event_time_ms / 1000, tz=timezone.utc) if event_time_ms
        else datetime.now(timezone.utc)
    )
    await renew_subscription_by_token(token, renewed_at)

    value = PLAN_PRICES_INR.get(sub["product_id"])
    if not GA4_API_SECRET or not sub["app_instance_id"] or not value:
        return "renewed_not_forwarded"

    digest = hashlib.sha256(message_key.encode()).hexdigest()[:16]
    transaction_id = f"{sub['order_id'] or 'rtdn'}:{digest}"
    payload = build_purchase_payload(
        sub["app_instance_id"], sub["product_id"], value, transaction_id, notification_type, event_time_ms
    )
    try:
        ok = await send_to_ga4(payload)
    except httpx.HTTPError as e:
        logger.warning("GA4 MP request failed: %s", e)
        ok = False
    return "forwarded" if ok else "forward_failed"


async def _validate(app_instance_id: str) -> None:
    global GA4_MP_DEBUG
    GA4_MP_DEBUG = True
    payload = build_purchase_payload(app_instance_id, "bhaktidhara_annual_399", 399.0, "validation-test", 2)
    async with httpx.AsyncClient(timeout=10.0) as client:
        resp = await client.post(_endpoint(), json=payload)
    print(json.dumps(resp.json(), indent=2))


if __name__ == "__main__":
    import asyncio

    if len(sys.argv) != 2 or not GA4_API_SECRET:
        sys.exit("Usage: GA4_API_SECRET=... python -m app.ga4_forwarder <app_instance_id>")
    asyncio.run(_validate(sys.argv[1]))
