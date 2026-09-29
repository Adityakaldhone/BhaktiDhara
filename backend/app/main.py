import os
import logging
from contextlib import asynccontextmanager
from datetime import datetime, timezone, timedelta
from typing import Optional

from fastapi import FastAPI, Query, Header, HTTPException, status
from fastapi.responses import HTMLResponse
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
# pyrefly: ignore [missing-import]
from apscheduler.schedulers.asyncio import AsyncIOScheduler
# pyrefly: ignore [missing-import]
from apscheduler.triggers.cron import CronTrigger

from app.database import (
    init_db,
    get_cached_horoscope,
    save_cached_horoscope,
    get_cached_panchang,
    save_cached_panchang,
    record_device_ping,
    get_admin_metrics,
)
from app.gemini_service import generate_horoscope, generate_panchang
from app.cron import run_daily_precache_job, RASHI_NAMES

# Logging setup
logging.basicConfig(level=logging.INFO, format="%(asctime)s - %(levelname)s - %(message)s")
logger = logging.getLogger("bhaktidhara.api")

ADMIN_SECRET = os.getenv("ADMIN_SECRET", "mandir_secret_2026")
scheduler = AsyncIOScheduler()


@asynccontextmanager
async def lifespan(app: FastAPI):
    # 1. Initialize SQLite Database
    await init_db()
    logger.info("SQLite Database initialized.")

    # 2. Schedule Nightly Precaching Cron Job at 00:05 AM IST (18:35 UTC)
    scheduler.add_job(
        run_daily_precache_job,
        trigger=CronTrigger(hour=18, minute=35, timezone="UTC"),  # 00:05 AM IST
        id="nightly_vedic_precache",
        replace_existing=True,
    )
    scheduler.start()
    logger.info("Nightly precaching scheduler started (00:05 AM IST).")

    yield

    scheduler.shutdown()
    logger.info("Scheduler shutdown.")


