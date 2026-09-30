# pyrefly: ignore [missing-import]
import aiosqlite
import json
import os
from datetime import datetime, timezone, timedelta
from typing import Optional, Dict, Any, List

DB_PATH = os.getenv("DB_PATH", "bhaktidhara.db")

# All day-level buckets use Indian Standard Time.
IST_OFFSET = timedelta(hours=5, minutes=30)
IST_SQL_MODIFIER = "+330 minutes"

DEFAULT_APP_CONFIG: Dict[str, Any] = {
    "min_supported_version": "1.0.0",
    "latest_version": "1.0.4",
    "update_url": "",
    "force_update": False,
    "maintenance_mode": False,
    "maintenance_message": "",
    "feature_flags": {
        "horoscope": True,
        "panchang": True,
        "jaap": True,
        "bhajan": True,
        "ads": True,
        "premium_paywall": True,
        "status_cards": True,
        "status_card_photo": True,
    },
}


def ist_today_str() -> str:
    return (datetime.now(timezone.utc) + IST_OFFSET).strftime("%Y-%m-%d")


def utc_now_iso() -> str:
    return datetime.now(timezone.utc).isoformat()


async def _fetch_scalar(db, sql: str, params: tuple = ()) -> int:
    async with db.execute(sql, params) as cur:
        row = await cur.fetchone()
        return (row[0] or 0) if row else 0


async def _fetch_map(db, sql: str, params: tuple = ()) -> Dict[str, int]:
    async with db.execute(sql, params) as cur:
        return {str(r[0]): r[1] for r in await cur.fetchall()}


async def init_db():
    """Initializes the SQLite database tables."""
    async with aiosqlite.connect(DB_PATH) as db:
        await db.execute("PRAGMA journal_mode=WAL")

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
            ("notes", "TEXT DEFAULT ''"),
            ("vip_granted", "INTEGER DEFAULT 0"),
            ("blocked", "INTEGER DEFAULT 0"),
        ]:
            try:
                await db.execute(f"ALTER TABLE devices ADD COLUMN {col[0]} {col[1]}")
            except Exception:
                pass

        await db.execute("""
            CREATE TABLE IF NOT EXISTS daily_active (
                date_str TEXT NOT NULL,
                device_id TEXT NOT NULL,
                sessions INTEGER DEFAULT 1,
                PRIMARY KEY (date_str, device_id)
            )
        """)

        await db.execute("""
            CREATE TABLE IF NOT EXISTS events (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                device_id TEXT NOT NULL,
                name TEXT NOT NULL,
                item TEXT DEFAULT '',
                props_json TEXT DEFAULT '{}',
                created_at TIMESTAMP NOT NULL
            )
        """)
        await db.execute("CREATE INDEX IF NOT EXISTS idx_events_created ON events(created_at)")
        await db.execute("CREATE INDEX IF NOT EXISTS idx_events_name ON events(name, created_at)")
        await db.execute("CREATE INDEX IF NOT EXISTS idx_events_device ON events(device_id, created_at)")

        await db.execute("""
            CREATE TABLE IF NOT EXISTS api_stats (
                date_str TEXT NOT NULL,
                metric TEXT NOT NULL,
                count INTEGER DEFAULT 0,
                PRIMARY KEY (date_str, metric)
            )
        """)

        await db.execute("""
            CREATE TABLE IF NOT EXISTS announcements (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                title TEXT NOT NULL,
                body TEXT NOT NULL,
                locale TEXT DEFAULT 'all',
                link TEXT DEFAULT '',
                active INTEGER DEFAULT 1,
                created_at TIMESTAMP NOT NULL,
                expires_at TIMESTAMP
            )
        """)

        await db.execute("""
            CREATE TABLE IF NOT EXISTS app_config (
                key TEXT PRIMARY KEY,
                value_json TEXT NOT NULL
            )
        """)

        await db.execute("""
            CREATE TABLE IF NOT EXISTS job_runs (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                job TEXT NOT NULL,
                started_at TIMESTAMP NOT NULL,
                finished_at TIMESTAMP,
                status TEXT DEFAULT 'running',
                detail TEXT DEFAULT ''
            )
        """)

        await db.execute("""
            CREATE TABLE IF NOT EXISTS push_tokens (
                device_id TEXT PRIMARY KEY,
                token TEXT NOT NULL,
                enabled INTEGER DEFAULT 1,
                platform TEXT DEFAULT '',
                updated_at TIMESTAMP NOT NULL
            )
        """)

        await db.execute("""
            CREATE TABLE IF NOT EXISTS push_campaigns (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                title TEXT NOT NULL,
                body TEXT NOT NULL,
                image_url TEXT DEFAULT '',
                route TEXT DEFAULT '',
                aarti_id TEXT DEFAULT '',
                audience TEXT DEFAULT 'all',
                locale TEXT DEFAULT '',
                platform TEXT DEFAULT '',
                target_device_id TEXT DEFAULT '',
                dormant_days INTEGER DEFAULT 7,
                status TEXT DEFAULT 'scheduled',
                scheduled_at TIMESTAMP,
                repeat TEXT DEFAULT 'none',
                created_at TIMESTAMP NOT NULL,
                last_sent_at TIMESTAMP,
                send_count INTEGER DEFAULT 0,
                success_count INTEGER DEFAULT 0,
                failure_count INTEGER DEFAULT 0,
                total_reach INTEGER DEFAULT 0,
                last_error TEXT DEFAULT ''
            )
        """)

        await db.execute("""
            CREATE TABLE IF NOT EXISTS admin_audit (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                action TEXT NOT NULL,
                detail TEXT DEFAULT '',
                created_at TIMESTAMP NOT NULL
            )
        """)

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


