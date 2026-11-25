#!/usr/bin/env python3
"""
Extracts BhaktiDhara app data and catalogs into a unified SQLite database
and JSON knowledge base for the Voice Agent.
"""

from __future__ import annotations

import subprocess
import shutil
import os
import re
import json
import sqlite3
import urllib.request
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parent.parent.parent
BACKEND_DIR = BASE_DIR / "backend"
DATA_DIR = BACKEND_DIR / "data"
DB_PATH = DATA_DIR / "voice_agent_catalog.db"
JSON_PATH = DATA_DIR / "voice_knowledge.json"
LIVE_CATALOG_SNAPSHOT = DATA_DIR / "live_catalog.json"
LIVE_CATALOG_URL = os.environ.get(
    "BHAKTI_LIVE_CATALOG_URL",
    "https://bhaktidharaapp.in/api/v1/catalog",
)

# Ensure data directory exists
DATA_DIR.mkdir(parents=True, exist_ok=True)

# 1. Definitive Rashis Mapping
# `id` = Vedic slug used in speech; `app_id` = Flutter kAllRashis id
RASHIS = [
    {
        "id": "mesh",
        "app_id": "aries",
        "name_en": "Aries",
        "name_mr": "मेष",
        "name_hi": "मेष",
        "aliases": ["mesh", "mesha", "aries", "मेष", "मेष राशी", "mesh rashi", "मेष राशि"]
    },
    {
        "id": "vrishabh",
        "app_id": "taurus",
        "name_en": "Taurus",
        "name_mr": "वृषभ",
        "name_hi": "वृषभ",
        "aliases": [
            "vrishabh", "vrushabh", "vrushab", "vrishab", "vrisabh", "vrishabha",
            "vrushabha", "vrisabha", "taurus", "वृषभ", "वृषभ राशी", "vrushab rashi",
            "vrishabh rashi", "vrushabh rashi", "वृषभ राशि", "वृष"
        ]
    },
    {
        "id": "mithun",
        "app_id": "gemini",
        "name_en": "Gemini",
        "name_mr": "मिथुन",
        "name_hi": "मिथुन",
        "aliases": ["mithun", "mithuna", "gemini", "मिथुन", "मिथुन राशी", "mithun rashi", "मिथुन राशि"]
    },
    {
        "id": "kark",
        "app_id": "cancer",
        "name_en": "Cancer",
        "name_mr": "कर्क",
        "name_hi": "कर्क",
        "aliases": ["kark", "karka", "karkat", "cancer", "कर्क", "कर्क राशी", "kark rashi", "कर्क राशि"]
    },
    {
        "id": "singh",
        "app_id": "leo",
        "name_en": "Leo",
        "name_mr": "सिंह",
        "name_hi": "सिंह",
        "aliases": ["singh", "simha", "sinha", "leo", "सिंह", "सिंह राशी", "singh rashi", "simha rashi", "सिंह राशि"]
    },
    {
        "id": "kanya",
        "app_id": "virgo",
        "name_en": "Virgo",
        "name_mr": "कन्या",
        "name_hi": "कन्या",
        "aliases": ["kanya", "virgo", "कन्या", "कन्या राशी", "kanya rashi", "कन्या राशि"]
    },
    {
        "id": "tula",
        "app_id": "libra",
        "name_en": "Libra",
        "name_mr": "तूळ",
        "name_hi": "तुला",
        "aliases": ["tula", "tul", "libra", "तूळ", "तुला", "तूळ राशी", "tula rashi", "तुला राशि"]
    },
    {
        "id": "vrishchik",
        "app_id": "scorpio",
        "name_en": "Scorpio",
        "name_mr": "वृश्चिक",
        "name_hi": "वृश्चिक",
        "aliases": [
            "vrishchik", "vrushchik", "vrischik", "vruschik", "vrushik", "vrishik",
            "vrishchika", "vrushchika", "scorpio", "scorpius", "वृश्चिक", "वृश्चिक राशी",
            "vrishchik rashi", "vrushchik rashi", "वृश्चिक राशि"
        ]
    },
    {
        "id": "dhanu",
        "app_id": "sagittarius",
        "name_en": "Sagittarius",
        "name_mr": "धनु",
        "name_hi": "धनु",
        "aliases": ["dhanu", "dhanur", "sagittarius", "धनु", "धनु राशी", "धनुष्य", "dhanu rashi", "धनु राशि"]
    },
    {
        "id": "makar",
        "app_id": "capricorn",
        "name_en": "Capricorn",
        "name_mr": "मकर",
        "name_hi": "मकर",
        "aliases": ["makar", "makara", "capricorn", "मकर", "मकर राशी", "makar rashi", "मकर राशि"]
    },
    {
        "id": "kumbh",
        "app_id": "aquarius",
        "name_en": "Aquarius",
        "name_mr": "कुंभ",
        "name_hi": "कुम्भ",
        "aliases": [
            "kumbh", "kumbha", "kumb", "aquarius", "कुंभ", "कुम्भ",
            "कुंभ राशी", "kumbh rashi", "कुम्भ राशि", "kumb rashifal", "kumbh rashifal"
        ]
    },
    {
        "id": "meen",
        "app_id": "pisces",
        "name_en": "Pisces",
        "name_mr": "मीन",
        "name_hi": "मीन",
        "aliases": ["meen", "meena", "mina", "pisces", "मीन", "मीन राशी", "meen rashi", "मीन राशि"]
    }
]

