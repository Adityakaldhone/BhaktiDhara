"""Versioned horoscope generation and persistence integration for Bhaktidhara."""

from __future__ import annotations

import asyncio
import copy
import json
import logging
import math
import os
import re
from dataclasses import dataclass
from datetime import date, datetime, timedelta
from pathlib import Path
from typing import Awaitable, Callable
from weakref import WeakKeyDictionary, WeakValueDictionary

if __package__:
    from .horoscope_ephemeris import IST, MeeusEphemeris, SwissEphemeris, day_start, samples, transit
else:
    from horoscope_ephemeris import IST, MeeusEphemeris, SwissEphemeris, day_start, samples, transit

SCHEMA_VERSION = 2
LANGUAGES = {"en": 0, "hi": 1, "mr": 2}
COPY = json.loads(Path(__file__).with_name("horoscope_content.json").read_text(encoding="utf-8"))
LOGGER = logging.getLogger(__name__)
EPHEMERIS_MODE = os.getenv("HOROSCOPE_EPHEMERIS", "meeus").strip().lower()
if EPHEMERIS_MODE == "swiss":
    EPHEMERIS = SwissEphemeris()
elif EPHEMERIS_MODE == "meeus":
    EPHEMERIS = MeeusEphemeris(COPY["moon_terms"])
else:
    raise ValueError("HOROSCOPE_EPHEMERIS must be 'meeus' or 'swiss'")

_gemini: Callable[[str], str] | None = None
_locks_by_loop: WeakKeyDictionary = WeakKeyDictionary()
CacheReader = Callable[[str], Awaitable[dict | None]]
CacheWriter = Callable[[str, dict], Awaitable[None]]
DIGITS = str.maketrans("०१२३४५६७८९", "0123456789")
EN_MONTHS = (
    "January", "February", "March", "April", "May", "June", "July", "August",
    "September", "October", "November", "December",
)
MONTH_LOOKUP = {
    label.casefold(): index
    for index, labels in enumerate(COPY["months"], 1)
    for label in (*labels, EN_MONTHS[index - 1])
}
RASHI_LOOKUP = {alias: i for i, aliases in enumerate(COPY["aliases"]) for alias in aliases}
RULER_INDEX = (0, 1, 2, 3, 4, 2, 1, 0, 5, 6, 6, 5)
LABEL = {
    "general": ("General prediction", "राशिफल", "राशीभविष्य"),
    "lifeAspects": ("Life aspects", "जीवन के पहलू", "जीवनाचे पैलू"),
    "actions": ("Do’s and don’ts", "क्या करें और क्या न करें", "कृतीसाठी मार्गदर्शन"),
    "luckyElements": ("Lucky elements", "शुभ संकेत", "शुभ संकेत"),
    "spiritual": ("Vedic remedies", "वैदिक उपाय", "वैदिक उपाय"),
    "transit": ("Moon transit", "चंद्र गोचर", "चंद्र गोचर"),
    "career": ("Career & business", "करियर और व्यवसाय", "करिअर आणि व्यवसाय"),
    "finance": ("Finance & wealth", "धन और वित्त", "धन आणि आर्थिक व्यवहार"),
    "love": ("Love & relationships", "प्रेम और रिश्ते", "प्रेम आणि नाती"),
    "health": ("Health & well-being", "स्वास्थ्य और दिनचर्या", "आरोग्य आणि दिनक्रम"),
    "do": ("What to do", "क्या करें", "काय करावे"),
    "avoid": ("What to avoid", "क्या न करें", "काय टाळावे"),
    "color": ("Lucky color", "शुभ रंग", "शुभ रंग"),
    "number": ("Lucky number", "शुभ अंक", "शुभ अंक"),
    "direction": ("Lucky direction", "शुभ दिशा", "शुभ दिशा"),
    "muhurat": ("Abhijit Muhurat", "अभिजित मुहूर्त", "अभिजित मुहूर्त"),
    "mantra": ("Mantra", "मंत्र", "मंत्र"),
    "remedy": ("Simple remedy", "सरल उपाय", "सोपे उपाय"),
    "chant": ("11 recitations", "११ बार जप", "११ वेळा जप"),
    "western": ("Western Sun-sign dates", "पाश्चात्य सूर्य राशि की तिथियाँ", "पाश्चात्य सूर्य राशीच्या तारखा"),
    "east": ("East", "पूर्व", "पूर्व"), "west": ("West", "पश्चिम", "पश्चिम"),
    "north": ("North", "उत्तर", "उत्तर"), "south": ("South", "दक्षिण", "दक्षिण"),
    "reflection": ("Use the chant as a moment of reflection.", "जप के लिए कुछ शांत पल निकालें।", "जपासाठी काही शांत क्षण राखून ठेवा."),
}
FULL_ORDER = ("general", "lifeAspects", "actions", "luckyElements", "spiritual")


