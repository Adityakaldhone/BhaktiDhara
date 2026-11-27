"""
Deterministic-first, LLM-assisted Intent Resolver for BhaktiDhara Voice Agent.
Fully self-hosted and grounded in local catalog data.
"""

import os
import re
import json
import sqlite3
from contextlib import closing
import httpx

from . import app_help, birth_rashi
from .prompt import HOME_PROMPT, SYSTEM_PROMPT, RASHI_FOLLOWUP_PROMPT, feature_prompt
from pathlib import Path
from typing import Dict, Any, Optional, List

DATA_DIR = Path(__file__).resolve().parent.parent.parent / "data"
DB_PATH = DATA_DIR / "voice_agent_catalog.db"
JSON_PATH = DATA_DIR / "voice_knowledge.json"
OLLAMA_HOST = os.environ.get("OLLAMA_HOST", "http://localhost:11434")
OLLAMA_MODEL = os.environ.get("OLLAMA_MODEL", "bhaktidhara-voice:latest")

# Vedic slug → Flutter kAllRashis id
VEDIC_TO_APP_RASHI = {
    "mesh": "aries",
    "vrishabh": "taurus",
    "mithun": "gemini",
    "kark": "cancer",
    "singh": "leo",
    "kanya": "virgo",
    "tula": "libra",
    "vrishchik": "scorpio",
    "dhanu": "sagittarius",
    "makar": "capricorn",
    "kumbh": "aquarius",
    "meen": "pisces",
}

# Load memory cache of Knowledge
_KNOWLEDGE_CACHE = None


def normalize_rashi_id(raw: Optional[str]) -> Optional[str]:
    """Normalize Vedic or English rashi tokens to Flutter catalog ids."""
    if not raw:
        return None
    token = raw.strip().lower()
    if token in VEDIC_TO_APP_RASHI.values():
        return token
    if token in VEDIC_TO_APP_RASHI:
        return VEDIC_TO_APP_RASHI[token]
    for vedic, app_id in VEDIC_TO_APP_RASHI.items():
        if vedic in token or app_id in token:
            return app_id
    return token

def get_knowledge() -> Dict[str, Any]:
    global _KNOWLEDGE_CACHE
    if _KNOWLEDGE_CACHE is None and JSON_PATH.exists():
        with open(JSON_PATH, "r", encoding="utf-8") as f:
            _KNOWLEDGE_CACHE = json.load(f)
    return _KNOWLEDGE_CACHE or {"rashis": [], "features": [], "aartis": []}

def detect_locale(text: str, hint: Optional[str] = None) -> str:
    """Infers locale: mr-IN (default), hi-IN, or en-IN based on script and keywords."""
    if hint in ["mr-IN", "hi-IN", "en-IN"]:
        return hint
    text_lower = text.lower()
    
    # Hindi distinctive words (check first)
    hi_markers = ["दिखाओ", "खोलो", "सुनाओ", "बताओ", "मेरा", "मेरी", "कीजिए", "राशिफल", "चलाओ", "क्या", "है", "का", "की", "के", "किए"]
    for m in hi_markers:
        if m in text_lower:
            return "hi-IN"

    # Marathi distinctive suffixes & words
    mr_markers = ["दाखवा", "उघडा", "लावा", "ऐकायची", "सांगा", "माझे", "आहे", "वाजवा", "करायचा", "कशी", "करा", "राशीचे", "चा", "ची", "चे"]
    for m in mr_markers:
        if m in text_lower:
            return "mr-IN"
            
    # Check if Devanagari script is present
    has_devanagari = any('\u0900' <= char <= '\u097f' for char in text)
    if has_devanagari:
        return "mr-IN"
    return "en-IN"

def match_rashi(query: str) -> Optional[Dict[str, Any]]:
    """Checks for explicit Rashi reference with flexible transliteration matching."""
    q = query.lower()
    knowledge = get_knowledge()
    for rashi in knowledge.get("rashis", []):
        for alias in rashi["aliases"]:
            if _alias_in_query(alias, q) or any(
                _alias_in_query(alias + suffix, q) for suffix in ("च्या", "चे", "ला")
            ):
                return rashi

    # Phonetic normalization for Indian English / Romanized spellings
    q_norm = q.replace("vrush", "vrish").replace("vris", "vrish").replace("sh", "s")
    for rashi in knowledge.get("rashis", []):
        for alias in rashi["aliases"]:
            a_norm = alias.lower().replace("vrush", "vrish").replace("vris", "vrish").replace("sh", "s")
            if _alias_in_query(a_norm, q_norm):
                return rashi

    return None

def _alias_in_query(alias: str, query: str) -> bool:
    """True if alias appears as a whole token (not a substring of a longer word).

    Prevents 'jyot' matching 'jyotiba' / 'ज्योत' matching 'ज्योतिबा'.
    """
    a = alias.lower().strip()
    if not a:
        return False
    q = query.lower()
    # ASCII + Devanagari letter boundaries (\\b alone fails on Devanagari).
    pattern = (
        r"(?<![\w\u0900-\u097f])"
        + re.escape(a)
        + r"(?![\w\u0900-\u097f])"
    )
    return re.search(pattern, q) is not None


FEATURE_SPOKEN_ALIASES = {
    "grahan": ("solar eclipse", "lunar eclipse", "सूर्यग्रहण", "चंद्रग्रहण"),
    "granth": ("holy books", "holy book", "scripture library"),
    "greetings": ("good morning cards", "cards that say good morning", "good night cards", "cards that say good night", "शुभकामना", "शुभकामनाएं", "शुभकामनाएँ", "सुप्रभात", "शुभ रात्री", "शुभ रात्रि", "शुभेच्छापत्रे"),
    "ishta_devta": ("आराध्य दैवत", "उपास्य दैवत", "आराध्य देवता", "personal deity", "isht dev"),
}


def match_feature(query: str) -> Optional[Dict[str, Any]]:
    """Checks for core app features like mandir, panchang, jaap, etc."""
    knowledge = get_knowledge()
    # Prefer longer aliases so "akhand diya" wins over bare "diya".
    candidates: List[tuple] = []
    for feat in knowledge.get("features", []):
        for alias in (*feat["aliases"], *FEATURE_SPOKEN_ALIASES.get(feat["key"], ())):
            candidates.append((alias, feat))
    candidates.sort(key=lambda x: len(x[0]), reverse=True)
    for alias, feat in candidates:
        if _alias_in_query(alias, query):
            return feat
    return None


