import asyncio
import logging
from datetime import datetime, timezone, timedelta
from app.database import (
    get_cached_horoscope,
    save_cached_horoscope,
    get_cached_panchang,
    save_cached_panchang,
    start_job_run,
    update_job_run_detail,
    finish_job_run,
    prune_old_events,
)
from app.gemini_service import generate_horoscope, generate_panchang
from app.vedic_cache import PRECACHE_RPM, precache_item

logger = logging.getLogger("bhaktidhara.cron")

# Rashi names mapping
RASHI_NAMES = {
    "aries": {"mr": "मेष", "hi": "मेष", "en": "Aries"},
    "taurus": {"mr": "वृषभ", "hi": "वृषभ", "en": "Taurus"},
    "gemini": {"mr": "मिथुन", "hi": "मिथुन", "en": "Gemini"},
    "cancer": {"mr": "कर्क", "hi": "कर्क", "en": "Cancer"},
    "leo": {"mr": "सिंह", "hi": "सिंह", "en": "Leo"},
    "virgo": {"mr": "कन्या", "hi": "कन्या", "en": "Virgo"},
    "libra": {"mr": "तुला", "hi": "तुला", "en": "Libra"},
    "scorpio": {"mr": "वृश्चिक", "hi": "वृश्चिक", "en": "Scorpio"},
    "sagittarius": {"mr": "धनु", "hi": "धनु", "en": "Sagittarius"},
    "capricorn": {"mr": "मकर", "hi": "मकर", "en": "Capricorn"},
    "aquarius": {"mr": "कुंभ", "hi": "कुंभ", "en": "Aquarius"},
    "pisces": {"mr": "मीन", "hi": "मीन", "en": "Pisces"},
}

# Top cities pre-cached
TOP_CITIES = [
    {"id": "pune", "name_mr": "पुणे", "name_hi": "पुणे", "name_en": "Pune"},
    {"id": "mumbai", "name_mr": "मुंबई", "name_hi": "मुंबई", "name_en": "Mumbai"},
    {"id": "nagpur", "name_mr": "नागपूर", "name_hi": "नागपुर", "name_en": "Nagpur"},
    {"id": "nashik", "name_mr": "नाशिक", "name_hi": "नासिक", "name_en": "Nashik"},
    {"id": "delhi", "name_mr": "दिल्ली", "name_hi": "दिल्ली", "name_en": "New Delhi"},
    {"id": "varanasi", "name_mr": "वाराणसी", "name_hi": "वाराणसी", "name_en": "Varanasi"},
]


PRECACHE_LANGS = ["mr", "hi"]

_precache_lock = asyncio.Lock()


def precache_running() -> bool:
    return _precache_lock.locked()


def build_precache_items(date_str: str):
    """
    (label, key, lookup, generate, save) for everything the nightly job warms.
    Ordered by language so Marathi (the main audience) is ready first.
    """
    items = []
    for lang in PRECACHE_LANGS:
        for rashi_id, names in RASHI_NAMES.items():
            rashi_name = names.get(lang, names["mr"])
            items.append((
                f"horoscope {rashi_id} [{lang}]",
                ("horoscope", date_str, rashi_id, "today", lang),
                lambda r=rashi_id, l=lang: get_cached_horoscope(date_str, r, "today", l),
                lambda r=rashi_id, n=rashi_name, l=lang: generate_horoscope(
                    rashi_name=n, period="today", lang_code=l, date_text=date_str, rashi_id=r
                ),
                lambda data, r=rashi_id, l=lang: save_cached_horoscope(date_str, r, "today", l, data),
            ))
        for city in TOP_CITIES:
            city_name = city.get(f"name_{lang}", city["name_mr"])
            items.append((
                f"panchang {city['id']} [{lang}]",
                ("panchang", date_str, city["id"], lang),
                lambda c=city["id"], l=lang: get_cached_panchang(date_str, c, l),
                lambda n=city_name, l=lang: generate_panchang(city_name=n, date_str=date_str, lang_code=l),
                lambda data, c=city["id"], l=lang: save_cached_panchang(date_str, c, l, data),
            ))
    return items


async def run_daily_precache_job():
    """
    Pre-generates today's horoscopes and panchang, paced to PRECACHE_RPM Gemini
    calls per minute. Anything users already generated today is skipped, so each
    minute's budget goes to the next readings still missing.
    Runs at 00:05 AM IST every morning (and on demand from the admin panel).
    """
    if _precache_lock.locked():
        logger.info("Precache already running; skipping this trigger.")
        return

    async with _precache_lock:
        logger.info("Starting Daily Vedic Precaching Job (%s Gemini calls/min)...", PRECACHE_RPM)
        run_id = await start_job_run("nightly_precache")
        generated = skipped = fallback = failed = 0

        ist_now = datetime.now(timezone.utc) + timedelta(hours=5, minutes=30)
        today_str = ist_now.strftime("%Y-%m-%d")
        items = build_precache_items(today_str)

        def progress() -> str:
            return f"{generated} generated, {skipped} already cached, {fallback} unusable, {failed} failed"

        for index, (label, key, lookup, generate, save) in enumerate(items, start=1):
            try:
                result = await precache_item(key, lookup, generate, save)
                if result == "generated":
                    generated += 1
                    logger.info("Precached %s for %s", label, today_str)
                elif result == "cached":
                    skipped += 1
                else:
                    fallback += 1
                    logger.warning("Gemini returned unusable output for %s", label)
            except Exception as e:
                failed += 1
                logger.error("Error precaching %s: %s", label, e)
            await update_job_run_detail(run_id, f"{index}/{len(items)} · {progress()}")

        try:
            pruned = await prune_old_events()
        except Exception as e:
            pruned = 0
            logger.error(f"Error pruning old events: {e}")

        ok = generated + skipped
        status = "success" if ok == len(items) else ("partial" if ok else "failed")
        await finish_job_run(run_id, status, f"{progress()}, {pruned} old events pruned")
        logger.info("Daily Vedic Precaching Job finished: %s.", progress())
