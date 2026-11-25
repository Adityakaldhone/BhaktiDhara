#!/usr/bin/env python3
"""
Generates comprehensive multi-lingual Supervised Fine-Tuning (SFT) training datasets
in JSONL format (OpenAI / HuggingFace ShareGPT / Alpaca compatible) for training
open-source LLMs on the BhaktiDhara app codebase & devotional catalogs.
"""

import json
import os
from pathlib import Path

from voice_training_examples import (SYSTEM_PROMPT, HOME_PROMPT, coverage_examples,
                                     home_evaluation_queries, home_records, transcript_key)

BASE_DIR = Path(__file__).resolve().parent.parent.parent
DATA_DIR = BASE_DIR / "backend" / "data"
KNOWLEDGE_PATH = DATA_DIR / "voice_knowledge.json"
TRAIN_DIR = Path(os.environ.get("BHAKTI_TRAIN_DIR") or DATA_DIR / "training")
JSONL_OUTPUT = TRAIN_DIR / "bhaktidhara_voice_agent_train.jsonl"
ALPACA_OUTPUT = TRAIN_DIR / "bhaktidhara_alpaca_train.json"

TRAIN_DIR.mkdir(parents=True, exist_ok=True)

def create_sample(user_query: str, action: dict, response_text: str):
    output_obj = {
        "action": action,
        "response_text": response_text
    }
    return {
        "messages": [
            {"role": "system", "content": SYSTEM_PROMPT},
            {"role": "user", "content": user_query},
            {"role": "assistant", "content": json.dumps(output_obj, ensure_ascii=False)}
        ]
    }

