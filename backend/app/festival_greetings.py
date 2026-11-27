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
# Annual festivals appear once generated within the window; recurring monthly vrats
# appear a few days before their date so they don't stay pinned all month.
RECURRING_VISIBLE_BEFORE_DAYS = 3
# Category stays visible through the day after the festival.
VISIBLE_AFTER_DAYS = 1

RECURRING_VRATS = frozenset({
    "ekadashi",
    "sankashti_chaturthi",
    "vinayaki_chaturthi",
    "masik_shivaratri",
})

FESTIVAL_DATES: Dict[str, List[date]] = {
    "vasubaras": [date(2026, 11, 5), date(2027, 10, 26), date(2028, 10, 15), date(2029, 11, 3), date(2030, 10, 23)],
    "dhanteras": [date(2026, 11, 6), date(2027, 10, 27), date(2028, 10, 16), date(2029, 11, 4), date(2030, 10, 24)],
    "narak_chaturdashi": [date(2026, 11, 8), date(2027, 10, 28), date(2028, 10, 17), date(2029, 11, 5), date(2030, 10, 25)],
    "diwali": [date(2026, 11, 8), date(2027, 10, 29), date(2028, 10, 17), date(2029, 11, 5), date(2030, 10, 26)],
    "diwali_padwa": [date(2026, 11, 10), date(2027, 10, 30), date(2028, 10, 18), date(2029, 11, 6), date(2030, 10, 27)],
    "bhaubij": [date(2026, 11, 11), date(2027, 10, 31), date(2028, 10, 19), date(2029, 11, 7), date(2030, 10, 28)],
    "kartiki_ekadashi": [date(2026, 11, 20), date(2027, 11, 10), date(2028, 10, 28), date(2029, 11, 16), date(2030, 11, 5)],
    "tulsi_vivah": [date(2026, 11, 21), date(2027, 11, 10), date(2028, 10, 29), date(2029, 11, 17), date(2030, 11, 6)],
    "tripuri_purnima": [date(2026, 11, 24), date(2027, 11, 13), date(2028, 11, 1), date(2029, 11, 20), date(2030, 11, 9)],
    "gita_jayanti": [date(2026, 12, 20), date(2027, 12, 9), date(2028, 11, 27), date(2029, 12, 16), date(2030, 12, 5)],
    "datta_jayanti": [date(2026, 12, 23), date(2027, 12, 13), date(2028, 12, 1), date(2029, 12, 20), date(2030, 12, 9)],
    "makar_sankranti": [date(2027, 1, 15), date(2028, 1, 15), date(2029, 1, 14), date(2030, 1, 15)],
    "maghi_ganesh_jayanti": [date(2027, 2, 10), date(2028, 1, 30), date(2029, 1, 18), date(2030, 2, 6)],
    "vasant_panchami": [date(2027, 2, 11), date(2028, 1, 31), date(2029, 1, 19), date(2030, 2, 7)],
    "ratha_saptami": [date(2027, 2, 13), date(2028, 2, 3), date(2029, 1, 22), date(2030, 2, 9)],
    "maha_shivaratri": [date(2027, 3, 6), date(2028, 2, 23), date(2029, 2, 11), date(2030, 3, 2)],
    "holi": [date(2027, 3, 22), date(2028, 3, 11), date(2029, 2, 28), date(2030, 3, 19)],
    "gudi_padwa": [date(2027, 4, 7), date(2028, 3, 27), date(2029, 4, 14), date(2030, 4, 3)],
    "ram_navami": [date(2027, 4, 15), date(2028, 4, 3), date(2029, 4, 23), date(2030, 4, 12)],
    "hanuman_jayanti": [date(2027, 4, 20), date(2028, 4, 9), date(2029, 4, 28), date(2030, 4, 18)],
    "akshaya_tritiya": [date(2027, 5, 8), date(2028, 4, 27), date(2029, 5, 16), date(2030, 5, 5)],
    "nirjala_ekadashi": [date(2027, 6, 14), date(2028, 6, 3), date(2029, 6, 22), date(2030, 6, 12)],
    "vat_purnima": [date(2027, 6, 19), date(2028, 6, 7), date(2029, 6, 26), date(2030, 6, 15)],
    "ashadhi_ekadashi": [date(2027, 7, 14), date(2028, 7, 2), date(2029, 7, 21), date(2030, 7, 11)],
    "guru_purnima": [date(2027, 7, 18), date(2028, 7, 6), date(2029, 7, 25), date(2030, 7, 15)],
    "nag_panchami": [date(2027, 8, 6), date(2028, 7, 26), date(2029, 8, 14), date(2030, 8, 4)],
    "raksha_bandhan": [date(2027, 8, 17), date(2028, 8, 5), date(2029, 8, 24), date(2030, 8, 13)],
    "krishna_janmashtami": [date(2027, 8, 24), date(2028, 8, 13), date(2029, 8, 31), date(2030, 8, 20)],
    "hartalika": [date(2027, 9, 3), date(2028, 8, 22), date(2029, 9, 10), date(2030, 8, 31)],
    "ganesh_chaturthi": [date(2027, 9, 4), date(2028, 8, 23), date(2029, 9, 11), date(2030, 9, 1)],
    "anant_chaturdashi": [date(2027, 9, 14), date(2028, 9, 2), date(2029, 9, 21), date(2030, 9, 10)],
    "sharad_navratri": [date(2027, 9, 30), date(2028, 9, 19), date(2029, 10, 8), date(2030, 9, 28)],
    "vijayadashami": [date(2027, 10, 10), date(2028, 9, 28), date(2029, 10, 16), date(2030, 10, 6)],
    "kojagiri_purnima": [date(2027, 10, 14), date(2028, 10, 2), date(2029, 10, 21), date(2030, 10, 10)],
    "karva_chauth": [date(2027, 10, 19), date(2028, 10, 7), date(2029, 10, 26), date(2030, 10, 15)],
    # Monthly recurring Panchang observances (excluding Amavasya & Pradosh Vrat)
    "ekadashi": [
        date(2026, 12, 4), date(2026, 12, 20),
        date(2027, 1, 3), date(2027, 1, 19), date(2027, 2, 2), date(2027, 2, 17),
        date(2027, 3, 4), date(2027, 3, 18), date(2027, 4, 2), date(2027, 4, 17),
        date(2027, 5, 2), date(2027, 5, 16), date(2027, 6, 1), date(2027, 6, 30),
        date(2027, 7, 29), date(2027, 8, 12), date(2027, 8, 28), date(2027, 9, 11),
        date(2027, 9, 26), date(2027, 10, 11), date(2027, 10, 25), date(2027, 11, 24),
        date(2027, 12, 9), date(2027, 12, 23),
        date(2028, 1, 8), date(2028, 1, 22), date(2028, 2, 7), date(2028, 2, 20),
        date(2028, 3, 7), date(2028, 3, 21), date(2028, 4, 20), date(2028, 5, 5),
        date(2028, 5, 20), date(2028, 6, 18), date(2028, 7, 18), date(2028, 8, 1),
        date(2028, 8, 16), date(2028, 8, 30), date(2028, 9, 15), date(2028, 9, 29),
        date(2028, 10, 14), date(2028, 11, 13), date(2028, 11, 27), date(2028, 12, 12),
        date(2028, 12, 27),
        date(2029, 1, 10), date(2029, 1, 26), date(2029, 2, 9), date(2029, 2, 25),
        date(2029, 3, 10), date(2029, 3, 26), date(2029, 4, 9), date(2029, 4, 25),
        date(2029, 5, 9), date(2029, 5, 24), date(2029, 6, 7), date(2029, 7, 7),
        date(2029, 8, 6), date(2029, 8, 20), date(2029, 9, 4), date(2029, 9, 18),
        date(2029, 10, 4), date(2029, 10, 18), date(2029, 11, 2), date(2029, 12, 2),
        date(2029, 12, 16), date(2029, 12, 31),
        date(2030, 1, 15), date(2030, 1, 29), date(2030, 2, 14), date(2030, 2, 28),
        date(2030, 3, 15), date(2030, 3, 29), date(2030, 4, 14), date(2030, 4, 28),
        date(2030, 5, 14), date(2030, 5, 27), date(2030, 6, 26), date(2030, 7, 26),
        date(2030, 8, 9), date(2030, 8, 24), date(2030, 9, 8), date(2030, 9, 23),
        date(2030, 10, 7), date(2030, 10, 23), date(2030, 11, 21), date(2030, 12, 5),
        date(2030, 12, 21),
    ],
    "masik_shivaratri": [
        date(2026, 12, 7),
        date(2027, 1, 6), date(2027, 2, 5), date(2027, 3, 7), date(2027, 4, 5),
        date(2027, 5, 5), date(2027, 7, 3), date(2027, 8, 1), date(2027, 8, 30),
        date(2027, 9, 29), date(2027, 10, 28), date(2027, 11, 27), date(2027, 12, 26),
        date(2028, 1, 25), date(2028, 2, 24), date(2028, 3, 25), date(2028, 4, 23),
        date(2028, 5, 23), date(2028, 6, 21), date(2028, 7, 21), date(2028, 8, 19),
        date(2028, 10, 17), date(2028, 11, 15), date(2028, 12, 15),
        date(2029, 1, 13), date(2029, 2, 12), date(2029, 3, 14), date(2029, 4, 12),
        date(2029, 5, 12), date(2029, 6, 11), date(2029, 7, 10), date(2029, 8, 9),
        date(2029, 9, 7), date(2029, 11, 5), date(2029, 12, 4),
        date(2030, 1, 3), date(2030, 2, 1), date(2030, 3, 3), date(2030, 4, 1),
        date(2030, 5, 1), date(2030, 5, 31), date(2030, 6, 29), date(2030, 7, 29),
        date(2030, 8, 27), date(2030, 9, 26), date(2030, 11, 24), date(2030, 12, 23),
    ],
    "vinayaki_chaturthi": [
        date(2026, 12, 13),
        date(2027, 1, 12), date(2027, 2, 10), date(2027, 3, 12), date(2027, 4, 10),
        date(2027, 5, 10), date(2027, 6, 8), date(2027, 7, 7), date(2027, 8, 5),
        date(2027, 9, 4), date(2027, 10, 3), date(2027, 11, 2), date(2027, 12, 2),
        date(2028, 1, 1), date(2028, 1, 31), date(2028, 2, 29), date(2028, 3, 30),
        date(2028, 4, 28), date(2028, 5, 28), date(2028, 6, 26), date(2028, 7, 25),
        date(2028, 8, 23), date(2028, 9, 22), date(2028, 10, 21), date(2028, 11, 20),
        date(2028, 12, 20),
        date(2029, 1, 18), date(2029, 2, 17), date(2029, 3, 19), date(2029, 4, 18),
        date(2029, 5, 17), date(2029, 6, 16), date(2029, 7, 15), date(2029, 8, 13),
        date(2029, 9, 11), date(2029, 10, 11), date(2029, 11, 9), date(2029, 12, 9),
        date(2030, 1, 7), date(2030, 2, 6), date(2030, 3, 8), date(2030, 4, 7),
        date(2030, 5, 6), date(2030, 6, 5), date(2030, 7, 5), date(2030, 8, 3),
        date(2030, 9, 1), date(2030, 10, 30), date(2030, 11, 28), date(2030, 12, 28),
    ],
    "sankashti_chaturthi": [
        date(2026, 11, 27), date(2026, 12, 27),
        date(2027, 1, 25), date(2027, 2, 24), date(2027, 3, 26), date(2027, 4, 24),
        date(2027, 5, 24), date(2027, 6, 23), date(2027, 7, 23), date(2027, 8, 21),
        date(2027, 9, 20), date(2027, 10, 19), date(2027, 11, 17), date(2027, 12, 17),
        date(2028, 1, 15), date(2028, 3, 14), date(2028, 4, 13), date(2028, 5, 12),
        date(2028, 6, 11), date(2028, 7, 11), date(2028, 8, 9), date(2028, 9, 8),
        date(2028, 10, 7), date(2028, 11, 6), date(2028, 12, 5),
        date(2029, 1, 4), date(2029, 2, 2), date(2029, 3, 4), date(2029, 4, 2),
        date(2029, 5, 31), date(2029, 6, 29), date(2029, 7, 29), date(2029, 8, 28),
        date(2029, 9, 27), date(2029, 10, 26), date(2029, 11, 25), date(2029, 12, 24),
        date(2030, 1, 23), date(2030, 2, 21), date(2030, 3, 23), date(2030, 4, 21),
        date(2030, 6, 19), date(2030, 7, 18), date(2030, 8, 17), date(2030, 9, 15),
        date(2030, 10, 15), date(2030, 11, 14), date(2030, 12, 14),
    ],
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
    "gita_jayanti": {
        "names": ("गीता जयंती", "गीता जयंती", "Gita Jayanti"),
        "emoji": "📖",
        "target": 9,
        "headings": {
            "mr": "गीता जयंतीच्या हार्दिक शुभेच्छा",
            "hi": "गीता जयंती की हार्दिक शुभकामनाएं",
            "en": "Happy Gita Jayanti",
        },
        "quotes": {
            "mr": [
                "भगवद्गीतेतील ज्ञान आपल्या जीवनाला योग्य दिशा, शांती आणि बळ देवो.",
                "कर्म करत राहा, फळाची चिंता सोडा — श्रीकृष्णाचे हे वचन सदैव प्रेरणा देवो.",
                "गीतेच्या पवित्र विचारांनी आपले मन आणि घर उजळून निघो.",
            ],
            "hi": [
                "श्रीमद्भगवद्गीता का दिव्य ज्ञान आपके जीवन को सही दिशा और शांति प्रदान करे।",
                "कर्मयोग और भक्ति के मार्ग पर भगवान श्रीकृष्ण की कृपा सदा बनी रहे।",
                "गीता के पावन उपदेश आपके जीवन में प्रकाश और उत्साह भर दें।",
            ],
            "en": [
                "May the timeless wisdom of the Bhagavad Gita illuminate your path with peace and clarity.",
                "Walk the path of dharma and devotion with Lord Krishna's grace.",
                "Wishing you a blessed and inspiring Gita Jayanti.",
            ],
        },
        "scenes": [
            "An open sacred Sanskrit scripture resting on a carved wooden book stand beside a radiant peacock feather, bamboo flute and glowing brass diya on saffron silk, soft golden light",
            "A brass oil lamp illuminating an ancient palm-leaf manuscript with yellow marigold petals and tulsi leaves, serene devotional glow",
            "A peaceful temple courtyard at dawn with a wooden stand holding a sacred book, peacock feather and softly glowing diyas",
        ],
    },
    "datta_jayanti": {
        "names": ("श्री दत्त जयंती", "दत्तात्रेय जयंती", "Datta Jayanti"),
        "emoji": "🔱",
        "target": 12,
        "headings": {
            "mr": "श्री दत्त जयंतीच्या हार्दिक शुभेच्छा",
            "hi": "दत्तात्रेय जयंती की हार्दिक शुभकामनाएं",
            "en": "Happy Datta Jayanti",
        },
        "quotes": {
            "mr": [
                "दिगंबरा दिगंबरा श्रीपाद वल्लभ दिगंबरा! श्री गुरुदेवांची कृपा सदैव राहो.",
                "श्री दत्तगुरूंच्या आशीर्वादाने आपल्या घरी सुख, शांती आणि समृद्धी नांदो.",
                "अवधूत चिंतन श्री गुरुदेव दत्त! आपले जीवन भक्तीने पावन होवो.",
            ],
            "hi": [
                "भगवान दत्तात्रेय की असीम कृपा से आपका जीवन सुख, शांति और ज्ञान से भर जाए।",
                "श्री गुरुदेव दत्त के आशीर्वाद से आपके सभी संकट दूर हों।",
                "दत्तात्रेय जयंती के पावन पर्व पर भक्ति और आनंद की मंगल कामना।",
            ],
            "en": [
                "May Lord Dattatreya bless your home with wisdom, peace and divine protection.",
                "Seeking the grace of Shri Gurudev Datta on this sacred Datta Jayanti.",
                "May the blessings of Audumbar and Guru Datta guide your every step.",
            ],
        },
        "scenes": [
            "A sacred Audumbar tree in a peaceful temple courtyard lit with brass oil lamps under a glowing full moon, saffron flags and marigold garlands, serene twilight",
            "Holy paduka footprints adorned with yellow champa and marigold flowers on a stone pedestal beside a glowing brass diya and incense smoke",
            "A tranquil riverside temple of Maharashtra illuminated with diyas under a bright Margashirsha full moon, warm devotional glow",
        ],
    },
    "makar_sankranti": {
        "names": ("मकर संक्रांती", "मकर संक्रांति", "Makar Sankranti"),
        "emoji": "🪁",
        "target": 12,
        "headings": {
            "mr": "मकर संक्रांतीच्या हार्दिक शुभेच्छा",
            "hi": "मकर संक्रांति की हार्दिक शुभकामनाएं",
            "en": "Happy Makar Sankranti",
        },
        "quotes": {
            "mr": [
                "तिळगूळ घ्या आणि गोड गोड बोला! आपल्या आयुष्यात नात्यांचा गोडवा कायम राहो.",
                "सूर्याच्या उत्तरायण प्रवासाप्रमाणे आपले जीवनही प्रगतीच्या शिखरावर जावो.",
                "मकर संक्रांतीचा हा सण आपल्या घरी सुख, आरोग्य आणि आनंद घेऊन येवो.",
            ],
            "hi": [
                "तिल-गुड़ की मिठास और पतंगों की उड़ान आपके जीवन में नई खुशियाँ लाए।",
                "सूर्यदेव के उत्तरायण के साथ आपके जीवन में सुख, समृद्धि और प्रकाश बढ़े।",
                "मकर संक्रांति का यह पावन पर्व आपके परिवार के लिए मंगलमय हो।",
            ],
            "en": [
                "May the warmth of the sun and sweetness of tilgul fill your life with joy.",
                "Wishing you new heights, good health and sweet moments this Makar Sankranti.",
                "May Uttarayan bring bright sunshine and prosperity to your home.",
            ],
        },
        "scenes": [
            "Colourful traditional paper kites soaring across a bright golden-blue winter sky over sunlit terraces, soft warm morning glow",
            "A gleaming brass bowl filled with golden sesame-jaggery tilgul laddoos and sugarcane stalks decorated with marigold flowers on a woven mat",
            "Traditional painted clay sugad pots adorned with haldi-kumkum, sugarcane, marigold blossoms and wheat ears in warm morning sunlight",
        ],
    },
    "maghi_ganesh_jayanti": {
        "names": ("माघी गणेश जयंती", "गणेश जयंती", "Ganesh Jayanti"),
        "emoji": "🌺",
        "target": 9,
        "headings": {
            "mr": "माघी गणेश जयंतीच्या शुभेच्छा",
            "hi": "गणेश जयंती की शुभकामनाएं",
            "en": "Happy Ganesh Jayanti",
        },
        "quotes": {
            "mr": [
                "वक्रतुंड महाकाय! गणरायाच्या कृपेने आपल्या सर्व कार्यांत यश लाभो.",
                "माघी गणेश जयंतीच्या पवित्र दिनी बाप्पाचा आशीर्वाद सदैव आपल्या पाठीशी राहो.",
                "गणपती बाप्पा मोरया! सुखकर्ता आणि दुःखहर्ता आपल्या घरी नांदो.",
            ],
            "hi": [
                "विघ्नहर्ता श्री गणेश आपके जीवन की सभी बाधाएं दूर कर सुख-समृद्धि प्रदान करें।",
                "गणेश जयंती के शुभ अवसर पर बप्पा की कृपा आप पर सदा बनी रहे।",
                "प्रथम पूज्य श्री गणेश आपके घर में मंगल और आनंद लाएं।",
            ],
            "en": [
                "May Lord Ganesha remove every obstacle and bless you with wisdom and joy.",
                "Wishing you a spiritually uplifting and auspicious Ganesh Jayanti.",
                "Ganpati Bappa Morya! May Bappa's grace shine upon your family.",
            ],
        },
        "scenes": [
            "Fresh red hibiscus flowers, green durva grass blades, modak sweets and a lit brass diya on a gleaming silver pooja thali in warm temple light",
            "An ornate brass temple bell surrounded by red hibiscus garlands, turmeric-kumkum and glowing oil lamps, peaceful festive ambiance",
            "A traditional plate of steamed ukadiche modak on a banana leaf with jasmine flowers and a lit diya, warm morning sunlight",
        ],
    },
    "vasant_panchami": {
        "names": ("वसंत पंचमी", "वसंत पंचमी", "Vasant Panchami"),
        "emoji": "🌼",
        "target": 9,
        "headings": {
            "mr": "वसंत पंचमीच्या हार्दिक शुभेच्छा",
            "hi": "वसंत पंचमी की हार्दिक शुभकामनाएं",
            "en": "Happy Vasant Panchami",
        },
        "quotes": {
            "mr": [
                "सरस्वती मातेच्या कृपेने आपल्या जीवनात ज्ञान, कला आणि आनंदाचा वसंत फुलो.",
                "वसंत पंचमीच्या शुभदिनी नवे विचार आणि नवचैतन्य आपल्या घरी येवो.",
                "या कुंदेंदु तुषारहार धवला... विद्या आणि विवेकाची ज्योत सदैव तेवत राहो.",
            ],
            "hi": [
                "माँ सरस्वती की कृपा से आपका जीवन ज्ञान, बुद्धि और संगीत की मधुरता से भर जाए।",
                "वसंत पंचमी का यह पर्व आपके जीवन में नई उमंग और हरियाली लेकर आए।",
                "ज्ञान और कला की देवी माँ शारदा आपको सदा सद्बुद्धि प्रदान करें।",
            ],
            "en": [
                "May Goddess Saraswati bless you with wisdom, creativity and eternal learning.",
                "Welcome the golden hues of spring with joy and positivity.",
                "Wishing you a bright and blessed Vasant Panchami.",
            ],
        },
        "scenes": [
            "A classic Indian veena resting gracefully beside golden yellow mustard blossoms, white jasmine flowers and a lit brass diya in soft morning sun",
            "Blooming yellow marigold and mustard fields under warm golden spring sunlight with delicate petals drifting in the breeze",
            "A brass plate with saffron sweets, yellow flowers, books and a glowing lamp, serene Saraswati puja aesthetic",
        ],
    },
    "ratha_saptami": {
        "names": ("रथसप्तमी", "रथ सप्तमी", "Ratha Saptami"),
        "emoji": "☀️",
        "target": 9,
        "headings": {
            "mr": "रथसप्तमीच्या हार्दिक शुभेच्छा",
            "hi": "रथ सप्तमी की हार्दिक शुभकामनाएं",
            "en": "Happy Ratha Saptami",
        },
        "quotes": {
            "mr": [
                "सूर्यनारायणाच्या तेजाप्रमाणे आपले जीवन आरोग्य, ऊर्जा आणि यशाने उजळून निघो.",
                "रथसप्तमीच्या पवित्र दिनी उत्तम आरोग्य आणि दीर्घायुष्य लाभो हीच प्रार्थना.",
                "प्रत्येक पहाट नव्या आशेचा किरण घेऊन येवो.",
            ],
            "hi": [
                "भगवान सूर्यदेव के तेज से आपका जीवन उत्तम स्वास्थ्य, ऊर्जा और सफलता से आलोकित हो।",
                "रथ सप्तमी के पावन पर्व पर सूर्यदेव की कृपा आप पर सदा बनी रहे।",
                "आदित्य हृदय से आपका मन शांत और जीवन प्रकाशमय रहे।",
            ],
            "en": [
                "May Lord Surya bless you with radiant health, vitality and success.",
                "Wishing you warmth, energy and light on this auspicious Ratha Saptami.",
                "May the golden rays of the sun brighten every corner of your life.",
            ],
        },
        "scenes": [
            "Golden sunrise rays streaming over a tranquil river as a copper kalash offers sacred arghya water catching the sparkling morning light",
            "An ancient carved stone sun-temple chariot wheel bathed in warm golden dawn light with marigold garlands",
            "A glowing copper surya-arghya pot with red hibiscus flowers and sandalwood paste on a sunlit stone terrace at sunrise",
        ],
    },
    "maha_shivaratri": {
        "names": ("महाशिवरात्री", "महाशिवरात्रि", "Maha Shivaratri"),
        "emoji": "🔱",
        "target": 15,
        "headings": {
            "mr": "महाशिवरात्रीच्या हार्दिक शुभेच्छा",
            "hi": "महाशिवरात्रि की हार्दिक शुभकामनाएं",
            "en": "Happy Maha Shivaratri",
        },
        "quotes": {
            "mr": [
                "हर हर महादेव! भोलेनाथाच्या कृपेने आपल्या जीवनातील सर्व संकटे दूर होवोत.",
                "ॐ नमः शिवाय! महादेवाचा आशीर्वाद आपले घर शांती आणि समृद्धीने भरून टाको.",
                "शिवभक्तीने मन पावन आणि जीवन मंगलमय होवो.",
            ],
            "hi": [
                "हर हर महादेव! भगवान शिव की कृपा से आपके जीवन में शांति, शक्ति और सुख का वास हो।",
                "ॐ नमः शिवाय! भोलेनाथ आपके सभी कष्ट हर लें और जीवन को मंगलमय बनाएं।",
                "महाशिवरात्रि की पावन रात्रि आपके लिए भक्ति और आध्यात्मिक आनंद लाए।",
            ],
            "en": [
                "Om Namah Shivaya! May Lord Shiva bless you with inner strength, peace and grace.",
                "Har Har Mahadev! Wishing you a spiritually blissful Maha Shivaratri.",
                "May Mahadev's divine light guide your family towards harmony and joy.",
            ],
        },
        "scenes": [
            "A sacred black stone Shivling adorned with fresh green bilva leaves, white datura flowers and sacred ash under soft temple lamp light and drifting incense",
            "A gleaming brass trishul and damaru beside glowing clay diyas in a Himalayan stone temple under a starry crescent-moon night sky",
            "Milk and water flowing gracefully over a flower-decked Shivling surrounded by marigold petals and warm flickering oil lamps",
            "An ancient stone Shiva temple silhouette against snow-capped mountains under a serene night sky with crescent moon",
        ],
    },
    "holi": {
        "names": ("होळी आणि धूलिवंदन", "होली", "Holi"),
        "emoji": "🎨",
        "target": 15,
        "headings": {
            "mr": "होळीच्या रंगीत शुभेच्छा",
            "hi": "होली की हार्दिक शुभकामनाएं",
            "en": "Happy Holi",
        },
        "quotes": {
            "mr": [
                "रंगांच्या या उत्सवात आपले आयुष्य सुख, प्रेम आणि आनंदाच्या रंगांनी रंगून जावो!",
                "वाईट विचारांचे दहन होवो आणि आयुष्यात सद्भावनेचे नवे रंग बहरोत.",
                "होळी आणि धूलिवंदनाच्या मनःपूर्वक शुभेच्छा!",
            ],
            "hi": [
                "रंगों का यह पावन त्योहार आपके जीवन में खुशियाँ, प्रेम और उमंग के नए रंग भर दे।",
                "गुलाल की महक और अपनों का प्यार आपकी होली को यादगार बना दे।",
                "बुरा न मानो होली है! आपके परिवार को रंगोत्सव की हार्दिक शुभकामनाएं।",
            ],
            "en": [
                "May the vibrant colours of Holi paint your life with joy, love and togetherness.",
                "Celebrate the festival of colours with a heart full of happiness and peace.",
                "Wishing you and your loved ones a safe, joyful and colourful Holi!",
            ],
        },
        "scenes": [
            "Ornate brass bowls overflowing with vibrant pink, yellow, saffron and turquoise gulal powder on a carved wooden table, sunlit festive sparkles",
            "Colourful gulal powder clouds swirling in golden morning sunbeams over brass pichkari and marigold flowers",
            "Traditional thandai glasses garnished with rose petals and pistachios beside vibrant bowls of organic gulal and sweets",
        ],
    },
    "gudi_padwa": {
        "names": ("गुढीपाडवा", "गुड़ी पड़वा", "Gudi Padwa"),
        "emoji": "🚩",
        "target": 12,
        "headings": {
            "mr": "गुढीपाडव्याच्या हार्दिक शुभेच्छा",
            "hi": "गुड़ी पड़वा की हार्दिक शुभकामनाएं",
            "en": "Happy Gudi Padwa",
        },
        "quotes": {
            "mr": [
                "चैत्र नववर्षाच्या पहिल्या दिनी आरोग्याची, आनंदाची आणि समृद्धीची गुढी उभारूया!",
                "नूतन वर्ष आपल्यासाठी सुख, यश आणि भरभराट घेऊन येवो हीच सदिच्छा.",
                "कडुनिंबाचा कडवटपणा आणि गुळाचा गोडवा जपत नवीन वर्षाचे स्वागत करूया!",
            ],
            "hi": [
                "हिंदू नववर्ष गुड़ी पड़वा की हार्दिक शुभकामनाएं! नया वर्ष आपके लिए मंगलमय हो।",
                "चैत्र प्रतिपदा का यह पावन दिन आपके जीवन में सुख, शांति और समृद्धि लाए।",
                "नववर्ष की नई सुबह आपके परिवार के लिए खुशहाली लेकर आए।",
            ],
            "en": [
                "May this Hindu New Year bring health, prosperity and triumphant new beginnings.",
                "Raising the auspicious Gudi for peace, joy and abundance in your home.",
                "Wishing you a very happy and prosperous Gudi Padwa!",
            ],
        },
        "scenes": [
            "A tall traditional Maharashtrian Gudi draped in vibrant saffron and green silk cloth, topped with a gleaming inverted copper kalash, sugar-crystal gathi garland, neem and mango leaves on a sunlit balcony with rangoli",
            "An ornate doorway adorned with fresh mango-leaf toran, marigold garlands, vibrant rangoli and a raised festive Gudi in golden morning light",
            "A brass pooja thali with neem leaves, jaggery, kumkum and flowers beside a bright silk-draped Gudi, warm dawn glow",
        ],
    },
    "ram_navami": {
        "names": ("श्रीराम नवमी", "श्रीराम नवमी", "Ram Navami"),
        "emoji": "🏹",
        "target": 12,
        "headings": {
            "mr": "श्रीराम नवमीच्या हार्दिक शुभेच्छा",
            "hi": "श्रीराम नवमी की हार्दिक शुभकामनाएं",
            "en": "Happy Ram Navami",
        },
        "quotes": {
            "mr": [
                "प्रभू श्रीरामांच्या आदर्शांनी आपले जीवन सत्य, धर्म आणि आनंदाने परिपूर्ण होवो.",
                "जय श्रीराम! मर्यादा पुरुषोत्तम श्रीरामांचे आशीर्वाद सदैव आपल्या पाठीशी राहोत.",
                "रामनवमीच्या पवित्र दिनी घरात सुख, शांती आणि सद्भाव नांदो.",
            ],
            "hi": [
                "मर्यादा पुरुषोत्तम भगवान श्रीराम की कृपा से आपका जीवन सुख, धर्म और शांति से भर जाए।",
                "जय श्रीराम! राम नवमी का यह पावन पर्व आपके परिवार के लिए मंगलमय हो।",
                "प्रभु श्रीराम के आदर्श सदैव आपका मार्गदर्शन करें।",
            ],
            "en": [
                "May Lord Rama bless your home with righteousness, peace and eternal joy.",
                "Jai Shri Ram! Wishing you a blessed and auspicious Ram Navami.",
                "May the grace of Shri Ram guide you towards truth and harmony.",
            ],
        },
        "scenes": [
            "A sacred wooden cradle decorated with jasmine and marigold garlands, glowing brass lamps and rose petals in a sunlit temple sanctum",
            "A golden ceremonial bow and saffron flag fluttering over an ancient stone temple spire bathed in bright midday light",
            "A brass pooja thali with panjiri prasad, tulsi leaves, marigold flowers and lit diyas, warm devotional radiance",
        ],
    },
    "hanuman_jayanti": {
        "names": ("हनुमान जयंती", "हनुमान जयंती", "Hanuman Jayanti"),
        "emoji": "🚩",
        "target": 12,
        "headings": {
            "mr": "हनुमान जयंतीच्या हार्दिक शुभेच्छा",
            "hi": "हनुमान जयंती की हार्दिक शुभकामनाएं",
            "en": "Happy Hanuman Jayanti",
        },
        "quotes": {
            "mr": [
                "जय बजरंगबली! संकटमोचन मारुतीरायाच्या कृपेने आपल्याला बळ, बुद्धी आणि निर्भयता लाभो.",
                "पवनपुत्र हनुमानाचा आशीर्वाद सदैव आपल्या कुटुंबाचे रक्षण करो.",
                "हनुमान जयंतीच्या मंगल दिनी सर्व संकटे दूर होवोत!",
            ],
            "hi": [
                "संकटमोचन हनुमान जी की कृपा से आपको बल, बुद्धि और निर्भयता की प्राप्ति हो।",
                "जय बजरंगबली! पवनपुत्र आपके जीवन के सभी कष्ट और भय दूर करें।",
                "हनुमान जयंती के पावन अवसर पर भक्ति और शक्ति की मंगल कामना।",
            ],
            "en": [
                "May Lord Hanuman bless you with boundless courage, strength and devotion.",
                "Jai Bajrangbali! May Sankatmochan protect your family from all troubles.",
                "Wishing you a powerful and blessed Hanuman Jayanti.",
            ],
        },
        "scenes": [
            "An ornate golden-brass gada (mace) resting beside a garland of fresh orange calotropis (rui) flowers, sindoor bowl and glowing diyas in warm saffron light",
            "A fluttering saffron Hanuman flag atop a hilltop temple at golden sunrise, temple bells and warm morning rays",
            "A traditional brass thali with besan laddoos, orange marigold garlands, sindoor and a lit oil lamp, devotional atmosphere",
        ],
    },
    "akshaya_tritiya": {
        "names": ("अक्षय्य तृतीया", "अक्षय तृतीया", "Akshaya Tritiya"),
        "emoji": "🪙",
        "target": 9,
        "headings": {
            "mr": "अक्षय्य तृतीयेच्या हार्दिक शुभेच्छा",
            "hi": "अक्षय तृतीया की हार्दिक शुभकामनाएं",
            "en": "Happy Akshaya Tritiya",
        },
        "quotes": {
            "mr": [
                "अक्षय्य तृतीयेच्या शुभ मुहूर्तावर आपल्या घरी अक्षय सुख, समृद्धी आणि आरोग्य नांदो.",
                "आपले सर्व शुभ संकल्प आणि नवीन उपक्रम यशस्वी होवोत हीच प्रार्थना.",
                "सदैव अक्षय राहणारे सुख आणि समाधान आपल्या जीवनात येवो.",
            ],
            "hi": [
                "अक्षय तृतीया के पावन अवसर पर आपके घर में कभी न समाप्त होने वाला सुख और वैभव आए।",
                "माँ लक्ष्मी और भगवान विष्णु की कृपा से आपके सभी शुभ कार्य सफल हों।",
                "अक्षय तृतीया का यह अबूझ मुहूर्त आपके जीवन में नई खुशियां लाए।",
            ],
            "en": [
                "May this Akshaya Tritiya bring eternal prosperity, good fortune and joy to your home.",
                "Wishing endless blessings and success on every new beginning today.",
                "May Goddess Lakshmi shower lasting abundance upon your family.",
            ],
        },
        "scenes": [
            "A gleaming brass kalash topped with mango leaves and coconut, surrounded by gold coins, fresh jasmine flowers and lit diyas on red silk",
            "Earthen water pots adorned with mango blossoms, sandalwood paste and ripe golden mangoes in soft summer morning light",
            "Pink lotus blooms, gold ornaments and glowing clay lamps on an ornate brass pooja plate, rich warm glow",
        ],
    },
    "nirjala_ekadashi": {
        "names": ("निर्जला एकादशी", "निर्जला एकादशी", "Nirjala Ekadashi"),
        "emoji": "🙏",
        "target": 9,
        "headings": {
            "mr": "निर्जला एकादशीच्या शुभेच्छा",
            "hi": "निर्जला एकादशी की शुभकामनाएं",
            "en": "Happy Nirjala Ekadashi",
        },
        "quotes": {
            "mr": [
                "भगवान श्री विष्णूंच्या कृपेने आपले जीवन पवित्र, शांत आणि सुखमय होवो.",
                "संयम, भक्ती आणि सेवेचा हा पवित्र दिवस आपल्यासाठी मंगलमय ठरो.",
                "ॐ नमो भगवते वासुदेवाय!",
            ],
            "hi": [
                "ॐ नमो भगवते वासुदेवाय! श्रीहरि विष्णु की कृपा से आपका जीवन पावन और सुखमय हो।",
                "निर्जला एकादशी का पुण्य आपके परिवार में शांति और समृद्धि लाए।",
                "भक्ति और संयम का यह महापर्व आपके लिए मंगलमय हो।",
            ],
            "en": [
                "May Lord Vishnu bless your devotion with peace, purity and inner strength.",
                "Om Namo Bhagavate Vasudevaya! Wishing you a serene Nirjala Ekadashi.",
                "May the grace of Shri Hari fill your life with harmony.",
            ],
        },
        "scenes": [
            "A decorated earthen matka water pot with a hand-woven palm fan, tulsi leaves and glowing diya in a serene temple courtyard",
            "Yellow marigolds, sacred tulsi garland and brass shankh conch beside a glowing oil lamp on a wooden altar",
            "Calm river ghat at sunrise with floating diyas and temple bells, peaceful spiritual atmosphere",
        ],
    },
    "vat_purnima": {
        "names": ("वटपौर्णिमा", "वट पूर्णिमा", "Vat Purnima"),
        "emoji": "🌳",
        "target": 9,
        "headings": {
            "mr": "वटपौर्णिमेच्या हार्दिक शुभेच्छा",
            "hi": "वट पूर्णिमा की शुभकामनाएं",
            "en": "Happy Vat Purnima",
        },
        "quotes": {
            "mr": [
                "वडाच्या वृक्षाप्रमाणे आपल्या कुटुंबाचे नाते सदैव दृढ, हिरवेगार आणि दीर्घायुषी राहो.",
                "वटपौर्णिमेच्या पवित्र दिनी अखंड सौभाग्य, आरोग्य आणि आनंद लाभो.",
                "सात जन्माची साथ आणि प्रेमाचा धागा सदैव अतुट राहो!",
            ],
            "hi": [
                "वटवृक्ष की तरह आपका परिवार और रिश्ता सदा मजबूत, हरा-भरा और खुशहाल रहे।",
                "वट पूर्णिमा के पावन पर्व पर अखंड सौभाग्य और उत्तम स्वास्थ्य की शुभकामनाएं।",
                "प्रेम, विश्वास और समर्पण का यह पर्व आपके जीवन में सुख लाए।",
            ],
            "en": [
                "May your family bonds stand as strong and evergreen as the sacred banyan tree.",
                "Wishing you lifelong love, harmony and blessings on Vat Purnima.",
                "May this auspicious Purnima bring peace and happiness to your home.",
            ],
        },
        "scenes": [
            "An ancient sacred banyan tree wrapped with ceremonial white and saffron cotton threads, surrounded by glowing diyas, mango fruits and marigold garlands in soft morning sunlight",
            "A brass pooja thali with bangles, kumkum, flowers and a lit diya beneath overhanging banyan roots, serene golden light",
            "A tranquil village banyan shrine illuminated by soft dawn rays and blooming jasmine garlands",
        ],
    },
    "ashadhi_ekadashi": {
        "names": ("आषाढी एकादशी", "देवशयनी एकादशी", "Ashadhi Ekadashi"),
        "emoji": "🚩",
        "target": 12,
        "headings": {
            "mr": "आषाढी एकादशीच्या हार्दिक शुभेच्छा",
            "hi": "देवशयनी एकादशी की शुभकामनाएं",
            "en": "Happy Ashadhi Ekadashi",
        },
        "quotes": {
            "mr": [
                "विठुमाऊलीच्या कृपेने आपले जीवन भक्ती, आनंद आणि समाधानाने न्हाऊन निघो!",
                "माऊली माऊली! पांडुरंगाचा आशीर्वाद सदैव आपल्या कुटुंबावर राहो.",
                "पुंडलिक वरदा हरी विठ्ठल! आषाढी वारीचा भक्तिमय सोहळा मंगलमय होवो.",
            ],
            "hi": [
                "देवशयनी एकादशी पर भगवान विष्णु की असीम कृपा आपके परिवार पर बनी रहे।",
                "श्रीहरि के आशीर्वाद से आपका घर सुख, शांति और भक्ति से परिपूर्ण हो।",
                "आषाढ़ी एकादशी के पावन अवसर पर सभी भक्तों को मंगल शुभकामनाएं।",
            ],
            "en": [
                "May Lord Vitthal fill your heart with devotion, peace and pure bliss.",
                "Vithoba Rakhumai! Wishing you a spiritually uplifting Ashadhi Ekadashi.",
                "May the grace of Shri Hari protect and guide your family always.",
            ],
        },
        "scenes": [
            "Saffron warkari flags fluttering beside a tulsi vrindavan and brass taal cymbals along a misty monsoon riverside temple at dawn",
            "A floral palkhi with tulsi garlands, saffron flags and lit brass lamps in a stone temple courtyard",
            "Calm sacred river Chandrabhaga at sunrise with soft monsoon clouds, temple spires and glowing oil lamps",
        ],
    },
    "guru_purnima": {
        "names": ("गुरुपौर्णिमा", "गुरु पूर्णिमा", "Guru Purnima"),
        "emoji": "🙏",
        "target": 12,
        "headings": {
            "mr": "गुरुपौर्णिमेच्या हार्दिक शुभेच्छा",
            "hi": "गुरु पूर्णिमा की हार्दिक शुभकामनाएं",
            "en": "Happy Guru Purnima",
        },
        "quotes": {
            "mr": [
                "गुरूंच्या मार्गदर्शनाने आपल्या आयुष्यातील अज्ञानाचा अंधार दूर होवो आणि ज्ञानाचा प्रकाश पसरु दे.",
                "गुरुर्ब्रह्मा गुरुर्विष्णुः गुरुर्देवो महेश्वरः! सर्व गुरूंना वंदन.",
                "ज्यांनी आयुष्याला योग्य दिशा दिली, त्या सर्व गुरूंना गुरुपौर्णिमेनिमित्त शतशः नमन!",
            ],
            "hi": [
                "गुरु के आशीर्वाद से जीवन का हर अंधकार मिटे और ज्ञान का प्रकाश फैले।",
                "गुरु ब्रह्मा गुरु विष्णु, गुरु देवो महेश्वरः! गुरु पूर्णिमा की हार्दिक शुभकामनाएं।",
                "जीवन को सही राह दिखाने वाले सभी गुरुजनों को कोटि-कोटि नमन।",
            ],
            "en": [
                "With deep gratitude to every guru and mentor who lights the path of wisdom.",
                "May the blessings of your guru bring clarity, peace and purpose to your life.",
                "Wishing you a heartfelt and reverent Guru Purnima.",
            ],
        },
        "scenes": [
            "Holy guru paduka adorned with white mogra and marigold garlands beside glowing brass oil lamps and sacred scriptures under a bright full moon",
            "A serene ashram courtyard bathed in silver moonlight with warm lit diyas and drifting sandalwood incense",
            "A traditional brass lamp burning brightly beside a lotus flower and palm-leaf manuscripts, tranquil golden glow",
        ],
    },
    "nag_panchami": {
        "names": ("नागपंचमी", "नाग पंचमी", "Nag Panchami"),
        "emoji": "🌿",
        "target": 9,
        "headings": {
            "mr": "नागपंचमीच्या हार्दिक शुभेच्छा",
            "hi": "नाग पंचमी की हार्दिक शुभकामनाएं",
            "en": "Happy Nag Panchami",
        },
        "quotes": {
            "mr": [
                "निसर्गाबद्दल कृतज्ञता आणि श्रद्धेचा हा सण आपल्या घरी सुख आणि सुरक्षितता घेऊन येवो.",
                "नागपंचमीच्या पवित्र दिनी निसर्गाचे रक्षण आणि समृद्धीची कामना करूया.",
                "निसर्गदेवतेचे आशीर्वाद सदैव आपल्या पाठीशी राहोत!",
            ],
            "hi": [
                "नाग पंचमी का यह पावन पर्व आपके जीवन में सुख, सुरक्षा और समृद्धि लेकर आए।",
                "प्रकृति और परंपरा के इस सुंदर पर्व पर भगवान शिव की कृपा बनी रहे।",
                "नाग पंचमी की आप सभी को हार्दिक शुभकामनाएं।",
            ],
            "en": [
                "Celebrating reverence for nature and tradition this auspicious Nag Panchami.",
                "May Lord Shiva's blessings bring harmony and protection to your family.",
                "Wishing you a peaceful and blessed Nag Panchami.",
            ],
        },
        "scenes": [
            "A traditional stone shrine decorated with fresh green bilva leaves, turmeric-kumkum, lotus flowers and a lit brass diya in soft monsoon morning light",
            "A brass bowl of milk, popped jowar lahya and yellow flowers arranged neatly on a rangoli beside glowing oil lamps",
            "Lush green monsoon courtyard with marigold garlands, brass bell and warm flickering diyas",
        ],
    },
    "raksha_bandhan": {
        "names": ("रक्षाबंधन", "रक्षाबंधन", "Raksha Bandhan"),
        "emoji": "🧵",
        "target": 12,
        "headings": {
            "mr": "रक्षाबंधनाच्या हार्दिक शुभेच्छा",
            "hi": "रक्षाबंधन की हार्दिक शुभकामनाएं",
            "en": "Happy Raksha Bandhan",
        },
        "quotes": {
            "mr": [
                "राखीचा हा रेशमी धागा भावा-बहिणीतील प्रेम आणि विश्वासाचे नाते अधिक घट्ट करो.",
                "बहिणीची माया आणि भावाची साथ आयुष्यभर अशीच अबाधित राहो!",
                "रक्षाबंधन आणि नारळी पौर्णिमेच्या मनःपूर्वक शुभेच्छा.",
            ],
            "hi": [
                "रक्षा का यह पावन धागा भाई-बहन के अटूट प्रेम और विश्वास को सदा मजबूत रखे।",
                "मिठाई की मिठास और राखी का प्यार आपके रिश्ते को सदा महकाए रखे।",
                "रक्षाबंधन के पावन पर्व की हार्दिक शुभकामनाएं!",
            ],
            "en": [
                "A sacred thread of love, protection and lifelong memories. Happy Raksha Bandhan!",
                "May the bond between brother and sister grow warmer and stronger every year.",
                "Wishing you joy, laughter and sweet moments this Rakhi.",
            ],
        },
        "scenes": [
            "Handcrafted traditional silk rakhis adorned with pearls and gold thread resting on a gleaming brass aarti thali with kumkum, rice, sweets and a lit diya",
            "Colourful designer rakhis surrounded by rose petals, kaju katli sweets and warm glowing fairy lights on red velvet",
            "A decorated silver pooja plate with rakhi, coconut, roli-chawal and burning oil lamp in soft festive evening glow",
        ],
    },
    "krishna_janmashtami": {
        "names": ("श्रीकृष्ण जन्माष्टमी", "श्रीकृष्ण जन्माष्टमी", "Janmashtami"),
        "emoji": "🦚",
        "target": 15,
        "headings": {
            "mr": "श्रीकृष्ण जन्माष्टमीच्या शुभेच्छा",
            "hi": "श्रीकृष्ण जन्माष्टमी की शुभकामनाएं",
            "en": "Happy Janmashtami",
        },
        "quotes": {
            "mr": [
                "नंद घर आनंद भयो, जय कन्हैया लाल की! श्रीकृष्णाच्या कृपेने घर आनंदाने भरून जावो.",
                "बासरीच्या मधुर सुरांप्रमाणे आपले जीवनही सुंदर आणि प्रेमळ होवो.",
                "गोकुळाष्टमीच्या पवित्र दिनी बाळकृष्णाचा आशीर्वाद सदैव राहो!",
            ],
            "hi": [
                "नंद के आनंद भयो, जय कन्हैया लाल की! श्रीकृष्ण की कृपा आप पर सदा बनी रहे।",
                "बांसुरी की मधुर धुन की तरह आपका जीवन भी प्रेम और आनंद से भर जाए।",
                "श्रीकृष्ण जन्माष्टमी के पावन पर्व की हार्दिक शुभकामनाएं!",
            ],
            "en": [
                "May Lord Krishna fill your home with love, laughter and divine melody.",
                "Haathi Ghoda Palki, Jai Kanhaiya Lal Ki! Wishing you a joyful Janmashtami.",
                "May the blessings of Bal Gopal bring endless bliss to your family.",
            ],
        },
        "scenes": [
            "A golden bamboo flute adorned with a radiant peacock feather, resting beside an ornate earthen pot overflowing with fresh white butter (makhan) and jasmine flowers, warm midnight glow",
            "A flower-decked wooden swing (jhula) illuminated by tiny hanging oil lamps and rose petals in a serene temple courtyard",
            "A gleaming brass peacock crown, flute and makhan handi surrounded by marigold garlands and glowing diyas",
        ],
    },
    "hartalika": {
        "names": ("हरतालिका", "हरतालिका तीज", "Hartalika"),
        "emoji": "🌿",
        "target": 9,
        "headings": {
            "mr": "हरतालिकेच्या हार्दिक शुभेच्छा",
            "hi": "हरतालिका तीज की शुभकामनाएं",
            "en": "Happy Hartalika Teej",
        },
        "quotes": {
            "mr": [
                "शिव-पार्वतीच्या कृपेने आपल्या घरी अखंड सौभाग्य, प्रेम आणि सुख नांदो.",
                "हरतालिकेच्या पवित्र व्रताने आपल्या सर्व मनोकामना पूर्ण होवोत.",
                "भक्ती आणि समर्पणाचा हा सण आपल्यासाठी मंगलमय ठरो.",
            ],
            "hi": [
                "भगवान शिव और माता पार्वती के आशीर्वाद से आपके जीवन में सदा प्रेम और सौभाग्य बना रहे।",
                "हरतालिका तीज के पावन पर्व पर आपकी सभी मनोकामनाएं पूर्ण हों।",
                "सुख, शांति और अखंड सौभाग्य की मंगल कामना।",
            ],
            "en": [
                "May Lord Shiva and Goddess Parvati bless your home with eternal love and harmony.",
                "Wishing you joy, devotion and fulfilment on Hartalika Teej.",
                "May this auspicious day bring peace and blessings to your family.",
            ],
        },
        "scenes": [
            "Fresh green leaves, jasmine garlands, colourful glass bangles, mehendi and a glowing brass diya arranged on a decorated pooja plate",
            "A peaceful clay Shiv-Parvati shrine adorned with bilva leaves, champak flowers and flickering oil lamps",
            "Lush monsoon garden swing decorated with marigold and jasmine flowers, warm festive twilight",
        ],
    },
    "ganesh_chaturthi": {
        "names": ("श्री गणेश चतुर्थी", "गणेश चतुर्थी", "Ganesh Chaturthi"),
        "emoji": "🐘",
        "target": 18,
        "headings": {
            "mr": "श्री गणेश चतुर्थीच्या हार्दिक शुभेच्छा",
            "hi": "गणेश चतुर्थी की हार्दिक शुभकामनाएं",
            "en": "Happy Ganesh Chaturthi",
        },
        "quotes": {
            "mr": [
                "गणपती बाप्पा मोरया, मंगलमूर्ती मोरया! बाप्पाच्या आगमनाने घरात सुख-समृद्धी नांदो.",
                "विघ्नहर्ता श्री गणेश आपल्या सर्व संकटांचे निवारण करो आणि यश देवो.",
                "मोदकाचा गोडवा आणि आरतीचा नाद आपल्या घरी सदैव निनादत राहो!",
            ],
            "hi": [
                "गणपति बप्पा मोरया! विघ्नहर्ता श्री गणेश आपके जीवन की सभी बाधाएं दूर करें।",
                "बप्पा के आगमन से आपके घर में सुख, शांति और समृद्धि का वास हो।",
                "गणेश चतुर्थी के पावन पर्व की सपरिवार हार्दिक शुभकामनाएं!",
            ],
            "en": [
                "Ganpati Bappa Morya! May Lord Ganesha bless your home with wisdom, joy and prosperity.",
                "May Vighnaharta remove every obstacle from your path and fill your life with peace.",
                "Wishing you a joyful and blessed Ganesh Chaturthi!",
            ],
        },
        "scenes": [
            "A grand floral mandap backdrop decorated with red hibiscus, yellow marigold garlands, hanging brass bells and glowing oil lamps, warm festive radiance",
            "A silver thali overflowing with twenty-one traditional steamed ukadiche modak, fresh durva grass and red hibiscus flowers beside a lit brass diya",
            "A vibrant rangoli with a lotus motif surrounded by rows of glowing diyas, saffron drapes and temple incense smoke",
            "Traditional brass samai lamps glowing beside marigold torans and auspicious auspicious swastika rangoli in a warm festive home",
        ],
    },
    "anant_chaturdashi": {
        "names": ("अनंत चतुर्दशी", "अनंत चतुर्दशी", "Anant Chaturdashi"),
        "emoji": "🙏",
        "target": 9,
        "headings": {
            "mr": "अनंत चतुर्दशीच्या शुभेच्छा",
            "hi": "अनंत चतुर्दशी की शुभकामनाएं",
            "en": "Happy Anant Chaturdashi",
        },
        "quotes": {
            "mr": [
                "गणपती बाप्पा मोरया, पुढच्या वर्षी लवकर या! बाप्पाचे आशीर्वाद सदैव सोबत राहोत.",
                "भगवान अनंताच्या कृपेने आपल्या घरी सुख, शांती आणि समृद्धी अखंड राहो.",
                "भक्तीभावाने भरलेला हा दिवस आपल्यासाठी मंगलमय ठरो.",
            ],
            "hi": [
                "गणपति बप्पा मोरया, अगले बरस तू जल्दी आ! बप्पा की कृपा सदा बनी रहे।",
                "भगवान अनंत के आशीर्वाद से आपका जीवन सुख और शांति से परिपूर्ण रहे।",
                "अनंत चतुर्दशी के पावन अवसर पर हार्दिक शुभकामनाएं।",
            ],
            "en": [
                "Ganpati Bappa Morya, Pudhchya Varshi Lavkar Ya! May Bappa's blessings stay with you all year.",
                "May Lord Ananta bless your family with boundless peace and prosperity.",
                "Wishing you a devotional and joyous Anant Chaturdashi.",
            ],
        },
        "scenes": [
            "Golden sunset over calm ocean waves with marigold petals floating on the water and glowing diyas along the shore",
            "A sacred saffron-red Anant thread beside a brass kalash, lotus flowers and flickering oil lamps on a silk cloth",
            "Festive temple courtyard illuminated with brass lamps, flower petals and gentle evening glow",
        ],
    },
    "sharad_navratri": {
        "names": ("शारदीय नवरात्रोत्सव", "शारदीय नवरात्रि", "Navratri"),
        "emoji": "🌺",
        "target": 15,
        "headings": {
            "mr": "नवरात्रोत्सवाच्या हार्दिक शुभेच्छा",
            "hi": "नवरात्रि की हार्दिक शुभकामनाएं",
            "en": "Happy Navratri",
        },
        "quotes": {
            "mr": [
                "आदिशक्ती जगदंबेच्या कृपेने आपल्या घरी शक्ती, भक्ती आणि आनंदाचा वर्षाव होवो.",
                "घटस्थापनेपासून सुरू होणारे हे नऊ दिवस आपल्या जीवनात नवचैतन्य घेऊन येवोत.",
                "जय माता दी! देवीची कृपा सदैव आपल्या पाठीशी राहो.",
            ],
            "hi": [
                "जय माता दी! माँ दुर्गा की असीम कृपा से आपका घर सुख, शक्ति और समृद्धि से भर जाए।",
                "नवरात्रि के नौ पावन दिन आपके जीवन में नई ऊर्जा और खुशियाँ लेकर आएं।",
                "माँ अंबे के आशीर्वाद से आपके सभी कार्य सफल हों।",
            ],
            "en": [
                "Jai Mata Di! May Maa Durga bless you with strength, courage and endless joy.",
                "May the nine sacred nights of Navratri illuminate your home with devotion and peace.",
                "Wishing you a vibrant and blessed Navratri!",
            ],
        },
        "scenes": [
            "A sacred earthen Ghatasthapana kalash with sprouted green wheat-grass, coconut, marigold garlands and an akhand brass diya glowing warmly",
            "Colourful decorated wooden dandiya sticks beside a glowing brass garba pot pierced with patterns casting starry shadows at night",
            "Nine flickering clay diyas arranged around red hibiscus and rose petals on a festive rangoli",
        ],
    },
    "vijayadashami": {
        "names": ("विजयादशमी (दसरा)", "विजयादशमी (दशहरा)", "Dussehra"),
        "emoji": "🏹",
        "target": 12,
        "headings": {
            "mr": "दसऱ्याच्या हार्दिक शुभेच्छा",
            "hi": "विजयादशमी की हार्दिक शुभकामनाएं",
            "en": "Happy Dussehra",
        },
        "quotes": {
            "mr": [
                "सोन्यासारखे आपले नाते आणि आपट्याच्या पानांसारखे अबाधित राहो! विजयादशमीच्या शुभेच्छा.",
                "असत्यावर सत्याचा आणि वाईटावर चांगल्याचा विजय आपल्या जीवनात सदैव घडत राहो.",
                "नव्या शुभ कार्याच्या आरंभासाठी दसऱ्याचा हा सोनेरी मुहूर्त मंगलमय ठरो!",
            ],
            "hi": [
                "बुराई पर अच्छाई और असत्य पर सत्य की जीत का यह महापर्व आपके जीवन में विजय लाए।",
                "दशहरा के पावन अवसर पर आपके घर में सुख, शांति और समृद्धि का वास हो।",
                "विजयादशमी की आप सभी को हार्दिक शुभकामनाएं!",
            ],
            "en": [
                "May truth, goodness and courage always triumph in your life. Happy Dussehra!",
                "Sharing golden Apta leaves and warm wishes for success and prosperity.",
                "Wishing you a victorious and blessed Vijayadashami!",
            ],
        },
        "scenes": [
            "Fresh green Apta (sona) leaves tied with bright orange marigold blossoms resting on a brass pooja thali with kumkum, saffron cloth and a lit diya",
            "A golden ceremonial bow and arrow adorned with marigold flowers beside glowing brass lamps in warm autumn evening light",
            "Vibrant orange and yellow marigold garlands framing a sunlit traditional doorway with festive rangoli",
        ],
    },
    "kojagiri_purnima": {
        "names": ("कोजागिरी पौर्णिमा", "शरद पूर्णिमा", "Kojagiri Purnima"),
        "emoji": "🌕",
        "target": 9,
        "headings": {
            "mr": "कोजागिरी पौर्णिमेच्या शुभेच्छा",
            "hi": "शरद पूर्णिमा की शुभकामनाएं",
            "en": "Happy Kojagiri Purnima",
        },
        "quotes": {
            "mr": [
                "शरद ऋतूतील या चांदण्यात मसाला दुधाचा गोडवा आणि लक्ष्मीमातेचा आशीर्वाद लाभो.",
                "कोजागिरीच्या पूर्ण चंद्राप्रमाणे आपले आयुष्य शांत, सुंदर आणि तेजोमय होवो.",
                "सुख, समृद्धी आणि आनंदाचा वर्षाव आपल्या घरी सदैव राहो!",
            ],
            "hi": [
                "शरद पूर्णिमा की पावन चांदनी आपके जीवन में स्वास्थ्य, शांति और सुख-समृद्धि की वर्षा करे।",
                "माँ लक्ष्मी की कृपा से आपका घर सदा धन-धान्य से भरा रहे।",
                "शरद पूर्णिमा की आप सभी को हार्दिक शुभकामनाएं!",
            ],
            "en": [
                "May the silver moonlight of Sharad Purnima shower peace, health and prosperity upon you.",
                "Enjoy the warmth of saffron milk and loved ones under the radiant full moon.",
                "Wishing you a serene and blessed Kojagiri Purnima.",
            ],
        },
        "scenes": [
            "A silver bowl of creamy saffron-pistachio masala milk resting on a moonlit terrace table catching the reflection of a giant luminous full moon",
            "White jasmine and lotus flowers floating in a brass urli beside glowing diyas under a bright autumn full moon sky",
            "A serene rooftop courtyard bathed in silver moonlight with warm lanterns and festive sweets",
        ],
    },
    "karva_chauth": {
        "names": ("करवा चौथ", "करवा चौथ", "Karva Chauth"),
        "emoji": "🌙",
        "target": 9,
        "headings": {
            "mr": "करवा चौथच्या शुभेच्छा",
            "hi": "करवा चौथ की हार्दिक शुभकामनाएं",
            "en": "Happy Karva Chauth",
        },
        "quotes": {
            "mr": [
                "प्रेम, विश्वास आणि अखंड सौभाग्याचा हा सण आपल्या जीवनात सदैव आनंद घेऊन येवो.",
                "चंद्राच्या शीतल प्रकाशाप्रमाणे आपले नाते शांत आणि मधुर राहो.",
                "करवा चौथच्या मनःपूर्वक शुभेच्छा!",
            ],
            "hi": [
                "चाँद की चांदनी और दीपों की रोशनी आपके जीवन में सदा प्रेम और सौभाग्य बनाए रखे।",
                "विश्वास और समर्पण का यह पावन पर्व आपके रिश्ते को और मधुर बनाए।",
                "करवा चौथ की आप सभी को हार्दिक शुभकामनाएं!",
            ],
            "en": [
                "May the moonlight bless your bond with endless love, trust and togetherness.",
                "Wishing you a joyful, warm and blessed Karva Chauth.",
                "May your home always shine with happiness and harmony.",
            ],
        },
        "scenes": [
            "An ornate brass sieve (chalni), painted earthen karva pot, glowing diya and red rose petals on a moonlit terrace overlooking a glowing crescent moon",
            "A beautifully decorated red velvet pooja thali with glowing oil lamp, kumkum, sweets and marigold flowers against a starry evening sky",
            "Warm lanterns and lit diyas along a peaceful rooftop railing under a luminous night moon",
        ],
    },
    # ── Recurring Monthly Panchang Observances (excluding Amavasya & Pradosh) ───
    "ekadashi": {
        "names": ("एकादशी", "एकादशी", "Ekadashi"),
        "emoji": "🪷",
        "target": 12,
        "headings": {
            "mr": "पावन एकादशीच्या शुभेच्छा",
            "hi": "पावन एकादशी की शुभकामनाएं",
            "en": "Blessed Ekadashi",
        },
        "quotes": {
            "mr": [
                "ॐ नमो भगवते वासुदेवाय! पांडुरंगाच्या कृपेने आपले जीवन शांत आणि भक्तीमय होवो.",
                "एकादशीच्या पवित्र दिनी घरात सुख, शांती आणि आरोग्य नांदो.",
                "विठुरायाचे नामस्मरण आपल्या सर्व कार्यांना यश देवो!",
            ],
            "hi": [
                "ॐ नमो भगवते वासुदेवाय! भगवान श्रीहरि विष्णु की कृपा आप पर सदा बनी रहे।",
                "एकादशी का यह पावन दिन आपके जीवन में शांति, भक्ति और सकारात्मक ऊर्जा लाए।",
                "श्रीहरि के आशीर्वाद से आपका घर सुख-समृद्धि से परिपूर्ण रहे।",
            ],
            "en": [
                "Om Namo Bhagavate Vasudevaya! May Lord Vishnu bless your day with peace and devotion.",
                "Wishing you a spiritually serene and blessed Ekadashi.",
                "May the grace of Shri Hari bring harmony and positivity to your home.",
            ],
        },
        "scenes": [
            "A sacred brass shankh conch, fresh tulsi leaves, yellow marigold garland and a glowing brass diya on a wooden altar in soft dawn light",
            "Pink lotus blossoms floating in a serene temple pond at sunrise with warm golden reflections",
            "A traditional tulsi vrindavan adorned with glowing oil lamps and fresh yellow flowers at morning prayer time",
            "An ornate brass lamp burning beside sandalwood paste, tulsi beads (mala) and flowers in a peaceful sanctuary",
        ],
    },
    "masik_shivaratri": {
        "names": ("मासिक शिवरात्री", "मासिक शिवरात्रि", "Masik Shivaratri"),
        "emoji": "🔱",
        "target": 9,
        "headings": {
            "mr": "मासिक शिवरात्रीच्या शुभेच्छा",
            "hi": "मासिक शिवरात्रि की शुभकामनाएं",
            "en": "Blessed Masik Shivaratri",
        },
        "quotes": {
            "mr": [
                "ॐ नमः शिवाय! महादेवाच्या कृपेने आपले मन शांत आणि जीवन मंगलमय होवो.",
                "हर हर महादेव! भोलेनाथांचा आशीर्वाद सदैव आपल्या पाठीशी राहो.",
                "शिवभक्तीने आयुष्यातील सर्व चिंता दूर होवोत!",
            ],
            "hi": [
                "ॐ नमः शिवाय! भगवान शिव की कृपा से आपके जीवन में शांति और शक्ति का वास हो।",
                "हर हर महादेव! मासिक शिवरात्रि का यह पावन दिन आपके लिए मंगलमय हो।",
                "भोलेनाथ का आशीर्वाद आपके परिवार की सदा रक्षा करे।",
            ],
            "en": [
                "Om Namah Shivaya! May Lord Shiva bless your evening with calm and divine grace.",
                "Har Har Mahadev! Wishing you peace and strength on Masik Shivaratri.",
                "May Mahadev's blessings guide and protect your family.",
            ],
        },
        "scenes": [
            "A serene stone Shivling adorned with fresh green bilva leaves, white flowers and a softly glowing brass diya in peaceful twilight",
            "A gleaming brass trishul and rudraksha mala resting beside burning oil lamps under a calm crescent-moon sky",
            "Ancient temple pillars illuminated by warm flickering clay diyas with gentle incense smoke rising",
        ],
    },
    "vinayaki_chaturthi": {
        "names": ("विनायकी चतुर्थी", "विनायक चतुर्थी", "Vinayak Chaturthi"),
        "emoji": "🌺",
        "target": 9,
        "headings": {
            "mr": "विनायकी चतुर्थीच्या शुभेच्छा",
            "hi": "विनायक चतुर्थी की शुभकामनाएं",
            "en": "Happy Vinayak Chaturthi",
        },
        "quotes": {
            "mr": [
                "वक्रतुंड महाकाय! गणरायाच्या कृपेने आपल्या सर्व शुभ कार्यांत यश लाभो.",
                "विनायकी चतुर्थीच्या पवित्र दिनी गणपती बाप्पाचा आशीर्वाद सदैव राहो.",
                "ॐ गं गणपतये नमः! घरात सुख, शांती आणि समृद्धी नांदो.",
            ],
            "hi": [
                "ॐ गं गणपतये नमः! विघ्नहर्ता श्री गणेश आपके जीवन के सभी विघ्न हर लें।",
                "विनायक चतुर्थी के पावन अवसर पर बप्पा की कृपा आप पर सदा बनी रहे।",
                "श्री गणेश के आशीर्वाद से आपका हर दिन मंगलमय हो।",
            ],
            "en": [
                "Om Gam Ganapataye Namah! May Lord Ganesha bless your day with wisdom and success.",
                "Wishing you an obstacle-free and joyful Vinayak Chaturthi.",
                "Ganpati Bappa Morya! May Bappa's grace brighten your home.",
            ],
        },
        "scenes": [
            "Fresh red hibiscus blossoms, green durva grass, golden modak sweets and a lit brass diya on an ornate pooja thali in warm morning sun",
            "A peaceful temple doorway decorated with orange marigold toran and glowing oil lamps",
            "A brass bell, red flowers and sacred kumkum arranged neatly beside a softly burning diya",
        ],
    },
    "sankashti_chaturthi": {
        "names": ("संकष्टी चतुर्थी", "संकष्टी चतुर्थी", "Sankashti Chaturthi"),
        "emoji": "🌙",
        "target": 9,
        "headings": {
            "mr": "संकष्टी चतुर्थीच्या शुभेच्छा",
            "hi": "संकष्टी चतुर्थी की शुभकामनाएं",
            "en": "Happy Sankashti Chaturthi",
        },
        "quotes": {
            "mr": [
                "संकष्टी चतुर्थीच्या पवित्र दिनी गणराया आपल्या सर्व संकटांचे निवारण करो.",
                "चंद्रोदयाच्या साक्षीने बाप्पाची कृपा आपल्या कुटुंबावर सदैव राहो.",
                "गणपती बाप्पा मोरया! मन शांत आणि जीवन आनंदमय होवो.",
            ],
            "hi": [
                "संकष्टी चतुर्थी के पावन पर्व पर श्री गणेश आपके सभी संकट और कष्ट दूर करें।",
                "चंद्रोदय के साथ आपके जीवन में सुख, शांति और समृद्धि का प्रकाश फैले।",
                "गणपति बप्पा मोरया! बप्पा का आशीर्वाद सदा आपके साथ रहे।",
            ],
            "en": [
                "May Lord Ganesha remove all worries and bring peace to your heart this Sankashti Chaturthi.",
                "Seeking Bappa's blessings under the rising moon for happiness and well-being.",
                "Ganpati Bappa Morya! Wishing you a serene and blessed evening.",
            ],
        },
        "scenes": [
            "A glowing crescent moon rising over a peaceful temple courtyard with lit brass diyas, red hibiscus flowers and modak prasad on a silver thali",
            "A traditional brass aarti thali with durva grass, flowers and a lit oil lamp illuminated by soft evening moonlight",
            "Rows of clay diyas glowing along a quiet stone courtyard beneath a starry moonrise sky",
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


def _visible_before_days(slug: str) -> int:
    return RECURRING_VISIBLE_BEFORE_DAYS if slug in RECURRING_VRATS else GENERATION_WINDOW_DAYS


async def sync_festival_categories() -> None:
    """Creates missing festival categories, pins visible ones to the top
    (soonest first) and hides finished, far-future or still-empty ones."""
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
            in_window = occurrence is not None and (occurrence - today).days <= _visible_before_days(slug)
            visible = in_window and sum(counts.values()) > 0
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
            days_away = (occ - today).days if occ else None
            out.append({
                "slug": slug,
                "name": fest["names"][2],
                "date": occ.isoformat() if occ else None,
                "days_away": days_away,
                "in_generation_window": days_away is not None and 0 <= days_away <= GENERATION_WINDOW_DAYS,
                "visible": days_away is not None and days_away <= _visible_before_days(slug) and sum(counts.values()) > 0,
                "target": fest["target"],
                "counts": counts,
            })
    out.sort(key=lambda item: (item["days_away"] is None, item["days_away"] if item["days_away"] is not None else 99999))
    return out