@dataclass(frozen=True)
class Request:
    index: int
    period: str
    language: str
    start: date

    @property
    def rashi_id(self) -> str:
        return COPY["signs"][self.index][0].lower()

    @property
    def end(self) -> date:
        return self.start + timedelta(days=6 if self.period == "weekly" else 0)

    def text(self, translations) -> str:
        return translations[LANGUAGES[self.language]]

    def label(self, key: str) -> str:
        return self.text(LABEL[key])

    @property
    def key(self) -> str:
        writer = "gemini" if _gemini is not None else "rules"
        return (f"horoscope:v{SCHEMA_VERSION}:{EPHEMERIS.key}:{writer}:"
                f"{self.rashi_id}:{self.period}:{self.start.isoformat()}:{self.language}")


def configure_horoscope_gemini(generator: Callable[[str], str] | None) -> None:
    """Use the existing server Gemini client for wording, when enabled."""
    global _gemini
    enabled = os.getenv("HOROSCOPE_USE_GEMINI", "1").strip().lower() not in {"0", "false", "off"}
    _gemini = generator if enabled else None


def _rashi_index(name: str, rashi_id: str | None) -> int:
    for value in (rashi_id or "", name):
        for token in re.split(r"[^a-z\u0900-\u097f]+", value.strip().lower()):
            if token in RASHI_LOOKUP:
                return RASHI_LOOKUP[token]
    raise ValueError("Unknown Janma Rashi")


def _legacy_date(value: str) -> date | None:
    text = value.strip().translate(DIGITS)
    match = re.match(r"^(\d{4}-\d{2}-\d{2})(?=$|\s|T)", text)
    if match:
        return date.fromisoformat(match[1])
    match = re.search(r"(\d{1,2})\s+([^\s,]+)\s*,?\s+(\d{4})", text)
    if match and match[2].casefold() in MONTH_LOOKUP:
        return date(int(match[3]), MONTH_LOOKUP[match[2].casefold()], int(match[1]))
    match = re.search(r"([^\s,]+)\s+(\d{1,2}),?\s+(\d{4})", text)
    if match and match[1].casefold() in MONTH_LOOKUP:
        return date(int(match[3]), MONTH_LOOKUP[match[1].casefold()], int(match[2]))
    return None


def _request(rashi_name, period, lang_code, date_text, rashi_id, forecast_date, now):
    period = period.strip().lower()
    if period not in {"today", "tomorrow", "weekly"}:
        raise ValueError("Use today, tomorrow, or weekly")
    language = re.split(r"[-_]", lang_code.strip().lower(), maxsplit=1)[0]
    if language not in LANGUAGES:
        raise ValueError("Use en, hi, or mr")
    if forecast_date is None:
        start = _legacy_date(date_text or "")
    elif isinstance(forecast_date, str):
        start = date.fromisoformat(forecast_date)
    elif isinstance(forecast_date, date) and not isinstance(forecast_date, datetime):
        start = forecast_date
    else:
        raise ValueError("forecast_date must be an ISO calendar date")
    if start is None:
        instant = now if now is not None else datetime.now(IST)
        if instant.tzinfo is None or instant.utcoffset() is None:
            raise ValueError("now must be timezone-aware")
        start = instant.astimezone(IST).date()
        if period == "tomorrow":
            start += timedelta(days=1)
    if period == "weekly":
        start -= timedelta(days=start.weekday())
    return Request(_rashi_index(rashi_name, rashi_id), period, language, start)


