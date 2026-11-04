"""Festival greeting cards (Diwali season and beyond).

Each festival gets its own greeting category. The nightly job fills the
soonest upcoming festivals first, within the daily free image budget, and
festival categories are pinned to the top of the app until the day after the
festival, then hidden.

Dates come from the app's tithi engine (Pune). Add next year's dates to
FESTIVAL_DATES before the season starts.
"""
import asyncio
import logging
import os
from datetime import date, datetime, timedelta, timezone
from typing import Any, Dict, List, Optional, Tuple

import aiosqlite

from app.database import (
    DB_PATH,
    finish_job_run,
    log_admin_action,
    start_job_run,
    update_job_run_detail,
    utc_now_iso,
)
from app.greeting_generator import (
    _generator_lock,
    _last_job_status,
    _save_greeting_to_db,
    generate_single_greeting_image,
)

logger = logging.getLogger("bhaktidhara.festival_greetings")

IST = timezone(timedelta(hours=5, minutes=30))
LANGS = ("mr", "hi", "en")
LAYOUTS = ("bottom_gradient", "center_card", "top_banner", "magazine_minimal")

# Start generating this many days before a festival.
GENERATION_WINDOW_DAYS = 10
# Category stays visible through the day after the festival.
VISIBLE_AFTER_DAYS = 1

FESTIVAL_DATES: Dict[str, List[date]] = {
    "vasubaras": [date(2026, 11, 5)],
    "dhanteras": [date(2026, 11, 6)],
    "narak_chaturdashi": [date(2026, 11, 8)],
    "diwali": [date(2026, 11, 8)],
    "diwali_padwa": [date(2026, 11, 10)],
    "bhaubij": [date(2026, 11, 11)],
    "kartiki_ekadashi": [date(2026, 11, 20)],
    "tulsi_vivah": [date(2026, 11, 21)],
    "tripuri_purnima": [date(2026, 11, 24)],
}

