"""Mandir decisions. Values such as remaining ghee are resolved on the device."""
import json
import re
from pathlib import Path
from typing import Any, Dict, Optional

MANDIR_GUIDE = json.loads(Path(__file__).with_name("mandir_guide.json").read_text(encoding="utf-8"))
VALID_MANDIR_LABELS = frozenset(MANDIR_GUIDE["topics"].keys())

_MANDIR_CANCEL_RE = re.compile(
    r"(?:^|\s)(?:don't|don’t|do not|never|cancel|stop asking|forget|leave .+ quiet)\b|"
    r"(?:मत |नको|नका|रद्द|राहू दे|रहने दो|रहने दे)|"
    r"\b(?:mat|nako|rahu de|rehne do)\b",
    re.IGNORECASE,
)

_QUESTION_RE = re.compile(
    r"\b(?:how|where|which|what|explain|guide|help)\b|"
    r"कैसे|कसा|कसे|कशी|कहाँ|कुठे|किधर|काय|क्या|समझाओ|समजावून",
    re.IGNORECASE,
)

_UNAVAILABLE_RE = re.compile(
    r"\b(?:tilak|kumkum|ticket|book|reserve|purchase|order|buy|prasad delivery|aarti pass|vip darshan)\b|"
    r"तिलक|कुंकू|टिकट|बुक",
    re.IGNORECASE,
)

_JYOT_NOUN_RE = re.compile(
    r"ghee|tup|diya|lamp|jyot|jyoti|kalash|घी|तूप|दिवा|दीया|दीपक|ज्योत|कलश",
    re.IGNORECASE,
)
_OFFER_CUE_RE = re.compile(
    r"offer|refill|top up|pour|fill|chadha|taka|घाल|भर|अर्पण|डाल|चढ़ा",
    re.IGNORECASE,
)
_READ_LEVEL_RE = re.compile(
    r"how much|level|percentage|still have|left|remaining ghee|shillak|"
    r"कितना|किती|status|शिल्लक|बचा|उरलं|बाकी|percent",
    re.IGNORECASE,
)
_READ_TIME_RE = re.compile(
    r"how long|run out|remaining|time left|कितनी देर|किती वेळ|किती तास|hours|timer",
    re.IGNORECASE,
)
_STREAK_RE = re.compile(
    r"streak|days|क्रम|सलग|दिवस|दिन|badge|आकडा|day count",
    re.IGNORECASE,
)


def mandir_reply(kind: str, locale: str = "mr-IN") -> str:
    lang = locale[:2] if locale[:2] in ("en", "hi", "mr") else "mr"
    topic = MANDIR_GUIDE["topics"].get(kind) or {}
    replies = topic.get("reply") or {}
    return replies.get(lang) or replies.get("en") or ""


def validated_mandir_action(proposal: Optional[Dict[str, Any]], text: str) -> Optional[Dict[str, str]]:
    """Validate and guard a Mandir model proposal against deterministic safety rules."""
    if not isinstance(proposal, dict):
        return None
    action = proposal.get("action")
    data = action if isinstance(action, dict) else proposal
    kind = data.get("type") if isinstance(data, dict) else action
    if not isinstance(kind, str) or kind not in VALID_MANDIR_LABELS:
        return None

    fold = text.strip().casefold()
    if _MANDIR_CANCEL_RE.search(fold) and kind != "stop_aarti":
        return {"type": "cancel"}
    if kind == "other" and _UNAVAILABLE_RE.search(fold):
        return {"type": "unavailable"}
    return {"type": kind}


def _resolve_jyot_follow_up(fold: str) -> Optional[str]:
    if _STREAK_RE.search(fold):
        return "read_streak"
    if _READ_TIME_RE.search(fold):
        return "read_time"
    if _READ_LEVEL_RE.search(fold):
        return "read_ghee"
    if _QUESTION_RE.search(fold):
        return "explain_ghee"
    if _OFFER_CUE_RE.search(fold):
        return "offer_ghee"
    if any(k in fold for k in ("refill", "fill", "pour", "offer", "full", "भरो", "भरा", "डालो", "घात", "भर")):
        return "offer_ghee"
    if any(k in fold for k in ("left", "level", "percent", "kitna", "kiti", "शिल्लक", "बचा", "उरलं", "बाकी")):
        return "read_ghee"
    return None


def _resolve_offering_follow_up(fold: str) -> Optional[str]:
    if any(k in fold for k in ("ghee", "tup", "diya", "lamp", "घी", "तूप", "दिवा", "दीया")):
        return "offer_ghee"
    if any(k in fold for k in ("flower", "phool", "pushpanjali", "फूल", "फुले", "पुष्पांज", "हार")):
        return "offer_flowers"
    if any(k in fold for k in ("naivedya", "bhog", "food", "नैवेद्य", "भोग")):
        return "offer_food"
    return None


def _resolve_aarti_follow_up(fold: str) -> Optional[str]:
    if any(k in fold for k in ("close", "stop", "put away", "band", "बंद", "हटा", "थांब")):
        return "stop_aarti"
    if any(k in fold for k in ("status", "open?", "started", "चालू", "खुली", "suru", "running")):
        return "read_aarti"
    if _QUESTION_RE.search(fold) or any(k in fold for k in ("how", "explain", "कैसे", "कसा", "समझा")):
        return "explain_aarti"
    if any(k in fold for k in ("lyrics", "verse", "video", "पद्य", "कडवे", "बोल", "व्हिडिओ")):
        return "explain_player"
    if any(k in fold for k in ("open", "start", "begin", "खोल", "उघड", "शुरू", "सुरू", "चालू कर")):
        return "start_aarti"
    return None