async def clear_cache(older_than_days: Optional[int] = None) -> Dict[str, int]:
    """Deletes cached horoscope/panchang rows. `None` clears everything."""
    async with aiosqlite.connect(DB_PATH) as db:
        if older_than_days is None:
            h = await db.execute("DELETE FROM horoscope_cache")
            p = await db.execute("DELETE FROM panchang_cache")
        else:
            cutoff = (datetime.now(timezone.utc) + IST_OFFSET - timedelta(days=older_than_days)).strftime("%Y-%m-%d")
            h = await db.execute("DELETE FROM horoscope_cache WHERE date_str < ?", (cutoff,))
            p = await db.execute("DELETE FROM panchang_cache WHERE date_str < ?", (cutoff,))
        await db.commit()
        return {"horoscope_deleted": h.rowcount, "panchang_deleted": p.rowcount}


# ── API usage counters ───────────────────────────────────────────────────────

async def increment_api_stat(metric: str, amount: int = 1):
    async with aiosqlite.connect(DB_PATH) as db:
        await db.execute(
            """
            INSERT INTO api_stats (date_str, metric, count) VALUES (?, ?, ?)
            ON CONFLICT(date_str, metric) DO UPDATE SET count = api_stats.count + excluded.count
            """,
            (ist_today_str(), metric, amount),
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
) -> Dict[str, Any]:
    """Upserts a device ping with optional user-provided name & location.

    Returns the admin-controlled flags for this device.
    """
    now = utc_now_iso()
    u_name = (user_name or "").strip()[:80]
    c_name = (city or "").strip()[:80]
    s_name = (state or "").strip()[:80]
    ctry_name = (country or "").strip()[:80]

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
        await db.execute(
            """
            INSERT INTO daily_active (date_str, device_id, sessions) VALUES (?, ?, 1)
            ON CONFLICT(date_str, device_id) DO UPDATE SET sessions = daily_active.sessions + 1
            """,
            (ist_today_str(), device_id),
        )
        await db.execute(
            "INSERT INTO events (device_id, name, item, props_json, created_at) VALUES (?, 'app_open', '', '{}', ?)",
            (device_id, now),
        )
        await db.commit()

        async with db.execute(
            "SELECT vip_granted, blocked FROM devices WHERE device_id = ?", (device_id,)
        ) as cur:
            row = await cur.fetchone()
        return {
            "vipGranted": bool(row[0]) if row else False,
            "blocked": bool(row[1]) if row else False,
        }


async def record_events(device_id: str, events: List[Dict[str, Any]]):
    """Stores a batch of feature-usage events from a device."""
    if not events:
        return
    now = utc_now_iso()
    rows = []
    for e in events[:100]:
        name = str(e.get("name", "")).strip()[:60]
        if not name:
            continue
        props = e.get("props") or {}
        item = str(props.get("item", "")).strip()[:120]
        created = str(e.get("ts") or now)[:40]
        rows.append((device_id, name, item, json.dumps(props, ensure_ascii=False)[:2000], created))
    if not rows:
        return
    async with aiosqlite.connect(DB_PATH) as db:
        await db.executemany(
            "INSERT INTO events (device_id, name, item, props_json, created_at) VALUES (?, ?, ?, ?, ?)",
            rows,
        )
        await db.commit()


async def prune_old_events(keep_days: int = 180) -> int:
    async with aiosqlite.connect(DB_PATH) as db:
        cur = await db.execute(
            "DELETE FROM events WHERE datetime(created_at) < datetime('now', ?)",
            (f"-{keep_days} day",),
        )
        await db.commit()
        return cur.rowcount


# ── Admin: legacy summary (used by /api/v1/admin/stats) ──────────────────────

async def get_admin_metrics() -> Dict[str, Any]:
    """Computes total installs, DAU, MAU, VIP subscribers, cities, and recent devices."""
    async with aiosqlite.connect(DB_PATH) as db:
        db.row_factory = aiosqlite.Row
        total_devices = await _fetch_scalar(db, "SELECT COUNT(*) FROM devices")
        dau = await _fetch_scalar(db, "SELECT COUNT(*) FROM devices WHERE datetime(last_seen) >= datetime('now', '-1 day')")
        mau = await _fetch_scalar(db, "SELECT COUNT(*) FROM devices WHERE datetime(last_seen) >= datetime('now', '-30 day')")
        vip_subscribers = await _fetch_scalar(db, "SELECT COUNT(*) FROM devices WHERE is_vip = 1 OR vip_granted = 1")
        platforms = await _fetch_map(db, "SELECT platform, COUNT(*) FROM devices GROUP BY platform")
        locales = await _fetch_map(db, "SELECT locale, COUNT(*) FROM devices GROUP BY locale")
        cities = await _fetch_map(
            db, "SELECT city, COUNT(*) AS cnt FROM devices WHERE city != '' GROUP BY city ORDER BY cnt DESC LIMIT 15"
        )
        horoscope_cache_count = await _fetch_scalar(db, "SELECT COUNT(*) FROM horoscope_cache")
        panchang_cache_count = await _fetch_scalar(db, "SELECT COUNT(*) FROM panchang_cache")

        return {
            "total_installs": total_devices,
            "daily_active_users_dau": dau,
            "monthly_active_users_mau": mau,
            "vip_subscribers": vip_subscribers,
            "platforms": platforms,
            "locales": locales,
            "cities": cities,
            "cache_entries": {
                "horoscope_count": horoscope_cache_count,
                "panchang_count": panchang_cache_count,
            },
        }


# ── Admin: overview ──────────────────────────────────────────────────────────

def _day_series(days: int) -> List[str]:
    today = datetime.now(timezone.utc) + IST_OFFSET
    return [(today - timedelta(days=i)).strftime("%Y-%m-%d") for i in range(days - 1, -1, -1)]


