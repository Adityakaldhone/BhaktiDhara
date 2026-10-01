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


# ── Phase 6: Daily 6:00 AM IST Curiosity Cliffhanger Push Notification ──────────

MORNING_CLIFFHANGER_TEMPLATES = [
    # 0: Monday
    {
        "title": "🔱 आजचे राशीभविष्य: महादेवांचा आशीर्वाद व ग्रहसंकेत!",
        "body": "कामात यश व कौटुंबिक सौख्य कोणाला लाभणार? आजचा सावधगिरीचा इशारा व शुभ काळ पहा ➔",
    },
    # 1: Tuesday
    {
        "title": "🚩 आजचे राशीभविष्य: मंगळ ग्रहाचे मोठे संक्रमण!",
        "body": "संकटमुक्तीसाठी आज कोणती रास ठरेल भाग्यवान? दुपारी ही एक चूक टाळा ➔ तुमचे भविष्य पहा",
    },
    # 2: Wednesday
    {
        "title": "🐘 आजचे राशीभविष्य: श्री गणेशाची विशेष कृपा!",
        "body": "नोकरी, व्यवसाय व आर्थिक स्थितीचे आजचे शुभ संकेत! आजची मैत्री रास व बीजमंत्र पहा ➔",
    },
    # 3: Thursday
    {
        "title": "✨ आजचे राशीभविष्य: गुरु ग्रहाचे शुभ भ्रमण!",
        "body": "आज भाग्य कोणाची साथ देणार? तुमचा ३-वेळचा शुभ काळ व विशेष उपाय ➔ ॲपमध्ये पहा",
    },
    # 4: Friday
    {
        "title": "🌺 आजचे राशीभविष्य: धनलाभाचे विशेष योग!",
        "body": "आर्थिक प्रगती व नवीन संधी कोणाला मिळणार? आज काय टाळावे हे नक्की पहा ➔",
    },
    # 5: Saturday
    {
        "title": "🪐 आजचे राशीभविष्य: शनीदेवाची दृष्टी व सावधगिरी!",
        "body": "कोणत्या राशींनी आज विशेष काळजी घ्यावी? ग्रह शांतीचा सिद्ध उपाय व शुभ वेळ ➔ त्वरित पहा",
    },
    # 6: Sunday
    {
        "title": "☀️ आजचे राशीभविष्य: सूर्यदेवाची विशेष कृपा!",
        "body": "आज कोणत्या राशींसाठी धनलाभ व प्रगतीचा मोठा योग? पण दुपारी काय टाळावे? ➔ त्वरित जाणून घ्या",
    },
]

