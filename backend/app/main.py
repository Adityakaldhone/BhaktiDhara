import csv
import hmac
import io
import os
import logging
from contextlib import asynccontextmanager
from datetime import datetime, timezone, timedelta
from pathlib import Path
from typing import Optional, List, Dict, Any

from fastapi import FastAPI, Query, Header, HTTPException, Depends, status
from fastapi.responses import HTMLResponse, StreamingResponse, FileResponse
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field
# pyrefly: ignore [missing-import]
from apscheduler.schedulers.asyncio import AsyncIOScheduler
# pyrefly: ignore [missing-import]
from apscheduler.triggers.cron import CronTrigger

from app.database import (
    init_db,
    ist_today_str,
    clear_cache,
    increment_api_stat,
    record_device_ping,
    record_events,
    get_admin_metrics,
    get_overview,
    get_retention,
    list_users,
    export_users,
    get_user_detail,
    update_user,
    delete_user,
    get_engagement,
    list_announcements,
    create_announcement,
    update_announcement,
    delete_announcement,
    get_app_config,
    save_app_config,
    get_system_status,
    log_admin_action,
    save_push_token,
    delete_push_tokens,
    get_push_tokens_for,
    estimate_push_reach,
    create_push_campaign,
    list_push_campaigns,
    get_push_campaign,
    get_due_push_campaign_ids,
    claim_push_campaign,
    record_push_result,
    set_push_campaign_status,
    delete_push_campaign,
    get_push_stats,
    record_subscription,
    get_device_subscription_status,
    cancel_subscription_by_token,
    get_subscription_stats,
)
from app.cron import (
    run_daily_precache_job,
    build_precache_items,
    precache_running,
    RASHI_NAMES,
    send_daily_morning_horoscope_push,
)
from app.vedic_cache import (
    GeminiBusy,
    get_or_create_horoscope,
    get_or_create_panchang,
    limiter_status,
)
from app.push_service import (
    PushNotConfigured,
    push_status,
    build_topic_target,
    send_to_topic_target,
    send_to_tokens,
)
from app.gemini_service import consult_vedic_ai

# Logging setup
logging.basicConfig(level=logging.INFO, format="%(asctime)s - %(levelname)s - %(message)s")
logger = logging.getLogger("bhaktidhara.api")

DEFAULT_ADMIN_SECRET = "mandir_secret_2026"
ADMIN_SECRET = os.getenv("ADMIN_SECRET", DEFAULT_ADMIN_SECRET)
STATIC_DIR = Path(__file__).parent / "static"
STARTED_AT = datetime.now(timezone.utc)
scheduler = AsyncIOScheduler()


@asynccontextmanager
async def lifespan(app: FastAPI):
    # 1. Initialize SQLite Database
    await init_db()
    logger.info("SQLite Database initialized.")
    if ADMIN_SECRET == DEFAULT_ADMIN_SECRET:
        logger.warning("ADMIN_SECRET is still the default value. Set a strong secret in .env!")

    # 2. Schedule Nightly Precaching Cron Job at 00:05 AM IST (18:35 UTC)
    scheduler.add_job(
        run_daily_precache_job,
        trigger=CronTrigger(hour=18, minute=35, timezone="UTC"),  # 00:05 AM IST
        id="nightly_vedic_precache",
        replace_existing=True,
        max_instances=1,
        misfire_grace_time=3600,
    )
    scheduler.add_job(
        run_due_push_campaigns,
        trigger="interval",
        minutes=1,
        id="push_campaign_dispatcher",
        replace_existing=True,
        max_instances=1,
        coalesce=True,
    )
    # 3. Schedule Daily 6:00 AM IST Curiosity Cliffhanger Push (00:30 UTC)
    scheduler.add_job(
        send_daily_morning_horoscope_push,
        trigger=CronTrigger(hour=0, minute=30, timezone="UTC"),  # 06:00 AM IST
        id="morning_horoscope_curiosity_push",
        replace_existing=True,
        max_instances=1,
        misfire_grace_time=1800,
    )
    scheduler.start()
    logger.info("Nightly precaching (00:05 AM IST) and morning push (06:00 AM IST) schedulers started.")
    logger.info("Push notifications: %s", push_status())

    yield

    scheduler.shutdown()
    logger.info("Scheduler shutdown.")