async def get_overview(days: int = 30) -> Dict[str, Any]:
    days = max(7, min(days, 180))
    today = ist_today_str()
    async with aiosqlite.connect(DB_PATH) as db:
        total = await _fetch_scalar(db, "SELECT COUNT(*) FROM devices")
        new_today = await _fetch_scalar(
            db, f"SELECT COUNT(*) FROM devices WHERE date(first_seen, '{IST_SQL_MODIFIER}') = ?", (today,)
        )
        new_7d = await _fetch_scalar(
            db, "SELECT COUNT(*) FROM devices WHERE datetime(first_seen) >= datetime('now', '-7 day')"
        )
        new_prev_7d = await _fetch_scalar(
            db,
            "SELECT COUNT(*) FROM devices WHERE datetime(first_seen) >= datetime('now', '-14 day') "
            "AND datetime(first_seen) < datetime('now', '-7 day')",
        )
        dau = await _fetch_scalar(db, "SELECT COUNT(*) FROM daily_active WHERE date_str = ?", (today,))
        wau = await _fetch_scalar(
            db, "SELECT COUNT(*) FROM devices WHERE datetime(last_seen) >= datetime('now', '-7 day')"
        )
        mau = await _fetch_scalar(
            db, "SELECT COUNT(*) FROM devices WHERE datetime(last_seen) >= datetime('now', '-30 day')"
        )
        dormant = await _fetch_scalar(
            db, "SELECT COUNT(*) FROM devices WHERE datetime(last_seen) < datetime('now', '-30 day')"
        )
        vip_paid = await _fetch_scalar(db, "SELECT COUNT(*) FROM devices WHERE is_vip = 1")
        vip_granted = await _fetch_scalar(db, "SELECT COUNT(*) FROM devices WHERE vip_granted = 1 AND is_vip = 0")
        blocked = await _fetch_scalar(db, "SELECT COUNT(*) FROM devices WHERE blocked = 1")
        sessions_today = await _fetch_scalar(
            db, "SELECT COALESCE(SUM(sessions), 0) FROM daily_active WHERE date_str = ?", (today,)
        )

        series_days = _day_series(days)
        start = series_days[0]
        installs_by_day = await _fetch_map(
            db,
            f"SELECT date(first_seen, '{IST_SQL_MODIFIER}') AS d, COUNT(*) FROM devices "
            f"WHERE date(first_seen, '{IST_SQL_MODIFIER}') >= ? GROUP BY d",
            (start,),
        )
        active_by_day = await _fetch_map(
            db, "SELECT date_str, COUNT(*) FROM daily_active WHERE date_str >= ? GROUP BY date_str", (start,)
        )
        sessions_by_day = await _fetch_map(
            db, "SELECT date_str, SUM(sessions) FROM daily_active WHERE date_str >= ? GROUP BY date_str", (start,)
        )
        installs_before = await _fetch_scalar(
            db, f"SELECT COUNT(*) FROM devices WHERE date(first_seen, '{IST_SQL_MODIFIER}') < ?", (start,)
        )
        cumulative, running = [], installs_before
        for d in series_days:
            running += installs_by_day.get(d, 0)
            cumulative.append(running)

        hourly = await _fetch_map(
            db,
            f"SELECT CAST(strftime('%H', created_at, '{IST_SQL_MODIFIER}') AS INTEGER) AS h, COUNT(*) FROM events "
            "WHERE name = 'app_open' AND datetime(created_at) >= datetime('now', '-14 day') GROUP BY h",
        )

        platforms = await _fetch_map(db, "SELECT platform, COUNT(*) FROM devices GROUP BY platform")
        locales = await _fetch_map(db, "SELECT locale, COUNT(*) FROM devices GROUP BY locale")
        versions = await _fetch_map(
            db, "SELECT app_version, COUNT(*) AS c FROM devices GROUP BY app_version ORDER BY c DESC LIMIT 10"
        )
        cities = await _fetch_map(
            db, "SELECT city, COUNT(*) AS c FROM devices WHERE city != '' GROUP BY city ORDER BY c DESC LIMIT 15"
        )
        states = await _fetch_map(
            db, "SELECT state, COUNT(*) AS c FROM devices WHERE state != '' GROUP BY state ORDER BY c DESC LIMIT 10"
        )

    def pct(a, b):
        return round(a * 100.0 / b, 1) if b else 0.0

    return {
        "kpis": {
            "total_installs": total,
            "new_today": new_today,
            "new_7d": new_7d,
            "new_7d_growth_pct": pct(new_7d - new_prev_7d, new_prev_7d) if new_prev_7d else None,
            "dau": dau,
            "wau": wau,
            "mau": mau,
            "stickiness_pct": pct(dau, mau),
            "dormant_30d": dormant,
            "vip_paid": vip_paid,
            "vip_granted": vip_granted,
            "vip_conversion_pct": pct(vip_paid, total),
            "blocked": blocked,
            "sessions_today": sessions_today,
            "avg_sessions_per_dau": round(sessions_today / dau, 2) if dau else 0,
        },
        "series": {
            "days": series_days,
            "installs": [installs_by_day.get(d, 0) for d in series_days],
            "cumulative_installs": cumulative,
            "active": [active_by_day.get(d, 0) for d in series_days],
            "sessions": [sessions_by_day.get(d, 0) for d in series_days],
        },
        "hourly_activity": [hourly.get(h, 0) for h in range(24)],
        "breakdowns": {
            "platforms": platforms,
            "locales": locales,
            "versions": versions,
            "cities": cities,
            "states": states,
        },
    }


# ── Admin: retention ─────────────────────────────────────────────────────────

