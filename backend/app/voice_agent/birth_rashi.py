"""Collect birth facts for one voice conversation and compute the sidereal Moon sign."""
import re
from datetime import date, datetime, time, timedelta, timezone
from zoneinfo import ZoneInfo, ZoneInfoNotFoundError

from ..horoscope_engine import COPY, DIGITS, EPHEMERIS
from .app_help import BIRTH_RASHI as GUIDE

ACTION = "find_birth_rashi"
MONTHS = {name: number for number, names in enumerate(GUIDE["months"], 1) for name in names}
MONTH = "|".join(sorted(map(re.escape, MONTHS), key=len, reverse=True))
DAY = r"([0-9]{1,2})(?:st|nd|rd|th)?"
DAY_FIRST = re.compile(rf"(?<![0-9]){DAY}\s+({MONTH})[ ,]+([0-9]{{4}})(?![0-9])")
MONTH_FIRST = re.compile(rf"({MONTH})\s+{DAY}[ ,]+([0-9]{{4}})(?![0-9])")
ZONE_ID = re.compile(r"[A-Za-z_]+(?:/[A-Za-z_+0-9-]+)+")
SIGNS = COPY["signs"]
IMPLICIT = re.compile(GUIDE["implicit_uncertainty"].replace("{uncertain}", GUIDE["uncertain"]), re.I)


def matches(key, text):
    return re.search(GUIDE[key], text, re.I) is not None


def requested(text, pending):
    knows_topic = matches("sign_terms", text)
    uncertain = matches("uncertain", text)
    return ((pending == "ask_rashi" and IMPLICIT.fullmatch(text) is not None) or (knows_topic and uncertain)
            or (knows_topic and matches("discover", text) and not matches("reading", text))
            or (pending == "ask_rashi" and birth_date(text.translate(DIGITS))[0] is not None))


def birth_date(text):
    for pattern, order in ((GUIDE["date_iso"], "iso"), (GUIDE["date_numeric"], "numeric"),
                           (DAY_FIRST, "day"), (MONTH_FIRST, "month")):
        m = re.search(pattern, text)
        if not m:
            continue
        a, b, c = m.groups()
        if order == "iso":
            year, month, day = int(a), int(b), int(c)
        elif order == "numeric":
            year, day, month = int(c), int(a), int(b)
            if month > 12:
                day, month = month, day
            elif day <= 12 and day != month:
                return m, None
        else:
            day, month = (int(a), MONTHS[b]) if order == "day" else (int(b), MONTHS[a])
            year = int(c)
        try:
            value = date(year, month, day)
            return m, value if date(1850, 1, 1) <= value <= date.today() else None
        except ValueError:
            return m, None
    return None, None


def birth_time(text):
    for phrases in ("clock_phrases", "clock_words"):
        for word, value in GUIDE[phrases].items():
            text = re.sub(r"\b" + re.escape(word) + r"\b", value, text)
    for word, minute in GUIDE["clock_minutes"].items():
        text = re.sub(r"\b(\d{1,2})\s+" + re.escape(word) + r"\b", r"\g<1>:" + minute, text)
    for m in re.finditer(GUIDE["time"], text):
        prefix, h, minute, suffix = m.groups()
        if not (prefix or minute or suffix):
            continue
        hour = int(h)
        meridiem = (suffix or "").replace(".", "")
        if prefix or meridiem in ("am", "pm"):
            if not 1 <= hour <= 12:
                return True, None
            pm = meridiem == "pm" or prefix in ("दुपारी", "दोपहर", "रात्री", "रात", "संध्याकाळी", "शाम")
            hour = hour % 12 + 12 * pm
        elif not minute or (len(h) == 1 and 1 <= hour < 12):
            return True, None
        try:
            return True, time(hour, int(minute or 0)).isoformat(timespec="minutes")
        except ValueError:
            return True, None
    return False, None