app = FastAPI(
    title="BhaktiDhara API",
    description="High-performance, privacy-first Vedic Astrology & Mandir telemetry backend for Hetzner VPS",
    version="1.1.0",
    lifespan=lifespan,
)

# Enable CORS for Flutter Web & Mobile
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# ── Auth ─────────────────────────────────────────────────────────────────────

def _secret_ok(candidate: Optional[str]) -> bool:
    return bool(candidate) and hmac.compare_digest(candidate.encode(), ADMIN_SECRET.encode())


async def require_admin(
    x_admin_secret: Optional[str] = Header(None),
    secret: Optional[str] = Query(None, description="Legacy: admin secret as query param"),
):
    if not (_secret_ok(x_admin_secret) or _secret_ok(secret)):
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid admin secret")


# ── Models ───────────────────────────────────────────────────────────────────

class DevicePingRequest(BaseModel):
    deviceId: str
    platform: str = "android"  # android, ios, web
    appVersion: str = "1.0.4"
    locale: str = "mr"
    isVip: bool = False
    userName: Optional[str] = None
    city: Optional[str] = None
    state: Optional[str] = None
    country: Optional[str] = None


class SubscriptionVerifyRequest(BaseModel):
    deviceId: str
    purchaseToken: str
    productId: str
    platform: str = "android"
    orderId: Optional[str] = ""
    isTrial: bool = False
    rawReceipt: Optional[str] = ""


class TelemetryEvent(BaseModel):
    name: str
    props: Dict[str, Any] = Field(default_factory=dict)
    ts: Optional[str] = None


class TelemetryEventBatch(BaseModel):
    deviceId: str
    events: List[TelemetryEvent]


class UserUpdateRequest(BaseModel):
    notes: Optional[str] = None
    vipGranted: Optional[bool] = None
    blocked: Optional[bool] = None
    userName: Optional[str] = None


class AnnouncementCreate(BaseModel):
    title: str
    body: str
    locale: str = "all"
    link: str = ""
    expiresAt: Optional[str] = None


class AnnouncementUpdate(BaseModel):
    active: Optional[bool] = None


class PushTokenRequest(BaseModel):
    deviceId: str
    token: str
    enabled: bool = True
    platform: str = "android"


class PushTarget(BaseModel):
    audience: str = Field("all", description="all, vip, free, dormant, user")
    locale: str = ""
    platform: str = ""
    deviceId: str = ""
    dormantDays: int = Field(7, ge=1, le=365)


class PushCampaignCreate(PushTarget):
    title: str
    body: str
    imageUrl: str = ""
    route: str = Field("", description="'', aarti, panchang, jaap, horoscope, bhajan")
    aartiId: str = ""
    sendAt: Optional[str] = Field(None, description="ISO datetime; omit to send immediately")
    repeat: str = Field("none", description="none, daily")


class AppConfigUpdate(BaseModel):
    min_supported_version: Optional[str] = None
    latest_version: Optional[str] = None
    update_url: Optional[str] = None
    force_update: Optional[bool] = None
    maintenance_mode: Optional[bool] = None
    maintenance_message: Optional[str] = None
    feature_flags: Optional[Dict[str, bool]] = None


class VedicAiConsultRequest(BaseModel):
    rashi: str = Field(..., description="Rashi ID e.g. aries, taurus, etc.")
    question: str = Field(..., description="User's personal question")
    lang: str = Field("mr", description="mr, hi, en")
    initial: Optional[str] = Field(None, description="Optional user name initial")


# ── Public Endpoints ─────────────────────────────────────────────────────────

@app.get("/")
@app.get("/api/health")
def health_check():
    return {
        "service": "BhaktiDhara Sacred API",
        "status": "healthy",
        "version": app.version,
        "timestamp": datetime.now(timezone.utc).isoformat(),
    }