FESTIVALS: Dict[str, Dict[str, Any]] = {
    "vasubaras": {
        "names": ("वसुबारस", "गोवत्स द्वादशी", "Vasubaras"),
        "emoji": "🐄",
        "target": 12,
        "headings": {
            "mr": "वसुबारसच्या हार्दिक शुभेच्छा",
            "hi": "गोवत्स द्वादशी की शुभकामनाएं",
            "en": "Happy Vasubaras",
        },
        "quotes": {
            "mr": [
                "गोमातेच्या आशीर्वादाने आपले घर सुख, समृद्धी आणि आरोग्याने भरून जावो.",
                "दिवाळीच्या पहिल्या दिवशी गोमातेचे पूजन करूया, आनंदाचा दीप उजळूया!",
                "वसुबारसेपासून सुरू होणारी दिवाळी आपल्यासाठी मंगलमय ठरो.",
            ],
            "hi": [
                "गौमाता के आशीर्वाद से आपका घर सुख, समृद्धि और आरोग्य से भर जाए।",
                "दीपोत्सव की शुरुआत गौमाता के पूजन से, आपका जीवन मंगलमय हो।",
                "गोवत्स द्वादशी पर आपके परिवार पर सदा कृपा बनी रहे।",
            ],
            "en": [
                "May the blessings of Gau Mata fill your home with health, peace and prosperity.",
                "The festival of lights begins with gratitude. Wishing you a blessed Vasubaras!",
                "May this auspicious start of Diwali bring joy to your family.",
            ],
        },
        "scenes": [
            "A gentle white Indian cow and her calf adorned with marigold garlands, red and yellow cloth, turmeric and kumkum marks on their foreheads, standing in a clean village courtyard with a row of glowing clay diyas and a colourful rangoli, soft warm evening light",
            "A decorated calf nuzzling its mother cow, brass bells and flower garlands around their necks, traditional rangoli and lit diyas on the ground, golden hour glow",
            "A brass pooja thali with a diya, haldi-kumkum, rice grains, jaggery and green grass placed before a garlanded cow in a rustic Maharashtrian village courtyard, festive warm light",
            "A peaceful village cowshed decorated with mango-leaf toran and marigold strings, oil lamps glowing, a cow and calf resting, warm twilight sky",
        ],
    },
    "dhanteras": {
        "names": ("धनत्रयोदशी", "धनतेरस", "Dhanteras"),
        "emoji": "💰",
        "target": 12,
        "headings": {
            "mr": "धनत्रयोदशीच्या हार्दिक शुभेच्छा",
            "hi": "धनतेरस की हार्दिक शुभकामनाएं",
            "en": "Happy Dhanteras",
        },
        "quotes": {
            "mr": [
                "धन्वंतरीच्या कृपेने आरोग्य लाभो आणि लक्ष्मीच्या कृपेने घरात समृद्धी नांदो.",
                "आपल्या घरी सुख, समृद्धी आणि ऐश्वर्याचा सदैव वास राहो.",
                "धनत्रयोदशीचा हा शुभ दिवस आपल्या आयुष्यात भरभराट घेऊन येवो.",
            ],
            "hi": [
                "भगवान धन्वंतरि आपको उत्तम स्वास्थ्य दें और माँ लक्ष्मी अपार समृद्धि।",
                "आपके घर में सदा सुख, समृद्धि और ऐश्वर्य का वास हो।",
                "धनतेरस का यह पावन दिन आपके जीवन में खुशहाली लाए।",
            ],
            "en": [
                "May Lord Dhanvantari bless you with health and Goddess Lakshmi with abundance.",
                "Wishing your home endless prosperity, good health and happiness.",
                "May this Dhanteras bring wealth, wellness and new beginnings.",
            ],
        },
        "scenes": [
            "Shimmering gold coins spilling from an ornate brass kalash on a red silk cloth, surrounded by glowing clay diyas, marigold petals and kumkum, rich warm bokeh",
            "New shining brass and copper utensils arranged on a decorated pooja platform with diyas, rangoli and flower petals, festive Diwali evening glow",
            "Small red footprints of Goddess Lakshmi painted with kumkum leading to a decorated doorway with diyas, marigold toran and rangoli, warm night glow",
            "A silver coin, betel leaves, whole coriander seeds and a lit diya on an ornate brass plate, Dhanvantari pooja setup, soft golden light",
        ],
    },
    "narak_chaturdashi": {
        "names": ("नरक चतुर्दशी", "नरक चतुर्दशी", "Narak Chaturdashi"),
        "emoji": "🪔",
        "target": 12,
        "headings": {
            "mr": "नरक चतुर्दशीच्या हार्दिक शुभेच्छा",
            "hi": "नरक चतुर्दशी की शुभकामनाएं",
            "en": "Happy Narak Chaturdashi",
        },
        "quotes": {
            "mr": [
                "अभ्यंगस्नानाने मन प्रसन्न होवो आणि आयुष्यातील अंधार दूर होवो.",
                "उटण्याचा सुगंध आणि दिव्यांचा प्रकाश आपले जीवन उजळून टाको.",
                "वाईटावर चांगल्याचा विजय साजरा करूया, दिवाळीचा आनंद लुटूया!",
            ],
            "hi": [
                "बुराई पर अच्छाई की जीत का यह पर्व आपके जीवन से हर अंधकार दूर करे।",
                "दीपों की रोशनी आपके घर को खुशियों से जगमगा दे।",
                "आपका जीवन सदा स्वस्थ, सुंदर और प्रकाशमय रहे।",
            ],
            "en": [
                "May the light of this day remove every darkness from your life.",
                "Celebrate the victory of good over evil with joy and light.",
                "Wishing you a bright, healthy and joyful Choti Diwali.",
            ],
        },
        "scenes": [
            "Pre-dawn abhyanga snan setup: a brass bowl of fragrant ubtan, scented oil, a small copper pot and a lit diya on a wooden patla surrounded by rangoli, deep blue dawn sky through a window",
            "Rows of glowing clay diyas lining the steps of a traditional Indian home in early-morning darkness, faint dawn light on the horizon, colourful rangoli",
            "Golden sparklers and a glowing paper akash kandil lantern hanging on a balcony at dawn, lit diyas along the railing",
            "Ubtan bowl, scented oil and marigold flowers neatly arranged on a brass tray beside burning diyas, warm festive light",
        ],
    },
    "diwali": {
        "names": ("लक्ष्मीपूजन", "दीपावली", "Diwali"),
        "emoji": "🪔",
        "target": 18,
        "headings": {
            "mr": "शुभ दीपावली",
            "hi": "शुभ दीपावली",
            "en": "Happy Diwali",
        },
        "quotes": {
            "mr": [
                "दिव्यांच्या प्रकाशाने आपले आयुष्य उजळून निघो, लक्ष्मीची कृपा सदैव राहो.",
                "सुख, समृद्धी आणि आनंदाची ही दिवाळी आपल्या कुटुंबासाठी मंगलमय ठरो.",
                "फराळाचा गोडवा आणि दिव्यांचा प्रकाश आपल्या घरी सदैव राहो.",
            ],
            "hi": [
                "दीपों का यह पावन पर्व आपके जीवन में सुख, समृद्धि और खुशियाँ लाए।",
                "माँ लक्ष्मी की कृपा से आपका घर धन-धान्य से भरा रहे।",
                "रोशनी का यह त्योहार आपके परिवार के लिए मंगलमय हो।",
            ],
            "en": [
                "May the glow of diyas fill your home with joy, peace and prosperity.",
                "Wishing you and your family a sparkling and blessed Diwali.",
                "May Goddess Lakshmi shower endless blessings on your home.",
            ],
        },
        "scenes": [
            "Hundreds of glowing clay diyas arranged on a rangoli in front of a traditional Indian home at night, colourful akash kandil lanterns hanging overhead, magical warm bokeh",
            "A grand Lakshmi pooja setup with a brass kalash, pink lotus flowers, gold coins, sweets and many lit diyas on a red cloth, festive Diwali night glow",
            "A plate of Diwali faral sweets: ladoo, karanji, chakli, shankarpali and anarse on a brass thali surrounded by diyas and marigold flowers",
            "Night sky filled with colourful fireworks above a city skyline glowing with Diwali lights, lit diyas on a terrace in the foreground",
            "Close-up of an ornate brass diya flame with rose petals and a vibrant peacock rangoli, dreamy bokeh of fairy lights",
            "Paper akash kandil lanterns glowing orange and red hanging in a row outside a traditional Maharashtrian wada at night",
        ],
    },
    "diwali_padwa": {
        "names": ("दिवाळी पाडवा", "गोवर्धन पूजा", "Diwali Padwa"),
        "emoji": "🌼",
        "target": 12,
        "headings": {
            "mr": "दिवाळी पाडव्याच्या हार्दिक शुभेच्छा",
            "hi": "गोवर्धन पूजा की हार्दिक शुभकामनाएं",
            "en": "Happy Diwali Padwa",
        },
        "quotes": {
            "mr": [
                "दिवाळी पाडव्याच्या शुभदिनी आपले नाते अधिक घट्ट आणि प्रेमळ होवो.",
                "नवीन वर्ष आपल्याला यश, आरोग्य आणि समृद्धी घेऊन येवो.",
                "बलिप्रतिपदेच्या मंगल दिनी आपल्या घरी सुखाचा वर्षाव होवो.",
            ],
            "hi": [
                "गोवर्धन पूजा पर श्रीकृष्ण आपके परिवार की सदा रक्षा करें।",
                "नया वर्ष आपके लिए सफलता, स्वास्थ्य और समृद्धि लेकर आए।",
                "इस पावन दिन आपके जीवन में प्रेम और खुशियाँ बढ़ती रहें।",
            ],
            "en": [
                "May this Padwa bring love, togetherness and new beginnings.",
                "Wishing you a prosperous new year full of success and health.",
                "May Lord Krishna bless your family on this Govardhan Puja.",
            ],
        },
        "scenes": [
            "A traditional doorway decorated with mango-leaf and marigold toran, a rangoli and glowing diyas, soft morning sunlight, festive atmosphere",
            "An aarti thali with a lit diya, kumkum, rice and flowers on a red cloth, gold jewellery and folded new silk clothes beside it, warm festive glow",
            "A small decorated hill made of flowers and green leaves with miniature diyas around it symbolising Govardhan pooja, warm golden light",
            "A sweets box, gold coins and a lit diya on a wooden table with marigold flowers, celebration of a new beginning",
        ],
    },
    "bhaubij": {
        "names": ("भाऊबीज", "भाई दूज", "Bhai Dooj"),
        "emoji": "🙏",
        "target": 12,
        "headings": {
            "mr": "भाऊबीजेच्या हार्दिक शुभेच्छा",
            "hi": "भाई दूज की हार्दिक शुभकामनाएं",
            "en": "Happy Bhai Dooj",
        },
        "quotes": {
            "mr": [
                "बहिणीची माया आणि भावाचे प्रेम असेच कायम राहो.",
                "औक्षणाच्या ताटातील दिव्यासारखे आपले नाते सदैव उजळत राहो.",
                "भावा-बहिणीच्या पवित्र नात्याला उदंड आयुष्य लाभो.",
            ],
            "hi": [
                "भाई-बहन का यह पवित्र रिश्ता सदा प्रेम और विश्वास से भरा रहे।",
                "तिलक की लाली और दीपों की रोशनी आपके जीवन को खुशियों से भर दे।",
                "भाई दूज पर आपके रिश्ते में सदा मिठास बनी रहे।",
            ],
            "en": [
                "May the bond between brother and sister grow stronger every year.",
                "Wishing you love, laughter and lifelong togetherness this Bhai Dooj.",
                "A sister's prayer and a brother's promise, may this bond shine forever.",
            ],
        },
        "scenes": [
            "An ornate brass aarti thali with a lit diya, kumkum tilak, rice grains, a coconut and sweets on a red silk cloth, festive evening bokeh",
            "Gift boxes wrapped in shimmering golden paper beside a decorated aarti plate, diyas and marigold petals, warm celebration mood",
            "A hand-drawn rangoli with a diya in the centre, pedha and kaju katli sweets on a silver plate next to it, cosy festive lights",
            "A traditional wooden patla with rangoli around it, an aarti thali and diyas ready for the Bhaubij ceremony, warm golden light",
        ],
    },
    "kartiki_ekadashi": {
        "names": ("कार्तिकी एकादशी", "देवउठनी एकादशी", "Kartiki Ekadashi"),
        "emoji": "🚩",
        "target": 9,
        "headings": {
            "mr": "कार्तिकी एकादशीच्या हार्दिक शुभेच्छा",
            "hi": "देवउठनी एकादशी की शुभकामनाएं",
            "en": "Happy Kartiki Ekadashi",
        },
        "quotes": {
            "mr": [
                "विठुरायाच्या कृपेने आपले जीवन भक्ती, आनंद आणि समाधानाने भरून जावो.",
                "पंढरीच्या पांडुरंगाचे आशीर्वाद सदैव आपल्या पाठीशी राहोत.",
                "राम कृष्ण हरी! आपल्या घरी सुख आणि शांती नांदो.",
            ],
            "hi": [
                "भगवान विष्णु के जागरण के इस पावन दिन आपका जीवन मंगलमय हो।",
                "श्रीहरि की कृपा से आपके घर में सुख और शांति बनी रहे।",
                "देवउठनी एकादशी पर आपके सभी शुभ कार्य सफल हों।",
            ],
            "en": [
                "May Lord Vitthal bless your life with devotion, peace and joy.",
                "May the grace of Shri Hari always guide your path.",
                "Wishing you a blessed and peaceful Ekadashi.",
            ],
        },
        "scenes": [
            "An ancient stone temple spire at dawn above a calm river with saffron flags fluttering and glowing diyas floating on the water",
            "A tulsi garland, brass cymbals, a saffron flag and a lit diya on a wooden plank by a riverside temple at sunrise, devotional mood",
            "A decorated wooden palkhi with marigold flowers and saffron flags in a temple courtyard in soft morning light",
        ],
    },
    "tulsi_vivah": {
        "names": ("तुळशी विवाह", "तुलसी विवाह", "Tulsi Vivah"),
        "emoji": "🌿",
        "target": 9,
        "headings": {
            "mr": "तुळशी विवाहाच्या हार्दिक शुभेच्छा",
            "hi": "तुलसी विवाह की हार्दिक शुभकामनाएं",
            "en": "Happy Tulsi Vivah",
        },
        "quotes": {
            "mr": [
                "तुळशीमातेच्या आशीर्वादाने आपल्या घरी सुख, शांती आणि आरोग्य नांदो.",
                "तुळशी विवाहाच्या मंगल प्रसंगी आपल्या आयुष्यात आनंदाचे सूर उमटोत.",
                "अंगणातील तुळस जशी पवित्र, तसेच आपले जीवन मंगलमय होवो.",
            ],
            "hi": [
                "तुलसी माता के आशीर्वाद से आपके घर में सदा सुख-शांति बनी रहे।",
                "तुलसी विवाह का यह पावन पर्व आपके जीवन में मंगल लाए।",
                "आपके आँगन की तुलसी सदा हरी-भरी और आपका जीवन खुशहाल रहे।",
            ],
            "en": [
                "May Tulsi Mata bless your home with peace, health and harmony.",
                "Wishing you a joyful and auspicious Tulsi Vivah.",
                "May this sacred union bring blessings and new beginnings to your family.",
            ],
        },
        "scenes": [
            "A beautifully decorated tulsi vrindavan with sugarcane stalks forming a mandap, marigold garlands, a small red chunari, glowing diyas and rangoli in the evening",
            "A tulsi plant in a painted vrindavan adorned with bangles, flowers and haldi-kumkum, brass lamps around it, festive twilight",
            "A wedding-style mandap made of sugarcane around a tulsi plant with amla, flowers and diyas, warm evening glow",
        ],
    },
    "tripuri_purnima": {
        "names": ("त्रिपुरारी पौर्णिमा", "देव दीपावली", "Dev Deepawali"),
        "emoji": "🌕",
        "target": 9,
        "headings": {
            "mr": "त्रिपुरारी पौर्णिमेच्या शुभेच्छा",
            "hi": "देव दीपावली की हार्दिक शुभकामनाएं",
            "en": "Happy Dev Deepawali",
        },
        "quotes": {
            "mr": [
                "त्रिपुरारी पौर्णिमेचे दीप आपल्या आयुष्यातील अंधार दूर करोत.",
                "महादेवाच्या कृपेने आपले जीवन प्रकाशमय आणि मंगलमय होवो.",
                "दीपमाळेसारखे आपले आयुष्य सदैव उजळत राहो.",
            ],
            "hi": [
                "देव दीपावली के दीप आपके जीवन को सदा रोशन रखें।",
                "भगवान शिव की कृपा से आपका जीवन मंगलमय हो।",
                "कार्तिक पूर्णिमा का यह पावन पर्व आपके लिए शुभ हो।",
            ],
            "en": [
                "May the lamps of Dev Deepawali light up your life with blessings.",
                "May Lord Shiva fill your life with light and peace.",
                "Wishing you a blessed and radiant Kartik Purnima.",
            ],
        },
        "scenes": [
            "Thousands of diyas glowing on the steps of a river ghat under a bright full moon, reflections shimmering on the water",
            "A tall stone deepmal lamp tower in front of an old temple lit with hundreds of oil lamps under a full moon",
            "Floating diyas drifting on a calm river under a giant full moon, temple silhouette in the background",
        ],
    },
}