JAAP_ALIASES = (
    "jaap", "jap", "japa", "naamjaap", "namjaap", "naamjap", "namjap",
    "naam jaap", "nam jaap", "naam jap", "nam jap", "chant", "chanting",
    "जप", "जाप", "जपमाळ", "जपमाला", "नामजप", "नाम जप", "नामजाप", "नाम जाप",
    "जपाचा", "जपाची", "जपाचे", "जपासाठी", "नामजपासाठी", "नामजपाचा", "नामजपाची",
    "mala open", "open mala", "mala kholo", "जप माळ", "माळ उघडा", "माला खोलो",
)


JAAP_COUNTER_TERMS = ("mala", "माळ", "माला", "mantra", "मंत्र")
JAAP_STATS_TERMS = (
    "jaap stats", "jap stats", "japa stats", "chanting stats", "jaap history", "jap history",
    "japa history", "chanting history", "chanting streak", "jaap streak", "jap streak",
    "japa streak", "meri sadhana", "maajhi sadhana",
    "मेरी साधना", "माझी साधना", "जपाचा इतिहास", "जपाची आकडेवारी",
    "जाप का इतिहास", "जप किती", "जाप कितने", "किती जप", "कितना जप",
    "कितनी बार नाम जपा", "नामस्मरणाची मोजणी", "नामजपाचा इतिहास",
)
JAAP_UNSUPPORTED_PATTERN = re.compile(
    r"\b(?:don['’]t|do not|never|stop|cancel|pause|reset|resume|delete|clear|remind|"
    r"meaning|mean|translate|translation|explain|benefits|mat karo|"
    r"mat karna|nako|set|target|goal|automatically|export|and then)\b"
    r"|(?:और फिर|आणि मग|मत |नको|करू नका|काढून टाका|मिटवा|मिटाओ|बंद करा|बंद करो|रीसेट|अर्थ|मतलब|लक्ष्य)"
    r"|\d+\s*(?:times|repetitions|rounds|जप|जाप|बार|वेळा|माळा)"
)
CALENDAR_TERMS = (
    "festival calendar", "festival dates", "upcoming festivals",
    "tyohar", "san utsav", "दिनदर्शिका", "कॅलेंडर", "सणवार", "सण उत्सव",
    "त्योहार", "त्योहारों", "त्यौहार", "त्यौहारों", "पर्व", "कैलेंडर", "सण",
)


# Jaap mantra ids from Flutter JaapMantraCatalog + spoken aliases.
JAAP_MANTRA_ALIASES: List[tuple] = [
    ("radha", ["radha", "raadha", "राधा", "राधे", "radhe", "radhe radhe"]),
    ("swami_samarth", ["swami samarth", "स्वामी समर्थ", "samarth"]),
    ("shri_ram", ["shri ram", "shree ram", "sri ram", "श्री राम", "श्रीराम", "sitaram"]),
    ("ganesha", ["ganesha", "ganesh", "ganpati", "ganapataye", "गणपतये", "गणेश", "गणपती", "गणपति"]),
    ("om_namah_shivaya", ["om namah shivaya", "namah shivaya", "mahadev", "शिव", "शिवाय", "नमः शिवाय", "om namah shivay"]),
    ("vasudevaya", ["vasudevaya", "vasudeva", "वासुदेवाय", "विष्णु", "विष्णू", "vishnu"]),
    ("jai_shri_ram", ["jai shri ram", "jai sri ram", "जय श्री राम", "जय श्रीराम"]),
    ("hare_krishna", ["hare krishna", "हरे कृष्ण", "mahamantra"]),
    ("om_namo_narayanaya", ["narayanaya", "narayana", "नारायण", "नारायणाय"]),
    ("gayatri", ["gayatri", "bhur bhuvah svah", "भूर्भुवः स्वः", "गायत्री"]),
    ("shani_mantra", ["shani", "neelanjana samabhasam", "नीलांजन समाभासं", "शनि", "शनी"]),
    ("hanuman", ["hanuman", "हनुमान", "bajrang", "hanumate", "हनुमते"]),
    ("durga", ["durga", "दुर्गा", "ambaji", "ambe", "durgayai", "दुर्गायै"]),
    ("datta", ["datta", "दत्त", "dattatreya"]),
    ("vitthal", ["vitthal", "vithoba", "विठ्ठल", "pandurang", "ram krishna hari", "राम कृष्ण हरी", "विट्ठल"]),
    ("sai_ram", ["sai", "sai ram", "साई", "saibaba", "sai baba", "साईबाबा", "साईं बाबा"]),
    ("mahamrityunjaya", ["mahamrityunjaya", "महामृत्युंजय", "tryambakam", "त्र्यम्बकं", "त्र्यंबकं"]),
]


def match_jaap_mantra(query: str) -> Optional[str]:
    """Return JaapMantraCatalog id if the utterance names a mantra/deity."""
    q = query.lower()
    # Longer aliases first
    pairs = []
    for mid, aliases in JAAP_MANTRA_ALIASES:
        for a in aliases:
            pairs.append((a.lower(), mid))
    pairs.sort(key=lambda x: len(x[0]), reverse=True)
    for alias, mid in pairs:
        if _alias_in_query(alias, q):
            return mid
        if any(
            _alias_in_query(alias + suffix, q)
            for suffix in ("चा", "ची", "चे", "च्या", "नाम")
        ):
            return mid
    return None


# Goddess / deity spoken forms → preferred deity search tokens (for aarti ranking)
DEITY_SEARCH_ALIASES = {
    "durga": ["durga", "दुर्गा", "ambe", "ambaji", "तुलजा", "tulja"],
    "saraswati": ["saraswati", "सरस्वती", "sarasvati"],
    "lakshmi": ["lakshmi", "laxmi", "लक्ष्मी", "लक्ष्मी"],
    "kali": ["kali", "काली", "mahakali"],
    "parvati": ["parvati", "पार्वती", "gauri", "गौरी"],
    "radha": ["radha", "राधा"],
    "santoshi": ["santoshi", "संतोषी"],
    "annapurna": ["annapurna", "अन्नपूर्णा"],
    "jyotiba": [
        "jyotiba", "jotiba", "ज्योतिबा", "जोतिबा", "changbhala", "चांगभलं",
        "ratnagiri", "kedarnath jyotiba",
    ],
    "ganesha": ["ganesha", "ganesh", "ganpati", "गणेश", "गणपती"],
    "shiva": ["shiva", "shiv", "mahadev", "शिव"],
    "krishna": ["krishna", "कृष्ण", "gopal"],
    "rama": ["rama", "ram", "राम"],
    "hanuman": ["hanuman", "हनुमान"],
}


def _canonical_deity_tokens(query: str) -> List[str]:
    q = query.lower()
    tokens = []
    for _key, aliases in DEITY_SEARCH_ALIASES.items():
        for a in aliases:
            if _alias_in_query(a, q) or any(
                _alias_in_query(a + suffix, q) for suffix in ("चा", "ची", "चे")
            ):
                tokens.extend(aliases)
                break
    # unique preserve order
    seen = set()
    out = []
    for t in tokens:
        tl = t.lower()
        if tl not in seen:
            seen.add(tl)
            out.append(tl)
    return out