@app.get("/api/v1/horoscope")
async def get_horoscope_endpoint(
    rashi: str = Query(..., description="Rashi ID e.g. aries, taurus, etc."),
    period: str = Query("today", description="today, tomorrow, weekly"),
    lang: str = Query("mr", description="mr, hi, en"),
    force_refresh: bool = Query(False, description="Bypass cache"),
):
    """
    Returns horoscope reading.
    First checks SQLite cache (0ms). If missing, calls Gemini once, caches it, and returns.
    """
    ist_now = datetime.now(timezone.utc) + timedelta(hours=5, minutes=30)
    today_str = ist_now.strftime("%Y-%m-%d")
    rashi_id, period_id, lang_id = rashi.lower(), period.lower(), lang.lower()
    rashi_name = RASHI_NAMES.get(rashi_id, {}).get(lang_id, rashi.capitalize())

    try:
        reading, source = await get_or_create_horoscope(
            today_str, rashi_id, rashi_name, period_id, lang_id, force_refresh
        )
    except GeminiBusy as e:
        raise HTTPException(status_code=status.HTTP_503_SERVICE_UNAVAILABLE, detail=str(e))
    except Exception as e:
        logger.error(f"Failed to generate horoscope for {rashi}: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Unable to generate horoscope: {str(e)}",
        )

    if source == "cache":
        await increment_api_stat("horoscope_cache_hit")
    return {"source": source, "cachedDate": today_str, "reading": reading}


@app.get("/api/v1/panchang")
async def get_panchang_endpoint(
    city: str = Query("pune", description="City identifier or name"),
    date: Optional[str] = Query(None, description="YYYY-MM-DD or defaults to today"),
    lang: str = Query("mr", description="mr, hi, en"),
    force_refresh: bool = Query(False, description="Bypass cache"),
):
    """
    Returns authentic Vedic Panchang.
    Checks SQLite cache first. If missing, generates via Gemini, caches, and returns.
    """
    if not date:
        ist_now = datetime.now(timezone.utc) + timedelta(hours=5, minutes=30)
        date_str = ist_now.strftime("%Y-%m-%d")
    else:
        date_str = date

    clean_city_id = city.lower().strip()

    try:
        panchang, source = await get_or_create_panchang(
            date_str, clean_city_id, city, lang.lower(), force_refresh
        )
    except GeminiBusy as e:
        raise HTTPException(status_code=status.HTTP_503_SERVICE_UNAVAILABLE, detail=str(e))
    except Exception as e:
        logger.error(f"Failed to generate panchang for {city}: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Unable to generate panchang: {str(e)}",
        )

    if source == "cache":
        await increment_api_stat("panchang_cache_hit")
    return {"source": source, "date": date_str, "panchang": panchang}


@app.post("/api/v1/telemetry/ping")
async def anonymous_ping_endpoint(payload: DevicePingRequest):
    """
    Records an anonymous heartbeat ping from the app.
    Supports optional devotee user name and location if user granted permissions.
    Returns admin-controlled flags (e.g. complimentary VIP) for this device.
    """
    flags = await record_device_ping(
        device_id=payload.deviceId[:64],
        platform=payload.platform.lower()[:16],
        app_version=payload.appVersion[:20],
        locale=payload.locale.lower()[:8],
        is_vip=payload.isVip,
        user_name=payload.userName,
        city=payload.city,
        state=payload.state,
        country=payload.country,
    )
    return {"status": "ok", **flags}


@app.post("/api/v1/vedic-ai/consult")
async def consult_vedic_ai_endpoint(payload: VedicAiConsultRequest):
    """
    Provides personalized Vedic AI astrological consultation for user question.
    """
    try:
        result = await consult_vedic_ai(
            rashi_id=payload.rashi,
            question=payload.question,
            lang_code=payload.lang,
            initial=payload.initial,
        )
        await increment_api_stat("vedic_ai_consultation")
        return {"result": result}
    except Exception as e:
        logger.error(f"Failed to consult Vedic AI: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Unable to process Vedic consultation: {str(e)}",
        )