# 2. Definitive App Features Mapping
FEATURES = [
    {
        "key": "horoscope",
        "title_en": "Horoscope / Rashifal",
        "title_mr": "राशीभविष्य",
        "title_hi": "राशिफल",
        "aliases": ["horoscope", "rashifal", "rashi bhavishya", "राशीभविष्य", "भविष्य", "राशी", "राशिफल", "astrology"],
        "default_action": "open_horoscope"
    },
    {
        "key": "panchang",
        "title_en": "Vedic Panchang",
        "title_mr": "पंचांग",
        "title_hi": "पंचांग",
        "aliases": ["panchang", "पंचांग", "tithi", "तिथी", "rahu kaal", "राहुकाळ", "राहु काल", "muhurat", "मुहूर्त", "shubh muhurat"],
        "default_action": "open_panchang"
    },
    {
        "key": "mandir",
        "title_en": "Garbhagriha Mandir",
        "title_mr": "मंदिर दर्शन",
        "title_hi": "मंदिर दर्शन",
        "aliases": ["mandir", "darshan", "garbhagriha", "मंदिर", "दर्शन", "गाभारा", "देवघर", "arti thali"],
        "default_action": "open_mandir"
    },
    {
        "key": "jaap",
        "title_en": "Jaap Counter / Mala",
        "title_mr": "जप माळ",
        "title_hi": "जाप माला",
        "aliases": [
            "jaap", "jap", "japa", "mala", "chant", "जप", "जाप", "नामजप", "नाम जप",
            "naam jaap", "nam jap", "naam jap", "nam jaap", "naamjaap", "namjaap",
            "माळ", "माला", "jaap counter", "counter", "mantra"
        ],
        "default_action": "start_jaap"
    },
    {
        "key": "akhand_diya",
        "title_en": "Akhand Diya",
        "title_mr": "अखंड दिवा",
        "title_hi": "अखंड दीया",
        # Never use bare "jyot"/"ज्योत" — they substring-match "jyotiba"/"ज्योतिबा".
        "aliases": [
            "akhand diya", "akhand jyot", "akhand jyoti", "akhandjyot",
            "diya", "दीपक", "दिवा",
            "अखंड दिवा", "अखंड दीया", "अखंड ज्योत", "अखंड ज्योति",
        ],
        "default_action": "open_akhand_diya"
    },
    {
        "key": "granth",
        "title_en": "Pothi & Granth",
        "title_mr": "पोथी आणि ग्रंथ",
        "title_hi": "पोथी और ग्रंथ",
        "aliases": ["granth", "pothi", "adhyay", "पोथी", "ग्रंथ", "अध्याय", "gurucharitra", "गुरुचरित्र", "dasbodh", "दासबोध", "shivlilamrut", "शिवलीलामृत"],
        "default_action": "open_granth"
    },
    {
        "key": "kundali",
        "title_en": "Kundali & Milan",
        "title_mr": "कुंडली आणि मिलन",
        "title_hi": "कुंडली और मिलान",
        "aliases": [
            "kundali", "patrika", "kundli", "kundali chart", "birth chart",
            "janma kundali", "janam kundali", "open kundali", "chart",
            "पत्रिका", "कुंडली", "जन्म कुंडली", "कुंडली चार्ट", "गुण मिलन", "कुंडली मिलन"
        ],
        "default_action": "open_kundali"
    },
    {
        "key": "milan",
        "title_en": "Kundali Milan",
        "title_mr": "कुंडली मिलन",
        "title_hi": "कुंडली मिलान",
        "aliases": ["milan", "gun milan", "guna milan", "मिलन", "गुण मिलन", "कुंडली मिलन", "कुंडली मिलान"],
        "default_action": "open_milan"
    },
    {
        "key": "ishta_devta",
        "title_en": "Ishta Devta Calculator",
        "title_mr": "इष्ट देवता",
        "title_hi": "इष्ट देवता",
        "aliases": ["ishta devta", "ishta dev", "कुलदैवत", "इष्ट देव", "इष्ट देवता"],
        "default_action": "open_ishta_devta"
    },
    {
        "key": "greetings",
        "title_en": "Daily Suvichar & Greetings",
        "title_mr": "दैनिक सुविचार व शुभेच्छा",
        "title_hi": "दैनिक सुविचार व शुभकामनाएं",
        "aliases": ["suvichar", "greetings", "subhashit", "सुविचार", "शुभेच्छा", "status card", "शुभ सकाळ"],
        "default_action": "open_greetings"
    },
    {
        "key": "grahan",
        "title_en": "Grahan / Eclipse Timings",
        "title_mr": "सूर्य व चंद्र ग्रहण",
        "title_hi": "सूर्य व चंद्र ग्रहण",
        "aliases": ["grahan", "eclipse", "ग्रहण", "सूर्य ग्रहण", "चंद्र ग्रहण"],
        "default_action": "open_grahan"
    }
]