def _today_ist() -> date:
    return datetime.now(IST).date()


def _occurrence(slug: str, today: date) -> Optional[date]:
    """Next date of the festival that is still visible today, if any."""
    for d in sorted(FESTIVAL_DATES.get(slug, [])):
        if d + timedelta(days=VISIBLE_AFTER_DAYS) >= today:
            return d
    return None


def build_festival_prompt(scene: str) -> str:
    return (
        "Magnificent vertical 9:16 Indian festival greeting card background. "
        "Photorealistic 8k quality, rich warm festive lighting from glowing diyas, soft dreamy bokeh. "
        f"{scene}. "
        "Elegant composition with calm uncluttered space in the upper and lower thirds, "
        "vibrant yet graceful traditional colours, hyper-detailed textures, "
        "no people, no faces, no text, no letters, no watermark."
    )


def _card_theme(slug: str, lang: str, index: int) -> Dict[str, Any]:
    """Card #index of a festival in one language. Every third card is title-only."""
    fest = FESTIVALS[slug]
    quotes = fest["quotes"][lang]
    return {
        "theme": f"{slug} #{index + 1}",
        "scene": fest["scenes"][index % len(fest["scenes"])],
        "heading": fest["headings"][lang],
        "quote": "" if index % 3 == 2 else quotes[index % len(quotes)],
        "layout_style": LAYOUTS[index % len(LAYOUTS)],
        "text_overlay": True,
    }


