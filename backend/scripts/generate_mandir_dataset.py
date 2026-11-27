#!/usr/bin/env python3
"""
Generate a large Mandir in-shrine voice dataset (~15k sensible rows).

Pattern for multi-action features:
- bare feature noun → clarify_* (ask what to do)
- specific cue → exact action (read/offer/start/stop/…)

Single-action features (bell/conch/flowers) keep bare → perform.
Held-out eval rows stay untouched.
"""

from __future__ import annotations

import json
import random
import re
from collections import Counter, defaultdict
from pathlib import Path

from voice_training_examples import speech_variants, transcript_key

ROOT = Path(__file__).resolve().parents[1]
GUIDE = json.loads((ROOT / "app/voice_agent/mandir_guide.json").read_text(encoding="utf-8"))
OUT_DIR = ROOT / "datasets" / "mandir"
PROMPT = GUIDE["prompt"]

# Feature keyword banks — bare multi-action nouns → clarify_*; else default act.
SINGLE_WORD = {
    "clarify_jyot": (
        "ghee", "tup", "diya", "lamp", "jyot", "jyoti", "kalash",
        "घी", "तूप", "दिवा", "दीया", "दीपक", "ज्योत", "कलश",
        "akhand", "अखंड", "अखंड ज्योत", "अखंड दिवा",
    ),
    "clarify_aarti": (
        "aarti", "arti", "thali", "taat", "आरती", "थाली", "ताट",
    ),
    "clarify_food": (
        "naivedya", "bhog", "food", "नैवेद्य", "भोग", "prasada", "प्रसाद",
    ),
    "clarify_deity": (
        "deity", "devta", "devata", "murti", "देवता", "दैवत", "मूर्ति",
    ),
    "clarify_offering": (
        "offering", "offerings", "अर्पण", "चढ़ावा", "चढावा",
    ),
    "offer_ghee": (
        "refill", "pour ghee", "fill lamp", "ghee chadhao", "तूप घाला", "घी डालो",
    ),
    "ring_bell": (
        "bell", "ghanta", "ghanti", "ghantanad", "ghantanād",
        "घंटी", "घंटा", "घंटानाद", "नाद",
    ),
    "blow_conch": (
        "conch", "shankh", "shankha", "shankhnaad", "शंख", "शंखनाद",
    ),
    "offer_flowers": (
        "flower", "flowers", "phool", "phule", "pushpanjali",
        "petal", "petals", "garland",
        "फूल", "फुले", "पुष्पांजलि", "पुष्पांजली", "हार", "पंखुड़ी", "पंखुड़ियाँ",
    ),
    "start_aarti": (
        "open thali", "start aarti", "थाली खोलो", "आरती सुरू करा", "taat ughada",
    ),
    "offer_food": (
        "place bhog", "lagao naivedya", "भोग ठेवा", "नैवेद्य लगाओ",
    ),
    "change_deity": (
        "change deity", "switch murti", "देवता बदला", "मूर्ति चुनो",
    ),
    "read_streak": (
        "streak", "क्रम", "सलग",
    ),
    "overview": (
        "seva", "sevas", "ritual", "rituals", "सेवा", "सेवाएँ", "सेवां",
    ),
    "explain_player": (
        "lyrics", "verse", "verses", "video", "पद्य", "कडवे", "बोल",
        "व्हिडिओ", "वीडियो",
    ),
    "unavailable": (
        "tilak", "kumkum", "ticket", "तिलक", "कुंकू", "कुंकुम", "टिकट",
        "abhishek", "अभिषेक",
    ),
}

GHEE = (
    "ghee", "tup", "diya", "lamp", "jyot", "jyoti", "kalash",
    "घी", "तूप", "दिवा", "दीया", "दीपक", "ज्योत", "कलश",
    "akhand diya", "akhand jyot", "eternal lamp", "ghee pot", "ghee kalash",
    "अखंड ज्योत", "अखंड दिवा", "अखंड दीया", "घी कलश",
)
BELL = SINGLE_WORD["ring_bell"] + ("temple bell", "मंदिर की घंटी", "मंदिर घंटा", "दोनों घंटियाँ")
CONCH = SINGLE_WORD["blow_conch"] + ("shankh naad", "conch shell")
FLOWERS = SINGLE_WORD["offer_flowers"] + ("flower offering", "फूल अर्पण", "फुले अर्पण")
FOOD = (
    "naivedya", "bhog", "food", "नैवेद्य", "भोग", "food offering", "प्रसाद भोग", "नैवेद्य भोग",
)
AARTI = (
    "aarti", "arti", "thali", "taat", "आरती", "थाली", "ताट",
    "aarti thali", "arti thali", "आरती थाली", "आरतीचे ताट", "aarti session",
)
DEITY = (
    "deity", "devta", "devata", "murti", "देवता", "दैवत", "मूर्ति",
    "seated deity", "temple murti", "virajman", "विराजमान",
)