MEDIA_ALIASES = {
    "pasaydan": "pasayadan", "pasaydaan": "pasayadan", "pasay adan": "pasayadan",
    "पसायदान": "pasayadan", "ata vishwatmake deve": "pasayadan",
    "आता विश्वात्मके देवे": "pasayadan",
    "shani aarti": "shani_aarti", "shani dev aarti": "shani_aarti",
    "shani dev ki aarti": "shani_aarti",
    "shanidev aarti": "shani_aarti", "shani deva aarti": "shani_aarti",
    "शनि देव आरती": "shani_aarti", "शनिदेव आरती": "shani_aarti",
    "शनी देव आरती": "shani_aarti", "शनीची आरती": "shani_aarti",
    "शनिदेवाची आरती": "shani_aarti", "शनि देव की आरती": "shani_aarti",
}
MEDIA_REQUEST_WORDS = re.compile(
    r"^(?:(?:please|could you|can you|can we|could we|i would like to|i'd like to|i d like to|i want to|please let me|mujhe|mala|मला|मुझे|कृपया|जरा|play|open|show|read|listen to|hear|lyrics of|the) )+|"
    r"(?: (?:please|for me|sunna hai|sunni hai|aikaycha aahe|aikaychay|सुनना है|सुननी है|ऐकायचं आहे|ऐकायचे आहे|ऐकायचंय|वाचायचं आहे|पढ़ना है|lyrics|वाजवा|लावा|ऐका|उघडा|दाखवा|चलाओ|सुनाओ|खोलो|दिखाओ|chalao|sunao|kholo|dikhao))+$"
)


_indexed_songs = None
_songs_by_title = {}


def find_catalog_video(title):
    global _indexed_songs, _songs_by_title
    songs = get_knowledge().get("songs")
    if not songs:
        return None
    if songs is not _indexed_songs:
        index = {}
        for song in songs:
            for name in song["names"]:
                index.setdefault(name, song)
        _songs_by_title, _indexed_songs = index, songs
    name = " ".join(re.findall(r"[\w\u0900-\u097f]+", title.lower()))
    name = re.sub(r"\b(?:a+r+ti|aarati)\b", "aarti", name)
    if name in ("aarti", "bhajan", "song", "mantra", "आरती", "भजन", "मंत्र"):
        return None
    return _songs_by_title.get(name)


def search_aarti_db(query: str, limit: int = 3, *, prefer_audio: bool = False) -> List[Dict[str, Any]]:
    """Searches aartis database via deity-aware ranking, then title/FTS."""
    if not DB_PATH.exists():
        return []

    query = re.sub(r"\b(?:a+r+ti|aarati)\b", "aarti", query.lower())
    alias_query = MEDIA_REQUEST_WORDS.sub("", " ".join(
        re.sub(r"[^\w\u0900-\u097f]+", " ", query).split()
    )).strip()
    alias_id = MEDIA_ALIASES.get(alias_query)

    # Strip verbs / feature words so "open kundali chart" cannot leak into aarti FTS.
    stop_words = {
        "आरती", "लावा", "वाजवा", "उघडा", "उघड", "गाणे", "ऐका", "play", "aarti", "arti",
        "song", "chalao", "sunao", "dikhao", "open", "show", "please", "the", "my",
        "karo", "kholo", "dikhao", "chart", "kundali", "kundli", "patrika", "कुंडली",
        "horoscope", "rashifal", "panchang", "पंचांग", "mandir", "मंदिर",
        "jaap", "jap", "japa", "जप", "जाप", "naamjaap", "namjaap", "chant", "mala", "माला",
        "granth", "पोथी", "ग्रंथ", "today", "आजचा", "आज", "for", "me", "select", "continue",
        "goddess", "mata", "माता", "devi", "देवी",
    }
    tokens = [w for w in query.split() if w.lower() not in stop_words and len(w) > 1]
    if not tokens:
        return []
    keyword = " ".join(tokens)

    clean_q = re.sub(r"[^\w\s\u0900-\u097f]", " ", keyword).strip()
    words = [w for w in clean_q.split() if len(w) > 1]
    if not words:
        return []

    deity_tokens = _canonical_deity_tokens(query)

    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    cur = conn.cursor()

    results: List[Dict[str, Any]] = []

    cur.execute(
        "SELECT id, title, title_hi, title_mr, deity, deity_hi, deity_mr, "
        "youtube_video_id, has_audio FROM aartis"
    )
    catalog = [dict(row) for row in cur.fetchall()]
    alias_item = next((item for item in catalog if item["id"] == alias_id), None)
    if alias_item:
        conn.close()
        return [alias_item]

    request_words = {
        "i", "d", "me", "like", "to", "read", "listen", "hear", "the", "of", "for", "ji",
        "play", "open", "show", "please", "lyrics", "can", "could", "you",
        "की", "का", "ची", "लावा", "चलाओ", "सुनाओ", "सुना", "सकते", "हैं", "क्या", "आप",
        "मला", "ऐकायची", "आहे", "पाहायची", "वाचायची", "जरा", "कृपया",
    }
    query_words = set(alias_query.split())

    # A title match may have request words around it, but no extra title words.
    exact = []
    for item in catalog:
        titles = (item["title"], item["title_mr"], item["title_hi"])
        normalized_titles = (
            " ".join(re.sub(r"[^\w\u0900-\u097f]+", " ", title.lower()).split())
            for title in titles if title
        )
        matched_length = max((
            len(title) for title in normalized_titles
            if _alias_in_query(title, alias_query)
            and query_words - set(title.split()) <= request_words
        ), default=0)
        if matched_length:
            exact.append((matched_length, item))
    if exact:
        exact.sort(key=lambda match: (
            -match[0], prefer_audio and not match[1]["has_audio"], match[1]["id"],
        ))
        conn.close()
        return [item for _, item in exact[:limit]]

    media_terms = {
        "aarti", "bhajan", "stotra", "chalisa", "mantra", "song", "आरती",
        "भजन", "स्तोत्र", "चालीसा", "मंत्र",
    }
    deity_words = {word for alias in deity_tokens for word in alias.split()}
    generic_deity_request = query_words <= deity_words | media_terms | request_words
    if deity_tokens and generic_deity_request:
        aarti_requested = _alias_in_query("aarti", alias_query) or _alias_in_query("आरती", alias_query)
        scored = []
        for d in catalog:
            if aarti_requested and not any(
                term in (d.get(field) or "").lower()
                for field in ("id", "title", "title_mr", "title_hi")
                for term in ("aarti", "आरती")
            ):
                continue
            blob = " ".join(
                [
                    (d.get("deity") or ""),
                    (d.get("deity_hi") or ""),
                    (d.get("deity_mr") or ""),
                    (d.get("title") or ""),
                    (d.get("title_hi") or ""),
                    (d.get("title_mr") or ""),
                    (d.get("id") or ""),
                ]
            ).lower()
            score = 0
            for t in deity_tokens:
                if t in (d.get("deity") or "").lower() or t in (d.get("deity_hi") or "").lower() or t in (d.get("deity_mr") or "").lower():
                    score += 5
                if t in (d.get("id") or "").lower():
                    score += 4
                if t in (d.get("title") or "").lower() or t in (d.get("title_mr") or "").lower() or t in (d.get("title_hi") or "").lower():
                    score += 2
                if t in blob:
                    score += 1
            if score > 0:
                scored.append((score, d))
        scored.sort(key=lambda x: (prefer_audio and not x[1]["has_audio"], -x[0], x[1].get("title") or ""))
        results = [d for _, d in scored[:limit]]

    if not results:
        # 1. Exact or prefix match attempt on title or title_mr
        cur.execute(
            """
            SELECT id, title, title_hi, title_mr, deity, deity_hi, deity_mr, youtube_video_id, has_audio
            FROM aartis
            WHERE LOWER(title) LIKE ? OR LOWER(title_mr) LIKE ? OR LOWER(title_hi) LIKE ?
               OR LOWER(deity) LIKE ? OR LOWER(deity_mr) LIKE ? OR LOWER(deity_hi) LIKE ?
            LIMIT ?
            """,
            (
                f"%{clean_q}%",
                f"%{clean_q}%",
                f"%{clean_q}%",
                f"%{clean_q}%",
                f"%{clean_q}%",
                f"%{clean_q}%",
                limit,
            ),
        )
        rows = cur.fetchall()
        if rows:
            results = [dict(r) for r in rows]
        else:
            fts_query = " AND ".join(f'"{w}"*' for w in words)
            try:
                cur.execute(
                    """
                    SELECT a.id, a.title, a.title_hi, a.title_mr, a.deity, a.deity_hi,
                           a.deity_mr, a.youtube_video_id, a.has_audio
                    FROM aartis a
                    JOIN aartis_fts f ON a.id = f.id
                    WHERE aartis_fts MATCH ?
                    LIMIT ?
                    """,
                    (fts_query, limit),
                )
                results = [dict(r) for r in cur.fetchall()]
            except sqlite3.OperationalError:
                pass

    conn.close()
    return results