def horoscope_cache_key(
    rashi_name: str, period: str, lang_code: str, date_text: str = "",
    rashi_id: str | None = None, *, forecast_date: str | date | None = None,
    now: datetime | None = None,
) -> str:
    return _request(rashi_name, period, lang_code, date_text, rashi_id, forecast_date, now).key


def _house(sample, rashi_index: int) -> int:
    return (sample.sign - rashi_index) % 12


def _traditional_index(sample, rashi_index: int) -> int:
    house = _house(sample, rashi_index) + 1
    if house in {1, 3, 6, 7, 10, 11}:
        return 80
    favored = {2, 5, 9} if sample.waxing else {4, 8, 12}
    return 72 if house in favored else 64


def _time(instant: datetime, language: str) -> str:
    local = instant.astimezone(IST) + timedelta(seconds=30)
    if language == "en":
        period = "AM" if local.hour < 12 else "PM"
        return f"{local.hour % 12 or 12}:{local.minute:02} {period}"
    return f"{local.hour:02}:{local.minute:02}"


def _date_label(req: Request, day: date) -> str:
    return f"{day.day} {req.text(COPY['months'][day.month - 1])} {day.year}"


def _legacy_or_full_dates(req: Request) -> tuple[str, str]:
    date_text = _date_label(req, req.start)
    if req.period == "weekly":
        return (f"{date_text} – {_date_label(req, req.end)}",) * 2
    weekday = req.text(COPY["weekdays"][req.start.weekday()])
    if req.language == "en":
        return date_text, f"{weekday}, {EN_MONTHS[req.start.month-1]} {req.start.day}, {req.start.year}"
    return date_text, f"{weekday}, {date_text}"


def _transit_note(req: Request, position, last_sign: int | None) -> str:
    def name(i):
        sign = COPY["signs"][i][0 if req.language == "en" else 2]
        house = (i - req.index) % 12 + 1
        return req.text((f"{sign} (house {house})", f"{sign} (भाव {house})", f"{sign} (भाव {house})"))

    start = name(position.first)
    if last_sign is not None:
        finish = name(last_sign)
        return req.text((
            f"The Moon starts Monday in {start} and reaches {finish} by Sunday afternoon.",
            f"सोमवार की शुरुआत में चंद्रमा {start} में और रविवार दोपहर में {finish} में रहेगा।",
            f"सोमवारच्या सुरुवातीला चंद्र {start} येथे आणि रविवारी दुपारी {finish} येथे असेल.",
        ))
    if position.ingress is None:
        return req.text((
            f"The Moon stays in {start} throughout the day.",
            f"चंद्रमा पूरे दिन {start} में रहेगा।",
            f"चंद्र दिवसभर {start} येथे राहील.",
        ))
    finish, hour = name(position.last), _time(position.ingress, req.language)
    return req.text((
        f"The Moon starts in {start} and enters {finish} around {hour} IST.",
        f"चंद्रमा {start} से लगभग {hour} IST पर {finish} में प्रवेश करेगा।",
        f"चंद्र सुमारे {hour} IST ला {start} येथून {finish} येथे प्रवेश करेल.",
    ))