def extract_devotional_catalog_json():
    """Extracts from assets/devotional_catalog.json"""
    json_file = BASE_DIR / "assets" / "devotional_catalog.json"
    if not json_file.exists():
        return []
    try:
        with open(json_file, "r", encoding="utf-8") as f:
            data = json.load(f)
            return data.get("catalog", [])
    except Exception as e:
        print(f"Error reading devotional_catalog.json: {e}")
        return []


def fetch_live_catalog(url: str = LIVE_CATALOG_URL):
    """Pulls production /api/v1/catalog (remote aartis + deities)."""
    print(f"Fetching live catalog: {url}")
    try:
        req = urllib.request.Request(
            url,
            headers={"User-Agent": "BhaktiDhara-VoiceKnowledge/1.0", "Accept": "application/json"},
        )
        with urllib.request.urlopen(req, timeout=30) as resp:
            raw = resp.read()
        data = json.loads(raw.decode("utf-8"))
        LIVE_CATALOG_SNAPSHOT.write_bytes(raw)
        print(
            f"Live catalog OK version={data.get('version')} "
            f"aartis={len(data.get('aartis') or [])} "
            f"deities={len(data.get('deities') or [])}"
        )
        return data
    except Exception as e:
        print(f"Live catalog fetch failed ({e}); continuing with local sources only.")
        if LIVE_CATALOG_SNAPSHOT.exists():
            try:
                with LIVE_CATALOG_SNAPSHOT.open(encoding="utf-8") as f:
                    data = json.load(f)
                print(f"Using cached snapshot {LIVE_CATALOG_SNAPSHOT}")
                return data
            except Exception:
                pass
        return {"aartis": [], "deities": [], "version": None}


def normalize_aarti_row(it: dict, source: str) -> dict | None:
    it_id = (it.get("id") or "").strip()
    if not it_id or "$" in it_id:
        return None
    return {
        "id": it_id,
        "title": it.get("title") or it_id,
        "titleHi": it.get("titleHi") or it.get("title") or "",
        "titleMr": it.get("titleMr") or it.get("title") or "",
        "deity": it.get("deity") or "Devotional",
        "deityHi": it.get("deityHi") or it.get("deity") or "",
        "deityMr": it.get("deityMr") or it.get("deity") or "",
        "youtubeVideoId": it.get("youtubeVideoId") or "",
        **{key: it.get(key) or "" for key in ("about", "aboutHi", "aboutMr", "singer", "durationText")},
        "source_file": source,
        "live": source.startswith("live:"),
    }