async def resolve_with_ollama(text: str, locale: str, *, home_screen: bool = False, feature_intents: bool = False, pending_action: str | None = None) -> Optional[Dict[str, Any]]:
    """Calls local Ollama for ambiguous or complex intent understanding."""
    system = feature_prompt(app_help.TOPICS) if feature_intents else SYSTEM_PROMPT
    if home_screen:
        system = HOME_PROMPT
    if pending_action == "ask_rashi":
        system = RASHI_FOLLOWUP_PROMPT + " Previous question: which sign? Locale: " + locale
    try:
        async with httpx.AsyncClient(timeout=4.0) as client:
            resp = await client.post(
                f"{OLLAMA_HOST}/api/generate",
                json={
                    "model": OLLAMA_MODEL,
                    "prompt": f"User: {text}\nClassification:",
                    "system": system,
                    "format": "json",
                    "stream": False,
                    "options": {"temperature": 0.1, "num_predict": 128}
                }
            )
            if resp.status_code == 200:
                data = resp.json()
                parsed = json.loads(data.get("response", "{}"))
                return parsed
    except Exception as e:
        print(f"Ollama resolution fallback error: {e}")
    return None


async def resolve_with_local_llm(text: str, locale: str, *, navigation: bool = False,
                                 app_questions: bool = False, home_screen: bool = False, feature_intents: bool = False, pending_action: str | None = None) -> Optional[Dict[str, Any]]:
    """Prefer fine-tuned MLX adapter on Mac, then Ollama."""
    try:
        from .mlx_classifier import classify_with_mlx, mlx_available

        if mlx_available():
            import asyncio

            mlx_res = await asyncio.to_thread(classify_with_mlx, text, locale, navigation=navigation,
                                              app_questions=app_questions, feature_intents=feature_intents, home_screen=home_screen, pending_action=pending_action)
            if mlx_res and mlx_res.get("action"):
                print(f"[voice-mlx] classified -> {mlx_res.get('action')}")
                return mlx_res
    except Exception as e:
        print(f"MLX resolution fallback error: {e}")

    return await resolve_with_ollama(text, locale, feature_intents=feature_intents, home_screen=home_screen, pending_action=pending_action)