def _compose(req: Request, days, position) -> dict:
    house = COPY["houses"]
    first_index = _house(days[0][1], req.index)
    representative = days[3 if req.period == "weekly" else 0]
    first = house[first_index]
    middle = house[_house(representative[1], req.index)]
    final = house[_house(days[-1][1 if req.period == "weekly" else 2], req.index)]
    overview = req.text(first["outlook"])
    headline = req.text(COPY["headlines"][first_index])
    career = req.text(middle["career"])
    if req.period == "weekly":
        a, b, c = (req.text(item["topic"]) for item in (first, middle, final))
        overview = req.text((
            f"Early in the week, focus on {a}. Make room for {b} around midweek and for {c} over the weekend.",
            f"सप्ताह की शुरुआत में {a} पर ध्यान दें। सप्ताह के बीच में {b} और सप्ताहांत में {c} के लिए समय निकालें।",
            f"आठवड्याच्या सुरुवातीला {a} यावर भर राहील. मध्यावर {b} आणि शेवटी {c} यासाठी वेळ द्या.",
        ))
        if first != final:
            career = f"{req.text(first['career'])} {req.text(final['career'])}"
    else:
        if ((position.first - req.index) % 12, (position.last - req.index) % 12) == (9, 10):
            headline = req.text((
                "Career momentum builds as your network comes into focus",
                "काम में बढ़त के साथ सहयोग के रास्ते खुल सकते हैं",
                "कामाला गती मिळेल, ओळखींच्या वर्तुळातून सहकार्याची शक्यता",
            ))
        morning = house[_house(days[0][0], req.index)]
        if morning != final:
            a, b = (req.text(item["topic"]) for item in (morning, final))
            overview += " " + req.text((
                f"Start with {a}. By evening, your focus may turn to {b}.",
                f"सुबह {a} को समय दें। शाम तक {b} पर ध्यान जा सकता है।",
                f"सकाळी {a} यासाठी वेळ द्या. संध्याकाळी {b} याकडे लक्ष जाऊ शकते.",
            ))
        overview += " " + req.text(COPY["nakshatra"][days[0][1].nakshatra % 9])
    return {
        "headline": headline, "overview": overview, "career": career,
        "finance": req.text(COPY["finance"][first_index]),
        "love": req.text(middle["relationships"]), "health": req.text(middle["wellness"]),
        "do": req.text(first["action"]), "avoid": req.text(first["avoid"]),
    }


def _rewrite_matches_language(text: str, language: str) -> bool:
    letters = sum(character.isalpha() for character in text)
    indic = len(re.findall(r"[\u0900-\u097f]", text))
    if not letters:
        return False
    if language == "en":
        return indic == 0
    if indic / letters < 0.5:
        return False
    markers = (" आहे", " आणि ", "च्या ", "साठी", " करा", " टाळा", "ला गती", "वेळ द्या")
    marathi = sum(text.count(marker) for marker in markers)
    hindi = sum(text.count(marker) for marker in (" है", " हैं", " करें", " सकता", " के लिए", " नहीं"))
    return marathi < 2 if language == "hi" else hindi < 2


async def _polish(req: Request, wording: dict) -> tuple[dict, bool]:
    generator = _gemini
    if generator is None:
        return wording, False
    editable = ("headline", "overview", "career", "love", "do", "avoid")
    source = {key: wording[key] for key in editable}
    language = ("English", "Hindi", "Marathi")[LANGUAGES[req.language]]
    prompt = f"""Copyedit the supplied Bhaktidhara rashifal for {language} readers.
Return a JSON object with exactly the same keys and one string for each.
Keep each field's topic, level of certainty and practical meaning.
Use fluent {language} with a calm magazine-style voice and a clear day outlook first.
Keep the overview to three sentences. Use one practical action and one specific thing to avoid.
Do not introduce new transit names, timings, planets, scores, symptoms, financial predictions,
promises, events, risk claims, numerals or instructions. Preserve a mixed or quiet outlook
when present. Do not use markdown. Only polish the facts and advice already supplied.
Source text: {json.dumps(source, ensure_ascii=False)}"""
    try:
        raw = await asyncio.wait_for(asyncio.to_thread(generator, prompt), timeout=15)
        raw = re.sub(r"^\s*```(?:json)?\s*|\s*```\s*$", "", raw, flags=re.I)
        result = json.loads(raw)
        if not isinstance(result, dict) or set(result) != set(editable):
            return wording, False
        for key in editable:
            value = result[key]
            if (not isinstance(value, str) or not value.strip() or len(value) > 500
                    or "\n" in value or re.search(r"\d", value)
                    or not _rewrite_matches_language(value, req.language)):
                return wording, False
        return {**wording, **{key: result[key].strip() for key in editable}}, True
    except Exception as error:
        LOGGER.info("Horoscope copyediting unavailable (%s)", type(error).__name__)
        return wording, False