async def get_retention(weeks: int = 8) -> Dict[str, Any]:
    """Classic D1/D7/D30 retention plus weekly install cohorts."""
    weeks = max(2, min(weeks, 26))
    lookback_days = weeks * 7 + 35
    async with aiosqlite.connect(DB_PATH) as db:
        async with db.execute(
            f"SELECT device_id, date(first_seen, '{IST_SQL_MODIFIER}') FROM devices "
            "WHERE datetime(first_seen) >= datetime('now', ?)",
            (f"-{lookback_days} day",),
        ) as cur:
            installs = {r[0]: r[1] for r in await cur.fetchall()}
        cutoff = (datetime.now(timezone.utc) + IST_OFFSET - timedelta(days=lookback_days)).strftime("%Y-%m-%d")
        async with db.execute(
            "SELECT device_id, date_str FROM daily_active WHERE date_str >= ?", (cutoff,)
        ) as cur:
            active: Dict[str, set] = {}
            for dev, d in await cur.fetchall():
                active.setdefault(dev, set()).add(d)

    today = datetime.strptime(ist_today_str(), "%Y-%m-%d").date()

    def offset(day_str: str, n: int) -> str:
        return (datetime.strptime(day_str, "%Y-%m-%d").date() + timedelta(days=n)).isoformat()

    def day_n_retention(n: int) -> Dict[str, Any]:
        eligible = retained = 0
        for dev, first in installs.items():
            if datetime.strptime(first, "%Y-%m-%d").date() + timedelta(days=n) > today:
                continue
            eligible += 1
            days_active = active.get(dev, set())
            # Treat "retained on day N" as active on any day in [N, N+window) for sparse ping data.
            window = 1 if n == 1 else (2 if n == 7 else 5)
            if any(offset(first, n + k) in days_active for k in range(window)):
                retained += 1
        return {"eligible": eligible, "retained": retained, "pct": round(retained * 100.0 / eligible, 1) if eligible else 0.0}

    # Weekly cohorts (Monday-start weeks)
    current_week_start = today - timedelta(days=today.weekday())
    cohorts = []
    for w in range(weeks - 1, -1, -1):
        wk_start = current_week_start - timedelta(weeks=w)
        wk_end = wk_start + timedelta(days=7)
        members = [
            dev for dev, first in installs.items()
            if wk_start <= datetime.strptime(first, "%Y-%m-%d").date() < wk_end
        ]
        row = {"week": wk_start.isoformat(), "size": len(members), "weeks": []}
        for k in range(1, 5):
            k_start = wk_start + timedelta(weeks=k)
            if k_start > today:
                row["weeks"].append(None)
                continue
            k_days = {(k_start + timedelta(days=i)).isoformat() for i in range(7)}
            kept = sum(1 for dev in members if active.get(dev, set()) & k_days)
            row["weeks"].append(round(kept * 100.0 / len(members), 1) if members else None)
        cohorts.append(row)

    return {
        "d1": day_n_retention(1),
        "d7": day_n_retention(7),
        "d30": day_n_retention(30),
        "cohorts": cohorts,
    }


# ── Admin: users ─────────────────────────────────────────────────────────────

_USER_SORTS = {
    "last_seen": "last_seen DESC",
    "first_seen": "first_seen DESC",
    "pings": "ping_count DESC",
    "name": "user_name COLLATE NOCASE ASC",
}


def _device_row_to_dict(r) -> Dict[str, Any]:
    return {
        "deviceId": r["device_id"],
        "userName": r["user_name"] or "",
        "city": r["city"] or "",
        "state": r["state"] or "",
        "country": r["country"] or "",
        "platform": r["platform"],
        "appVersion": r["app_version"],
        "locale": r["locale"],
        "isVip": bool(r["is_vip"]),
        "vipGranted": bool(r["vip_granted"]),
        "blocked": bool(r["blocked"]),
        "notes": r["notes"] or "",
        "firstSeen": r["first_seen"],
        "lastSeen": r["last_seen"],
        "pingCount": r["ping_count"],
    }


def _build_user_filters(
    search: str = "",
    platform: str = "",
    locale: str = "",
    tier: str = "",
    status: str = "",
):
    where, params = [], []
    if search:
        where.append("(user_name LIKE ? OR city LIKE ? OR state LIKE ? OR device_id LIKE ? OR notes LIKE ?)")
        like = f"%{search}%"
        params += [like] * 5
    if platform:
        where.append("platform = ?")
        params.append(platform)
    if locale:
        where.append("locale = ?")
        params.append(locale)
    if tier == "vip":
        where.append("(is_vip = 1 OR vip_granted = 1)")
    elif tier == "paid":
        where.append("is_vip = 1")
    elif tier == "granted":
        where.append("vip_granted = 1")
    elif tier == "free":
        where.append("is_vip = 0 AND vip_granted = 0")
    if status == "active7d":
        where.append("datetime(last_seen) >= datetime('now', '-7 day')")
    elif status == "dormant":
        where.append("datetime(last_seen) < datetime('now', '-30 day')")
    elif status == "new7d":
        where.append("datetime(first_seen) >= datetime('now', '-7 day')")
    elif status == "blocked":
        where.append("blocked = 1")
    clause = ("WHERE " + " AND ".join(where)) if where else ""
    return clause, params


async def list_users(
    search: str = "",
    platform: str = "",
    locale: str = "",
    tier: str = "",
    status: str = "",
    sort: str = "last_seen",
    page: int = 1,
    page_size: int = 25,
) -> Dict[str, Any]:
    page = max(1, page)
    page_size = max(1, min(page_size, 200))
    clause, params = _build_user_filters(search, platform, locale, tier, status)
    order = _USER_SORTS.get(sort, _USER_SORTS["last_seen"])
    async with aiosqlite.connect(DB_PATH) as db:
        db.row_factory = aiosqlite.Row
        total = await _fetch_scalar(db, f"SELECT COUNT(*) FROM devices {clause}", tuple(params))
        async with db.execute(
            f"SELECT * FROM devices {clause} ORDER BY {order} LIMIT ? OFFSET ?",
            (*params, page_size, (page - 1) * page_size),
        ) as cur:
            rows = await cur.fetchall()
    return {
        "total": total,
        "page": page,
        "pageSize": page_size,
        "users": [_device_row_to_dict(r) for r in rows],
    }