REMINDER_REQUEST = re.compile(
    r"aarti (?:reminders?|alerts?|notifications?)|(?:reminders?|alerts?) for (?:my |the )?(?:daily )?aarti|"
    r"आरतीची आठवण|आरती आठवण|आरती (?:का )?रिमाइंडर"
)
LANGUAGE_REQUEST = re.compile(
    r"(?:switch|set|change|use|make) .{0,32}(?:interface|menus)|make (?:the |this )?app (?:marathi|hindi|english)|switch (?:the )?menus to |"
    r"language settings|app language|(?:change|chnage|switch|set|select) (?:the )?language|"
    r"(?:switch|change) (?:to|from) (?:marathi|hindi|english)|(?:app|अॅप|ॲप) (?:मराठीत|हिंदीत|इंग्रजीत|(?:marathi|hindi|english) (?:mein|madhe))|"
    r"bhasha badlo|bhasha badla|language badlo|"
    r"(?:ऐप|एप) की भाषा|अॅपची भाषा|ॲपची भाषा|भाषा बदल[ाोणे]?|भाषा निवडा|भाषा चुनें|"
    r"(?:मराठी|हिंदी|हिन्दी|इंग्रजी|अंग्रेज़ी) (?:में बदलो|मध्ये बदला|करा)"
)
LANGUAGES = {
    "mr": ("marathi", "मराठी", "मराठीत"),
    "hi": ("hindi", "हिंदी", "हिन्दी", "हिंदीत"),
    "en": ("english", "इंग्रजी", "इंग्रजीत", "अंग्रेजी", "अंग्रेज़ी"),
}
FEEDBACK_REQUEST = re.compile(
    r"\b(?:feedback|suggestions?|request (?:a deity|to add a deity)|report (?:a |an )?(?:problem|issue|bug))\b|"
    r"अभिप्राय|प्रतिक्रिया|फीडबैक|फीडबॅक|सूचना द्या|सुझाव|तक्रार|समस्या बताएं"
)
SHRINE_REQUEST = re.compile(
    r"^[\s,]*(?:please )?(?:(?:open|show|go to|take me to) (?:the |my )?)?"
    r"(?:virtual shrine|shrine|temple|mandir(?: darshan)?|garbhagriha|darshan|मंदिर|देवघर|दर्शन|गाभारा)"
    r"(?: (?:open|kholo|khol do|dikhao|please|उघडा|दाखवा|खोलो|दिखाओ|दर्शन खोलो))?[.!?।]*$"
    r"|देवघरात (?:घेऊन जा|घेऊन जाल)|(?:दर्शन|darshan) (?:घ्यायचे|करना है)"
)
DIYA_REQUEST = re.compile(
    r"^(?:please )?(?:(?:open|show) (?:the )?)?"
    r"(?:akhand (?:diya|jyot|jyoti)|eternal lamp|अखंड (?:दिवा|दीया|दीप|ज्योत|ज्योति))"
    r"(?: (?:open|kholo|दाखवा|उघडा|खोलो|दिखाओ|का पन्ना खोलना))?[.!?।]*$"
)
# A model proposal must agree with a concrete part of the original request.
# Shrine, settings, and media routes are resolved by their dedicated handlers.
MODEL_ROUTE_CUES = {
    "open_horoscope": ("horoscope", "rashifal", "rashi", "star sign", "zodiac", "राशी", "राशि", "राशिफल", "राशीभविष्य", "forecast"),
    "open_panchang": ("hindu calendar", "auspicious", "पंचांग"),
    "open_granth": ("scripture", "scriptures", "sacred books", "पोथ्या"),
    "open_kundali": ("natal", "born", "birth details", "birth time", "janam patri", "जन्मपत्री", "janmapatrika"),
    "open_milan": ("marriage", "matrimony", "wedding match", "compatibility", "shaadi", "विवाह", "लग्नासाठी"),
    "open_ishta_devta": ("personal deity", "tutelary deity", "आराध्य देवता"),
    "open_greetings": ("greeting cards", "morning cards", "night cards", "good night", "शुभकामना", "शुभेच्छा", "शुभ रात्री", "शुभ रात्रि"),
    "open_grahan": ("eclipse", "grahan", "ग्रहण"),
    "open_calendar": ("festival", "festivals", "tyoharon", "उत्सव", "सण", "त्योहार"),
    "start_jaap": ("recite", "repeat the mantra", "मंत्र जपा", "नामस्मरण"),
    "open_jaap_stats": ("recitations", "streak", "नामस्मरण"),
}