@app.post("/api/v1/telemetry/event")
async def telemetry_event_endpoint(payload: TelemetryEventBatch):
    """Records a batch of anonymous feature-usage events (aarti opened, jaap completed...)."""
    await record_events(payload.deviceId[:64], [e.model_dump() for e in payload.events])
    return {"status": "ok"}


@app.post("/api/v1/telemetry/push-token")
async def push_token_endpoint(payload: PushTokenRequest):
    """Registers the device's FCM token so it can be targeted from the admin dashboard."""
    await save_push_token(
        payload.deviceId[:64], payload.token[:4096], payload.enabled, payload.platform.lower()[:16]
    )
    return {"status": "ok"}


@app.get("/api/v1/config")
async def public_config_endpoint():
    """Remote config the app reads on launch: force-update, maintenance mode, feature flags."""
    return await get_app_config()


@app.get("/api/v1/announcements")
async def public_announcements_endpoint(locale: str = Query("", description="mr, hi, en")):
    """Live in-app announcements for the given language."""
    return {"announcements": await list_announcements(only_live=True, locale=locale.lower())}


# ── Subscription & In-App Purchase Endpoints ─────────────────────────────────

@app.post("/api/v1/subscription/verify")
async def verify_subscription_endpoint(payload: SubscriptionVerifyRequest):
    """
    Verifies and records an in-app subscription purchase from Google Play Billing.
    Activates VIP status and returns verified entitlement dates.
    """
    if not payload.deviceId or not payload.purchaseToken or not payload.productId:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Missing deviceId, purchaseToken, or productId",
        )

    result = await record_subscription(
        device_id=payload.deviceId[:64],
        product_id=payload.productId[:64],
        purchase_token=payload.purchaseToken[:512],
        platform=payload.platform.lower()[:16],
        order_id=payload.orderId or "",
        is_trial=payload.isTrial,
        auto_renewing=True,
        raw_receipt=payload.rawReceipt or "",
    )
    await increment_api_stat("subscription_verified")
    logger.info(
        f"Subscription verified: device={payload.deviceId[:12]}..., product={payload.productId}, trial={payload.isTrial}"
    )
    return result


@app.get("/api/v1/subscription/status")
async def subscription_status_endpoint(deviceId: str = Query(..., description="Device ID")):
    """Returns active subscription status and entitlement for a device."""
    return await get_device_subscription_status(deviceId[:64])


@app.post("/api/v1/subscription/webhook")
async def subscription_webhook_endpoint(payload: Dict[str, Any]):
    """
    Receives Google Cloud Pub/Sub Real-Time Developer Notifications (RTDN).
    Handles SUBSCRIPTION_RENEWED, SUBSCRIPTION_CANCELED, SUBSCRIPTION_EXPIRED.
    """
    try:
        message = payload.get("message", {})
        data_b64 = message.get("data", "")
        if data_b64:
            import base64
            decoded_json = base64.b64decode(data_b64).decode("utf-8")
            event_data = json.loads(decoded_json)
        else:
            event_data = payload

        sub_notification = event_data.get("subscriptionNotification", {})
        token = sub_notification.get("purchaseToken")
        notification_type = sub_notification.get("notificationType")

        # 3: CANCELED, 12: REVOKED, 13: EXPIRED
        if token and notification_type in (3, 12, 13):
            await cancel_subscription_by_token(token)
            logger.info(f"Subscription cancelled via webhook for token: {token[:12]}...")

        return {"status": "ok"}
    except Exception as e:
        logger.warning(f"Error processing subscription webhook: {e}")
        return {"status": "error", "message": str(e)}


# ── Admin Dashboard (HTML) ───────────────────────────────────────────────────

@app.get("/admin", response_class=HTMLResponse, include_in_schema=False)
@app.get("/api/v1/admin/dashboard", response_class=HTMLResponse, include_in_schema=False)
async def admin_dashboard_html():
    """Single-page admin dashboard. Auth happens client-side via the X-Admin-Secret header."""
    return FileResponse(STATIC_DIR / "admin.html", media_type="text/html")