def zone_id(text):
    if m := ZONE_ID.search(text):
        try:
            return ZoneInfo(m[0]).key
        except (ValueError, ZoneInfoNotFoundError):
            pass
    found = None
    for zone, terms in GUIDE["zones"].items():
        if re.search(r"(?:^|[\s,(])(?:" + terms + r")(?=$|[\s.,)!?।])", text, re.I):
            if found is not None:
                return None  # Multiple places in different zones need clarification.
            found = zone
    return found


def reply(text, locale, key, state=None, sign_index=None, **values):
    message = GUIDE["replies"][key][locale[:2]].format(**values)
    if sign_index is not None:
        action = {"type": "open_horoscope", "rashi_id": SIGNS[sign_index][0].lower(),
                  "rashi_name": values["sign"], "feature_key": "birth_rashi"}
        status = "action_ready"
    elif state is not None:
        action = {"type": ACTION}
        status = "needs_clarification"
    else:
        action = {"type": "none"}
        status = "answered"
    return {"transcript": text, "locale": locale, "response_text": message, "status": status,
            "action": action, "birth_details": state, "choices": []}


def turn(text, locale, prior=None):
    state = {k: v for k, v in (prior or {}).items() if k in ("date", "time", "zone", "step") and isinstance(v, str)}
    def ask(key, **values):
        return reply(text, locale, key, {**state, "step": key}, **values)

    query = text.casefold().translate(DIGITS)
    if (prior and matches("uncertain", query) and
            (matches("missing_date", query) or (state.get("step") == "date" and not matches("unknown_time", query)))):
        return reply(text, locale, "missing_date")
    if zone := zone_id(text):
        state["zone"] = zone
    if matches("unknown_time", query):
        state.pop("time", None)
    match, parsed_date = birth_date(query)
    if match:
        if parsed_date is None:
            state.pop("date", None)
            return ask("date")
        state["date"] = parsed_date.isoformat()
        query = query[:match.start()] + " " + query[match.end():]
    supplied_time, clock = birth_time(query)
    if supplied_time and clock is None:
        state.pop("time", None)
        return ask("invalid_time")
    if clock:
        state["time"] = clock
    try:
        day = date.fromisoformat(state.get("date", ""))
        if not date(1850, 1, 1) <= day <= date.today():
            raise ValueError
    except ValueError:
        state.pop("date", None)
        return ask("date" if prior or state else "start")
    try:
        location = ZoneInfo(state.get("zone", ""))
    except (ZoneInfoNotFoundError, ValueError):
        state.pop("zone", None)
        return ask("zone")
    name_index = 0 if locale.startswith("en") else 2
    def sign_at(instant):
        return int(EPHEMERIS.longitudes(instant.astimezone(timezone.utc))[1] // 30)
    if "time" in state:
        try:
            wall = datetime.combine(day, time.fromisoformat(state["time"]))
        except ValueError:
            state.pop("time")
            return ask("invalid_time")
        instants = [wall.replace(tzinfo=location, fold=fold).astimezone(timezone.utc) for fold in (0, 1)]
        valid = [instant for instant in instants if instant.astimezone(location).replace(tzinfo=None) == wall]
        if not valid:
            state.pop("time")
            return ask("invalid_time")
        first, last = sign_at(valid[0]), sign_at(valid[-1])
        if first != last:
            return reply(text, locale, "uncertain", first=SIGNS[first][name_index], last=SIGNS[last][name_index])
    else:
        start = datetime.combine(day, time.min, location)
        end = datetime.combine(day + timedelta(days=1), time.min, location).astimezone(timezone.utc)
        first, last = sign_at(start), sign_at(end - timedelta(microseconds=1))
        if first != last:
            values = {"first": SIGNS[first][name_index], "last": SIGNS[last][name_index]}
            if (matches("unknown_time", query) or
                    (state.get("step") in ("time", "invalid_time") and matches("uncertain", query))):
                return reply(text, locale, "uncertain", **values)
            return ask("time", **values)
    return reply(text, locale, "result", sign_index=first, sign=SIGNS[first][name_index])