OFFER_VERBS = (
    "offer", "refill", "pour", "fill", "top up", "chadhao", "chadha", "taka", "take",
    "do", "start", "open",
    "घालो", "घाला", "भरें", "भरा", "अर्पण करो", "अर्पण करा", "डाल दो", "डालो",
    "चढ़ाओ", "चढ़ा दो", "लाओ", "लावा",
)
RING_VERBS = (
    "ring", "sound", "play", "blow", "baja", "bajao", "vajva", "do",
    "वाजवा", "बजाओ", "बजा दो", "नाद करो", "नाद करा", "करो", "करा",
)
START_VERBS = (
    "start", "open", "begin", "chalu", "suru", "launch", "show",
    "शुरू करो", "सुरू करा", "चालू करो", "खोलो", "उघडा", "लावा", "दिखाओ", "दाखवा",
)
STOP_VERBS = (
    "stop", "close", "put away", "end", "band", "hata", "hide",
    "बंद करो", "बंद करा", "हटा दो", "थांबवा", "बंद कर दो", "बंद",
)
ASK = (
    "how", "what", "where", "which", "explain", "guide", "help", "tell",
    "कैसे", "कसा", "कसे", "कशी", "कहाँ", "कुठे", "क्या", "काय",
    "समझाओ", "समजावून", "बताओ", "सांगा", "कैसे करें", "कसे करायचे",
)
READ = (
    "how much", "status", "level", "kitna", "kiti", "remaining", "left",
    "कितना", "किती", "बाकी", "शिल्लक", "बचा", "उरलं", "batao", "sang", "check",
)
POLITE = (
    "", "please ", "pls ", "kindly ", "can you ", "could you ", "I want ", "I need ",
    "मुझे ", "मला ", "जरा ", "कृपया ", "थोड़ा ", "abhi ", "ata ", "now ",
)
SOFT_END = ("", " please", " now", " na", " करो", " करा", " दो", " दे", " ना")

CANCEL = (
    "don't", "do not", "never", "cancel", "mat", "nako", "नको", "मत", "रद्द",
    "रहने दो", "राहू दे", "please don't", "अभी मत", "आता नको", "stop asking",
)


def row(query: str, label: str) -> dict:
    return {
        "messages": [
            {"role": "system", "content": PROMPT},
            {"role": "user", "content": query},
            {"role": "assistant", "content": json.dumps({"action": {"type": label}}, ensure_ascii=False)},
        ]
    }


def polish(text: str) -> list[str]:
    text = " ".join(text.split())
    out = [text]
    for p in POLITE:
        if not p:
            continue
        out.append(f"{p}{text}".strip())
    for e in SOFT_END:
        if not e:
            continue
        out.append(f"{text}{e}".strip())
    return out


def expand(seeds: list[str], *, stt_limit: int = 6) -> list[str]:
    out, seen = [], set()
    for seed in seeds:
        for variant in speech_variants(seed, limit=stt_limit):
            for item in polish(variant):
                key = transcript_key(item)
                if not key or key in seen:
                    continue
                seen.add(key)
                out.append(item)
    return out


def combos(nouns, verbs, templates) -> list[str]:
    seeds = []
    for noun in nouns:
        for verb in verbs:
            for tmpl in templates:
                seeds.append(tmpl.format(noun=noun, verb=verb))
    return seeds


