#!/usr/bin/env python3
"""Validate Google App Campaign asset lengths (headline <= 30, description <= 90).

Usage:
  check_assets.py --headline "..." --headline "..." --description "..."
  check_assets.py --file assets.txt   # lines prefixed with "H:" or "D:"
Exit code 1 if any asset exceeds its limit.
"""
import argparse
import sys

LIMITS = {"H": 30, "D": 90}


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--headline", action="append", default=[])
    parser.add_argument("--description", action="append", default=[])
    parser.add_argument("--file")
    args = parser.parse_args()

    assets = [("H", h) for h in args.headline] + [("D", d) for d in args.description]
    if args.file:
        with open(args.file, encoding="utf-8") as f:
            for line in f:
                kind, _, text = line.strip().partition(":")
                if kind.upper() in LIMITS and text:
                    assets.append((kind.upper(), text.strip()))

    failed = False
    for kind, text in assets:
        n, limit = len(text), LIMITS[kind]
        ok = n <= limit
        failed |= not ok
        label = "Headline" if kind == "H" else "Description"
        print(f"{'OK ' if ok else 'OVER'} {label:<11} {n:>3}/{limit}  {text}")
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
