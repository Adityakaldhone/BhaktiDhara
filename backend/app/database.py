# pyrefly: ignore [missing-import]
import aiosqlite
import json
import os
from datetime import datetime, timezone
from typing import Optional, Dict, Any

DB_PATH = os.getenv("DB_PATH", "bhaktidhara.db")


async def init_db():
    """Initializes the SQLite database tables."""
    async with aiosqlite.connect(DB_PATH) as db:
        await db.execute("""
            CREATE TABLE IF NOT EXISTS horoscope_cache (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                date_str TEXT NOT NULL,
                rashi_id TEXT NOT NULL,
                period TEXT NOT NULL,
                lang_code TEXT NOT NULL,
                data_json TEXT NOT NULL,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                UNIQUE(date_str, rashi_id, period, lang_code)
            )
        """)

        await db.execute("""
            CREATE TABLE IF NOT EXISTS panchang_cache (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                date_str TEXT NOT NULL,
                city_id TEXT NOT NULL,
                lang_code TEXT NOT NULL,
                data_json TEXT NOT NULL,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                UNIQUE(date_str, city_id, lang_code)
            )
        """)

        await db.execute("""
            CREATE TABLE IF NOT EXISTS devices (
                device_id TEXT PRIMARY KEY,
                platform TEXT NOT NULL,
                app_version TEXT NOT NULL,
                locale TEXT DEFAULT 'en',
                is_vip INTEGER DEFAULT 0,
                user_name TEXT DEFAULT '',
                city TEXT DEFAULT '',
                state TEXT DEFAULT '',
                country TEXT DEFAULT '',
                first_seen TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                last_seen TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                ping_count INTEGER DEFAULT 1
            )
        """)

        # Gracefully add new columns if table was created in older version
        for col in [
            ("user_name", "TEXT DEFAULT ''"),
            ("city", "TEXT DEFAULT ''"),
            ("state", "TEXT DEFAULT ''"),
            ("country", "TEXT DEFAULT ''"),
        ]:
            try:
                await db.execute(f"ALTER TABLE devices ADD COLUMN {col[0]} {col[1]}")
            except Exception:
                pass

        await db.commit()


# ── Horoscope Cache Methods ──────────────────────────────────────────────────

async def get_cached_horoscope(date_str: str, rashi_id: str, period: str, lang_code: str) -> Optional[Dict[str, Any]]:
    async with aiosqlite.connect(DB_PATH) as db:
        async with db.execute(
            """
            SELECT data_json FROM horoscope_cache
            WHERE date_str = ? AND rashi_id = ? AND period = ? AND lang_code = ?
            """,
            (date_str, rashi_id, period, lang_code)
        ) as cursor:
            row = await cursor.fetchone()
            if row:
                return json.loads(row[0])
            return None


async def save_cached_horoscope(date_str: str, rashi_id: str, period: str, lang_code: str, data: Dict[str, Any]):
    async with aiosqlite.connect(DB_PATH) as db:
        await db.execute(
            """
            INSERT INTO horoscope_cache (date_str, rashi_id, period, lang_code, data_json)
            VALUES (?, ?, ?, ?, ?)
            ON CONFLICT(date_str, rashi_id, period, lang_code)
            DO UPDATE SET data_json = excluded.data_json, created_at = CURRENT_TIMESTAMP
            """,
            (date_str, rashi_id, period, lang_code, json.dumps(data, ensure_ascii=False))
        )
        await db.commit()


# ── Panchang Cache Methods ───────────────────────────────────────────────────

async def get_cached_panchang(date_str: str, city_id: str, lang_code: str) -> Optional[Dict[str, Any]]:
    async with aiosqlite.connect(DB_PATH) as db:
        async with db.execute(
            """
            SELECT data_json FROM panchang_cache
            WHERE date_str = ? AND city_id = ? AND lang_code = ?
            """,
            (date_str, city_id, lang_code)
        ) as cursor:
            row = await cursor.fetchone()
            if row:
                return json.loads(row[0])
            return None


async def save_cached_panchang(date_str: str, city_id: str, lang_code: str, data: Dict[str, Any]):
    async with aiosqlite.connect(DB_PATH) as db:
        await db.execute(
            """
            INSERT INTO panchang_cache (date_str, city_id, lang_code, data_json)
            VALUES (?, ?, ?, ?)
            ON CONFLICT(date_str, city_id, lang_code)
            DO UPDATE SET data_json = excluded.data_json, created_at = CURRENT_TIMESTAMP
            """,
            (date_str, city_id, lang_code, json.dumps(data, ensure_ascii=False))
        )
        await db.commit()


# ── Anonymous Telemetry / Device Methods ─────────────────────────────────────