# ── Admin API ────────────────────────────────────────────────────────────────

admin = [Depends(require_admin)]


@app.get("/api/v1/admin/subscriptions", dependencies=admin)
async def admin_subscriptions_endpoint():
    """Returns subscription analytics and breakdown for admin control room."""
    return await get_subscription_stats()


@app.get("/api/v1/admin/stats", dependencies=admin)
async def admin_stats_endpoint():
    """Legacy summary: total downloads, DAU, MAU, VIP subscribers."""
    return {
        "status": "success",
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "metrics": await get_admin_metrics(),
    }


@app.get("/api/v1/admin/overview", dependencies=admin)
async def admin_overview_endpoint(days: int = Query(30, ge=7, le=180)):
    return await get_overview(days)


@app.get("/api/v1/admin/retention", dependencies=admin)
async def admin_retention_endpoint(weeks: int = Query(8, ge=2, le=26)):
    return await get_retention(weeks)


@app.get("/api/v1/admin/users", dependencies=admin)
async def admin_users_endpoint(
    search: str = "",
    platform: str = "",
    locale: str = "",
    tier: str = Query("", description="vip, paid, granted, free"),
    status_filter: str = Query("", alias="status", description="active7d, dormant, new7d, blocked"),
    sort: str = Query("last_seen", description="last_seen, first_seen, pings, name"),
    page: int = Query(1, ge=1),
    page_size: int = Query(25, ge=1, le=200),
):
    return await list_users(search.strip(), platform, locale, tier, status_filter, sort, page, page_size)


@app.get("/api/v1/admin/users/export.csv", dependencies=admin)
async def admin_users_export_endpoint(
    search: str = "",
    platform: str = "",
    locale: str = "",
    tier: str = "",
    status_filter: str = Query("", alias="status"),
):
    users = await export_users(
        search=search.strip(), platform=platform, locale=locale, tier=tier, status=status_filter
    )
    buf = io.StringIO()
    columns = ["deviceId", "userName", "city", "state", "country", "platform", "appVersion", "locale",
               "isVip", "vipGranted", "blocked", "firstSeen", "lastSeen", "pingCount", "notes"]
    writer = csv.DictWriter(buf, fieldnames=columns, extrasaction="ignore")
    writer.writeheader()
    for user in users:
        # Neutralise spreadsheet formula injection from client-supplied names/cities.
        writer.writerow({
            k: ("'" + v if isinstance(v, str) and v[:1] in ("=", "+", "-", "@") else v)
            for k, v in user.items()
        })
    await log_admin_action("export_users", f"{len(users)} rows")
    filename = f"bhaktidhara_users_{datetime.now(timezone.utc).strftime('%Y%m%d')}.csv"
    return StreamingResponse(
        iter([buf.getvalue()]),
        media_type="text/csv",
        headers={"Content-Disposition": f'attachment; filename="{filename}"'},
    )


@app.get("/api/v1/admin/users/{device_id}", dependencies=admin)
async def admin_user_detail_endpoint(device_id: str):
    detail = await get_user_detail(device_id)
    if not detail:
        raise HTTPException(status_code=404, detail="User not found")
    return detail


@app.patch("/api/v1/admin/users/{device_id}", dependencies=admin)
async def admin_user_update_endpoint(device_id: str, payload: UserUpdateRequest):
    fields = payload.model_dump(exclude_none=True)
    if not await update_user(device_id, fields):
        raise HTTPException(status_code=404, detail="User not found or nothing to update")
    await log_admin_action("update_user", f"{device_id[:12]}… {sorted(fields.keys())}")
    return await get_user_detail(device_id)


@app.delete("/api/v1/admin/users/{device_id}", dependencies=admin)
async def admin_user_delete_endpoint(device_id: str):
    if not await delete_user(device_id):
        raise HTTPException(status_code=404, detail="User not found")
    await log_admin_action("delete_user", device_id[:12] + "…")
    return {"status": "deleted"}