app = FastAPI(
    title="BhaktiDhara API",
    description="High-performance, privacy-first Vedic Astrology & Mandir telemetry backend for Hetzner VPS",
    version="1.0.0",
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


# ── Endpoints ────────────────────────────────────────────────────────────────

@app.get("/")
@app.get("/api/health")
def health_check():
    return {
        "service": "BhaktiDhara Sacred API",
        "status": "healthy",
        "version": "1.0.0",
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

    # 1. Check cache
    if not force_refresh:
        cached = await get_cached_horoscope(today_str, rashi.lower(), period.lower(), lang.lower())
        if cached:
            return {
                "source": "cache",
                "cachedDate": today_str,
                "reading": cached,
            }

    # 2. Cache miss: Generate once via Gemini
    rashi_info = RASHI_NAMES.get(rashi.lower(), {})
    rashi_name = rashi_info.get(lang.lower(), rashi.capitalize())

    try:
        fresh_reading = await generate_horoscope(
            rashi_name=rashi_name,
            period=period.lower(),
            lang_code=lang.lower(),
            date_text=today_str,
            rashi_id=rashi.lower(),
        )
        await save_cached_horoscope(
            date_str=today_str,
            rashi_id=rashi.lower(),
            period=period.lower(),
            lang_code=lang.lower(),
            data=fresh_reading,
        )
        return {
            "source": "gemini_generated",
            "cachedDate": today_str,
            "reading": fresh_reading,
        }
    except Exception as e:
        logger.error(f"Failed to generate horoscope for {rashi}: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Unable to generate horoscope: {str(e)}",
        )


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

    # 1. Check cache
    if not force_refresh:
        cached = await get_cached_panchang(date_str, clean_city_id, lang.lower())
        if cached:
            return {
                "source": "cache",
                "date": date_str,
                "panchang": cached,
            }

    # 2. Cache miss: Generate via Gemini
    try:
        fresh_panchang = await generate_panchang(
            city_name=city,
            date_str=date_str,
            lang_code=lang.lower(),
        )
        await save_cached_panchang(
            date_str=date_str,
            city_id=clean_city_id,
            lang_code=lang.lower(),
            data=fresh_panchang,
        )
        return {
            "source": "gemini_generated",
            "date": date_str,
            "panchang": fresh_panchang,
        }
    except Exception as e:
        logger.error(f"Failed to generate panchang for {city}: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Unable to generate panchang: {str(e)}",
        )


@app.post("/api/v1/telemetry/ping")
async def anonymous_ping_endpoint(payload: DevicePingRequest):
    """
    Records an anonymous heartbeat ping from the app.
    Supports optional devotee user name and location if user granted permissions.
    """
    await record_device_ping(
        device_id=payload.deviceId,
        platform=payload.platform.lower(),
        app_version=payload.appVersion,
        locale=payload.locale.lower(),
        is_vip=payload.isVip,
        user_name=payload.userName,
        city=payload.city,
        state=payload.state,
        country=payload.country,
    )
    return {"status": "ok"}


@app.get("/api/v1/admin/stats")
async def admin_stats_endpoint(
    secret: str = Query(..., description="Admin authentication secret key"),
):
    """
    Admin dashboard metric: Total downloads, DAU, MAU, VIP subscribers.
    Password protected via secret key.
    """
    if secret != ADMIN_SECRET:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid admin secret")

    metrics = await get_admin_metrics()
    return {
        "status": "success",
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "metrics": metrics,
    }


@app.get("/admin", response_class=HTMLResponse)
@app.get("/api/v1/admin/dashboard", response_class=HTMLResponse)
async def admin_dashboard_html(
    secret: str = Query(..., description="Admin authentication secret key"),
):
    """
    Visual Web Dashboard for monitoring app installs, DAU, VIP subscribers,
    user locations, and device activity.
    """
    if secret != ADMIN_SECRET:
        return HTMLResponse(
            status_code=401,
            content="""
            <!DOCTYPE html>
            <html>
            <head><title>BhaktiDhara Admin - Unauthorized</title></head>
            <body style="font-family:sans-serif;background:#0d0c15;color:#fff;display:flex;align-items:center;justify-content:center;height:100vh;margin:0;">
                <div style="background:#1a192b;padding:40px;border-radius:12px;border:1px solid #ff9933;text-align:center;">
                    <h2 style="color:#ff9933;">🔒 Access Denied</h2>
                    <p>Invalid Admin Secret Key. Please pass ?secret=YOUR_KEY</p>
                </div>
            </body>
            </html>
            """,
        )

    metrics = await get_admin_metrics()

    # Format cities HTML
    cities_html = "".join(
        f'<span style="background:rgba(255,153,51,0.15);border:1px solid rgba(255,153,51,0.4);color:#ffb84d;padding:6px 14px;border-radius:20px;font-size:13px;display:inline-block;margin:4px;">📍 {city} <b style="color:#fff;">({count})</b></span>'
        for city, count in metrics.get("cities", {}).items()
    ) or '<span style="color:#888;">No location data yet</span>'

    # Format platforms HTML
    platforms_html = "".join(
        f'<span style="background:rgba(100,149,237,0.15);border:1px solid rgba(100,149,237,0.4);color:#87cefa;padding:6px 14px;border-radius:20px;font-size:13px;display:inline-block;margin:4px;">📱 {p.upper()}: <b style="color:#fff;">{cnt}</b></span>'
        for p, cnt in metrics.get("platforms", {}).items()
    )

    # Format recent devices rows
    rows_html = "".join(
        f"""
        <tr style="border-bottom:1px solid #222035;">
            <td style="padding:12px;font-family:monospace;color:#ff9933;font-size:12px;">{d['deviceId'][:16]}...</td>
            <td style="padding:12px;color:#fff;font-weight:600;">{d['userName']}</td>
            <td style="padding:12px;color:#cbd5e1;">📍 {d['city']}</td>
            <td style="padding:12px;color:#94a3b8;"><span style="text-transform:uppercase;background:#2d294a;padding:2px 8px;border-radius:6px;font-size:11px;">{d['platform']}</span> v{d['appVersion']}</td>
            <td style="padding:12px;">{'<span style="color:#ffd700;font-weight:bold;background:rgba(255,215,0,0.15);padding:3px 10px;border-radius:12px;">⭐ VIP</span>' if d['isVip'] else '<span style="color:#64748b;font-size:12px;">Free</span>'}</td>
            <td style="padding:12px;color:#94a3b8;font-size:12px;">{d['lastSeen'].replace('T', ' ')[:19]}</td>
            <td style="padding:12px;color:#38bdf8;font-weight:bold;text-align:center;">{d['pingCount']}</td>
        </tr>
        """
        for d in metrics.get("recent_devices", [])
    ) or '<tr><td colspan="7" style="padding:20px;text-align:center;color:#64748b;">No devices recorded yet</td></tr>'

    html_content = f"""
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>BhaktiDhara Telemetry & Mandir Admin</title>
        <link href="https://fonts.googleapis.com/css2?family=Outfit:wght@400;500;600;700&display=swap" rel="stylesheet">
        <style>
            * {{ margin:0; padding:0; box-sizing:border-box; font-family:'Outfit', sans-serif; }}
            body {{ background:#0a0914; color:#e2e8f0; padding:24px; min-height:100vh; }}
            .container {{ max-width:1200px; margin:0 auto; }}
            .header {{ display:flex; justify-content:space-between; align-items:center; margin-bottom:28px; border-bottom:1px solid #1f1d33; padding-bottom:18px; }}
            .title {{ font-size:26px; font-weight:700; color:#ff9933; display:flex; align-items:center; gap:10px; }}
            .stats-grid {{ display:grid; grid-template-columns:repeat(auto-fit, minmax(220px, 1fr)); gap:18px; margin-bottom:28px; }}
            .card {{ background:#131124; border:1px solid #23203d; border-radius:14px; padding:20px; position:relative; overflow:hidden; }}
            .card::before {{ content:''; position:absolute; top:0; left:0; right:0; height:3px; background:linear-gradient(90deg, #ff9933, #ff5722); }}
            .card-title {{ font-size:13px; text-transform:uppercase; color:#94a3b8; letter-spacing:0.5px; font-weight:600; margin-bottom:8px; }}
            .card-value {{ font-size:36px; font-weight:700; color:#fff; }}
            .badge-gold {{ color:#ffd700; }}
            .section {{ background:#131124; border:1px solid #23203d; border-radius:14px; padding:24px; margin-bottom:28px; }}
            .section-title {{ font-size:17px; font-weight:600; color:#ff9933; margin-bottom:16px; display:flex; align-items:center; gap:8px; }}
            table {{ width:100%; border-collapse:collapse; text-align:left; }}
            th {{ padding:12px; color:#94a3b8; font-size:12px; text-transform:uppercase; border-bottom:1px solid #23203d; }}
            .refresh-btn {{ background:#ff9933; color:#0a0914; font-weight:700; border:none; padding:10px 20px; border-radius:8px; cursor:pointer; text-decoration:none; font-size:13px; display:inline-block; }}
            .refresh-btn:hover {{ background:#ffad5a; }}
        </style>
    </head>
    <body>
        <div class="container">
            <div class="header">
                <div>
                    <div class="title">🚩 BhaktiDhara Devotee Telemetry</div>
                    <p style="color:#64748b; font-size:13px; margin-top:4px;">Live App Installs, Active Users & Location Insights</p>
                </div>
                <div>
                    <a href="?secret={secret}" class="refresh-btn">🔄 Refresh Stats</a>
                </div>
            </div>

            <!-- Top KPI Cards -->
            <div class="stats-grid">
                <div class="card">
                    <div class="card-title">Total Unique Installs</div>
                    <div class="card-value">{metrics['total_installs']}</div>
                </div>
                <div class="card">
                    <div class="card-title">Active Today (DAU)</div>
                    <div class="card-value" style="color:#38bdf8;">{metrics['daily_active_users_dau']}</div>
                </div>
                <div class="card">
                    <div class="card-title">Active 30 Days (MAU)</div>
                    <div class="card-value" style="color:#a78bfa;">{metrics['monthly_active_users_mau']}</div>
                </div>
                <div class="card">
                    <div class="card-title">VIP Subscribers</div>
                    <div class="card-value badge-gold">⭐ {metrics['vip_subscribers']}</div>
                </div>
            </div>

            <!-- Breakdown Section -->
            <div class="stats-grid" style="grid-template-columns: 1fr 1fr;">
                <div class="section" style="margin-bottom:0;">
                    <div class="section-title">📍 Top Devotee Locations</div>
                    <div>{cities_html}</div>
                </div>
                <div class="section" style="margin-bottom:0;">
                    <div class="section-title">📱 Platforms & Cache</div>
                    <div>{platforms_html}</div>
                    <p style="margin-top:12px; font-size:13px; color:#64748b;">
                        Cached Today: <b>{metrics['cache_entries']['horoscope_count']}</b> Horoscopes, <b>{metrics['cache_entries']['panchang_count']}</b> Panchangs
                    </p>
                </div>
            </div>

            <!-- Recent Devices Table -->
            <div class="section" style="margin-top:28px;">
                <div class="section-title">📋 Recent Active Devotee Devices (Latest 25)</div>
                <div style="overflow-x:auto;">
                    <table>
                        <thead>
                            <tr>
                                <th>Device ID</th>
                                <th>Devotee Name</th>
                                <th>Location</th>
                                <th>Platform</th>
                                <th>Tier</th>
                                <th>Last Active</th>
                                <th style="text-align:center;">Pings</th>
                            </tr>
                        </thead>
                        <tbody>
                            {rows_html}
                        </tbody>
                    </table>
                </div>
            </div>
        </div>
    </body>
    </html>
    """
    return HTMLResponse(content=html_content)


@app.post("/api/v1/admin/trigger-precache")
async def trigger_precache_endpoint(
    secret: str = Query(..., description="Admin authentication secret key"),
):
    """Manually triggers the precache job immediately."""
    if secret != ADMIN_SECRET:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid admin secret")

    # Run in background
    scheduler.add_job(run_daily_precache_job, id="manual_precache_run")
    return {"status": "precache_job_started"}