async def record_device_ping(
    device_id: str,
    platform: str,
    app_version: str,
    locale: str,
    is_vip: bool,
    user_name: Optional[str] = None,
    city: Optional[str] = None,
    state: Optional[str] = None,
    country: Optional[str] = None,
):
    """Upserts a device ping with optional user-provided name & location."""
    now = datetime.now(timezone.utc).isoformat()
    u_name = (user_name or "").strip()
    c_name = (city or "").strip()
    s_name = (state or "").strip()
    ctry_name = (country or "").strip()

    async with aiosqlite.connect(DB_PATH) as db:
        await db.execute(
            """
            INSERT INTO devices (
                device_id, platform, app_version, locale, is_vip,
                user_name, city, state, country,
                first_seen, last_seen, ping_count
            )
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 1)
            ON CONFLICT(device_id) DO UPDATE SET
                platform = excluded.platform,
                app_version = excluded.app_version,
                locale = excluded.locale,
                is_vip = excluded.is_vip,
                user_name = CASE WHEN excluded.user_name != '' THEN excluded.user_name ELSE devices.user_name END,
                city = CASE WHEN excluded.city != '' THEN excluded.city ELSE devices.city END,
                state = CASE WHEN excluded.state != '' THEN excluded.state ELSE devices.state END,
                country = CASE WHEN excluded.country != '' THEN excluded.country ELSE devices.country END,
                last_seen = ?,
                ping_count = devices.ping_count + 1
            """,
            (
                device_id, platform, app_version, locale, 1 if is_vip else 0,
                u_name, c_name, s_name, ctry_name,
                now, now, now
            )
        )
        await db.commit()


async def get_admin_metrics() -> Dict[str, Any]:
    """Computes total installs, DAU, MAU, VIP subscribers, cities, and recent devices."""
    async with aiosqlite.connect(DB_PATH) as db:
        db.row_factory = aiosqlite.Row

        # Total unique installs
        async with db.execute("SELECT COUNT(*) as cnt FROM devices") as cur:
            row = await cur.fetchone()
            total_devices = row["cnt"] if row else 0

        # Active in last 24h (DAU)
        async with db.execute(
            "SELECT COUNT(*) as cnt FROM devices WHERE datetime(last_seen) >= datetime('now', '-1 day')"
        ) as cur:
            row = await cur.fetchone()
            dau = row["cnt"] if row else 0

        # Active in last 30d (MAU)
        async with db.execute(
            "SELECT COUNT(*) as cnt FROM devices WHERE datetime(last_seen) >= datetime('now', '-30 day')"
        ) as cur:
            row = await cur.fetchone()
            mau = row["cnt"] if row else 0

        # Total VIP Subscribers
        async with db.execute("SELECT COUNT(*) as cnt FROM devices WHERE is_vip = 1") as cur:
            row = await cur.fetchone()
            vip_subscribers = row["cnt"] if row else 0

        # Platforms breakdown
        async with db.execute(
            "SELECT platform, COUNT(*) as cnt FROM devices GROUP BY platform"
        ) as cur:
            platform_rows = await cur.fetchall()
            platforms = {row["platform"]: row["cnt"] for row in platform_rows}

        # Locales breakdown
        async with db.execute(
            "SELECT locale, COUNT(*) as cnt FROM devices GROUP BY locale"
        ) as cur:
            locale_rows = await cur.fetchall()
            locales = {row["locale"]: row["cnt"] for row in locale_rows}

        # Top Cities breakdown (where user allowed location or selected city)
        async with db.execute(
            "SELECT city, COUNT(*) as cnt FROM devices WHERE city != '' GROUP BY city ORDER BY cnt DESC LIMIT 15"
        ) as cur:
            city_rows = await cur.fetchall()
            cities = {row["city"]: row["cnt"] for row in city_rows}

        # Recent active devices (latest 25)
        async with db.execute(
            """
            SELECT device_id, platform, app_version, locale, is_vip, user_name, city, state, country, first_seen, last_seen, ping_count
            FROM devices
            ORDER BY last_seen DESC
            LIMIT 25
            """
        ) as cur:
            recent_rows = await cur.fetchall()
            recent_devices = [
                {
                    "deviceId": r["device_id"],
                    "userName": r["user_name"] or "Anonymous Devotee",
                    "city": r["city"] or "Unknown",
                    "platform": r["platform"],
                    "appVersion": r["app_version"],
                    "isVip": bool(r["is_vip"]),
                    "firstSeen": r["first_seen"],
                    "lastSeen": r["last_seen"],
                    "pingCount": r["ping_count"],
                }
                for r in recent_rows
            ]

        # Cache counts
        async with db.execute("SELECT COUNT(*) as cnt FROM horoscope_cache") as cur:
            row = await cur.fetchone()
            horoscope_cache_count = row["cnt"] if row else 0

        async with db.execute("SELECT COUNT(*) as cnt FROM panchang_cache") as cur:
            row = await cur.fetchone()
            panchang_cache_count = row["cnt"] if row else 0

        return {
            "total_installs": total_devices,
            "daily_active_users_dau": dau,
            "monthly_active_users_mau": mau,
            "vip_subscribers": vip_subscribers,
            "platforms": platforms,
            "locales": locales,
            "cities": cities,
            "recent_devices": recent_devices,
            "cache_entries": {
                "horoscope_count": horoscope_cache_count,
                "panchang_count": panchang_cache_count,
            },
        }