@app.get("/api/v1/admin/engagement", dependencies=admin)
async def admin_engagement_endpoint(days: int = Query(7, ge=1, le=180), event: str = ""):
    return await get_engagement(days, event)


@app.get("/api/v1/admin/announcements", dependencies=admin)
async def admin_announcements_list():
    return {"announcements": await list_announcements()}


@app.post("/api/v1/admin/announcements", dependencies=admin)
async def admin_announcements_create(payload: AnnouncementCreate):
    if not payload.title.strip() or not payload.body.strip():
        raise HTTPException(status_code=400, detail="Title and body are required")
    ann_id = await create_announcement(payload.title, payload.body, payload.locale, payload.link, payload.expiresAt)
    await log_admin_action("create_announcement", payload.title[:80])
    return {"id": ann_id}


@app.patch("/api/v1/admin/announcements/{ann_id}", dependencies=admin)
async def admin_announcements_update(ann_id: int, payload: AnnouncementUpdate):
    if not await update_announcement(ann_id, payload.active):
        raise HTTPException(status_code=404, detail="Announcement not found")
    await log_admin_action("toggle_announcement", f"#{ann_id} active={payload.active}")
    return {"status": "ok"}


@app.delete("/api/v1/admin/announcements/{ann_id}", dependencies=admin)
async def admin_announcements_delete(ann_id: int):
    if not await delete_announcement(ann_id):
        raise HTTPException(status_code=404, detail="Announcement not found")
    await log_admin_action("delete_announcement", f"#{ann_id}")
    return {"status": "deleted"}


@app.get("/api/v1/admin/config", dependencies=admin)
async def admin_config_get():
    return await get_app_config()


@app.put("/api/v1/admin/config", dependencies=admin)
async def admin_config_put(payload: AppConfigUpdate):
    updates = payload.model_dump(exclude_none=True)
    config = await save_app_config(updates)
    await log_admin_action("update_config", ", ".join(sorted(updates.keys())))
    return config


@app.get("/api/v1/admin/system", dependencies=admin)
async def admin_system_endpoint():
    data = await get_system_status()
    job = scheduler.get_job("nightly_vedic_precache")
    data["server"] = {
        "version": app.version,
        "started_at": STARTED_AT.isoformat(),
        "uptime_seconds": int((datetime.now(timezone.utc) - STARTED_AT).total_seconds()),
        "gemini_model": os.getenv("GEMINI_MODEL", ""),
        "gemini_key_configured": bool(os.getenv("GEMINI_API_KEY")),
        "default_admin_secret": ADMIN_SECRET == DEFAULT_ADMIN_SECRET,
        "next_precache_run": job.next_run_time.isoformat() if job and job.next_run_time else None,
        "precache_items": len(build_precache_items(ist_today_str())),
        "precache_running": precache_running(),
        **limiter_status(),
    }
    return data


@app.post("/api/v1/admin/trigger-precache", dependencies=admin)
async def trigger_precache_endpoint():
    """Manually triggers the precache job immediately."""
    if precache_running():
        return {"status": "already_running"}
    scheduler.add_job(run_daily_precache_job, id="manual_precache_run", replace_existing=True)
    await log_admin_action("trigger_precache")
    return {"status": "precache_job_started"}


@app.post("/api/v1/admin/cache/clear", dependencies=admin)
async def admin_cache_clear_endpoint(
    older_than_days: Optional[int] = Query(None, ge=0, description="Omit to clear everything"),
):
    result = await clear_cache(older_than_days)
    await log_admin_action(
        "clear_cache", "all" if older_than_days is None else f"older than {older_than_days}d"
    )
    return result


# ── Push notifications ───────────────────────────────────────────────────────

PUSH_ROUTES = {"", "aarti", "panchang", "jaap", "horoscope", "bhajan"}
PUSH_AUDIENCES = {"all", "vip", "free", "dormant", "user"}


def _parse_iso_utc(value: str) -> datetime:
    dt = datetime.fromisoformat(value.strip().replace("Z", "+00:00"))
    if dt.tzinfo is None:
        dt = dt.replace(tzinfo=timezone.utc)
    return dt.astimezone(timezone.utc)