async def export_users(**filters) -> List[Dict[str, Any]]:
    clause, params = _build_user_filters(**filters)
    async with aiosqlite.connect(DB_PATH) as db:
        db.row_factory = aiosqlite.Row
        async with db.execute(f"SELECT * FROM devices {clause} ORDER BY last_seen DESC", tuple(params)) as cur:
            return [_device_row_to_dict(r) for r in await cur.fetchall()]


async def get_user_detail(device_id: str) -> Optional[Dict[str, Any]]:
    async with aiosqlite.connect(DB_PATH) as db:
        db.row_factory = aiosqlite.Row
        async with db.execute("SELECT * FROM devices WHERE device_id = ?", (device_id,)) as cur:
            row = await cur.fetchone()
        if not row:
            return None
        async with db.execute(
            "SELECT name, item, props_json, created_at FROM events WHERE device_id = ? AND name != 'app_open' "
            "ORDER BY created_at DESC LIMIT 50",
            (device_id,),
        ) as cur:
            events = [
                {"name": r["name"], "item": r["item"], "props": json.loads(r["props_json"] or "{}"), "at": r["created_at"]}
                for r in await cur.fetchall()
            ]
        async with db.execute(
            "SELECT date_str, sessions FROM daily_active WHERE device_id = ? ORDER BY date_str DESC LIMIT 60",
            (device_id,),
        ) as cur:
            active_days = [{"date": r["date_str"], "sessions": r["sessions"]} for r in await cur.fetchall()]
        top_features = await _fetch_map(
            db,
            "SELECT name, COUNT(*) AS c FROM events WHERE device_id = ? AND name != 'app_open' "
            "GROUP BY name ORDER BY c DESC LIMIT 8",
            (device_id,),
        )
    return {
        "user": _device_row_to_dict(row),
        "events": events,
        "activeDays": active_days,
        "topFeatures": top_features,
    }


async def update_user(device_id: str, fields: Dict[str, Any]) -> bool:
    allowed = {"notes": "notes", "vipGranted": "vip_granted", "blocked": "blocked", "userName": "user_name"}
    sets, params = [], []
    for key, col in allowed.items():
        if key in fields and fields[key] is not None:
            val = fields[key]
            if isinstance(val, bool):
                val = 1 if val else 0
            elif isinstance(val, str):
                val = val.strip()[:500]
            sets.append(f"{col} = ?")
            params.append(val)
    if not sets:
        return False
    async with aiosqlite.connect(DB_PATH) as db:
        cur = await db.execute(f"UPDATE devices SET {', '.join(sets)} WHERE device_id = ?", (*params, device_id))
        await db.commit()
        return cur.rowcount > 0


async def delete_user(device_id: str) -> bool:
    async with aiosqlite.connect(DB_PATH) as db:
        cur = await db.execute("DELETE FROM devices WHERE device_id = ?", (device_id,))
        await db.execute("DELETE FROM events WHERE device_id = ?", (device_id,))
        await db.execute("DELETE FROM daily_active WHERE device_id = ?", (device_id,))
        await db.execute("DELETE FROM push_tokens WHERE device_id = ?", (device_id,))
        await db.commit()
        return cur.rowcount > 0


# ── Admin: engagement ────────────────────────────────────────────────────────

async def get_engagement(days: int = 7, event: str = "") -> Dict[str, Any]:
    days = max(1, min(days, 180))
    span = (f"-{days} day",)
    async with aiosqlite.connect(DB_PATH) as db:
        async with db.execute(
            "SELECT name, COUNT(*) AS c, COUNT(DISTINCT device_id) AS u FROM events "
            "WHERE name != 'app_open' AND datetime(created_at) >= datetime('now', ?) "
            "GROUP BY name ORDER BY c DESC LIMIT 30",
            span,
        ) as cur:
            features = [{"name": r[0], "count": r[1], "users": r[2]} for r in await cur.fetchall()]

        item_filter = "AND name = ?" if event else "AND name != 'app_open'"
        item_params = (*span, event) if event else span
        async with db.execute(
            "SELECT name, item, COUNT(*) AS c, COUNT(DISTINCT device_id) AS u FROM events "
            f"WHERE item != '' AND datetime(created_at) >= datetime('now', ?) {item_filter} "
            "GROUP BY name, item ORDER BY c DESC LIMIT 25",
            item_params,
        ) as cur:
            items = [{"event": r[0], "item": r[1], "count": r[2], "users": r[3]} for r in await cur.fetchall()]

        series_days = _day_series(min(days, 60) if days > 1 else 7)
        async with db.execute(
            f"SELECT date(created_at, '{IST_SQL_MODIFIER}') AS d, name, COUNT(*) FROM events "
            "WHERE name != 'app_open' AND date(created_at, ?) >= ? GROUP BY d, name",
            (IST_SQL_MODIFIER, series_days[0]),
        ) as cur:
            per_day: Dict[str, Dict[str, int]] = {}
            for d, name, c in await cur.fetchall():
                per_day.setdefault(name, {})[d] = c

        vip_unlocks = await _fetch_scalar(
            db,
            "SELECT COUNT(DISTINCT device_id) FROM events WHERE name = 'vip_unlock' "
            "AND datetime(created_at) >= datetime('now', ?)",
            span,
        )
        paywall_views = await _fetch_scalar(
            db,
            "SELECT COUNT(DISTINCT device_id) FROM events WHERE name = 'paywall_view' "
            "AND datetime(created_at) >= datetime('now', ?)",
            span,
        )

    top_names = [f["name"] for f in features[:6]]
    return {
        "days": days,
        "features": features,
        "items": items,
        "trend": {
            "days": series_days,
            "series": {n: [per_day.get(n, {}).get(d, 0) for d in series_days] for n in top_names},
        },
        "funnel": {"paywall_views": paywall_views, "vip_unlocks": vip_unlocks},
    }


