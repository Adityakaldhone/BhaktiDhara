"""Prepare Mandir-only MLX data or score a candidate on reserved requests."""
import argparse
import json
import random
from collections import defaultdict
from pathlib import Path

DATA = Path(__file__).resolve().parents[1] / "datasets/mandir"


def records(split):
    return [json.loads(line) for line in (DATA / f"{split}.jsonl").read_text().splitlines() if line.strip()]


def unpack(row):
    _, user, assistant = row["messages"]
    return user["content"], json.loads(assistant["content"])["action"]["type"]


def prepare(directory):
    rng = random.Random(42)
    groups = defaultdict(list)
    seen = {" ".join(unpack(r)[0].casefold().split()) for r in records("held_out")}
    for row in records("plain") + records("mixed"):
        text, intent = unpack(row)
        key = " ".join(text.casefold().split())
        if key in seen:
            raise ValueError(f"Duplicate or reserved Mandir prompt: {text!r}")
        seen.add(key)
        groups[intent].append(row)
    train, valid = [], []
    for rows in groups.values():
        rng.shuffle(rows)
        valid.append(rows[0])
        train.extend(rows[1:])
    directory.mkdir(exist_ok=True, parents=True)
    for split, rows in (("train", train), ("valid", valid)):
        rng.shuffle(rows)
        (directory / f"{split}.jsonl").write_text("".join(json.dumps(row, ensure_ascii=False) + "\n" for row in rows))
        print(f"{split}: {len(rows)}")


def evaluate():
    from app.voice_agent.mlx_classifier import classify_with_mlx
    rows = records("held_out")
    correct = 0
    for row in rows:
        q, expected = unpack(row)
        result = classify_with_mlx(q, mandir_screen=True) or {}
        actual = result.get("action")
        correct += expected == actual
        print(f"{'PASS' if actual == expected else 'FAIL'} {q} | expected {expected} | got {actual}", flush=True)
    print(f"Mandir held-out decisions: {correct}/{len(rows)}")


if __name__ == "__main__":
    p = argparse.ArgumentParser()
    p.add_argument("--prepare", type=Path)
    args = p.parse_args()
    if args.prepare:
        prepare(args.prepare)
    else:
        evaluate()
