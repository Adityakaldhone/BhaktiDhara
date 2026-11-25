"""Prepare paired feature questions and executable screen requests for MLX."""
import json
import os
import random
import sys
from collections import defaultdict
from pathlib import Path

from voice_training_examples import coverage_examples, home_evaluation_queries, transcript_key

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))
from app.voice_agent.prompt import feature_prompt

HELP = json.loads((ROOT / "app/voice_agent/app_help.json").read_text())
TOPICS = HELP["topics"]

QUESTIONS = {
    "en": ["How does {name} work?", "Explain {name} to me", "What can I do with {name}?", "I'm new to {name}. How do I use it?"],
    "hi": ["{name} कैसे इस्तेमाल करूँ?", "{name} के बारे में समझाइए", "{name} में क्या मिलता है?"],
    "mr": ["{name} कसं वापरायचं?", "{name} बद्दल माहिती द्या", "{name} मध्ये काय करता येतं?"],
}
COMMANDS = {
    "en": ["Open {name}", "I'd like to go to {name}", "Could you take me to {name}?", "Bring up {name} please"],
    "hi": ["{name} खोल दो", "मुझे {name} पर ले चलो", "{name} दिखाइए"],
    "mr": ["{name} उघडा", "मला {name} वर घेऊन जा", "{name} दाखव"],
}


# Nearby words can also refer to another app, a shop or an unsupported operation.
OUTSIDE_APP = (
    "Open my banking app's inbox", "Read the alerts from my work email", "Show me messages in my social media account",
    "Change my mobile keyboard language", "Pin a message in our group chat", "Unlock my bank card",
    "I forgot the PIN for my ATM", "Tell me the code that unlocks my SIM card", "Track my parcel",
    "Pay my electricity bill", "Book a physical temple visit for tomorrow", "Buy a brass lamp",
    "Find a shop selling clarified butter", "How much does a jar of ghee cost?", "Send flower delivery to my house",
    "Find today's temperature near the shrine", "Show rain clouds over the temple", "When will the storm reach my city?",
    "Erase all my notification messages", "Switch on notifications for another application", "Open a restaurant menu",
    "Export my chant streak to a spreadsheet", "Order a printed horoscope by post", "Mute all alerts on my phone",
    "Reset my debit card passcode", "Write a song about this app", "Buy me a ticket for an eclipse tour",
    "मेरे बैंक के संदेश दिखाओ", "दुकान से दीपक मंगवा दो", "मोबाइल का पासकोड बताओ", "मौसम का नक्शा दिखाओ",
    "सारे जप रिकॉर्ड हटाओ", "मेरे ईमेल के नोटिफिकेशन दिखाओ", "माझ्या बँकेचा पिन बदला",
    "घरासाठी तूप मागवा", "उद्याच्या पावसाचा अंदाज सांगा", "माझ्या फोनमधले सगळे मेसेज पुसा",
    "दुसऱ्या अॅपमधली सूचना वाचा", "माझ्यासाठी पूजा साहित्य खरेदी करा",
)


def prepare(directory):
    directory.mkdir(parents=True, exist_ok=True)
    prompt = feature_prompt(TOPICS)
    buckets = defaultdict(list)
    seen = home_evaluation_queries()

    def add(query, action):
        key = transcript_key(query)
        if key in seen:
            return
        seen.add(key)
        bucket = action.get("feature_key") if action["type"] == "answer_app_question" else action["type"]
        buckets[bucket].append({"messages": [{"role": "system", "content": prompt},
            {"role": "user", "content": query}, {"role": "assistant", "content": json.dumps(
                {"action": action}, ensure_ascii=False, separators=(",", ":"))}]})

    for topic, info in TOPICS.items():
        answer = {"type": "answer_app_question", "feature_key": topic}
        for query in info["examples"]:
            add(query, answer)
        for lang, name in info["labels"].items():
            for template in QUESTIONS[lang]:
                add(template.format(name=name), answer)
            if action := info.get("screen_action"):
                for template in COMMANDS[lang]:
                    add(template.format(name=name), {"type": action})
    for query, action, _ in coverage_examples():
        if action["type"] not in ("open_aarti", "play_aarti"):
            add(query, action)
    for query in OUTSIDE_APP:
        add(query, {"type": "none"})
    rng = random.Random(42)
    train, valid = [], []
    for bucket, items in buckets.items():
        rng.shuffle(items)
        n = max(1, len(items) // 10) if len(items) >= 3 else 0
        valid.extend(items[:n])
        train.extend(items[n:] if os.environ.get("BHAKTI_MLX_FEATURE_NEGATIVES") == "1" and bucket == "none"
                     else items[n:n + 36])
    if os.environ.get("BHAKTI_MLX_FEATURE_NEGATIVES") == "1":
        negative, replay = [], []
        for row in train:
            kind = json.loads(row["messages"][-1]["content"])["action"]["type"]
            (negative if kind == "none" else replay).append(row)
        train = negative + rng.sample(replay, min(len(replay), 2 * len(negative)))
    for split, rows in (("train", train), ("valid", valid)):
        rng.shuffle(rows)
        with (directory / (split + ".jsonl")).open("w") as f:
            for row in rows:
                f.write(json.dumps(row, ensure_ascii=False) + "\n")
    adapter_dir = Path(os.environ.get("BHAKTI_MLX_OUTPUT", directory.parent.parent))
    adapter_dir.mkdir(parents=True, exist_ok=True)
    (adapter_dir / "prompt.txt").write_text(prompt)
    print(f"Feature adapter: {len(TOPICS)} topics, {len(train)} training rows, {len(valid)} validation rows.")


if __name__ == "__main__":
    prepare(Path(os.environ["BHAKTI_TRAIN_DIR"]) / "mlx")