# ── Announcements ────────────────────────────────────────────────────────────

def _announcement_row(r) -> Dict[str, Any]:
    return {
        "id": r["id"],
        "title": r["title"],
        "body": r["body"],
        "locale": r["locale"],
        "link": r["link"],
        "active": bool(r["active"]),
        "createdAt": r["created_at"],
        "expiresAt": r["expires_at"],
    }


async def list_announcements(only_live: bool = False, locale: str = "") -> List[Dict[str, Any]]:
    where, params = [], []
    if only_live:
        where.append("active = 1 AND (expires_at IS NULL OR expires_at = '' OR datetime(expires_at) > datetime('now'))")
        if locale:
            where.append("(locale = 'all' OR locale = ?)")
            params.append(locale)
    clause = ("WHERE " + " AND ".join(where)) if where else ""
    async with aiosqlite.connect(DB_PATH) as db:
        db.row_factory = aiosqlite.Row
        async with db.execute(f"SELECT * FROM announcements {clause} ORDER BY created_at DESC LIMIT 100", tuple(params)) as cur:
            return [_announcement_row(r) for r in await cur.fetchall()]


async def create_announcement(title: str, body: str, locale: str, link: str, expires_at: Optional[str]) -> int:
    async with aiosqlite.connect(DB_PATH) as db:
        cur = await db.execute(
            "INSERT INTO announcements (title, body, locale, link, active, created_at, expires_at) VALUES (?, ?, ?, ?, 1, ?, ?)",
            (title.strip()[:200], body.strip()[:2000], locale or "all", (link or "").strip()[:500], utc_now_iso(), expires_at or None),
        )
        await db.commit()
        return cur.lastrowid


async def update_announcement(ann_id: int, active: Optional[bool]) -> bool:
    if active is None:
        return False
    async with aiosqlite.connect(DB_PATH) as db:
        cur = await db.execute("UPDATE announcements SET active = ? WHERE id = ?", (1 if active else 0, ann_id))
        await db.commit()
        return cur.rowcount > 0


async def delete_announcement(ann_id: int) -> bool:
    async with aiosqlite.connect(DB_PATH) as db:
        cur = await db.execute("DELETE FROM announcements WHERE id = ?", (ann_id,))
        await db.commit()
        return cur.rowcount > 0


# ── Remote app config ────────────────────────────────────────────────────────

async def get_app_config() -> Dict[str, Any]:
    config = json.loads(json.dumps(DEFAULT_APP_CONFIG))
    async with aiosqlite.connect(DB_PATH) as db:
        async with db.execute("SELECT key, value_json FROM app_config") as cur:
            for key, value_json in await cur.fetchall():
                try:
                    value = json.loads(value_json)
                except Exception:
                    continue
                if key == "feature_flags" and isinstance(value, dict):
                    config["feature_flags"].update(value)
                else:
                    config[key] = value
    return config


async def save_app_config(updates: Dict[str, Any]) -> Dict[str, Any]:
    async with aiosqlite.connect(DB_PATH) as db:
        for key, value in updates.items():
            if key not in DEFAULT_APP_CONFIG:
                continue
            await db.execute(
                "INSERT INTO app_config (key, value_json) VALUES (?, ?) "
                "ON CONFLICT(key) DO UPDATE SET value_json = excluded.value_json",
                (key, json.dumps(value, ensure_ascii=False)),
            )
        await db.commit()
    return await get_app_config()


# ── Jobs, audit & system ─────────────────────────────────────────────────────

async def start_job_run(job: str) -> int:
    async with aiosqlite.connect(DB_PATH) as db:
        cur = await db.execute("INSERT INTO job_runs (job, started_at) VALUES (?, ?)", (job, utc_now_iso()))
        await db.commit()
        return cur.lastrowid


async def update_job_run_detail(run_id: int, detail: str):
    """Live progress for a running job, shown in the admin panel."""
    async with aiosqlite.connect(DB_PATH) as db:
        await db.execute("UPDATE job_runs SET detail = ? WHERE id = ?", (detail[:1000], run_id))
        await db.commit()


async def finish_job_run(run_id: int, status: str, detail: str = ""):
    async with aiosqlite.connect(DB_PATH) as db:
        await db.execute(
            "UPDATE job_runs SET finished_at = ?, status = ?, detail = ? WHERE id = ?",
            (utc_now_iso(), status, detail[:1000], run_id),
        )
        await db.commit()


async def log_admin_action(action: str, detail: str = ""):
    async with aiosqlite.connect(DB_PATH) as db:
        await db.execute(
            "INSERT INTO admin_audit (action, detail, created_at) VALUES (?, ?, ?)",
            (action, detail[:500], utc_now_iso()),
        )
        await db.commit()


