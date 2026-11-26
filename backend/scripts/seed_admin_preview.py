"""Seeds a local preview SQLite database (backend/data/admin_preview.db) with
realistic BhaktiDhara devotees, subscriptions, daily active sessions, events,
push campaigns, announcements, feedback, and deity requests for local review.
"""
import asyncio
import json
import os
import random
import sys
from datetime import datetime, timedelta, timezone
from pathlib import Path

BACKEND_DIR = Path(__file__).resolve().parents[1]
PREVIEW_DB = BACKEND_DIR / "data" / "admin_preview.db"
os.environ["DB_PATH"] = str(PREVIEW_DB)
sys.path.insert(0, str(BACKEND_DIR))

import aiosqlite  # noqa: E402
from app import database, greetings  # noqa: E402


CITIES = [
    ("Pune", "Maharashtra"),
    ("Mumbai", "Maharashtra"),
    ("Nagpur", "Maharashtra"),
    ("Nashik", "Maharashtra"),
    ("Thane", "Maharashtra"),
    ("Kolhapur", "Maharashtra"),
    ("Indore", "Madhya Pradesh"),
    ("Jaipur", "Rajasthan"),
    ("Bengaluru", "Karnataka"),
    ("Ahmedabad", "Gujarat"),
    ("Delhi", "Delhi"),
    ("Surat", "Gujarat"),
]

NAMES = [
    "Aarav Joshi", "Prachi Kulkarni", "Omkar Deshmukh", "Sneha Patil",
    "Rohan Gokhale", "Ananya Sharma", "Vikramaditya Rao", "Pooja Sawant",
    "Ketan Bhosale", "Neha Tiwari", "Siddharth Verma", "Aditi Iyer",
    "Mayur Shinde", "Kavita Nair", "Harshal Pawar", "Rutuja Chavan",
    "", "", "",  # anonymous devotees too
]

DEVICES = [
    ("Samsung Galaxy S24", "Android 15"),
    ("OnePlus 12R", "Android 14"),
    ("Redmi Note 13 Pro", "Android 14"),
    ("Vivo V30", "Android 14"),
    ("Realme GT 6", "Android 14"),
    ("Pixel 8", "Android 15"),
    ("iPhone 15", "iOS 18.1"),
    ("iPhone 14", "iOS 17.6"),
]

AARTIS = [
    "ganpati_sukhakarta", "shiv_lavthavti", "hanuman_chalisa",
    "durga_aarti", "vitthal_yuge_atthavis", "swami_samarth_aarti",
    "krishna_aarti_kunjbihari", "mahalaxmi_aarti",
]
DEITIES = ["Lord Ganesha", "Lord Shiva", "Lord Hanuman", "Goddess Durga", "Lord Vitthal", "Swami Samarth", "Lord Krishna"]
MANTRAS = ["om_namah_shivaya", "gayatri_mantra", "hanuman_beeja", "ganesh_atharvashirsha", "ram_raksha"]
PLANS = [
    ("bhaktidhara_annual_399", 365, 399, 0.45),
    ("bhaktidhara_halfyearly_229", 180, 229, 0.18),
    ("bhaktidhara_quarterly_129", 90, 129, 0.17),
    ("bhaktidhara_monthly_51", 30, 51, 0.20),
]