def extract_live_deities(live: dict) -> list:
    deities = []
    for d in live.get("deities") or []:
        key = (d.get("key") or "").strip()
        if not key:
            continue
        aliases = d.get("aliases") or []
        if isinstance(aliases, str):
            aliases = [a.strip() for a in aliases.split(",") if a.strip()]
        deities.append({
            "key": key,
            "name_en": d.get("nameEn") or key,
            "name_hi": d.get("nameHi") or "",
            "name_mr": d.get("nameMr") or "",
            "aliases": aliases,
            "source": "live",
        })
    return deities

def extract_from_dart_catalogs():
    """Extracts aartis and devotional songs from lib/data/datasources/*.dart"""
    datasources_dir = BASE_DIR / "lib" / "data" / "datasources"
    items = []
    
    # Simple regex pattern to capture AartiItem(...) constructors
    item_pattern = re.compile(
        r"AartiItem\s*\(\s*id:\s*['\"]([^'\"]+)['\"].*?"
        r"title:\s*['\"]([^'\"]+)['\"].*?"
        r"(?:titleHi:\s*['\"]([^'\"]+)['\"].*?)?"
        r"(?:titleMr:\s*['\"]([^'\"]+)['\"].*?)?"
        r"deity:\s*['\"]([^'\"]+)['\"].*?"
        r"(?:deityHi:\s*['\"]([^'\"]+)['\"].*?)?"
        r"(?:deityMr:\s*['\"]([^'\"]+)['\"].*?)?",
        re.DOTALL
    )
    
    for dart_file in datasources_dir.glob("*.dart"):
        try:
            content = dart_file.read_text(encoding="utf-8")
            # Find all AartiItem blocks
            blocks = content.split("AartiItem(")
            for block in blocks[1:]:
                # Extract fields with individual regexes for robustness
                id_m = re.search(r"id:\s*['\"]([^'\"]+)['\"]", block)
                if not id_m:
                    continue
                item_id = id_m.group(1)
                
                title_m = re.search(r"title:\s*['\"]([^'\"]+)['\"]", block)
                title_hi_m = re.search(r"titleHi:\s*['\"]([^'\"]+)['\"]", block)
                title_mr_m = re.search(r"titleMr:\s*['\"]([^'\"]+)['\"]", block)
                
                deity_m = re.search(r"deity:\s*['\"]([^'\"]+)['\"]", block)
                deity_hi_m = re.search(r"deityHi:\s*['\"]([^'\"]+)['\"]", block)
                deity_mr_m = re.search(r"deityMr:\s*['\"]([^'\"]+)['\"]", block)
                
                video_m = re.search(r"youtubeVideoId:\s*['\"]([^'\"]+)['\"]", block)
                
                items.append({
                    "id": item_id,
                    "title": title_m.group(1) if title_m else item_id,
                    "titleHi": title_hi_m.group(1) if title_hi_m else "",
                    "titleMr": title_mr_m.group(1) if title_mr_m else "",
                    "deity": deity_m.group(1) if deity_m else "Devotional",
                    "deityHi": deity_hi_m.group(1) if deity_hi_m else "",
                    "deityMr": deity_mr_m.group(1) if deity_mr_m else "",
                    "youtubeVideoId": video_m.group(1) if video_m else "",
                    "source_file": dart_file.name
                })
        except Exception as e:
            print(f"Error reading {dart_file.name}: {e}")
            
    return items

def openable_catalog():
    # Dart evaluates computed regional entries and the same collection the UI opens.
    export = DATA_DIR / "bundled_voice_catalog.json"
    dart = shutil.which("dart")
    if dart:
        output = subprocess.check_output(
            [dart, str(BASE_DIR / "backend/scripts/export_voice_catalog.dart")], cwd=BASE_DIR,
        )
        rows = json.loads(output)
        if not rows["aartis"]:
            raise ValueError("Flutter returned an empty devotional catalog")
        export.write_bytes(output)
        return rows
    if export.exists():
        cached = json.loads(export.read_text(encoding="utf-8"))
        return cached if isinstance(cached, dict) else {"aartis": cached, "songs": []}
    # Older Python-only checkouts can still build their legacy catalog.
    return {"aartis": extract_from_dart_catalogs() + extract_devotional_catalog_json(), "songs": []}