async def get_system_status() -> Dict[str, Any]:
    today = ist_today_str()
    series_days = _day_series(14)
    async with aiosqlite.connect(DB_PATH) as db:
        db.row_factory = aiosqlite.Row
        horoscope_total = await _fetch_scalar(db, "SELECT COUNT(*) FROM horoscope_cache")
        panchang_total = await _fetch_scalar(db, "SELECT COUNT(*) FROM panchang_cache")
        horoscope_today = await _fetch_scalar(db, "SELECT COUNT(*) FROM horoscope_cache WHERE date_str = ?", (today,))
        panchang_today = await _fetch_scalar(db, "SELECT COUNT(*) FROM panchang_cache WHERE date_str = ?", (today,))
        events_total = await _fetch_scalar(db, "SELECT COUNT(*) FROM events")

        async with db.execute(
            "SELECT date_str, metric, count FROM api_stats WHERE date_str >= ?", (series_days[0],)
        ) as cur:
            stats: Dict[str, Dict[str, int]] = {}
            for r in await cur.fetchall():
                stats.setdefault(r["metric"], {})[r["date_str"]] = r["count"]

        async with db.execute("SELECT * FROM job_runs ORDER BY id DESC LIMIT 10") as cur:
            jobs = [
                {"id": r["id"], "job": r["job"], "startedAt": r["started_at"], "finishedAt": r["finished_at"],
                 "status": r["status"], "detail": r["detail"]}
                for r in await cur.fetchall()
            ]
        async with db.execute("SELECT * FROM admin_audit ORDER BY id DESC LIMIT 25") as cur:
            audit = [{"action": r["action"], "detail": r["detail"], "at": r["created_at"]} for r in await cur.fetchall()]

    metrics = sorted(stats.keys())
    today_stats = {m: stats[m].get(today, 0) for m in metrics}
    hits = today_stats.get("horoscope_cache_hit", 0) + today_stats.get("panchang_cache_hit", 0)
    misses = today_stats.get("horoscope_gemini", 0) + today_stats.get("panchang_gemini", 0)
    try:
        db_size = os.path.getsize(DB_PATH)
    except OSError:
        db_size = 0

    return {
        "db": {"path": DB_PATH, "size_bytes": db_size, "events_total": events_total},
        "cache": {
            "horoscope_total": horoscope_total,
            "panchang_total": panchang_total,
            "horoscope_today": horoscope_today,
            "panchang_today": panchang_today,
            "hit_rate_today_pct": round(hits * 100.0 / (hits + misses), 1) if (hits + misses) else None,
        },
        "api": {
            "days": series_days,
            "today": today_stats,
            "series": {m: [stats[m].get(d, 0) for d in series_days] for m in metrics},
        },
        "jobs": jobs,
        "audit": audit,
    }


# ── Push notifications ───────────────────────────────────────────────────────

async def save_push_token(device_id: str, token: str, enabled: bool, platform: str):
    async with aiosqlite.connect(DB_PATH) as db:
        # A token belongs to exactly one install.
        await db.execute("DELETE FROM push_tokens WHERE token = ? AND device_id != ?", (token, device_id))
        await db.execute(
            """
            INSERT INTO push_tokens (device_id, token, enabled, platform, updated_at) VALUES (?, ?, ?, ?, ?)
            ON CONFLICT(device_id) DO UPDATE SET
                token = excluded.token, enabled = excluded.enabled,
                platform = excluded.platform, updated_at = excluded.updated_at
            """,
            (device_id, token, 1 if enabled else 0, platform, utc_now_iso()),
        )
        await db.commit()


async def delete_push_tokens(tokens: List[str]):
    if not tokens:
        return
    async with aiosqlite.connect(DB_PATH) as db:
        await db.executemany("DELETE FROM push_tokens WHERE token = ?", [(t,) for t in tokens])
        await db.commit()


def _push_audience_filter(
    audience: str, locale: str, platform: str, device_id: str = "", dormant_days: int = 7
):
    where, params = ["p.enabled = 1"], []
    if audience == "vip":
        where.append("(d.is_vip = 1 OR d.vip_granted = 1)")
    elif audience == "free":
        where.append("COALESCE(d.is_vip, 0) = 0 AND COALESCE(d.vip_granted, 0) = 0")
    elif audience == "dormant":
        where.append("datetime(d.last_seen) < datetime('now', ?)")
        params.append(f"-{max(1, int(dormant_days))} day")
    elif audience == "user":
        where.append("p.device_id = ?")
        params.append(device_id)
    if locale:
        where.append("d.locale = ?")
        params.append(locale)
    if platform:
        where.append("p.platform = ?")
        params.append(platform)
    return "WHERE " + " AND ".join(where), params


async def get_push_tokens_for(
    audience: str, locale: str = "", platform: str = "", device_id: str = "", dormant_days: int = 7
) -> List[str]:
    clause, params = _push_audience_filter(audience, locale, platform, device_id, dormant_days)
    async with aiosqlite.connect(DB_PATH) as db:
        async with db.execute(
            f"SELECT p.token FROM push_tokens p LEFT JOIN devices d ON d.device_id = p.device_id {clause}",
            tuple(params),
        ) as cur:
            return [r[0] for r in await cur.fetchall()]


async def estimate_push_reach(
    audience: str, locale: str = "", platform: str = "", device_id: str = "", dormant_days: int = 7
) -> int:
    clause, params = _push_audience_filter(audience, locale, platform, device_id, dormant_days)
    async with aiosqlite.connect(DB_PATH) as db:
        return await _fetch_scalar(
            db,
            f"SELECT COUNT(*) FROM push_tokens p LEFT JOIN devices d ON d.device_id = p.device_id {clause}",
            tuple(params),
        )


_CAMPAIGN_FIELDS = (
    "title", "body", "image_url", "route", "aarti_id", "audience", "locale", "platform",
    "target_device_id", "dormant_days", "status", "scheduled_at", "repeat",
)


async def create_push_campaign(fields: Dict[str, Any]) -> int:
    cols = [c for c in _CAMPAIGN_FIELDS if c in fields]
    async with aiosqlite.connect(DB_PATH) as db:
        cur = await db.execute(
            f"INSERT INTO push_campaigns ({', '.join(cols)}, created_at) VALUES ({', '.join('?' for _ in cols)}, ?)",
            (*[fields[c] for c in cols], utc_now_iso()),
        )
        await db.commit()
        return cur.lastrowid