async def seed() -> None:
    if PREVIEW_DB.exists():
        PREVIEW_DB.unlink()
    await database.init_db()
    await greetings.init_greetings_db()

    rng = random.Random(2026)
    now = datetime.now(timezone.utc)
    ist_offset = timedelta(hours=5, minutes=30)

    devices_rows = []
    da_rows = []
    events_rows = []
    sub_rows = []
    push_token_rows = []

    total_users = 320
    for idx in range(total_users):
        dev_id = f"bd-dev-{idx:04d}-{rng.randint(1000, 9999)}"
        # Skew installs toward recent weeks for realistic growth curve
        days_ago = int((rng.random() ** 1.35) * 65)
        first_dt = now - timedelta(days=days_ago, hours=rng.randint(0, 23), minutes=rng.randint(0, 59))
        # Determine retention behavior
        bucket = rng.random()
        if bucket < 0.08:
            # Uninstalled
            last_dt = min(now - timedelta(days=1), first_dt + timedelta(days=rng.randint(0, 8)))
            uninstalled_at = (last_dt + timedelta(days=1)).isoformat()
        elif bucket < 0.22:
            # Dormant
            last_dt = min(now - timedelta(days=31), first_dt + timedelta(days=rng.randint(0, 10)))
            uninstalled_at = ""
        elif bucket < 0.40:
            # At-risk (8-30d)
            last_dt = now - timedelta(days=rng.randint(8, 28), hours=rng.randint(0, 23))
            if last_dt < first_dt:
                last_dt = first_dt
            uninstalled_at = ""
        else:
            # Active in last 7d
            last_dt = now - timedelta(days=rng.randint(0, 6), hours=rng.randint(0, 20))
            if last_dt < first_dt:
                last_dt = first_dt
            uninstalled_at = ""

        model, os_ver = rng.choice(DEVICES)
        platform = "ios" if "iPhone" in model else "android"
        locale = rng.choices(["mr", "hi", "en"], weights=[0.56, 0.31, 0.13])[0]
        app_ver = rng.choices(["1.0.4", "1.0.3", "1.0.2"], weights=[0.74, 0.19, 0.07])[0]
        city, state = rng.choice(CITIES)
        name = rng.choice(NAMES)

        is_vip = 1 if rng.random() < 0.17 else 0
        vip_granted = 1 if (not is_vip and rng.random() < 0.03) else 0
        blocked = 1 if rng.random() < 0.01 else 0

        # Active days between first_dt and last_dt
        span_days = max(1, (last_dt.date() - first_dt.date()).days + 1)
        n_active_days = min(span_days, rng.randint(1, min(span_days, 28)))
        chosen_offsets = sorted(rng.sample(range(span_days), n_active_days))
        if 0 not in chosen_offsets:
            chosen_offsets[0] = 0

        total_pings = 0
        for off in chosen_offsets:
            d_utc = first_dt + timedelta(days=off)
            d_ist_str = (d_utc + ist_offset).strftime("%Y-%m-%d")
            sessions = rng.choices([1, 2, 3, 4], weights=[0.55, 0.25, 0.13, 0.07])[0]
            total_pings += sessions
            da_rows.append((d_ist_str, dev_id, sessions))

            # Peak hours around 6-9 AM IST and 6-9 PM IST
            ist_hr = rng.choices(
                list(range(24)),
                weights=[1, 1, 1, 1, 2, 7, 14, 16, 12, 7, 5, 4, 4, 3, 3, 4, 5, 7, 11, 13, 10, 6, 3, 2],
            )[0]
            ev_dt = (d_utc + ist_offset).replace(hour=ist_hr, minute=rng.randint(0, 59)) - ist_offset
            if ev_dt > now:
                ev_dt = now - timedelta(minutes=rng.randint(5, 120))
            ev_iso = ev_dt.isoformat()
            events_rows.append((dev_id, "app_open", "", "{}", ev_iso))

            for _ in range(rng.randint(1, 3)):
                ev_name = rng.choices(
                    ["aarti_open", "jaap_mala_complete", "mandir_open", "mandir_ritual", "horoscope_view", "panchang_open", "bhajan_open", "greeting_share", "nitya_pinned", "share"],
                    weights=[25, 16, 15, 12, 14, 10, 9, 8, 5, 3],
                )[0]
                item = ""
                if ev_name in ("aarti_open", "nitya_pinned", "bhajan_open"):
                    item = rng.choice(AARTIS)
                elif ev_name in ("mandir_open", "mandir_ritual"):
                    item = rng.choice(DEITIES)
                elif ev_name == "jaap_mala_complete":
                    item = rng.choice(MANTRAS)
                elif ev_name == "greeting_share":
                    item = rng.choice(["morning", "devotional", "motivation", "festival"])
                elif ev_name == "horoscope_view":
                    item = rng.choice(["aries", "taurus", "leo", "scorpio", "aquarius", "pisces"])
                events_rows.append((dev_id, ev_name, item, json.dumps({"item": item}), ev_iso))

        devices_rows.append((
            dev_id, platform, app_ver, locale, is_vip, name, city, state, "India",
            first_dt.isoformat(), last_dt.isoformat(), max(1, total_pings), "", vip_granted,
            blocked, "", model, os_ver, uninstalled_at,
        ))

        if not uninstalled_at and rng.random() < 0.84:
            push_token_rows.append((dev_id, f"fcm-tok-{idx:04d}", 1 if rng.random() < 0.9 else 0, platform, last_dt.isoformat()))

        # Paywall funnel events for subset of users
        if rng.random() < 0.42:
            pv_dt = (first_dt + timedelta(days=rng.randint(0, min(5, span_days - 1)))).isoformat()
            events_rows.append((dev_id, "paywall_view", "subscription_sheet", "{}", pv_dt))
            if rng.random() < 0.62:
                pid = rng.choices([p[0] for p in PLANS], weights=[p[3] for p in PLANS])[0]
                events_rows.append((dev_id, "plan_select", pid, "{}", pv_dt))
                if rng.random() < 0.72:
                    events_rows.append((dev_id, "subscribe_tap", pid, "{}", pv_dt))
                    events_rows.append((dev_id, "subscription_purchase_start", pid, "{}", pv_dt))
                    if not is_vip and rng.random() < 0.15:
                        events_rows.append((dev_id, "subscription_purchase_cancel", pid, "{}", pv_dt))

        if is_vip:
            pid, dur_days, price, _ = rng.choices(PLANS, weights=[p[3] for p in PLANS])[0]
            sub_start = first_dt + timedelta(days=rng.randint(0, min(4, span_days - 1)))
            is_trial = 1 if rng.random() < 0.22 else 0
            status = "cancelled" if rng.random() < 0.12 else "active"
            exp_dt = sub_start + timedelta(days=(7 if is_trial else dur_days))
            if exp_dt < now and status == "active":
                exp_dt = now + timedelta(days=rng.randint(15, dur_days))
            sub_rows.append((
                dev_id, pid, f"ptok-{idx:04d}", f"GPA.4421-{idx:04d}", platform,
                status, is_trial, 1 if status == "active" else 0,
                sub_start.isoformat(), exp_dt.isoformat(), "", sub_start.isoformat(),
            ))
            events_rows.append((dev_id, "subscription_activated", pid, json.dumps({"is_trial": bool(is_trial), "price": price}), sub_start.isoformat()))
            events_rows.append((dev_id, "vip_unlock", pid, "{}", sub_start.isoformat()))

        if rng.random() < 0.18:
            events_rows.append((dev_id, "rewarded_ad_earned", "jaap_theme:1", "{}", last_dt.isoformat()))
        if rng.random() < 0.28:
            events_rows.append((dev_id, "festive_popup_view", "diwali_2026", "{}", last_dt.isoformat()))
            if rng.random() < 0.24:
                events_rows.append((dev_id, "festive_popup_click", "diwali_2026", "{}", last_dt.isoformat()))

    async with aiosqlite.connect(PREVIEW_DB) as db:
        await db.executemany(
            """
            INSERT INTO devices (
                device_id, platform, app_version, locale, is_vip, user_name, city, state, country,
                first_seen, last_seen, ping_count, notes, vip_granted, blocked, app_instance_id,
                device_model, os_version, uninstalled_at
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            """,
            devices_rows,
        )
        await db.executemany(
            "INSERT OR REPLACE INTO daily_active (date_str, device_id, sessions) VALUES (?, ?, ?)",
            da_rows,
        )
        await db.executemany(
            "INSERT INTO events (device_id, name, item, props_json, created_at) VALUES (?, ?, ?, ?, ?)",
            events_rows,
        )
        await db.executemany(
            """
            INSERT INTO subscriptions (
                device_id, product_id, purchase_token, order_id, platform, status,
                is_trial, auto_renewing, started_at, expires_at, raw_receipt, updated_at
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            """,
            sub_rows,
        )
        await db.executemany(
            "INSERT OR REPLACE INTO push_tokens (device_id, token, enabled, platform, updated_at) VALUES (?, ?, ?, ?, ?)",
            push_token_rows,
        )
        # Seed push campaigns, announcements, api_stats, job_runs, feedback & deity requests
        await db.executemany(
            """
            INSERT INTO push_campaigns (
                title, body, route, audience, locale, status, scheduled_at, repeat,
                created_at, last_sent_at, send_count, success_count, failure_count, total_reach
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            """,
            [
                ("🪔 सकाळची आरती", "शुभ प्रभात! आजची आरती करूया 🙏", "", "all", "mr", "scheduled", (now + timedelta(hours=8)).isoformat(), "daily", (now - timedelta(days=12)).isoformat(), (now - timedelta(hours=14)).isoformat(), 12, 198, 4, 202),
                ("♈ आजचे राशिभविष्य", "तुमच्या राशीसाठी आजचा शुभ रंग आणि उपाय पहा ✨", "horoscope", "all", "", "sent", (now - timedelta(days=2)).isoformat(), "none", (now - timedelta(days=2)).isoformat(), (now - timedelta(days=2)).isoformat(), 1, 235, 3, 238),
                ("📿 संध्याकाळचा जप", "१०८ जप पूर्ण करून आपली भक्ती साखळी टिकवा 🔥", "jaap", "free", "hi", "sent", (now - timedelta(days=5)).isoformat(), "none", (now - timedelta(days=5)).isoformat(), (now - timedelta(days=5)).isoformat(), 1, 142, 2, 144),
            ],
        )
        await db.execute(
            "INSERT INTO announcements (title, body, locale, link, active, created_at) VALUES (?, ?, ?, ?, 1, ?)",
            ("🪔 Kartik Purnima Special Aartis", "New sacred stotras and special Mandir Deepotsav theme are now live!", "all", "", (now - timedelta(days=3)).isoformat()),
        )
        await db.executemany(
            "INSERT INTO events (device_id, name, item, props_json, created_at) VALUES (?, ?, ?, ?, ?)",
            [
                ("bd-dev-0000-" + devices_rows[0][0].split("-")[-1], "deity_requested", "मोरखडी Siddheshwar", json.dumps({"deity_name": "मोरखडी Siddheshwar", "lang": "mr", "source": "aarti_search"}, ensure_ascii=False), (now - timedelta(hours=2)).isoformat()),
                ("bd-dev-0001-" + devices_rows[1][0].split("-")[-1], "deity_requested", "Khandoba Maharaj", json.dumps({"deity_name": "Khandoba Maharaj", "lang": "mr", "source": "aarti_search"}), (now - timedelta(days=1)).isoformat()),
                ("bd-dev-0002-" + devices_rows[2][0].split("-")[-1], "app_feedback", "Please add morning alarm chime for Kakad Aarti!", json.dumps({"message": "Please add morning alarm chime for Kakad Aarti!", "lang": "en", "app_version": "1.0.4"}), (now - timedelta(hours=18)).isoformat()),
            ],
        )
        for d_off in range(14):
            d_str = ((now - timedelta(days=d_off)) + ist_offset).strftime("%Y-%m-%d")
            await db.execute("INSERT OR REPLACE INTO api_stats VALUES (?, 'horoscope_cache_hit', ?)", (d_str, rng.randint(180, 420)))
            await db.execute("INSERT OR REPLACE INTO api_stats VALUES (?, 'panchang_cache_hit', ?)", (d_str, rng.randint(120, 290)))
            await db.execute("INSERT OR REPLACE INTO api_stats VALUES (?, 'horoscope_gemini', ?)", (d_str, rng.randint(12, 36)))
        await db.execute(
            "INSERT INTO job_runs (job, started_at, finished_at, status, detail) VALUES (?, ?, ?, ?, ?)",
            ("nightly_vedic_precache", (now - timedelta(hours=16)).isoformat(), (now - timedelta(hours=15, minutes=52)).isoformat(), "success", "Cached 36/36 readings across mr/hi/en"),
        )
        await db.execute(
            "INSERT INTO admin_audit (action, detail, created_at) VALUES (?, ?, ?)",
            ("seed_preview", "Initialized local preview analytics database", now.isoformat()),
        )
        await db.commit()

    print(f"Seeded preview DB at {PREVIEW_DB}: {len(devices_rows)} devices, {len(sub_rows)} subscriptions, {len(events_rows)} events")


if __name__ == "__main__":
    asyncio.run(seed())