async def _lang_counts(db: aiosqlite.Connection, slug: str) -> Dict[str, int]:
    counts = {lang: 0 for lang in LANGS}
    async with db.execute(
        """SELECT gi.lang, COUNT(*) FROM greeting_images gi
           JOIN greeting_categories c ON c.id = gi.category_id
           WHERE c.slug = ? GROUP BY gi.lang""",
        (slug,),
    ) as cur:
        for lang, n in await cur.fetchall():
            if lang in counts:
                counts[lang] = n
    return counts


async def sync_festival_categories() -> None:
    """Creates missing festival categories, pins visible ones to the top
    (soonest first) and hides finished or still-empty ones."""
    today = _today_ist()
    async with aiosqlite.connect(DB_PATH) as db:
        for slug, fest in FESTIVALS.items():
            mr, hi, en = fest["names"]
            await db.execute(
                """INSERT OR IGNORE INTO greeting_categories
                   (slug, name_mr, name_hi, name_en, emoji, sort_order, active, created_at)
                   VALUES (?, ?, ?, ?, ?, 0, 0, ?)""",
                (slug, mr, hi, en, fest["emoji"], utc_now_iso()),
            )
            occurrence = _occurrence(slug, today)
            counts = await _lang_counts(db, slug)
            visible = occurrence is not None and sum(counts.values()) > 0
            sort_order = -1000 + (occurrence - today).days if occurrence else 0
            await db.execute(
                "UPDATE greeting_categories SET active = ?, sort_order = ? WHERE slug = ?",
                (int(visible), sort_order, slug),
            )
        await db.commit()