def _line(label: str, text: str = "", score: float | None = None) -> dict:
    return {"label": label, "text": text, "score": score}


def _section(req: Request, kind: str, *lines: dict) -> dict:
    return {"kind": kind, "title": req.label(kind), "lines": list(lines)}


def _round_half_up(value: float) -> int:
    return math.floor(value + 0.5)


_SIGN_RELATIONS = {
    "aries": {
        "compatible": {"mr": "सिंह व धनु", "hi": "सिंह व धनु", "en": "Leo & Sagittarius"},
        "caution": {"mr": "वृश्चिक", "hi": "वृश्चिक", "en": "Scorpio"},
    },
    "taurus": {
        "compatible": {"mr": "कन्या व मकर", "hi": "कन्या व मकर", "en": "Virgo & Capricorn"},
        "caution": {"mr": "मेष", "hi": "मेष", "en": "Aries"},
    },
    "gemini": {
        "compatible": {"mr": "तूळ व कुंभ", "hi": "तुला व कुंभ", "en": "Libra & Aquarius"},
        "caution": {"mr": "कर्क", "hi": "कर्क", "en": "Cancer"},
    },
    "cancer": {
        "compatible": {"mr": "वृश्चिक व मीन", "hi": "वृश्चिक व मीन", "en": "Scorpio & Pisces"},
        "caution": {"mr": "धनु", "hi": "धनु", "en": "Sagittarius"},
    },
    "leo": {
        "compatible": {"mr": "मेष व धनु", "hi": "मेष व धनु", "en": "Aries & Sagittarius"},
        "caution": {"mr": "मकर", "hi": "मकर", "en": "Capricorn"},
    },
    "virgo": {
        "compatible": {"mr": "वृषभ व मकर", "hi": "वृषभ व मकर", "en": "Taurus & Capricorn"},
        "caution": {"mr": "कुंभ", "hi": "कुंभ", "en": "Aquarius"},
    },
    "libra": {
        "compatible": {"mr": "मिथुन व कुंभ", "hi": "मिथुन व कुंभ", "en": "Gemini & Aquarius"},
        "caution": {"mr": "मीन", "hi": "मीन", "en": "Pisces"},
    },
    "scorpio": {
        "compatible": {"mr": "कर्क व मीन", "hi": "कर्क व मीन", "en": "Cancer & Pisces"},
        "caution": {"mr": "मेष", "hi": "मेष", "en": "Aries"},
    },
    "sagittarius": {
        "compatible": {"mr": "मेष व सिंह", "hi": "मेष व सिंह", "en": "Aries & Leo"},
        "caution": {"mr": "वृषभ", "hi": "वृषभ", "en": "Taurus"},
    },
    "capricorn": {
        "compatible": {"mr": "वृषभ व कन्या", "hi": "वृषभ व कन्या", "en": "Taurus & Virgo"},
        "caution": {"mr": "मिथुन", "hi": "मिथुन", "en": "Gemini"},
    },
    "aquarius": {
        "compatible": {"mr": "मिथुन व तूळ", "hi": "मिथुन व तुला", "en": "Gemini & Libra"},
        "caution": {"mr": "कर्क", "hi": "कर्क", "en": "Cancer"},
    },
    "pisces": {
        "compatible": {"mr": "कर्क व वृश्चिक", "hi": "कर्क व वृश्चिक", "en": "Cancer & Scorpio"},
        "caution": {"mr": "सिंह", "hi": "सिंह", "en": "Leo"},
    },
}

_COMPAT_TIPS = {
    "mr": "{compat} राशीच्या सहकाऱ्यांशी कामात उत्तम समन्वय व लाभ होईल. {caution} राशीशी बोलताना संयम ठेवा.",
    "hi": "{compat} राशि के जातकों से सहयोग व सफलता मिलेगी। {caution} राशि से व्यर्थ वाद-विवाद टालें।",
    "en": "Synergy with {compat} brings notable progress. Maintain patient dialogue with {caution} to prevent friction.",
}