def _next_daily_run(scheduled_at: Optional[str]) -> str:
    now = datetime.now(timezone.utc)
    base = _parse_iso_utc(scheduled_at) if scheduled_at else now
    # The dispatcher can fire slightly before the stored time (SQLite compares whole seconds),
    # so anything due within the next minute counts as today's run.
    while base <= now + timedelta(minutes=1):
        base += timedelta(days=1)
    return base.isoformat()


async def dispatch_push_campaign(campaign_id: int, allow_statuses: tuple = ("scheduled",)) -> Dict[str, Any]:
    """Sends one campaign now. Returns the delivery result."""
    if not await claim_push_campaign(campaign_id, allow_statuses):
        return {"skipped": True}
    c = await get_push_campaign(campaign_id)
    next_run = _next_daily_run(c.get("scheduled_at")) if c.get("repeat") == "daily" else None
    try:
        if c["audience"] in ("user", "dormant"):
            tokens = await get_push_tokens_for(
                c["audience"], c["locale"], c["platform"], c["target_device_id"], c["dormant_days"]
            )
            result = await send_to_tokens(c, tokens)
            await delete_push_tokens(result["invalid_tokens"])
            reach = result["success"]
        else:
            target = build_topic_target(c["audience"], c["locale"], c["platform"])
            result = await send_to_topic_target(c, target)
            reach = await estimate_push_reach(c["audience"], c["locale"], c["platform"]) if result["success"] else 0
    except PushNotConfigured as e:
        result, reach = {"success": 0, "failure": 1, "error": str(e), "invalid_tokens": []}, 0
    except Exception as e:
        logger.exception("Push campaign %s failed", campaign_id)
        result, reach = {"success": 0, "failure": 1, "error": str(e), "invalid_tokens": []}, 0

    await record_push_result(campaign_id, result["success"], result["failure"], result["error"], next_run, reach)
    logger.info("Push campaign %s: %s ok, %s failed", campaign_id, result["success"], result["failure"])
    return {
        "success": result["success"],
        "failure": result["failure"],
        "error": result["error"],
        "reach": reach,
        "removedInvalidTokens": len(result["invalid_tokens"]),
        "nextRun": next_run,
    }


async def run_due_push_campaigns():
    for campaign_id in await get_due_push_campaign_ids():
        await dispatch_push_campaign(campaign_id)


@app.get("/api/v1/admin/push/overview", dependencies=admin)
async def admin_push_overview():
    return {
        "status": push_status(),
        "stats": await get_push_stats(),
        "campaigns": await list_push_campaigns(),
    }


@app.post("/api/v1/admin/push/estimate", dependencies=admin)
async def admin_push_estimate(payload: PushTarget):
    reach = await estimate_push_reach(
        payload.audience, payload.locale, payload.platform, payload.deviceId.strip(), payload.dormantDays
    )
    target = (
        {"tokens": True} if payload.audience in ("user", "dormant")
        else build_topic_target(payload.audience, payload.locale, payload.platform)
    )
    return {"reach": reach, "target": target}