def build_seeds() -> dict[str, list[str]]:
    seeds: dict[str, list[str]] = defaultdict(list)

    # 1) Single-word / short keyword triggers — mandatory for every feature noun.
    for label, words in SINGLE_WORD.items():
        for w in words:
            seeds[label].append(w)
            seeds[label].append(w.capitalize() if w.isascii() else w)
            seeds[label].extend(polish(w))

    # 2) Perform rituals — combinatorial.
    seeds["offer_ghee"] += combos(
        GHEE, OFFER_VERBS,
        ("{verb} the {noun}", "{verb} {noun}", "{noun} {verb}", "mandir mein {noun} {verb}",
         "दीये में {noun} {verb}", "दिव्यात {noun} {verb}", "lamp {verb}", "{noun} seva"),
    )
    seeds["ring_bell"] += combos(
        BELL, RING_VERBS,
        ("{verb} the {noun}", "{verb} {noun}", "{noun} {verb}", "mandir ki {noun} {verb}",
         "दोनों {noun} {verb}", "{noun} seva"),
    )
    seeds["blow_conch"] += combos(
        CONCH, RING_VERBS,
        ("{verb} the {noun}", "{verb} {noun}", "{noun} {verb}", "do {noun}", "{noun} seva"),
    )
    seeds["offer_flowers"] += combos(
        FLOWERS, OFFER_VERBS,
        ("{verb} {noun}", "{verb} the {noun}", "{noun} {verb}", "भगवान को {noun} {verb}",
         "देवाला {noun} {verb}", "{noun} seva"),
    )
    seeds["offer_food"] += combos(
        FOOD, OFFER_VERBS + ("place", "lagao", "theva", "लगाओ", "ठेवा", "रखो"),
        ("{verb} {noun}", "{verb} the {noun}", "{noun} {verb}", "भगवान को {noun} {verb}",
         "देवासमोर {noun} {verb}", "{noun} seva"),
    )
    seeds["start_aarti"] += combos(
        AARTI, START_VERBS,
        ("{verb} the {noun}", "{verb} {noun}", "{noun} {verb}", "begin {noun}", "{noun} seva"),
    )
    seeds["stop_aarti"] += combos(
        AARTI, STOP_VERBS,
        ("{verb} the {noun}", "{verb} {noun}", "{noun} {verb}", "end {noun}"),
    )
    seeds["change_deity"] += combos(
        DEITY,
        ("change", "switch", "replace", "pick", "choose", "open", "show", "badlo", "badala",
         "बदलो", "बदला", "चुनो", "निवडा", "खोलो", "उघडा"),
        ("{verb} the {noun}", "{verb} {noun}", "{noun} {verb}", "let me {verb} {noun}",
         "{noun} picker", "{noun} list"),
    )

    # 3) Read / status — many unique sensible asks.
    for noun in ("ghee", "tup", "diya", "lamp", "jyot", "kalash", "घी", "तूप", "दिवा", "दीया", "ज्योत", "कलश"):
        for ask in READ:
            seeds["read_ghee"].append(f"{ask} {noun}")
            seeds["read_ghee"].append(f"{noun} {ask}")
        seeds["read_ghee"].extend([
            f"{noun} percentage", f"{noun} left", f"is {noun} full", f"{noun} kitna hai",
            f"{noun} कितना है", f"{noun} किती आहे",
        ])
    seeds["read_ghee"] += [
        "How much ghee is left?", "दीये में कितना घी है?", "दिव्यात किती तूप उरलंय?",
        "ghee level kitna hai", "दीये का percentage बताओ", "lamp status", "kalash level",
        "ज्योत शिल्लक", "ज्योत शिल्लक na", "diya shillak", "jyot leftover",
        "तूप शिल्लक", "घी बचा कितना", "lamp left",
    ]
    seeds["clarify_jyot"] += [
        "jyot", "diya", "ज्योत", "दिवा", "ghee", "kalash", "lamp", "अखंड ज्योत",
        "just jyot", "only diya", "केवल ज्योत", "फक्त दिवा", "about the lamp",
        "diya wala", "jyot wali baat", "ज्योत बद्दल", "दीये के बारे में",
    ]
    seeds["clarify_aarti"] += [
        "aarti", "thali", "taat", "आरती", "थाली", "ताट", "arti",
        "just aarti", "only thali", "केवल आरती", "फक्त ताट", "aarti wala",
        "आरती बद्दल", "थाली के बारे में",
    ]
    seeds["clarify_food"] += [
        "naivedya", "bhog", "नैवेद्य", "भोग", "food", "prasada",
        "just bhog", "only naivedya", "केवल भोग", "फक्त नैवेद्य",
        "भोग बद्दल", "नैवेद्य के बारे में",
    ]
    seeds["clarify_deity"] += [
        "deity", "devta", "murti", "देवता", "दैवत", "मूर्ति",
        "just deity", "only murti", "केवल देवता", "फक्त दैवत",
        "देवता बद्दल", "मूर्ति के बारे में",
    ]

    # Contrast pairs: same noun + specific cue → exact action (training signal).
    for noun in ("ज्योत", "दिवा", "jyot", "diya", "ghee", "lamp", "कलश", "तूप"):
        seeds["read_ghee"] += [f"{noun} शिल्लक", f"{noun} शिल्लक na", f"{noun} left", f"शिल्लक {noun}", f"{noun} बचा"]
        seeds["read_time"] += [f"{noun} कितनी देर", f"{noun} किती वेळ", f"{noun} time left", f"timer {noun}"]
        seeds["offer_ghee"] += [f"{noun} भरो", f"{noun} भर", f"refill {noun}", f"{noun} घाला", f"fill {noun}"]
        seeds["read_streak"] += [f"{noun} streak", f"{noun} क्रम", f"सलग {noun}"]
        seeds["explain_ghee"] += [f"{noun} कैसे", f"{noun} कसा", f"how {noun}", f"explain {noun}"]

    for noun in ("आरती", "थाली", "ताट", "aarti", "thali", "taat", "arti"):
        seeds["start_aarti"] += [f"{noun} खोलो", f"{noun} उघडा", f"open {noun}", f"start {noun}", f"{noun} सुरू"]
        seeds["stop_aarti"] += [f"{noun} बंद", f"close {noun}", f"stop {noun}", f"{noun} बंद करो", f"{noun} हटा"]
        seeds["read_aarti"] += [f"{noun} status", f"{noun} चालू आहे का", f"is {noun} open", f"{noun} खुली है"]
        seeds["explain_aarti"] += [f"{noun} कैसे", f"{noun} कसा", f"how {noun}", f"explain {noun}"]

    for noun in ("भोग", "नैवेद्य", "bhog", "naivedya", "food"):
        seeds["offer_food"] += [f"{noun} ठेवा", f"{noun} लगाओ", f"place {noun}", f"offer {noun}", f"{noun} रखो"]
        seeds["read_food"] += [f"{noun} status", f"{noun} रखा है", f"{noun} ठेवला आहे का", f"is {noun} placed"]
        seeds["explain_food"] += [f"{noun} कैसे", f"{noun} कसा", f"how {noun}", f"explain {noun}"]

    for noun in ("देवता", "दैवत", "मूर्ति", "deity", "devta", "murti"):
        seeds["change_deity"] += [f"{noun} बदला", f"{noun} बदलो", f"change {noun}", f"switch {noun}", f"{noun} चुनो"]
        seeds["read_deity"] += [f"{noun} कोण", f"{noun} कौन", f"which {noun}", f"who is {noun}", f"current {noun}"]
        seeds["explain_deity"] += [f"{noun} कैसे बदलें", f"{noun} कसा बदलायचा", f"how {noun}", f"explain {noun}"]

    # Distinctive short follow-ups after clarify (avoid ultra-ambiguous words like "open").
    seeds["read_ghee"] += ["शिल्लक", "शिल्लक na", "बचा कितना", "उरलं किती", "ghee level"]
    seeds["offer_ghee"] += ["भरो", "भरा", "refill ghee", "तूप घाला", "घी डालो"]
    seeds["read_time"] += ["किती वेळ पुरेल", "कितनी देर जलेगी", "burn time left"]
    seeds["start_aarti"] += ["थाली खोलो", "ताट उघडा", "start thali", "आरती सुरू"]
    seeds["stop_aarti"] += ["थाली बंद", "ताट बंद", "close thali", "आरती बंद"]
    seeds["read_aarti"] += ["थाली status", "ताट चालू आहे का", "is thali open"]
    seeds["offer_food"] += ["भोग ठेवा", "नैवेद्य लगाओ", "place bhog"]
    seeds["read_food"] += ["भोग आधीच आहे का", "नैवेद्य रखा है क्या", "bhog status"]
    seeds["change_deity"] += ["देवता बदला", "मूर्ति बदलो", "change murti"]
    seeds["read_deity"] += ["कोणते दैवत", "कौन देवता", "which murti", "current deity"]

    for phrase in (
        "how long until lamp runs out", "remaining burn time", "time left on diya",
        "diya kab khatam", "jyot kiti vel", "hours left", "burn countdown",
        "मेरा दीया कितनी देर और जलेगा", "माझा दिवा अजून किती वेळ जळेल",
        "दीपक का time left", "ghee kab khatam hoga", "kalash कितने घंटे",
        "when will lamp empty", "akhand diya timer", "ज्योत कितनी देर",
    ):
        seeds["read_time"].append(phrase)

    for phrase in (
        "lamp streak", "diya streak", "jyot streak", "streak days", "continuous days",
        "मेरी अखंड ज्योत कितने दिनों से", "माझ्या दिव्याचे सलग दिवस",
        "diya ka streak", "क्रम कितने दिन", "सलग दिवस किती", "badge days",
        "akhand streak", "mandir streak", "day count", "सलग ज्योत",
    ):
        seeds["read_streak"].append(phrase)

    for phrase in (
        "naivedya status", "bhog status", "is bhog placed", "have I offered food",
        "क्या भोग रखा है", "नैवेद्य ठेवला आहे का", "food offering done",
        "भोग लावला का", "check naivedya", "is prasada there", "देवासमोर भोग आहे का",
        "already offered naivedya", "भोग अभी है क्या",
    ):
        seeds["read_food"].append(phrase)

    for phrase in (
        "is thali open", "aarti status", "thali on", "is aarti running",
        "क्या थाली खुली है", "ताट चालू आहे का", "aarti session chalu",
        "thali mode", "आरती चालू आहे का", "read thali status", "taat open?",
    ):
        seeds["read_aarti"].append(phrase)

    for phrase in (
        "which deity", "who is seated", "current deity", "murti name",
        "अभी कौन विराजमान", "सध्या कोणते दैवत", "kaun sa dev", "seated murti",
        "देवता का नाम", "दैवताचे नाव", "who is in mandir", "temple murti who",
    ):
        seeds["read_deity"].append(phrase)

    # 4) Explain / how-to
    explain_map = {
        "explain_ghee": ("ghee", "diya", "kalash", "tup", "घी", "दिवा", "कलश", "refill", "streak with ghee"),
        "explain_bell": ("bell", "ghanta", "ghanti", "घंटी", "घंटानाद"),
        "explain_conch": ("conch", "shankh", "शंख", "शंखनाद"),
        "explain_flowers": ("flowers", "pushpanjali", "phool", "फूल", "पुष्पांजलि"),
        "explain_food": ("naivedya", "bhog", "नैवेद्य", "भोग", "food offering"),
        "explain_aarti": ("aarti thali", "thali", "taat", "आरती थाली", "ताट"),
        "explain_deity": ("deity picker", "change deity", "devta list", "देवता बदल", "मूर्ति चुन"),
        "explain_player": ("lyrics", "verse", "video", "sing myself", "कडवे", "पद्य", "वीडियो"),
    }
    for label, topics in explain_map.items():
        for topic in topics:
            for ask in ASK:
                seeds[label].append(f"{ask} {topic}")
                seeds[label].append(f"{topic} {ask}")
            seeds[label].append(f"explain {topic}")
            seeds[label].append(f"{topic} कैसे")
            seeds[label].append(f"{topic} कसा")

    seeds["overview"] += [
        "what can I do", "mandir options", "ritual list", "seva list", "help mandir",
        "मंदिर में क्या कर सकते", "देवघरात काय करता येतं", "available rituals",
        "shrine features", "virtual mandir help", "यहाँ क्या-क्या है", "सेवा सूची",
        "darshan ke baad kya", "list actions", "mandir guide", "overview",
    ]

    seeds["clarify_offering"] += [
        "offer something", "make an offering", "kuch chadhao", "अर्पण करो",
        "चढ़ावा", "do offering", "काहीतरी अर्पण", "सेवा अर्पण", "offer please",
    ]

    seeds["clarify"] += [
        "that one", "this one", "do it", "वो करो", "ते करा", "same", "continue",
        "वही", "तेच", "yes that", "previous one", "उसी को",
    ]

    # 5) Cancel = cancel cue + feature word (single-feature aware).
    cancel_targets = (
        "bell", "ghanti", "घंटी", "shankh", "शंख", "ghee", "घी", "diya", "flowers",
        "फूल", "bhog", "भोग", "naivedya", "pushpanjali", "aarti", "thali", "deity", "devta",
    )
    for noun in cancel_targets:
        for cue in CANCEL:
            seeds["cancel"].append(f"{cue} {noun}")
            seeds["cancel"].append(f"{noun} {cue}")

    seeds["unavailable"] += [
        "tilak", "kumkum", "charan sparsh", "jalabhishek", "dugdhabhishek",
        "ticket", "vip darshan", "prasad delivery", "aarti pass",
        "तिलक", "कुंकू", "अभिषेक", "चरण स्पर्श", "टिकट",
        "turn off diya", "extinguish lamp", "diya बुझाओ", "विझवा",
        "book darshan", "buy puja", "order flowers delivery",
    ]

    seeds["other"] += [
        "horoscope", "rashifal", "panchang", "kundali", "jaap", "calendar",
        "premium", "language", "feedback", "grahan", "weather", "instagram",
        "राशिफल", "पंचांग", "कुंडली", "नामजप", "कैलेंडर",
        "open panchang", "start jaap", "play chalisa", "show premium",
        "fly to tokyo", "what's cricket score",
    ]

    # Guide examples stay authoritative.
    for label, info in GUIDE["topics"].items():
        seeds[label].extend(info.get("examples") or [])

    return {label: list(dict.fromkeys(vals)) for label, vals in seeds.items()}