_CAUTION_WINDOWS = {
    "mr": "दुपारी १२:०० - ०३:३०",
    "hi": "दोपहर १२:०० - ०३:३०",
    "en": "12:00 PM - 03:30 PM",
}


async def _generate(req: Request) -> dict:
    length = 7 if req.period == "weekly" else 1
    days = [samples(EPHEMERIS, req.start + timedelta(days=i)) for i in range(length)]
    position = transit(EPHEMERIS, req.start)
    wording, ai = await _polish(req, _compose(req, days, position))
    all_samples = [sample for day in days for sample in day]
    rating = _round_half_up(sum(_traditional_index(sample, req.index)
                                for sample in all_samples) / len(all_samples))
    if rating >= 77:
        mood_score, moods = 4.0, ("Favorable & active", "अनुकूल और सक्रिय", "अनुकूल आणि सक्रिय")
    elif rating >= 70:
        mood_score, moods = 3.5, ("Steady & balanced", "स्थिर और संतुलित", "स्थिर आणि संतुलित")
    else:
        mood_score, moods = 3.0, ("Quiet & reflective", "शांत और विचारशील", "शांत आणि चिंतनशील")

    def aspect_score(houses):
        points = sum(
            (3.5 if _traditional_index(sample, req.index) >= 77 else 3.0)
            + (0.5 if _house(sample, req.index) + 1 in houses else 0.0)
            for sample in all_samples
        )
        return _round_half_up(2 * points / len(all_samples)) / 2

    def line(key):
        return _line(req.label(key), wording[key])

    western, vedic, devanagari, symbol = COPY["signs"][req.index]
    sign_title = f"{western} / {vedic} ({devanagari})" if req.language == "en" else f"{devanagari} ({western})"
    ruler = COPY["rulers"][RULER_INDEX[req.index]]
    color, mantra, remedy = (req.text(ruler[key]) for key in ("color", "mantra", "remedy"))
    lord = req.text(ruler["name"])
    mantra_count = f"{mantra} · {req.label('chant')}"
    lucky = [
        _line(req.label("color"), color),
        _line(req.label("number"), ruler["number"]),
        _line(req.label("direction"), req.label(ruler["direction"])),
    ]
    m1, d1, m2, d2 = COPY["sun_dates"][req.index]

    def date_range(month, day):
        return (f"{EN_MONTHS[month-1]} {day}" if req.language == "en"
                else f"{day} {req.text(COPY['months'][month - 1])}")

    transit_note = _transit_note(req, position, days[-1][1].sign if length == 7 else None)
    lines = [
        _line(req.label(key), wording[key], aspect_score(houses))
        for key, houses in (
            ("career", {3, 6, 10, 11}), ("finance", {2, 8, 10, 11}),
            ("love", {4, 5, 7, 11}), ("health", {1, 4, 6, 12}),
        )
    ]
    actions = _section(req, "actions", line("do"), line("avoid"))
    date_text, date_and_day = _legacy_or_full_dates(req)
    short_overview = re.split(r"(?<=[.!?।])\s+", wording["overview"], maxsplit=1)[0]
    if length == 1 and position.ingress and days[0][1].sign != position.last:
        later = req.text(COPY["houses"][(position.last - req.index) % 12]["topic"])
        short_overview += " " + req.text((
            f"Later, your focus may turn to {later}.",
            f"दिन आगे बढ़ने पर {later} पर ध्यान जा सकता है।",
            f"दिवस पुढे सरकत असताना {later} याकडे लक्ष जाऊ शकते.",
        ))

    page = {
        "symbol": symbol, "signTitle": sign_title, "dateAndDay": date_and_day,
        "sunSignDates": f"{req.label('western')} · {date_range(m1, d1)} – {date_range(m2, d2)}",
        "element": req.text(COPY["elements"][req.index % 4]), "rulingPlanet": lord,
        "headline": wording["headline"], "mood": req.text(moods), "moodScore": mood_score,
        "ephemerisSource": EPHEMERIS.name, "transitNote": transit_note,
        "moonIngressUtc": position.ingress.isoformat() if position.ingress and length == 1 else None,
        "muhuratUtc": None,
        "fullSections": [
            _section(req, "general", _line("", wording["overview"]),
                     _line(req.label("transit"), transit_note)),
            _section(req, "lifeAspects", *lines),
            actions,
            _section(req, "luckyElements", *lucky),
            _section(req, "spiritual", _line(req.label("mantra"), mantra_count),
                     _line(req.label("remedy"), remedy)),
        ],
        "summarySections": [
            _section(req, "general", _line("", short_overview)),
            _section(req, "lifeAspects", *[_line(row["label"], score=row["score"]) for row in lines]),
            actions,
            _section(req, "luckyElements", *lucky[:2]),
        ],
    }

    house = COPY["houses"]
    representative = days[3 if length == 7 else 0]

    rel = _SIGN_RELATIONS.get(req.rashi_id, _SIGN_RELATIONS["aries"])
    compat_rashi = rel["compatible"].get(req.language, rel["compatible"]["mr"])
    caution_rashi = rel["caution"].get(req.language, rel["caution"]["mr"])
    compat_tip_template = _COMPAT_TIPS.get(req.language, _COMPAT_TIPS["mr"])
    compat_tip = compat_tip_template.format(compat=compat_rashi, caution=caution_rashi)
    caution_window = _CAUTION_WINDOWS.get(req.language, _CAUTION_WINDOWS["mr"])
    caution_title = wording["avoid"]
    caution_detail = f"{req.label('avoid')}: {wording['avoid']}. {req.label('do')}: {wording['do']}."

    return {
        "schemaVersion": SCHEMA_VERSION,
        "rashiId": req.rashi_id, "period": req.period, "langCode": req.language,
        "forecastDate": req.start.isoformat(), "forecastEndDate": req.end.isoformat(),
        "timeZone": "Asia/Kolkata", "dateText": date_text,
        "summary": (f"{wording['overview']}\n\n"
                    f"{req.label('do')}\n{wording['do']}\n\n"
                    f"{req.label('avoid')}\n{wording['avoid']}"),
        "career": wording["career"], "finance": wording["finance"],
        "love": wording["love"], "health": wording["health"],
        "luckyNumber": ruler["number"], "luckyColor": color, "remedy": remedy,
        "cautionTitle": caution_title,
        "cautionDetail": caution_detail,
        "cautionWindow": caution_window,
        "timeSlots": {
            "morning": req.text(house[_house(representative[0], req.index)]["action"]),
            "afternoon": wording["career"],
            "evening": req.text(house[_house(representative[2], req.index)]["relationships"]),
        },
        "compatibleRashi": compat_rashi,
        "cautionRashi": caution_rashi,
        "compatibilityTip": compat_tip,
        "rulingDeity": lord, "deityMantra": mantra_count, "mantraBenefit": req.label("reflection"),
        "auspiciousPercentage": rating, "isAiGenerated": ai, "presentation": page,
    }


