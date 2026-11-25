"""Prepare the Home-only LoRA, weighting result selection and cancellations."""
import json
import os
import random
from collections import defaultdict
from pathlib import Path

from voice_training_examples import HOME_CONTROL_PROMPT, home_records, home_evaluation_queries, transcript_key


def prepare(directory):
    adapter_dir = Path(os.environ.get("BHAKTI_MLX_OUTPUT", directory.parent.parent))
    adapter_dir.mkdir(parents=True, exist_ok=True)
    (adapter_dir / "home_control_prompt.txt").write_text(HOME_CONTROL_PROMPT, encoding="utf-8")
    rng = random.Random(42)
    reserved = home_evaluation_queries()
    groups = defaultdict(list)
    seen = set()
    for split in ("plain", "mixed"):
        for row in home_records(split):
            system, user, assistant = row["messages"]
            key = transcript_key(user["content"])
            if key in seen or key in reserved:
                continue
            seen.add(key)
            system["content"] = HOME_CONTROL_PROMPT
            action = json.loads(assistant["content"])["action"]
            # The screen supplies the spoken response after resolving current state.
            assistant["content"] = json.dumps({"action": action}, ensure_ascii=False)
            groups[action["type"], action.get("feature_key")].append(row)

    train, valid = [], []
    for (kind, topic), rows in groups.items():
        rng.shuffle(rows)
        n = max(1, len(rows) // 10) if len(rows) >= 4 else 0
        valid.extend(rows[:n][:12])
        remaining = rows[n:]
        limit = {"open_home_result": 220, "none": 120, "filter_home": 45,
                 "search_home": 45, "read_home_region": 30, "read_home_search": 30}.get(kind, 5)
        train.extend(remaining[:limit])
    for split, rows in (("train", train), ("valid", valid)):
        rng.shuffle(rows)
        directory.mkdir(parents=True, exist_ok=True)
        (directory / f"{split}.jsonl").write_text(
            "".join(json.dumps(row, ensure_ascii=False) + "\n" for row in rows), encoding="utf-8")
        print(f"{split}: {len(rows)}")


if __name__ == "__main__":
    prepare(Path(os.environ["BHAKTI_TRAIN_DIR"]) / "mlx")