def classify_split(query: str, label: str, rng: random.Random) -> str:
    has_latin = bool(re.search(r"[A-Za-z]", query))
    has_deva = bool(re.search(r"[\u0900-\u097f]", query))
    if has_latin and has_deva:
        return "mixed"
    return "mixed" if rng.random() < 0.25 else "plain"


def main() -> None:
    rng = random.Random(42)
    OUT_DIR.mkdir(parents=True, exist_ok=True)

    held_keys = {
        transcript_key(json.loads(line)["messages"][1]["content"])
        for line in (OUT_DIR / "held_out.jsonl").read_text(encoding="utf-8").splitlines()
        if line.strip()
    }

    seed_map = build_seeds()
    by_label: dict[str, list[str]] = {}
    perform = {
        "offer_ghee", "ring_bell", "blow_conch", "offer_flowers", "offer_food",
        "start_aarti", "stop_aarti", "change_deity",
    }
    for label, seed_list in seed_map.items():
        limit = 8 if label in perform else 5
        by_label[label] = expand(seed_list, stt_limit=limit)

    # Aim for ~15k unique sensible rows; denser on clarify + contrast actions.
    clarify = {
        "clarify_jyot", "clarify_aarti", "clarify_food", "clarify_deity",
        "clarify_offering",
    }
    floors = {label: (280 if label in perform else 220) for label in by_label}
    ceilings = {label: (480 if label in perform else 420) for label in by_label}
    for label in clarify:
        floors[label] = 320
        ceilings[label] = 520
    for label in ("cancel", "unavailable", "other", "clarify", "overview"):
        floors[label] = 200
        ceilings[label] = 360
    TARGET = 15000

    wrappers = (
        "please {}", "{} please", "{} now", "abhi {}", "ata {}",
        "कृपया {}", "जरा {}", "{} कर दो", "{} करा", "do {}",
        "mandir {}", "{} in mandir", "देवघर {}", "{} सेवा",
        "quick {}", "{} once", "eka {}", "एक {}",
    )

    final: dict[str, list[str]] = {}
    for label, queries in by_label.items():
        cleaned, seen = [], set()
        for q in queries:
            key = transcript_key(q)
            if not key or key in held_keys or key in seen:
                continue
            seen.add(key)
            cleaned.append(q)
        rng.shuffle(cleaned)

        floor, ceil = floors[label], ceilings[label]
        base = list(cleaned)
        i = 0
        while len(cleaned) < floor and base:
            wrapped = wrappers[i % len(wrappers)].format(base[i % len(base)])
            key = transcript_key(wrapped)
            i += 1
            if not key or key in seen or key in held_keys:
                if i > floor * 12:
                    break
                continue
            seen.add(key)
            cleaned.append(wrapped)
        final[label] = cleaned[:ceil]

    plain_rows, mixed_rows, exhaustive = [], [], []
    for label, queries in final.items():
        for q in queries:
            item = row(q, label)
            exhaustive.append(item)
            (mixed_rows if classify_split(q, label, rng) == "mixed" else plain_rows).append(item)

    # If still under target, add more unique single-word + soft prefix variants.
    if len(exhaustive) < TARGET:
        existing = {transcript_key(r["messages"][1]["content"]) for r in exhaustive}
        extras = []
        for label, words in SINGLE_WORD.items():
            for w in words:
                for pref in ("", "please ", "abhi ", "जरा ", "कृपया ", "do ", "show ", "open ", "just ", "only "):
                    for end in ("", " now", " na", " करो", " करा", " दो", " दे"):
                        q = f"{pref}{w}{end}".strip()
                        key = transcript_key(q)
                        if not key or key in existing or key in held_keys:
                            continue
                        existing.add(key)
                        extras.append(row(q, label))
        rng.shuffle(extras)
        need = TARGET - len(exhaustive)
        exhaustive.extend(extras[: max(0, need)])
        for item in extras[: max(0, need)]:
            q = item["messages"][1]["content"]
            (mixed_rows if classify_split(q, "", rng) == "mixed" else plain_rows).append(item)

    rng.shuffle(plain_rows)
    rng.shuffle(mixed_rows)
    rng.shuffle(exhaustive)

    # Always keep every bare feature keyword row, then fill to target with balance.
    must_keep = []
    rest = []
    must_keys = set()
    for item in exhaustive:
        q = item["messages"][1]["content"]
        if len(q.split()) == 1:
            key = transcript_key(q)
            if key not in must_keys:
                must_keys.add(key)
                must_keep.append(item)
                continue
        rest.append(item)

    # Re-inject every SINGLE_WORD token explicitly (guarantees training coverage).
    for label, words in SINGLE_WORD.items():
        for w in words:
            key = transcript_key(w)
            if not key or key in must_keys or key in held_keys:
                continue
            must_keys.add(key)
            must_keep.append(row(w, label))

    by = defaultdict(list)
    for item in rest:
        lab = json.loads(item["messages"][-1]["content"])["action"]["type"]
        by[lab].append(item)
    for lab in by:
        rng.shuffle(by[lab])

    trimmed = list(must_keep)
    seen = {transcript_key(r["messages"][1]["content"]) for r in trimmed}
    while len(trimmed) < TARGET and any(by.values()):
        progressed = False
        for lab in list(by.keys()):
            while by[lab]:
                item = by[lab].pop()
                key = transcript_key(item["messages"][1]["content"])
                if key in seen:
                    continue
                seen.add(key)
                trimmed.append(item)
                progressed = True
                break
            if len(trimmed) >= TARGET:
                break
        if not progressed:
            break
    exhaustive = trimmed
    rng.shuffle(exhaustive)
    plain_rows = [r for r in exhaustive if classify_split(r["messages"][1]["content"], "", rng) == "plain"]
    mixed_rows = [r for r in exhaustive if classify_split(r["messages"][1]["content"], "", rng) == "mixed"]

    (OUT_DIR / "exhaustive.jsonl").write_text(
        "".join(json.dumps(r, ensure_ascii=False) + "\n" for r in exhaustive),
        encoding="utf-8",
    )
    (OUT_DIR / "plain.jsonl").write_text(
        "".join(json.dumps(r, ensure_ascii=False) + "\n" for r in plain_rows),
        encoding="utf-8",
    )
    (OUT_DIR / "mixed.jsonl").write_text(
        "".join(json.dumps(r, ensure_ascii=False) + "\n" for r in mixed_rows),
        encoding="utf-8",
    )

    counts = Counter(
        json.loads(r["messages"][-1]["content"])["action"]["type"] for r in exhaustive
    )
    singles = sum(
        1 for r in exhaustive
        if len(r["messages"][1]["content"].split()) == 1
    )
    print(f"Exhaustive Mandir dataset: {len(exhaustive)} rows")
    print(f"  plain={len(plain_rows)} mixed={len(mixed_rows)} held_out={len(held_keys)} (unchanged)")
    print(f"  labels={len(counts)} single_word_rows≈{singles}")
    for label, n in counts.most_common():
        print(f"    {label}: {n}")
    print(f"Saved {OUT_DIR / 'exhaustive.jsonl'}")


if __name__ == "__main__":
    main()