@dataclass(frozen=True)
class City:
    name: str
    latitude: float
    longitude: float


def _city(name: str | None, latitude: float | None, longitude: float | None) -> City | None:
    if name is None and latitude is None and longitude is None:
        return None
    if (not isinstance(name, str) or not name.strip() or len(name) > 100
            or type(latitude) not in (float, int) or not -90 <= latitude <= 90
            or type(longitude) not in (float, int) or not -180 <= longitude <= 180):
        raise ValueError("Provide a city name and valid latitude and longitude together")
    return City(name.strip(), latitude, longitude)


def _attach_city(base: dict, req: Request, city: City | None) -> dict:
    # A city-specific time is per response. The same reading is persisted once.
    result = copy.deepcopy(base)
    if city is None or req.period == "weekly" or req.start.weekday() == 2:
        return result
    daylight = EPHEMERIS.daylight(day_start(req.start), city.latitude, city.longitude)
    if daylight is None:
        return result
    sunrise, sunset = daylight
    interval = (sunset - sunrise) / 15
    start, end = sunrise + 7 * interval, sunrise + 8 * interval
    page = result["presentation"]
    page["muhuratUtc"] = {"start": start.isoformat(), "end": end.isoformat()}
    timing = _line(req.label("muhurat"),
                   f"{_time(start, req.language)} – {_time(end, req.language)} IST · {city.name}")
    for key in ("fullSections", "summarySections"):
        lucky = next(section for section in page[key] if section["kind"] == "luckyElements")
        lucky["lines"].insert(2, timing.copy())
    return result