def _resolve_food_follow_up(fold: str) -> Optional[str]:
    if any(k in fold for k in ("already", "is there", "have i", "status", "आधीच", "रखा", "ठेवला", "placed")):
        return "read_food"
    if _QUESTION_RE.search(fold) or any(k in fold for k in ("how", "explain", "कैसे", "कसा")):
        return "explain_food"
    if any(k in fold for k in ("place", "offer", "lagao", "theva", "लगा", "ठेव", "रख", "अर्पण", "chadha")):
        return "offer_food"
    return None


def _resolve_deity_follow_up(fold: str) -> Optional[str]:
    if any(k in fold for k in ("which", "who", "name", "seeing", "seated", "कौन", "कोण", "विराजमान", "current")):
        return "read_deity"
    if _QUESTION_RE.search(fold) or any(k in fold for k in ("how", "explain", "कैसे", "कसा")):
        return "explain_deity"
    if any(k in fold for k in ("change", "switch", "replace", "pick", "choose", "बदल", "चुन", "निवड", "खोल", "उघड")):
        return "change_deity"
    return None


def classify_mandir_deterministic(text: str, *, pending_action: str | None = None) -> Dict[str, str]:
    """Deterministic Mandir intent classifier for offline/no-MLX servers."""
    fold = " ".join(text.strip().casefold().split())
    if not fold:
        return {"type": "other"}
    if _MANDIR_CANCEL_RE.search(fold):
        if any(k in fold for k in ("thali", "aarti", "ताट", "थाली", "आरती")) and any(
            k in fold for k in ("stop", "close", "put away", "band", "बंद", "हटा")
        ):
            return {"type": "stop_aarti"}
        return {"type": "cancel"}

    if _UNAVAILABLE_RE.search(fold):
        return {"type": "unavailable"}

    # Prefer a short follow-up answer; otherwise fall through so a new full
    # command is not trapped in clarify.
    if pending_action == "clarify_jyot":
        follow = _resolve_jyot_follow_up(fold)
        if follow:
            return {"type": follow}
    if pending_action == "clarify_aarti":
        follow = _resolve_aarti_follow_up(fold)
        if follow:
            return {"type": follow}
    if pending_action == "clarify_food":
        follow = _resolve_food_follow_up(fold)
        if follow:
            return {"type": follow}
    if pending_action == "clarify_deity":
        follow = _resolve_deity_follow_up(fold)
        if follow:
            return {"type": follow}
    if pending_action == "clarify_offering":
        follow = _resolve_offering_follow_up(fold)
        if follow:
            return {"type": follow}

    is_q = bool(_QUESTION_RE.search(fold))

    if any(k in fold for k in ("streak", "क्रम", "सलग", "day count", "badge")) and not any(
        k in fold for k in ("jaap", "jap", "chant", "जप", "जाप", "नामजप")
    ):
        return {"type": "read_streak"}

    if _JYOT_NOUN_RE.search(fold):
        specific = _resolve_jyot_follow_up(fold)
        if specific and specific != "explain_ghee":
            return {"type": specific}
        if is_q:
            return {"type": "explain_ghee"}
        if _OFFER_CUE_RE.search(fold):
            return {"type": "offer_ghee"}
        # Ambiguous bare “ज्योत” / diya / ghee → ask what to do next.
        return {"type": "clarify_jyot"}

    if any(k in fold for k in ("bell", "ghanta", "ghanti", "घंटी", "घंटा", "घंटानाद")):
        return {"type": "explain_bell" if is_q else "ring_bell"}

    if any(k in fold for k in ("conch", "shankh", "शंख")):
        return {"type": "explain_conch" if is_q else "blow_conch"}

    if any(k in fold for k in ("flower", "petal", "garland", "pushpanjali", "phool", "फूल", "फुले", "पुष्पांज", "हार")):
        return {"type": "explain_flowers" if is_q else "offer_flowers"}

    if any(k in fold for k in ("naivedya", "bhog", "food", "नैवेद्य", "भोग")):
        specific = _resolve_food_follow_up(fold)
        if specific:
            return {"type": specific}
        if is_q:
            return {"type": "explain_food"}
        # Bare naivedya/bhog → ask place vs status vs how.
        return {"type": "clarify_food"}

    if any(k in fold for k in ("video", "verse", "lyrics", "sing myself", "manual singing", "पद्य", "कडवे", "व्हिडिओ", "वीडियो", "बोल")):
        return {"type": "explain_player"}

    if any(k in fold for k in ("thali", "aarti", "taat", "थाली", "ताट", "आरती", "arti")):
        specific = _resolve_aarti_follow_up(fold)
        if specific:
            return {"type": specific}
        if is_q:
            return {"type": "explain_aarti"}
        # Bare aarti/thali → ask open/close/status/how.
        return {"type": "clarify_aarti"}

    # Note: bare "darshan/दर्शन" is a home navigation cue (open Mandir), not a deity ask.
    if any(k in fold for k in ("deity", "devta", "dev", "murti", "देवता", "दैवत", "देव", "मूर्ति")):
        specific = _resolve_deity_follow_up(fold)
        if specific:
            return {"type": specific}
        if is_q:
            return {"type": "explain_deity"}
        # Bare deity → ask change vs name vs how.
        return {"type": "clarify_deity"}

    if any(k in fold for k in ("what can i do", "choices", "rituals", "seva", "सेवा", "करता येतं", "कर सकते")):
        return {"type": "overview"}
    if any(k in fold for k in ("offering", "अर्पण", "चढ़ाना", "चढ़ावा")):
        return {"type": "clarify_offering"}

    return {"type": "other"}