async def resolve_voice_turn(text: str, locale_hint: Optional[str] = None, *, pending_action: Optional[str] = None,
                             birth_details: dict | None = None) -> Dict[str, Any]:
    """
    Main deterministic-first intent resolver.
    Returns structured action-ready or clarification response.
    """
    text_clean = text.strip()
    locale = detect_locale(text_clean, locale_hint)
    query = " ".join(text_clean.lower().split())

    def result(action, replies, status="action_ready"):
        return {
            "status": status,
            "transcript": text_clean,
            "locale": locale,
            "response_text": dict(zip(("en-IN", "hi-IN", "mr-IN"), replies))[locale],
            "action": action,
            "choices": [],
        }

    def not_found():
        return result(
            {"type": "none"},
            (
                "I couldn’t find a matching item or feature in BhaktiDhara.",
                "मुझे भक्तिधारा में इसका कोई विकल्प नहीं मिला।",
                "भक्तिधारामध्ये यासाठी काही सापडले नाही.",
            ),
            status="not_found",
        )

    def horoscope_result(sign):
        name = sign["name_" + locale[:2]]
        return result(
            {"type": "open_horoscope", "rashi_id": sign.get("app_id") or sign["id"],
             "rashi_name": name, "feature_key": "horoscope"},
            (f"Opening today's horoscope for {name}.", f"{name} राशि का आज का राशिफल खोला जा रहा है।",
             f"{name} राशीचे आजचे राशीभविष्य उघडत आहे."),
        )

    def route_result(kind):
        route = app_help.ROUTES[kind]
        return result({"type": kind}, [route["reply"][lang] for lang in ("en", "hi", "mr")],
                      status=route.get("status", "action_ready"))

    def answer_topic(key):
        replies = app_help.TOPICS[key]["reply"]
        return result({"type": "answer_app_question", "feature_key": key},
                      [replies[lang] for lang in ("en", "hi", "mr")], status="answered")

    def open_topic(key):
        info = app_help.TOPICS[key]
        kind = info["screen_action"]
        if kind in app_help.ROUTES:
            return route_result(kind)
        names = info["labels"]
        return result({"type": kind}, (f"Opening {names['en']}.", f"{names['hi']} खोल रहे हैं।",
                                       f"{names['mr']} उघडत आहे."))

    collecting = pending_action == birth_rashi.ACTION
    if pending_action in ("ask_rashi", birth_rashi.ACTION) and birth_rashi.matches("cancel", query):
        return birth_rashi.reply(text_clean, locale, "cancel")
    if birth_rashi.requested(query, pending_action) and not birth_rashi.matches("switch", query):
        return birth_rashi.turn(text_clean, locale, birth_details if collecting else None)
    if collecting:
        # A new command can interrupt a pending birth question. Birth facts themselves
        # stay out of catalog lookup and the language model.
        if (not birth_rashi.matches("switch", query) and
                (any(c.isdecimal() for c in query) or birth_rashi.matches("personal_details", query)
                 or birth_rashi.zone_id(text_clean)
                 or birth_rashi.birth_time(query)[0] or birth_rashi.matches("uncertain", query))):
            return birth_rashi.turn(text_clean, locale, birth_details)
        redirected = await resolve_voice_turn(text_clean, locale)
        if redirected["action"]["type"] != "none" or app_help.DECLINE.search(query) or birth_rashi.matches("switch", query):
            return redirected
        return birth_rashi.turn(text_clean, locale, birth_details)

    if app_help.DECLINE.search(query):
        return not_found()
    if pending_action == "ask_rashi":
        answer = app_help.RASHI_ANSWER.fullmatch(query)
        if answer and (sign := match_rashi(answer.group(1))):
            return horoscope_result(sign)
    # Device-local activity is displayed on My Sadhana when the API is called alone.
    if any(pattern.fullmatch(query) for pattern in app_help.JAAP_VALUES.values()):
        return open_topic("jaap_stats")
    topics = app_help.matching_topics(query)
    topic = app_help.direct_topic(query, topics)
    instructions = bool(app_help.MODEL_QUESTION.search(query))
    if not topic and instructions and len(topics) == 1:
        topic = topics[0]
    if not topic and instructions and topics:
        proposal = await resolve_with_local_llm(text_clean, locale, feature_intents=True) or {}
        kind = proposal.get("action")
        fields = kind if isinstance(kind, dict) else proposal
        if (fields.get("type") or kind) == "answer_app_question" and fields.get("feature_key") in topics:
            topic = fields["feature_key"]
        else:
            return not_found()
    question = app_help.catalog_question(query)
    if topic and not question:
        return answer_topic(topic)

    if app_help.EXCLUDE.search(query) and any(
        re.search(app_help.TOPICS[key]["terms"], query) for key in ("language", "feedback", "reminders")
    ):
        return not_found()

    clues = app_help.catalog_clues(query)
    if not question and clues:
        proposal = await resolve_with_local_llm(text_clean, locale, app_questions=True) or {}
        action = proposal.get("action")
        fields = action if isinstance(action, dict) else proposal
        title = fields.get("query")
        field = fields.get("field")
        if ((fields.get("type") or action) != "answer_app_question" or field not in clues
                or not isinstance(title, str) or not _alias_in_query(title, query)):
            return not_found()
        question = (field, title)
    if question:
        field, requested = question
        # Only a title or a reviewed title alias can supply a catalog fact.
        item = app_help.find_catalog_item(
            requested, get_knowledge().get("aartis", []), MEDIA_ALIASES, locale.split("-")[0],
        )
        catalog_id = "aarti_id"
        if item is None:
            item = find_catalog_video(requested)
            catalog_id = "song_id"
        if item:
            replies = [app_help.catalog_reply(field, item, lang) for lang in ("en", "hi", "mr")]
            return result({"type": "answer_app_question", "feature_key": "catalog",
                           catalog_id: item["id"], "field": field}, replies, status="answered")
        if field in ("about", "availability") and (topic or len(topics) == 1):
            return answer_topic(topic or topics[0])
        if field != "availability" or not topics:
            return not_found()

    if key := app_help.screen_topic(query):
        return open_topic(key)
    if kind := app_help.match_route(query):
        return route_result(kind)

    if topics and app_help.FEATURE_EXPLANATION.search(query):
        proposal = await resolve_with_local_llm(text_clean, locale, feature_intents=True) or {}
        action = proposal.get("action")
        fields = action if isinstance(action, dict) else proposal
        if (fields.get("type") or action) == "answer_app_question" and fields.get("feature_key") in topics:
            return answer_topic(fields["feature_key"])
        if not proposal and len(topics) == 1:
            return answer_topic(topics[0])
        return not_found()

    if REMINDER_REQUEST.search(query):
        return result({"type": "open_aarti_reminders"}, (
            "Opening aarti reminder settings.", "आरती रिमाइंडर खोल रहे हैं।", "आरती आठवण उघडत आहे.",
        ))

    if LANGUAGE_REQUEST.search(query) or query in ("language", "भाषा"):
        target = re.search(r"\bfrom .+? (?:to|into) (.+)", query)
        language_text = target.group(1) if target else query
        codes = [
            code for code, labels in LANGUAGES.items()
            if any(_alias_in_query(label, language_text) for label in labels)
        ]
        if len(codes) == 1:
            return result(
                {"type": "set_language", "language_code": codes[0]},
                ("Changing the app language.", "ऐप की भाषा बदल रहे हैं।", "अॅपची भाषा बदलत आहे."),
            )
        if not codes and _alias_in_query("to", query):
            return not_found()
        return result(
            {"type": "open_language_settings"},
            ("Choose Marathi, Hindi, or English.", "मराठी, हिंदी या अंग्रेज़ी चुनें।", "मराठी, हिंदी किंवा इंग्रजी निवडा."),
        )
    if FEEDBACK_REQUEST.search(query):
        return result(
            {"type": "open_feedback"},
            ("Opening the feedback form.", "सुझाव फ़ॉर्म खोल रहे हैं।", "अभिप्राय फॉर्म उघडत आहे."),
        )

    def wants_playback(words):
        return any(_alias_in_query(term, words) for term in (
            "वाजवा", "लावा", "ऐका", "play", "listen", "hear", "start", "चलाओ", "सुनाओ", "सुना",
            "सुनना", "सुननी", "ऐकायचं", "ऐकायचे", "ऐकायचंय", "sunna", "sunni", "aikaycha", "aikaychay", "chalao", "sunao",
        ))

    is_play_intent = wants_playback(text_clean)

    def media_result(aarti_matches):
        top = aarti_matches[0]
        title_field = {"en-IN": "title", "hi-IN": "title_hi", "mr-IN": "title_mr"}[locale]
        title = top.get(title_field) or top["title"]
        # A lyric can itself contain a word like “सुना”. Look outside the title.
        command = query
        for name in (top.get("title"), top.get("title_mr"), top.get("title_hi")):
            if name:
                command = command.replace(name.lower(), " ")
        play = is_play_intent and wants_playback(command)
        action_type = "play_aarti" if play else "open_aarti"
        if play and not top["has_audio"]:
            reply = {
                "en-IN": f"Opening {title}. Audio is unavailable.",
                "hi-IN": f"{title} खोल रहे हैं। ऑडियो उपलब्ध नहीं है।",
                "mr-IN": f"{title} उघडत आहे. ऑडिओ उपलब्ध नाही.",
            }[locale]
        else:
            reply = {
                "en-IN": f"Opening {title}.",
                "hi-IN": f"{title} खोल रहे हैं।",
                "mr-IN": f"{title} उघडत आहे.",
            }[locale]
        return {
            "status": "action_ready",
            "transcript": text_clean,
            "locale": locale,
            "response_text": reply,
            "action": {
                "type": action_type,
                "aarti_id": top["id"],
                "title": title,
                "youtube_video_id": top.get("youtube_video_id"),
                "has_audio": bool(top.get("has_audio"))
            },
            "choices": [
                {"id": m["id"], "title": m.get("title_mr") or m.get("title")}
                for m in aarti_matches[1:]
            ]
        }

    media_words = MEDIA_REQUEST_WORDS.sub("", query.strip(" ?!।.")).strip()
    if DB_PATH.is_file() and media_words:
        # Preserve punctuation inside titles, e.g. "(108 Jap)".
        columns = {"en-IN": "title", "hi-IN": "title_hi", "mr-IN": "title_mr"}
        preferred = columns[locale]
        with closing(sqlite3.connect(DB_PATH)) as conn:
            conn.row_factory = sqlite3.Row
            rows = conn.execute(
                f"SELECT * FROM aartis WHERE title = ? COLLATE NOCASE OR title_hi = ? COLLATE NOCASE "
                f"OR title_mr = ? COLLATE NOCASE ORDER BY ({preferred} = ? COLLATE NOCASE) DESC, rowid LIMIT 1",
                (media_words,) * 4,
            ).fetchall()
        if rows:
            return media_result([dict(rows[0])])

    video = None
    if not re.search(r"lyrics|read |वाचा|वाचाय|पढ़|शब्द", query) and not MEDIA_ALIASES.get(media_words):
        video = find_catalog_video(media_words)

    def video_result():
        title = video["title"]
        return result({"type": "open_song_video", "song_id": video["id"], "title": title}, (
            f"Opening the video for {title}.", f"{title} का वीडियो खोल रहे हैं।", f"{title} चा व्हिडिओ उघडत आहे.",
        ))

    if video and is_play_intent:
        return video_result()

    shrine_control = any(_alias_in_query(term, text_clean) for term in ("diya", "दिवा", "दीया", "lamp", "bell"))
    if shrine_control and any(_alias_in_query(term, text_clean) for term in (
        "switch off", "turn off", "बंद करो", "बंद करा", "विझवा",
    )):
        return {
            "status": "unsupported",
            "transcript": text_clean,
            "locale": locale,
            "response_text": {
                "en-IN": "You can control the diya from the shrine.",
                "hi-IN": "दीये के नियंत्रण मंदिर में मिलेंगे।",
                "mr-IN": "दिव्याची नियंत्रणे देवघरात आहेत.",
            }[locale],
            "action": {"type": "none"},
            "choices": [],
        }

    # Route explicit jaap requests before short zodiac aliases or catalog hits.
    explicit_jaap = any(_alias_in_query(term, query) for term in JAAP_ALIASES)
    counter_term = any(_alias_in_query(term, query) for term in JAAP_COUNTER_TERMS)
    stats = any(_alias_in_query(term, query) for term in JAAP_STATS_TERMS) or (
        explicit_jaap and any(_alias_in_query(term, query) for term in ("history", "stats", "streak", "record", "lifetime count"))
    )
    about_jaap = not stats and query.startswith("what is ")
    if (explicit_jaap or counter_term or stats) and (
        JAAP_UNSUPPORTED_PATTERN.search(query) or about_jaap
    ):
        return {
            "status": "unsupported",
            "transcript": text_clean,
            "locale": locale,
            "response_text": {
                "en-IN": "You can ask me to open the jaap counter or show your jaap history.",
                "hi-IN": "आप मुझसे जप माला या जप का इतिहास खोलने को कह सकते हैं।",
                "mr-IN": "तुम्ही जप माळ किंवा जपाचा इतिहास उघडायला सांगू शकता.",
            }[locale],
            "action": {"type": "none"},
            "choices": [],
        }
    action = None
    if stats:
        action = {"type": "open_jaap_stats", "feature_key": "jaap_stats"}
        replies = ("Opening your jaap history.", "जप का इतिहास खोल रहे हैं।", "जपाचा इतिहास उघडत आहे.")
    elif explicit_jaap or query in JAAP_COUNTER_TERMS:
        action = {"type": "start_jaap", "feature_key": "jaap"}
        mantra_id = match_jaap_mantra(query)
        if mantra_id:
            action["mantra_id"] = mantra_id
        replies = ("Opening the jaap counter.", "जप माला खोल रहे हैं।", "जप माळ उघडत आहे.")
    elif any(_alias_in_query(term, query) for term in CALENDAR_TERMS) or (
        _alias_in_query("calendar", query)
        and any(_alias_in_query(term, query) for term in ("festival", "festivals"))
    ):
        action = {"type": "open_calendar", "feature_key": "calendar"}
        replies = ("Opening the festival calendar.", "त्योहारों का कैलेंडर खोल रहे हैं।", "सणांची दिनदर्शिका उघडत आहे.")
    if action:
        return {
            "status": "action_ready",
            "transcript": text_clean,
            "locale": locale,
            "response_text": dict(zip(("en-IN", "hi-IN", "mr-IN"), replies))[locale],
            "action": action,
            "choices": [],
        }

    # Rashi / Horoscope matching
    rashi_match = match_rashi(text_clean)
    is_horoscope_intent = any(
        w in text_clean.lower()
        for w in [
            "राशी",
            "राशि",
            "भविष्य",
            "rashifal",
            "horoscope",
            "राशिफल",
            "राशीचे",
            "rashi",
            "rasi",
        ]
    )
    
    if rashi_match and (is_horoscope_intent or (not is_play_intent and len(query.split()) <= 4)):
        return horoscope_result(rashi_match)

    # Panchang / Rahu Kaal Matching
    panchang_fields = {
        "rahu_kaal": ("राहुकाळ", "राहुकाल", "rahu kaal", "rahukaal"),
        "tithi": ("तिथी", "तिथि", "tithi"),
        "muhurat": ("मुहूर्त", "muhurat", "muhurta"),
        "nakshatra": ("नक्षत्र", "nakshatra"),
        "sunrise": ("सूर्योदय", "sunrise"),
        "sunset": ("सूर्यास्त", "sunset"),
    }
    field = next(
        (key for key, aliases in panchang_fields.items() if any(term in query for term in aliases)),
        None,
    )
    if field or "पंचांग" in query or _alias_in_query("panchang", query):
        reply = {
            "en-IN": "Opening today's Panchang.",
            "hi-IN": "आज का पंचांग खोल रहे हैं।",
            "mr-IN": "आजचे पंचांग उघडत आहे.",
        }[locale]
        return {
            "status": "action_ready",
            "transcript": text_clean,
            "locale": locale,
            "response_text": reply,
            "action": {
                "type": "open_panchang",
                "field": field,
                "feature_key": "panchang"
            },
            "choices": []
        }
        
    if DIYA_REQUEST.search(query):
        return {
            "status": "action_ready",
            "transcript": text_clean,
            "locale": locale,
            "response_text": {
                "en-IN": "Opening the Akhand Diya.",
                "hi-IN": "अखंड दीया खोल रहे हैं।",
                "mr-IN": "अखंड दिवा उघडत आहे.",
            }[locale],
            "action": {"type": "open_akhand_diya", "feature_key": "akhand_diya"},
            "choices": [],
        }

    # Mandir / Garbhagriha Matching
    if SHRINE_REQUEST.search(query):
        reply = {"mr-IN": "श्री मंदिर गर्भगृह दर्शन सुरू करत आहे.", "hi-IN": "मंदिर गर्भगृह दर्शन खोला जा रहा है।", "en-IN": "Opening the temple shrine."}[locale]
        return {
            "status": "action_ready",
            "transcript": text_clean,
            "locale": locale,
            "response_text": reply,
            "action": {
                "type": "open_mandir",
                "feature_key": "mandir"
            },
            "choices": []
        }
        
    # Granth / Pothi Matching
    granth_signals = (
        "पोथी", "पोथ्या", "ग्रंथ", "गुरुचरित्र", "दासबोध", "शिवलीलामृत", "अध्याय",
        "granth", "pothi", "gurucharitra", "dasbodh", "shivlilamrut",
    )
    if any(sig in query for sig in granth_signals):
        chap_match = re.search(r"(\d+)", text_clean)
        chapter = int(chap_match.group(1)) if chap_match else None
        reply = {
            "en-IN": "Opening the granth library.",
            "hi-IN": "ग्रंथ संग्रह खोल रहे हैं।",
            "mr-IN": "ग्रंथ संग्रह उघडत आहे.",
        }[locale]
        return {
            "status": "action_ready",
            "transcript": text_clean,
            "locale": locale,
            "response_text": reply,
            "action": {
                "type": "open_granth",
                "chapter": chapter,
                "feature_key": "granth"
            },
            "choices": []
        }

    # Kundali / birth chart
    q_lower = text_clean.lower()
    kundali_signals = [
        "kundali", "kundli", "patrika", "birth chart", "kundali chart",
        "janma kundali", "janam kundali", "natal chart", "natal horoscope",
        "कुंडली", "पत्रिका", "जन्म कुंडली", "कुंडली चार्ट",
    ]
    milan_signals = (
        "milan", "मिलन", "मिलान", "marriage compatibility", "पत्रिका जुळव", "गुण जुळ",
    )
    comparing_charts = ("chart" in q_lower and
                        re.search(r"compar(?:e|ing)|match(?:ing)?", q_lower) and
                        re.search(r"marriage|matrimony|couple|two (?:birth )?charts", q_lower))
    if comparing_charts or any(sig in q_lower for sig in milan_signals) or (
        "पत्र्य" in q_lower and "जुळव" in q_lower
    ):
        reply = (
            "कुंडली मिलन उघडत आहे."
            if locale == "mr-IN"
            else ("कुंडली मिलान खोला जा रहा है।" if locale == "hi-IN" else "Opening kundali milan.")
        )
        return {
            "status": "action_ready",
            "transcript": text_clean,
            "locale": locale,
            "response_text": reply,
            "action": {"type": "open_milan", "feature_key": "milan"},
            "choices": [],
        }
    if any(sig in q_lower for sig in kundali_signals) or (
        "chart" in q_lower and any(w in q_lower for w in ["kundali", "kundli", "birth", "कुंडली", "open"])
    ):
        reply = (
            "कुंडली उघडत आहे."
            if locale == "mr-IN"
            else ("कुंडली खोली जा रही है।" if locale == "hi-IN" else "Opening your kundali chart.")
        )
        return {
            "status": "action_ready",
            "transcript": text_clean,
            "locale": locale,
            "response_text": reply,
            "action": {"type": "open_kundali", "feature_key": "kundali"},
            "choices": [],
        }

    # Other app features (Ishta Devta, Greetings, Grahan, etc.)
    feat = match_feature(text_clean)
    if feat and feat.get("default_action") not in ("play_aarti", "open_aarti", "search_aarti", "start_jaap", "open_mandir", "open_akhand_diya"):
        if feat["default_action"] == "open_horoscope" and not rashi_match:
            return route_result("ask_rashi")
        # Prefer English reply for en-IN
        if locale == "en-IN":
            reply = f"Opening {feat.get('title_en', feat['key'])}."
        elif locale == "hi-IN":
            reply = f"{feat['title_hi']} खोला जा रहा है।"
        else:
            reply = f"{feat['title_mr']} उघडत आहे."
        return {
            "status": "action_ready",
            "transcript": text_clean,
            "locale": locale,
            "response_text": reply,
            "action": {
                "type": feat["default_action"],
                "feature_key": feat["key"]
            },
            "choices": []
        }

    if video:
        return video_result()

    # Devotional media lookup
    aarti_matches = search_aarti_db(text_clean, prefer_audio=is_play_intent)
    if aarti_matches:
        return media_result(aarti_matches)

    navigate = bool(app_help.FEATURE_NAVIGATION.search(query))
    if topics and (navigate or app_help.FEATURE_INQUIRY.search(query)):
        proposal = await resolve_with_local_llm(text_clean, locale, feature_intents=True) or {}
        action = proposal.get("action")
        fields = action if isinstance(action, dict) else proposal
        kind = fields.get("type") or action
        if kind == "answer_app_question" and fields.get("feature_key") in topics:
            return answer_topic(fields["feature_key"])
        if navigate and len(topics) == 1 and kind == app_help.TOPICS[topics[0]].get("screen_action"):
            return open_topic(topics[0])
        return not_found()

    cues = {
        kind for kind, terms in MODEL_ROUTE_CUES.items()
        if any(_alias_in_query(term, query) for term in terms)
    }
    cues.update(kind for kind, route in app_help.ROUTES.items()
                if route.get("cues") and re.search(route["cues"], query))
    if "open_horoscope" in cues and not rashi_match:
        cues.add("ask_rashi")
    if cues and not app_help.EXCLUDE.search(query):
        navigation = cues.issubset(MODEL_ROUTE_CUES)
        proposal = await resolve_with_local_llm(
            text_clean, locale, navigation=navigation,
            app_questions=not navigation and cues.isdisjoint({"ask_rashi", "open_notifications"}),
        ) or {}
        action = proposal.get("action")
        if isinstance(action, dict):
            action = {**proposal, **action}
        else:
            action = {**proposal, "type": action}
        kind = action.get("type")
        if isinstance(kind, str) and kind in cues:
            payload = {"type": kind}
            if kind in ("open_horoscope", "ask_rashi"):
                return horoscope_result(rashi_match) if rashi_match else route_result("ask_rashi")
            if kind == "start_jaap":
                payload["mantra_id"] = match_jaap_mantra(query)
            route = app_help.ROUTES.get(kind)
            if route:
                replies = [route["reply"][lang] for lang in ("en", "hi", "mr")]
            else:
                feature = next((f for f in get_knowledge().get("features", [])
                                if f["default_action"] == kind), None)
                replies = (
                    f"Opening {feature['title_en']}." if feature else "Opening the requested screen.",
                    f"{feature['title_hi']} खोल रहे हैं।" if feature else "संबंधित पृष्ठ खोल रहे हैं।",
                    f"{feature['title_mr']} उघडत आहे." if feature else "संबंधित पान उघडत आहे.",
                )
            return result(payload, replies)

    if pending_action == "ask_rashi":
        proposal = await resolve_with_local_llm(text_clean, locale, pending_action=pending_action) or {}
        kind = proposal.get("action")
        if (kind.get("type") if isinstance(kind, dict) else kind) == birth_rashi.ACTION:
            return birth_rashi.turn(text_clean, locale)

    return not_found()