@app.post("/api/v1/admin/push/campaigns", dependencies=admin)
async def admin_push_create(payload: PushCampaignCreate):
    if not payload.title.strip() or not payload.body.strip():
        raise HTTPException(status_code=400, detail="Title and message are required")
    if payload.audience not in PUSH_AUDIENCES:
        raise HTTPException(status_code=400, detail="Unknown audience")
    if payload.route not in PUSH_ROUTES:
        raise HTTPException(status_code=400, detail="Unknown screen to open")
    if payload.audience == "user" and not payload.deviceId.strip():
        raise HTTPException(status_code=400, detail="Device ID is required for a single-user push")
    if payload.route == "aarti" and not payload.aartiId.strip():
        raise HTTPException(status_code=400, detail="Aarti ID is required to open an aarti")
    if payload.repeat not in ("none", "daily"):
        raise HTTPException(status_code=400, detail="Repeat must be 'none' or 'daily'")

    now = datetime.now(timezone.utc)
    try:
        send_at = (_parse_iso_utc(payload.sendAt) if payload.sendAt else now).replace(microsecond=0)
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid schedule date")
    send_immediately = send_at <= now + timedelta(seconds=30)

    campaign_id = await create_push_campaign({
        "title": payload.title.strip()[:200],
        "body": payload.body.strip()[:1000],
        "image_url": payload.imageUrl.strip()[:500],
        "route": payload.route,
        "aarti_id": payload.aartiId.strip()[:120],
        "audience": payload.audience,
        "locale": payload.locale if payload.locale in ("mr", "hi", "en") else "",
        "platform": payload.platform if payload.platform in ("android", "ios") else "",
        "target_device_id": payload.deviceId.strip()[:64],
        "dormant_days": payload.dormantDays,
        "status": "scheduled",
        "scheduled_at": send_at.isoformat(),
        "repeat": payload.repeat,
    })
    await log_admin_action(
        "push_create",
        f"#{campaign_id} '{payload.title[:60]}' → {payload.audience}"
        f"{'/' + payload.locale if payload.locale else ''} {'now' if send_immediately else send_at.isoformat()}"
        f"{' daily' if payload.repeat == 'daily' else ''}",
    )
    if send_immediately:
        result = await dispatch_push_campaign(campaign_id)
        return {"id": campaign_id, "sent": True, **result}
    return {"id": campaign_id, "sent": False, "scheduledAt": send_at.isoformat()}


@app.post("/api/v1/admin/push/campaigns/{campaign_id}/send", dependencies=admin)
async def admin_push_send_now(campaign_id: int):
    campaign = await get_push_campaign(campaign_id)
    if not campaign:
        raise HTTPException(status_code=404, detail="Campaign not found")
    result = await dispatch_push_campaign(campaign_id, ("scheduled", "sent", "failed", "cancelled"))
    if result.get("skipped"):
        raise HTTPException(status_code=409, detail="Campaign is already being sent")
    await log_admin_action("push_send_now", f"#{campaign_id}")
    return result


@app.post("/api/v1/admin/push/campaigns/{campaign_id}/cancel", dependencies=admin)
async def admin_push_cancel(campaign_id: int):
    campaign = await get_push_campaign(campaign_id)
    if not campaign or campaign["status"] != "scheduled":
        raise HTTPException(status_code=400, detail="Only scheduled campaigns can be paused")
    await set_push_campaign_status(campaign_id, "cancelled")
    await log_admin_action("push_cancel", f"#{campaign_id}")
    return {"status": "cancelled"}


@app.post("/api/v1/admin/push/campaigns/{campaign_id}/resume", dependencies=admin)
async def admin_push_resume(campaign_id: int):
    campaign = await get_push_campaign(campaign_id)
    if not campaign or campaign["status"] != "cancelled":
        raise HTTPException(status_code=400, detail="Only paused campaigns can be resumed")
    next_run = _next_daily_run(campaign["scheduled_at"]) if campaign["repeat"] == "daily" else None
    await set_push_campaign_status(campaign_id, "scheduled", next_run)
    await log_admin_action("push_resume", f"#{campaign_id}")
    return {"status": "scheduled"}


@app.delete("/api/v1/admin/push/campaigns/{campaign_id}", dependencies=admin)
async def admin_push_delete(campaign_id: int):
    if not await delete_push_campaign(campaign_id):
        raise HTTPException(status_code=404, detail="Campaign not found")
    await log_admin_action("push_delete", f"#{campaign_id}")
    return {"status": "deleted"}


@app.post("/api/v1/admin/push/send-morning-horoscope", dependencies=admin)
async def admin_send_morning_horoscope():
    """Manually triggers the daily 6:00 AM IST Horoscope curiosity cliffhanger push immediately."""
    result = await send_daily_morning_horoscope_push()
    await log_admin_action("trigger_morning_push", f"Result: {result}")
    return {"status": "ok", "result": result}