def _campaign_row(r) -> Dict[str, Any]:
    d = dict(r)
    reach = d.get("total_reach") or 0
    d["opens"] = d.get("opens") or 0
    d["open_rate_pct"] = round(min(100.0, d["opens"] * 100.0 / reach), 1) if reach else None
    return d


async def list_push_campaigns(limit: int = 100) -> List[Dict[str, Any]]:
    async with aiosqlite.connect(DB_PATH) as db:
        db.row_factory = aiosqlite.Row
        async with db.execute(
            """
            SELECT c.*, (
                SELECT COUNT(DISTINCT e.device_id) FROM events e
                WHERE e.name = 'push_open' AND e.item = CAST(c.id AS TEXT)
            ) AS opens
            FROM push_campaigns c ORDER BY c.id DESC LIMIT ?
            """,
            (limit,),
        ) as cur:
            return [_campaign_row(r) for r in await cur.fetchall()]


async def get_push_campaign(campaign_id: int) -> Optional[Dict[str, Any]]:
    async with aiosqlite.connect(DB_PATH) as db:
        db.row_factory = aiosqlite.Row
        async with db.execute("SELECT * FROM push_campaigns WHERE id = ?", (campaign_id,)) as cur:
            row = await cur.fetchone()
            return dict(row) if row else None


async def get_due_push_campaign_ids() -> List[int]:
    async with aiosqlite.connect(DB_PATH) as db:
        async with db.execute(
            "SELECT id FROM push_campaigns WHERE status = 'scheduled' "
            "AND scheduled_at IS NOT NULL AND datetime(scheduled_at) <= datetime('now') ORDER BY scheduled_at"
        ) as cur:
            return [r[0] for r in await cur.fetchall()]


async def claim_push_campaign(campaign_id: int, allow_statuses: tuple = ("scheduled",)) -> bool:
    """Atomically marks a campaign as sending so the scheduler never double-sends."""
    placeholders = ", ".join("?" for _ in allow_statuses)
    async with aiosqlite.connect(DB_PATH) as db:
        cur = await db.execute(
            f"UPDATE push_campaigns SET status = 'sending' WHERE id = ? AND status IN ({placeholders})",
            (campaign_id, *allow_statuses),
        )
        await db.commit()
        return cur.rowcount > 0


async def record_push_result(
    campaign_id: int, success: int, failure: int, error: str, next_scheduled_at: Optional[str], reach: int = 0
):
    if next_scheduled_at:
        status = "scheduled"
    else:
        status = "sent" if success > 0 else "failed"
    async with aiosqlite.connect(DB_PATH) as db:
        await db.execute(
            """
            UPDATE push_campaigns SET
                status = ?, last_sent_at = ?, send_count = send_count + 1,
                success_count = success_count + ?, failure_count = failure_count + ?,
                total_reach = total_reach + ?,
                last_error = ?, scheduled_at = COALESCE(?, scheduled_at)
            WHERE id = ?
            """,
            (status, utc_now_iso(), success, failure, reach, (error or "")[:500], next_scheduled_at, campaign_id),
        )
        await db.commit()


async def set_push_campaign_status(campaign_id: int, status: str, scheduled_at: Optional[str] = None) -> bool:
    async with aiosqlite.connect(DB_PATH) as db:
        cur = await db.execute(
            "UPDATE push_campaigns SET status = ?, scheduled_at = COALESCE(?, scheduled_at) WHERE id = ?",
            (status, scheduled_at, campaign_id),
        )
        await db.commit()
        return cur.rowcount > 0


async def delete_push_campaign(campaign_id: int) -> bool:
    async with aiosqlite.connect(DB_PATH) as db:
        cur = await db.execute("DELETE FROM push_campaigns WHERE id = ?", (campaign_id,))
        await db.commit()
        return cur.rowcount > 0


async def get_push_stats() -> Dict[str, Any]:
    async with aiosqlite.connect(DB_PATH) as db:
        tokens_total = await _fetch_scalar(db, "SELECT COUNT(*) FROM push_tokens")
        tokens_enabled = await _fetch_scalar(db, "SELECT COUNT(*) FROM push_tokens WHERE enabled = 1")
        installs = await _fetch_scalar(db, "SELECT COUNT(*) FROM devices")
        by_platform = await _fetch_map(
            db, "SELECT platform, COUNT(*) FROM push_tokens WHERE enabled = 1 GROUP BY platform"
        )
        by_locale = await _fetch_map(
            db,
            "SELECT COALESCE(d.locale, 'unknown'), COUNT(*) FROM push_tokens p "
            "LEFT JOIN devices d ON d.device_id = p.device_id WHERE p.enabled = 1 GROUP BY 1",
        )
        sent_30d = await _fetch_scalar(
            db,
            "SELECT COALESCE(SUM(send_count), 0) FROM push_campaigns "
            "WHERE last_sent_at IS NOT NULL AND datetime(last_sent_at) >= datetime('now', '-30 day')",
        )
        opens_30d = await _fetch_scalar(
            db,
            "SELECT COUNT(*) FROM events WHERE name = 'push_open' AND datetime(created_at) >= datetime('now', '-30 day')",
        )
        scheduled = await _fetch_scalar(db, "SELECT COUNT(*) FROM push_campaigns WHERE status = 'scheduled'")
    return {
        "tokens_total": tokens_total,
        "tokens_enabled": tokens_enabled,
        "opt_in_pct": round(tokens_enabled * 100.0 / installs, 1) if installs else 0.0,
        "by_platform": by_platform,
        "by_locale": by_locale,
        "campaigns_sent_30d": sent_30d,
        "opens_30d": opens_30d,
        "scheduled": scheduled,
    }
