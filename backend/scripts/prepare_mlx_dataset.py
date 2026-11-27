#!/usr/bin/env python3
"""
Split BhaktiDhara voice SFT JSONL into MLX-LM train/valid files.
MLX expects a folder with train.jsonl + valid.jsonl (chat messages format).
"""

from __future__ import annotations

import argparse
import json
import os
from collections import defaultdict
import random
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parent.parent.parent
DATA_DIR = BASE_DIR / "backend" / "data"
TRAIN_DIR = Path(os.environ.get("BHAKTI_TRAIN_DIR") or DATA_DIR / "training")
SOURCE = TRAIN_DIR / "bhaktidhara_voice_agent_train.jsonl"
OUT_DIR = TRAIN_DIR / "mlx"


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--valid-ratio", type=float, default=0.08)
    parser.add_argument("--seed", type=int, default=42)
    parser.add_argument("--max-aarti", type=int, default=800,
                        help="Cap aarti-heavy samples so feature intents stay well represented")
    parser.add_argument(
        "--balance-actions", action="store_true",
        help="Give each action similar weight for a follow-up training pass",
    )
    parser.add_argument("--focus-action", action="append", default=[],
                        help="Mix corrections for these actions with equally many rehearsal rows")
    args = parser.parse_args()

    if not SOURCE.exists():
        raise SystemExit(
            f"Missing {SOURCE}. Run extract_voice_knowledge.py then generate_training_dataset.py first."
        )

    rows = []
    with SOURCE.open(encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            rows.append(json.loads(line))

    # Reserve training coverage for every action and named argument before sampling.
    rng = random.Random(args.seed)
    rng.shuffle(rows)
    groups = defaultdict(list)
    for row in rows:
        action = json.loads(row["messages"][-1]["content"])["action"]
        key = (action["type"], action.get("aarti_id") or action.get("query"),
               action.get("mantra_id"), action.get("rashi_id"),
               action.get("language_code"), action.get("feature_key"),
               action.get("region"), action.get("section"), action.get("position"),
               action.get("deity_key"), action.get("book_slug"), action.get("enabled"),
               action.get("field"), action.get("chapter"))
        groups[key].append(row)

    train = [items[0] for items in groups.values()]
    valid = []
    media_types = {"play_aarti", "open_aarti"}
    remaining = []
    for key, items in groups.items():
        if len(items) >= 3 and rng.random() < args.valid_ratio * len(items):
            valid.append(items[1])
            items = items[2:]
        else:
            items = items[1:]
        remaining.extend((key[0], row) for row in items)

    media_count = sum(key[0] in media_types for key in groups)
    rng.shuffle(remaining)
    for action_type, row in remaining:
        if action_type in media_types:
            if media_count >= args.max_aarti:
                continue
            media_count += 1
        train.append(row)
    if args.balance_actions:
        by_action = defaultdict(list)
        for row in train:
            action = json.loads(row["messages"][-1]["content"])["action"]
            by_action[action["type"]].append(row)
        required = defaultdict(list)
        for key, items in groups.items():
            if any(key[2:]) or key[1] in ("pasayadan", "shani_aarti"):
                required[key[0]].append(items[0])

        train = []
        for action_type, items in by_action.items():
            if action_type == "answer_app_question":
                # Each answer needs examples in several languages, even for a small topic.
                by_topic = defaultdict(list)
                for row in items:
                    topic = json.loads(row["messages"][-1]["content"])["action"]["feature_key"]
                    by_topic[topic].append(row)
                for examples in by_topic.values():
                    if len(examples) > 32:
                        examples = rng.sample(examples, 32)
                    train.extend(examples)
                    train.extend(rng.choices(examples, k=max(0, 10 - len(examples))))
                continue
            picked = required[action_type]
            rng.shuffle(items)
            remaining = [row for row in items if row not in picked]
            cohort = (picked + remaining)[:32]
            train.extend(cohort)
            train.extend(rng.choices(cohort, k=32 - len(cohort)))

    if args.focus_action:
        focus = set(args.focus_action)
        correction, rehearsal = [], []
        for row in train:
            kind = json.loads(row["messages"][-1]["content"])["action"]["type"]
            (correction if kind in focus else rehearsal).append(row)
        if not correction or not rehearsal:
            parser.error("--focus-action requires both correction and rehearsal examples")
        train = correction + rng.sample(rehearsal, min(len(rehearsal), len(correction)))

    rng.shuffle(train)
    rng.shuffle(valid)

    OUT_DIR.mkdir(parents=True, exist_ok=True)
    train_path = OUT_DIR / "train.jsonl"
    valid_path = OUT_DIR / "valid.jsonl"

    def write(path: Path, items: list) -> None:
        with path.open("w", encoding="utf-8") as f:
            for item in items:
                f.write(json.dumps(item, ensure_ascii=False) + "\n")

    write(train_path, train)
    write(valid_path, valid)

    media_count = sum(json.loads(row["messages"][-1]["content"])["action"]["type"] in media_types
                      for row in train)
    print(f"Media training examples: {media_count}")
    print(f"Train: {len(train)} -> {train_path}")
    print(f"Valid: {len(valid)} -> {valid_path}")


if __name__ == "__main__":
    main()
