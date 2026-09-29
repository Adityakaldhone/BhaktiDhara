import asyncio
import logging
from datetime import datetime, timezone, timedelta
from app.database import (
    save_cached_horoscope,
    save_cached_panchang,
    start_job_run,
    finish_job_run,
    increment_api_stat,
    prune_old_events,
)
from app.gemini_service import generate_horoscope, generate_panchang

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


async def run_daily_precache_job():
    """
    Nightly cron job that pre-generates horoscopes and panchang for the day.
    Runs at 00:05 AM IST every morning.
    """
    logger.info("Starting Daily Vedic Precaching Job...")
    run_id = await start_job_run("nightly_precache")
    ok = failed = 0

    # Calculate IST date (UTC+5:30)
    ist_now = datetime.now(timezone.utc) + timedelta(hours=5, minutes=30)
    today_str = ist_now.strftime("%Y-%m-%d")

    # 1. Pre-generate Daily Horoscopes (12 rashis in Marathi & Hindi)
    for rashi_id, names in RASHI_NAMES.items():
        for lang in ["mr", "hi"]:
            rashi_name = names.get(lang, names["mr"])
            try:
                data = await generate_horoscope(
                    rashi_name=rashi_name,
                    period="today",
                    lang_code=lang,
                    date_text=today_str,
                    rashi_id=rashi_id,
                )
                await save_cached_horoscope(
                    date_str=today_str,
                    rashi_id=rashi_id,
                    period="today",
                    lang_code=lang,
                    data=data,
                )
                logger.info(f"Cached Horoscope: {rashi_id} [{lang}] for {today_str}")
                ok += 1
                # Slight throttle to prevent sudden burst
                await asyncio.sleep(0.5)
            except Exception as e:
                failed += 1
                logger.error(f"Error caching horoscope {rashi_id} [{lang}]: {e}")

    # 2. Pre-generate Panchang for key cities
    for city in TOP_CITIES:
        for lang in ["mr", "hi"]:
            city_name = city.get(f"name_{lang}", city["name_mr"])
            try:
                data = await generate_panchang(
                    city_name=city_name,
                    date_str=today_str,
                    lang_code=lang,
                )
                await save_cached_panchang(
                    date_str=today_str,
                    city_id=city["id"],
                    lang_code=lang,
                    data=data,
                )
                logger.info(f"Cached Panchang: {city['id']} [{lang}] for {today_str}")
                ok += 1
                await asyncio.sleep(0.5)
            except Exception as e:
                failed += 1
                logger.error(f"Error caching panchang {city['id']} [{lang}]: {e}")

    try:
        pruned = await prune_old_events()
    except Exception as e:
        pruned = 0
        logger.error(f"Error pruning old events: {e}")

    await increment_api_stat("precache_gemini", ok)
    if failed:
        await increment_api_stat("gemini_error", failed)
    status = "success" if failed == 0 else ("partial" if ok else "failed")
    await finish_job_run(run_id, status, f"{ok} cached, {failed} failed, {pruned} old events pruned")
    logger.info(f"Daily Vedic Precaching Job finished: {ok} ok, {failed} failed.")