def _usable(data: dict | None, req: Request) -> bool:
    if not isinstance(data, dict):
        return False
    page = data.get("presentation")
    return (
        data.get("schemaVersion") == SCHEMA_VERSION and data.get("rashiId") == req.rashi_id
        and data.get("period") == req.period and data.get("langCode") == req.language
        and data.get("forecastDate") == req.start.isoformat()
        and data.get("forecastEndDate") == req.end.isoformat()
        and all(isinstance(data.get(field), str) and data[field].strip()
                for field in ("dateText", "summary", "career", "finance", "health", "love"))
        and type(data.get("isAiGenerated")) is bool
        and type(data.get("auspiciousPercentage")) is int
        and isinstance(page, dict) and page.get("ephemerisSource") == EPHEMERIS.name
        and all(isinstance(page.get(field), str) and page[field].strip()
                for field in ("symbol", "headline", "transitNote", "signTitle", "dateAndDay"))
        and "muhuratUtc" in page and page["muhuratUtc"] is None
        and isinstance(page.get("fullSections"), list)
        and isinstance(page.get("summarySections"), list)
        and all(isinstance(sections, list) and len(sections) == len(order) and all(
            isinstance(section, dict) and section.get("kind") == kind
            and isinstance(section.get("lines"), list) and bool(section["lines"])
            for section, kind in zip(sections, order)
        ) for sections, order in (
            (page["fullSections"], FULL_ORDER), (page["summarySections"], FULL_ORDER[:-1])
        ))
    )


async def generate_horoscope(
    rashi_name: str, period: str, lang_code: str, date_text: str,
    rashi_id: str | None = None, *, forecast_date: str | date | None = None,
    city_name: str | None = None, latitude: float | None = None, longitude: float | None = None,
    now: datetime | None = None,
) -> dict:
    """Drop-in generation entry point for the uploaded service."""
    req = _request(rashi_name, period, lang_code, date_text, rashi_id, forecast_date, now)
    city = _city(city_name, latitude, longitude)
    return _attach_city(await _generate(req), req, city)


async def get_cached_horoscope(
    rashi_name: str, period: str, lang_code: str, date_text: str = "",
    rashi_id: str | None = None, *, read: CacheReader, upsert: CacheWriter,
    forecast_date: str | date | None = None, city_name: str | None = None,
    latitude: float | None = None, longitude: float | None = None,
    force_refresh: bool = False, now: datetime | None = None,
) -> dict:
    """API entry point with persistent cache. Callbacks use the forecast key."""
    req = _request(rashi_name, period, lang_code, date_text, rashi_id, forecast_date, now)
    city = _city(city_name, latitude, longitude)
    key = req.key

    if not force_refresh:
        saved = await read(key)
        if _usable(saved, req):
            return _attach_city(saved, req, city)

    loop = asyncio.get_running_loop()
    if loop not in _locks_by_loop:
        _locks_by_loop[loop] = WeakValueDictionary()
    locks = _locks_by_loop[loop]
    lock = locks.get(key)
    if lock is None:
        lock = locks[key] = asyncio.Lock()
    async with lock:
        saved = None if force_refresh else await read(key)
        if not _usable(saved, req):
            saved = await _generate(req)
            # Use an atomic upsert and a unique key in the shared database.
            await upsert(key, copy.deepcopy(saved))

    return _attach_city(saved, req, city)