async def _plan(budget: int) -> List[Tuple[str, str, int]]:
    """(festival, lang, card index) to generate, soonest festival first,
    alternating languages so each festival fills evenly."""
    today = _today_ist()
    upcoming = sorted(
        (occ, slug)
        for slug in FESTIVALS
        if (occ := _occurrence(slug, today)) and occ >= today
        and (occ - today).days <= GENERATION_WINDOW_DAYS
    )
    plan: List[Tuple[str, str, int]] = []
    async with aiosqlite.connect(DB_PATH) as db:
        for _, slug in upcoming:
            per_lang = FESTIVALS[slug]["target"] // len(LANGS)
            counts = await _lang_counts(db, slug)
            while len(plan) < budget:
                lang = min(LANGS, key=lambda l: counts[l])
                if counts[lang] >= per_lang:
                    break
                plan.append((slug, lang, counts[lang]))
                counts[lang] += 1
            if len(plan) >= budget:
                break
    return plan


async def run_festival_greetings_pipeline(
    budget: Optional[int] = None,
    is_manual_trigger: bool = False,
) -> Dict[str, Any]:
    """Generates up to `budget` festival cards for the upcoming festivals."""
    budget = budget or int(os.getenv("FESTIVAL_DAILY_BUDGET", "24"))
    if _generator_lock.locked():
        return {"status": "skipped", "message": "A greeting generation job is already running."}

    async with _generator_lock:
        await sync_festival_categories()
        plan = await _plan(budget)
        if not plan:
            msg = "No upcoming festival needs images."
            logger.info(msg)
            return {"status": "idle", "message": msg}

        run_id = await start_job_run("festival_greetings_generation")
        _last_job_status.update(running=True, last_run=utc_now_iso(), errors=[])
        success, failed, details = 0, 0, []

        for i, (slug, lang, index) in enumerate(plan, start=1):
            theme = _card_theme(slug, lang, index)
            progress = f"[{i}/{len(plan)}] {slug} {lang.upper()} #{index + 1} [{theme['layout_style']}]"
            _last_job_status["current_progress"] = progress
            await update_job_run_detail(run_id, progress)
            try:
                raw = await generate_single_greeting_image(
                    build_festival_prompt(theme["scene"]), theme=theme, lang=lang
                )
                img_id = await _save_greeting_to_db(raw, lang=lang, category_slug=slug)
                success += 1
                details.append(f"✓ {slug} {lang} #{img_id}")
            except Exception as e:
                failed += 1
                err = f"✗ {slug} {lang}: {e}"
                logger.error(err)
                _last_job_status["errors"].append(err)
                details.append(err)
            if i < len(plan):
                await asyncio.sleep(4)

        await sync_festival_categories()
        summary = f"Festival cards: {success} generated, {failed} failed out of {len(plan)}."
        status = "success" if failed == 0 else ("partial" if success else "failed")
        _last_job_status.update(running=False, current_progress=summary)
        _last_job_status["total_generated"] += success
        if success:
            _last_job_status["last_success"] = utc_now_iso()
        await finish_job_run(run_id, status, summary)
        await log_admin_action(
            "festival_greetings_auto_generated",
            f"Trigger: {'manual' if is_manual_trigger else 'cron_midnight'}, {summary}",
        )
        logger.info(summary)
        return {"status": status, "success": success, "failed": failed, "total": len(plan), "details": details}


async def festival_status() -> List[Dict[str, Any]]:
    today = _today_ist()
    out = []
    async with aiosqlite.connect(DB_PATH) as db:
        for slug, fest in FESTIVALS.items():
            occ = _occurrence(slug, today)
            counts = await _lang_counts(db, slug)
            out.append({
                "slug": slug,
                "name": fest["names"][2],
                "date": occ.isoformat() if occ else None,
                "target": fest["target"],
                "counts": counts,
            })
    return out