def main():
    print("Extracting BhaktiDhara data...")
    if os.environ.get("BHAKTI_CACHED_LIVE") == "1":
        live = json.loads(LIVE_CATALOG_SNAPSHOT.read_text()) if LIVE_CATALOG_SNAPSHOT.exists() else {}
    else:
        live = fetch_live_catalog()
    all_aartis = {}
    bundled = openable_catalog()
    for item in bundled["aartis"]:
        row = normalize_aarti_row(item, "flutter")
        if row:
            all_aartis.setdefault(row["id"], row)

    live_count = 0
    for it in live.get("aartis") or []:
        # Match the Flutter remote catalog requirements before offering a route.
        if not all(isinstance(it.get(key), str) and it[key].strip()
                   for key in ("id", "title", "deity", "youtubeVideoId")):
            continue
        if not any(isinstance(stanza, dict) and str(stanza.get("devanagari") or "").strip()
                   for stanza in it.get("lyrics") or []):
            continue
        row = normalize_aarti_row(it, f"live:{live.get('version') or 'catalog'}")
        if row:
            all_aartis.setdefault(row["id"], row)
            live_count += 1

    live_deities = extract_live_deities(live)
    aarti_list = list(all_aartis.values())
    print(
        f"Extracted {len(aarti_list)} unique Aartis / Stotras / Bhajans "
        f"(live rows merged: {live_count}, live deities: {len(live_deities)})."
    )
    
    # Build SQLite DB
    if DB_PATH.exists():
        DB_PATH.unlink()
        
    conn = sqlite3.connect(DB_PATH)
    cur = conn.cursor()
    
    # 1. Create aartis table & FTS
    cur.execute("""
    CREATE TABLE aartis (
        id TEXT PRIMARY KEY,
        title TEXT,
        title_hi TEXT,
        title_mr TEXT,
        deity TEXT,
        deity_hi TEXT,
        deity_mr TEXT,
        youtube_video_id TEXT,
        has_audio INTEGER
    );
    """)
    cur.execute("""
    CREATE VIRTUAL TABLE aartis_fts USING fts5(
        id, title, title_hi, title_mr, deity, deity_hi, deity_mr
    );
    """)
    
    for a in aarti_list:
        has_audio = 1 if a.get("youtubeVideoId") else 0
        cur.execute("""
        INSERT INTO aartis VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
        """, (
            a["id"], a["title"], a.get("titleHi", ""), a.get("titleMr", ""),
            a.get("deity", ""), a.get("deityHi", ""), a.get("deityMr", ""),
            a.get("youtubeVideoId", ""), has_audio
        ))
        cur.execute("""
        INSERT INTO aartis_fts VALUES (?, ?, ?, ?, ?, ?, ?)
        """, (
            a["id"], a["title"], a.get("titleHi", ""), a.get("titleMr", ""),
            a.get("deity", ""), a.get("deityHi", ""), a.get("deityMr", "")
        ))
        
    # 2. Create rashis table
    cur.execute("""
    CREATE TABLE rashis (
        id TEXT PRIMARY KEY,
        app_id TEXT,
        name_en TEXT,
        name_mr TEXT,
        name_hi TEXT,
        aliases TEXT
    );
    """)
    for r in RASHIS:
        cur.execute("INSERT INTO rashis VALUES (?, ?, ?, ?, ?, ?)", (
            r["id"], r.get("app_id", r["id"]), r["name_en"], r["name_mr"], r["name_hi"],
            ",".join(r["aliases"])
        ))
        
    # 3. Create features table
    cur.execute("""
    CREATE TABLE features (
        key TEXT PRIMARY KEY,
        title_en TEXT,
        title_mr TEXT,
        title_hi TEXT,
        aliases TEXT,
        default_action TEXT
    );
    """)
    for f in FEATURES:
        cur.execute("INSERT INTO features VALUES (?, ?, ?, ?, ?, ?)", (
            f["key"], f["title_en"], f["title_mr"], f["title_hi"], ",".join(f["aliases"]), f["default_action"]
        ))
        
    conn.commit()
    conn.close()
    print(f"Created SQLite database at {DB_PATH}")
    
    # Save combined JSON knowledge
    knowledge = {
        "rashis": RASHIS,
        "features": FEATURES,
        "aartis": aarti_list,
        "songs": bundled["songs"],
        "deities": live_deities,
        "live_catalog_version": live.get("version"),
        "live_catalog_url": LIVE_CATALOG_URL,
    }
    with open(JSON_PATH, "w", encoding="utf-8") as f:
        json.dump(knowledge, f, ensure_ascii=False, indent=2)
    print(f"Saved JSON knowledge to {JSON_PATH}")

if __name__ == "__main__":
    main()