def main():
    if not KNOWLEDGE_PATH.exists():
        raise SystemExit(f"Missing {KNOWLEDGE_PATH}. Run extract_voice_knowledge.py first.")

    with open(KNOWLEDGE_PATH, "r", encoding="utf-8") as f:
        knowledge = json.load(f)

    rashis = knowledge.get("rashis", [])
    features = knowledge.get("features", [])
    aartis = knowledge.get("aartis", [])
    deities = knowledge.get("deities", [])
    live_version = knowledge.get("live_catalog_version")
    if live_version:
        print(f"Using knowledge with live catalog version: {live_version}")

    train_samples = []

    # 1. Rashi & Horoscope Dataset
    for r in rashis:
        # Prefer Flutter catalog id (aquarius) over Vedic slug (kumbh)
        r_id = r.get("app_id") or r["id"]
        r_vedic = r["id"]
        r_mr = r["name_mr"]
        r_hi = r["name_hi"]
        r_en = r["name_en"]

        act = {
            "type": "open_horoscope",
            "rashi_id": r_id,
            "rashi_name": r_mr,
            "feature_key": "horoscope"
        }

        # Marathi queries
        mr_queries = [
            f"{r_mr} राशीचे आजचे भविष्य दाखवा",
            f"मला आजचे {r_mr} राशीचे राशीभविष्य सांगा",
            f"{r_mr} रास आज कशी आहे?",
            f"{r_mr} राशीचे आजचे भविष्य काय सांगते?",
            f"{r_mr} राशीचे भविष्य उघडा"
        ]
        mr_reply = f"{r_mr} राशीचे आजचे राशीभविष्य उघडत आहे."
        for q in mr_queries:
            train_samples.append(create_sample(q, act, mr_reply))

        # Hindi queries
        hi_queries = [
            f"{r_hi} राशि का आज का राशिफल दिखाओ",
            f"आज का {r_hi} राशिफल क्या है?",
            f"मुझे {r_hi} राशि का भविष्य बताओ",
            f"{r_hi} राशि का दैनिक राशिफल खोलो"
        ]
        hi_reply = f"{r_hi} राशि का आज का राशिफल खोला जा रहा है।"
        for q in hi_queries:
            train_samples.append(create_sample(q, act, hi_reply))

        # English / Hinglish queries
        en_queries = [
            f"Show today's horoscope for {r_en}",
            f"{r_vedic} rashifal dikhao",
            f"show the {r_vedic} rashifal",
            f"Open {r_en} daily horoscope",
            f"What is {r_en} rashi today?",
        ]
        en_reply = f"Opening today's horoscope for {r_en}."
        for q in en_queries:
            train_samples.append(create_sample(q, act, en_reply))

    # 2. Panchang & Muhurat Dataset
    panchang_items = [
        ("आजचा राहुकाळ किती वाजता आहे?", {"type": "open_panchang", "field": "rahu_kaal", "feature_key": "panchang"}, "आजचा राहुकाळ व पंचांग उघडत आहे."),
        ("आज का राहुकाल क्या है?", {"type": "open_panchang", "field": "rahu_kaal", "feature_key": "panchang"}, "आज का राहुकाल व पंचांग देखा जा रहा है।"),
        ("What is today's Rahu Kaal timing?", {"type": "open_panchang", "field": "rahu_kaal", "feature_key": "panchang"}, "Checking Rahu Kaal in today's Panchang."),
        ("आजची तिथी सांगा", {"type": "open_panchang", "field": "tithi", "feature_key": "panchang"}, "आजची तिथी व पंचांग उघडत आहे."),
        ("आज कौन सी तिथि है?", {"type": "open_panchang", "field": "tithi", "feature_key": "panchang"}, "आज की तिथि और पंचांग खोला जा रहा है।"),
        ("आजचे संपूर्ण पंचांग दाखवा", {"type": "open_panchang", "feature_key": "panchang"}, "आजचे संपूर्ण वैदिक पंचांग उघडत आहे."),
        ("आज का शुभ मुहूर्त बताओ", {"type": "open_panchang", "field": "muhurat", "feature_key": "panchang"}, "आज का शुभ मुहूर्त व पंचांग खोला जा रहा है।")
    ]
    for q, act, reply in panchang_items:
        train_samples.append(create_sample(q, act, reply))

    # 3. Mandir & 3D Garbhagriha
    mandir_items = [
        ("मंदिरात दर्शन करायचे आहे", {"type": "open_mandir", "feature_key": "mandir"}, "श्री मंदिर गर्भगृह दर्शन सुरू करत आहे."),
        ("मंदिर दर्शन खोलो", {"type": "open_mandir", "feature_key": "mandir"}, "मंदिर गर्भगृह दर्शन खोला जा रहा है।"),
        ("मला देवाचे दर्शन घ्यायचे आहे", {"type": "open_mandir", "feature_key": "mandir"}, "श्री मंदिर गर्भगृह दर्शन सुरू करत आहे."),
        ("Open Mandir Darshan", {"type": "open_mandir", "feature_key": "mandir"}, "Opening Garbhagriha Mandir darshan.")
    ]
    for q, act, reply in mandir_items:
        train_samples.append(create_sample(q, act, reply))

    # Curated multilingual utterances, aliases, and unsupported requests.
    for q, act, reply in coverage_examples():
        train_samples.append(create_sample(q, act, reply))

    # Granth opens the catalog. The client has no voice book/chapter action.
    for q in ("श्री गुरुचरित्र अध्याय ३ उघडा", "दासबोध उघडा",
              "शिवलीलामृत पोथी दाखवा", "Open Gurucharitra Chapter 1"):
        train_samples.append(create_sample(
            q, {"type": "open_granth", "feature_key": "granth"}, "Opening the granth library."
        ))

    # 6. Kundali, Milan & Ishta Devta
    feature_items = [
        ("पत्रिका बघायची आहे", {"type": "open_kundali", "feature_key": "kundali"}, "कुंडली पत्रिका उघडत आहे."),
        ("कुंडली उघडा", {"type": "open_kundali", "feature_key": "kundali"}, "कुंडली उघडत आहे."),
        ("open kundali chart", {"type": "open_kundali", "feature_key": "kundali"}, "Opening your kundali chart."),
        ("open birth chart", {"type": "open_kundali", "feature_key": "kundali"}, "Opening your kundali chart."),
        ("kundali chart kholo", {"type": "open_kundali", "feature_key": "kundali"}, "Opening your kundali chart."),
        ("जन्म कुंडली दिखाओ", {"type": "open_kundali", "feature_key": "kundali"}, "कुंडली खोली जा रही है।"),
        ("कुंडली मिलन दाखवा", {"type": "open_milan", "feature_key": "milan"}, "कुंडली मिलन उघडत आहे."),
        ("open kundali milan", {"type": "open_milan", "feature_key": "milan"}, "Opening kundali milan."),
        ("माझे इष्ट दैवत कोणते आहे?", {"type": "open_ishta_devta", "feature_key": "ishta_devta"}, "इष्ट देवता शोधक उघडत आहे."),
        ("आजचा सुविचार पाठवा", {"type": "open_greetings", "feature_key": "greetings"}, "दैनिक सुविचार व शुभेच्छा उघडत आहे."),
        # Hard negatives: must NOT open aarti
        ("open kundali not aarti", {"type": "open_kundali", "feature_key": "kundali"}, "Opening your kundali chart."),
    ]

    # 6b. Hard negatives: kumbh/rashifal must NEVER become kundali (sound-alike trap)
    kumbh_act = {
        "type": "open_horoscope",
        "rashi_id": "aquarius",
        "rashi_name": "कुंभ",
        "feature_key": "horoscope",
    }
    kumbh_hard = [
        ("show the kumbh rashifal", "Opening today's horoscope for Aquarius."),
        ("kumbh rashifal dikhao", "Opening today's horoscope for Aquarius."),
        ("कुंभ राशिफल दिखाओ", "कुंभ राशि का आज का राशिफल खोला जा रहा है।"),
        ("कुंभ राशीचे भविष्य दाखवा", "कुंभ राशीचे आजचे राशीभविष्य उघडत आहे."),
        ("open kumbh horoscope not kundali", "Opening today's horoscope for Aquarius."),
        ("kumbh rashi not kundali chart", "Opening today's horoscope for Aquarius."),
        ("aquarius rashifal", "Opening today's horoscope for Aquarius."),
    ]
    for q, reply in kumbh_hard:
        train_samples.append(create_sample(q, kumbh_act, reply))

    kundali_vs_kumbh = [
        ("open kundali chart not kumbh", {"type": "open_kundali", "feature_key": "kundali"}, "Opening your kundali chart."),
        ("birth chart kundali", {"type": "open_kundali", "feature_key": "kundali"}, "Opening your kundali chart."),
    ]
    for q, act, reply in kundali_vs_kumbh:
        train_samples.append(create_sample(q, act, reply))
    for q, act, reply in feature_items:
        train_samples.append(create_sample(q, act, reply))

    # 7. Live / remote deities (open deity list style → often aarti by deity name)
    for d in deities:
        key = d.get("key") or ""
        name_mr = d.get("name_mr") or key
        name_hi = d.get("name_hi") or key
        name_en = d.get("name_en") or key
        aliases = d.get("aliases") or []
        # Without a concrete aarti_id, teach open/search by deity query.
        open_act = {
            "type": "open_aarti",
            "query": name_en,
            "title": name_mr,
        }
        queries = [
            (f"{name_mr} ची आरती उघडा", f"{name_mr} ची आरती उघडत आहे."),
            (f"{name_hi} की आरती खोलो", f"{name_hi} की आरती खोली जा रही है।"),
            (f"Open {name_en} aarti", f"Opening aarti for {name_en}."),
            (f"{name_en} aarti dikhao", f"Opening aarti for {name_en}."),
        ]
        for alias in aliases:
            queries.append((f"{alias} aarti open", f"Opening aarti for {name_en}."))
        for q, reply in queries:
            train_samples.append(create_sample(q, open_act, reply))

    # 8. Aartis, Stotras & Bhajans (local + live catalog items)
    for a in aartis:
        a_id = a["id"]
        t_en = a.get("title", "")
        t_mr = a.get("titleMr") or t_en
        t_hi = a.get("titleHi") or t_en
        has_audio = bool(a.get("youtubeVideoId"))

        play_act = {
            "type": "play_aarti",
            "aarti_id": a_id,
            "title": t_mr,
            "has_audio": has_audio
        }
        open_act = {
            "type": "open_aarti",
            "aarti_id": a_id,
            "title": t_mr,
            "has_audio": has_audio
        }

        # Teach lookup by title. Metadata and availability are read at request time.
        for field, query, title in (
            ("singer", f"Who is the singer of {t_en}?", t_en),
            ("duration", f"How long is the recording of {t_en}?", t_en),
            ("about", f"{t_mr} बद्दल माहिती द्या", t_mr),
            ("availability", f"{t_hi} ऐप में है?", t_hi),
            ("audio", f"Does {t_en} have a recording?", t_en),
        ):
            train_samples.append(create_sample(query, {
                "type": "answer_app_question", "feature_key": "catalog", "field": field, "query": title,
            }, "Checking the catalog."))

        # Marathi queries
        train_samples.append(create_sample(f"{t_mr} लावा", play_act, f"{t_mr} सुरू करत आहे."))
        train_samples.append(create_sample(f"{t_mr} उघडा", open_act, f"{t_mr} उघडत आहे."))

        # Hindi queries
        train_samples.append(create_sample(f"{t_hi} चलाओ", play_act, f"{t_hi} शुरू की जा रही है।"))
        train_samples.append(create_sample(f"{t_hi} खोलो", open_act, f"{t_hi} खोला जा रहा है।"))

        # English queries
        train_samples.append(create_sample(f"Play {t_en}", play_act, f"Opening {t_en}."))
        train_samples.append(create_sample(f"Read the lyrics of {t_en}", open_act, f"Opening {t_en}."))
        train_samples.append(create_sample(f"{t_en} sunao", play_act, f"Opening {t_en}."))
        train_samples.append(create_sample(f"{t_en} vachayche aahe", open_act, f"Opening {t_en}."))

    held_out = home_evaluation_queries()
    home_rows = home_records("plain") + home_records("mixed")
    for row in home_rows:
        row["messages"][0]["content"] = HOME_PROMPT
    # Prefer the reviewed Home label when an older generator emits the same request.
    unique = {transcript_key(row["messages"][1]["content"]): row for row in train_samples + home_rows}
    train_samples = [row for key, row in unique.items() if key not in held_out]
    alpaca_samples = []
    for sample in train_samples:
        _, user, assistant = sample["messages"]
        alpaca_samples.append({
            "instruction": sample["messages"][0]["content"],
            "input": user["content"],
            "output": assistant["content"],
        })

    print(f"Generated {len(train_samples)} training samples.")

    # Write JSONL (Chat / OpenAI / Unsloth format)
    with open(JSONL_OUTPUT, "w", encoding="utf-8") as f:
        for s in train_samples:
            f.write(json.dumps(s, ensure_ascii=False) + "\n")
    print(f"Saved OpenAI/HuggingFace JSONL training dataset to:\n  {JSONL_OUTPUT}")

    # Write Alpaca format
    with open(ALPACA_OUTPUT, "w", encoding="utf-8") as f:
        json.dump(alpaca_samples, f, ensure_ascii=False, indent=2)
    print(f"Saved Alpaca format dataset to:\n  {ALPACA_OUTPUT}")

    # Generate an Ollama Modelfile for immediate local customized model building
    modelfile_path = TRAIN_DIR / "Modelfile"
    modelfile_content = f"""FROM qwen2.5:3b

# Set model temperature and parameters for deterministic and devotional assistant
PARAMETER temperature 0.1
PARAMETER top_p 0.95
PARAMETER stop "<|im_end|>"
PARAMETER stop "<|endoftext|>"

# Set the System Prompt embedded with BhaktiDhara's app capabilities
SYSTEM \"\"\"{SYSTEM_PROMPT}\"\"\"
"""
    with open(modelfile_path, "w", encoding="utf-8") as f:
        f.write(modelfile_content)
    print(f"Saved Ollama Modelfile to:\n  {modelfile_path}")

if __name__ == "__main__":
    main()