RASHI_CLIFFHANGERS = {
    "aries": {
        "title": "🚩 आज मेष राशीसाठी धनलाभाचा मोठा योग!",
        "body": "ग्रहांची मोठी अनुकूलता! पण दुपारी ही एक चूक टाळा... ➔ ॲपमध्ये पहा",
    },
    "taurus": {
        "title": "🚩 आज वृषभ राशीसाठी शुभ समाचार!",
        "body": "व्यापारात वाढ व नवे करार! आज कोणता वेळ टाळावा? ➔ त्वरित जाणून घ्या",
    },
    "gemini": {
        "title": "🚩 आज मिथुन राशीसाठी भाग्योदयाचे संकेत!",
        "body": "महत्त्वाच्या कामात यश! आजची अनुकूल मैत्री रास कोणती? ➔ ॲपमध्ये पहा",
    },
    "cancer": {
        "title": "🚩 आज कर्क राशीसाठी कौटुंबिक सौख्याचे योग!",
        "body": "अचानक धनलाभ व मनातील इच्छा पूर्ण! आज काय टाळावे? ➔ त्वरित पहा",
    },
    "leo": {
        "title": "🚩 आज सिंह राशीवर सूर्यदेवाची विशेष कृपा!",
        "body": "कामात मान-सन्मान व अधिकार वाढेल! आजचा ३-वेळचा शुभ काळ पहा ➔",
    },
    "virgo": {
        "title": "🚩 आज कन्या राशीसाठी अनपेक्षित लाभ!",
        "body": "बुद्धिमत्तेच्या जोरावर मोठे काम सिद्ध होईल! आजचा सावधगिरीचा इशारा ➔",
    },
    "libra": {
        "title": "🚩 आज तुला राशीसाठी संपत्ती वाढीचे संकेत!",
        "body": "भागीदारीत फायदा व सुख-समृद्धी! दुपारी १२ नंतर सावध राहा ➔",
    },
    "scorpio": {
        "title": "🚩 आज वृश्चिक राशीसाठी संकटनिवारण योग!",
        "body": "मंगळाचे शुभ भ्रमण! आजचा इष्टदेवता बीजमंत्र काय आहे? ➔ त्वरित पहा",
    },
    "sagittarius": {
        "title": "🚩 आज धनु राशीसाठी नशिबाची पूर्ण साथ!",
        "body": "अडकलेले पैसे परत मिळण्याची शक्यता! आजचा विशेष उपाय पहा ➔",
    },
    "capricorn": {
        "title": "🚩 आज मकर राशीसाठी करिअरमध्ये प्रगती!",
        "body": "शनीदेवांची कृपा व मेहनतीचे फळ! कोणाशी वाद टाळावा? ➔ ॲपमध्ये पहा",
    },
    "aquarius": {
        "title": "🚩 आज कुंभ राशीसाठी नवीन संधींचे द्वार!",
        "body": "मोठ्या यशाचे वेदिक संकेत! आजची शुभ वेळ व दिशा जाणून घ्या ➔",
    },
    "pisces": {
        "title": "🚩 आज मीन राशीसाठी आत्मिक शांती व भरभराट!",
        "body": "गुरु ग्रहाची शुभ दृष्टी! आज कोणता मंत्र जपावा? ➔ तुमचे भविष्य पहा",
    },
}


async def send_daily_morning_horoscope_push():
    """
    Sends the 6:00 AM IST daily curiosity cliffhanger push notification
    to bring devotees into the app for their daily horoscope, hourly breakdown,
    caution alert, and deity mantra.
    """
    from app.push_service import send_to_topic_target, PushNotConfigured

    ist_now = datetime.now(timezone.utc) + timedelta(hours=5, minutes=30)
    weekday = ist_now.weekday()  # 0 = Monday, 6 = Sunday
    template = MORNING_CLIFFHANGER_TEMPLATES[weekday]

    general_campaign = {
        "id": f"morning_push_{ist_now.strftime('%Y%m%d')}",
        "title": template["title"],
        "body": template["body"],
        "route": "horoscope",
        "focus": "caution",
    }

    try:
        # 1. Send personalized Rashi pushes to devotees subscribed to their Rashi
        for rashi_id, rashi_data in RASHI_CLIFFHANGERS.items():
            try:
                rashi_campaign = {
                    "id": f"rashi_push_{rashi_id}_{ist_now.strftime('%Y%m%d')}",
                    "title": rashi_data["title"],
                    "body": rashi_data["body"],
                    "route": "horoscope",
                    "rashi": rashi_id,
                    "focus": "caution",
                }
                await send_to_topic_target(rashi_campaign, {"topic": f"rashi_{rashi_id}"})
            except Exception as e:
                logger.warning(f"Error dispatching morning push for rashi {rashi_id}: {e}")

        # 2. Send to devotees subscribed to morning_horoscope (who haven't selected a rashi)
        result = await send_to_topic_target(general_campaign, {"topic": "morning_horoscope"})
        logger.info(f"Daily 6 AM Horoscope curiosity push sent: {result}")
        return result
    except PushNotConfigured:
        logger.info("Firebase push credentials not configured; morning push skipped.")
        return {"success": 0, "skipped": True}
    except Exception as e:
        logger.error(f"Failed to send 6 AM morning horoscope push: {e}")
        return {"success": 0, "error": str(e)}


