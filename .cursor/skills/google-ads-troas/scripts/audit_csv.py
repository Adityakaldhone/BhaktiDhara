#!/usr/bin/env python3
"""Weekly money-recovery audit for a Google Ads CSV export (asset / ad group / campaign).

Usage:
  audit_csv.py report.csv --gear 1 --target 12 --budget 400 --days 7
    --gear     1 = tCPI, 2 = tCPA, 3 = tROAS (current gear of the campaign)
    --target   current bid target: tCPI ₹ (gear 1), tCPA ₹ (gear 2), tROAS % (gear 3)
    --budget   current daily budget ₹
    --days     days covered by the export (for per-day volume)
    --spend-share  fraction of budget actually spent (default: computed from spend/days/budget)

Prints CPI, CPA, ROAS vs the 118% real break-even, the pause list, "Low" and
"Best" assets, and one next bid/budget move that respects the max-20% rule.
"""
import argparse
import csv
import io
import sys

BREAK_EVEN_ROAS = 100 / 0.85  # Google Play keeps 15% of subscription revenue
MAX_STEP = 0.20

COLUMNS = {
    "name": ["asset", "asset text", "headline", "description", "ad group", "ad group name", "campaign", "campaign name"],
    "type": ["asset type", "field type", "type"],
    "cost": ["cost", "spend", "amount spent"],
    "installs": ["installs", "install conversions"],
    "actions": ["in-app actions", "conversions", "conv.", "all conv."],
    "value": ["conv. value", "conversion value", "all conv. value", "total conv. value", "in-app action value"],
    "perf": ["performance", "performance label", "asset performance", "status"],
}


def num(raw):
    cleaned = "".join(c for c in (raw or "") if c.isdigit() or c in ".-")
    try:
        return float(cleaned) if cleaned not in ("", "-", ".") else 0.0
    except ValueError:
        return 0.0


def find_header(lines):
    # Google Ads exports often start with 1-2 title rows before the header.
    for i, line in enumerate(lines[:10]):
        if any(c in line.lower() for c in COLUMNS["cost"]) and "," in line:
            return i
    return 0


def resolve(header):
    lower = [h.strip().lower() for h in header]
    mapping = {}
    for key, options in COLUMNS.items():
        for opt in options:
            if opt in lower:
                mapping[key] = lower.index(opt)
                break
    return mapping


def load(path):
    with open(path, encoding="utf-8-sig") as f:
        lines = f.read().splitlines()
    rows = list(csv.reader(io.StringIO("\n".join(lines[find_header(lines):]))))
    header, data = rows[0], [r for r in rows[1:] if any(r)]
    m = resolve(header)
    if "cost" not in m:
        sys.exit(f"Could not find a cost column in: {header}")

    def col(row, key):
        idx = m.get(key)
        return row[idx] if idx is not None and idx < len(row) else ""

    items = []
    for r in data:
        name = col(r, "name") or "(unnamed)"
        if name.lower().startswith("total"):
            continue
        items.append({
            "name": name,
            "type": col(r, "type").strip(),
            "cost": num(col(r, "cost")),
            "installs": num(col(r, "installs")),
            "actions": num(col(r, "actions")),
            "value": num(col(r, "value")),
            "perf": col(r, "perf").strip().lower(),
        })
    return items


def step(current, factor):
    """Applies a relative change, clamped to the max-20% rule."""
    factor = max(1 - MAX_STEP, min(1 + MAX_STEP, factor))
    return current * factor, (factor - 1) * 100


def recommend(gear, target, budget, days, spend, installs, actions, cpi, cpa, roas, spend_share):
    actions_per_day = actions / days if days else 0
    out = []
    if gear == 1:
        if actions_per_day >= 10:
            nb, pct = step(budget, 0.80)
            out.append(f"GEAR UP → tCPA: {actions_per_day:.1f} actions/day (≥ 10). New campaign at tCPA "
                       f"₹{cpa * 1.2:,.2f} (CPA ₹{cpa:,.2f} + 20%), budget ≥ ₹{cpa * 12:,.0f}/day (10× tCPA).")
            out.append(f"Same day: Gear 1 budget ₹{budget:,.0f} → ₹{nb:,.0f} ({pct:+.0f}%) to fund it; keep both running ≥ 7 days.")
            return out
        if cpi and cpi <= target * 1.2:
            nb, pct = step(budget, 1.20)
            out.append(f"Budget ₹{budget:,.0f} → ₹{nb:,.0f} ({pct:+.0f}%): CPI ₹{cpi:,.2f} is within 120% of tCPI ₹{target:,.2f}.")
        elif cpi and cpi > target * 1.5:
            out.append(f"Hold budget ₹{budget:,.0f}. CPI ₹{cpi:,.2f} > 150% of target: replace 'Low' assets first.")
        else:
            out.append(f"Hold tCPI ₹{target:,.2f} and budget ₹{budget:,.0f} for another 7 days.")
        out.append(f"Stay in Gear 1: {actions_per_day:.1f} mid-funnel actions/day (need 10–15).")
    elif gear == 2:
        if cpa and cpa > target * 1.3:
            nt, pct = step(target, 1.10)
            out.append(f"tCPA ₹{target:,.2f} → ₹{nt:,.2f} ({pct:+.0f}%): CPA ₹{cpa:,.2f} is > 130% of target.")
        elif cpa and cpa <= target:
            nb, pct = step(budget, 1.20)
            out.append(f"Budget ₹{budget:,.0f} → ₹{nb:,.0f} ({pct:+.0f}%): CPA ₹{cpa:,.2f} ≤ target.")
        else:
            out.append(f"Hold tCPA ₹{target:,.2f} and budget ₹{budget:,.0f} for another 7 days.")
        if budget < target * 10:
            out.append(f"Budget is below 10× tCPA (₹{target * 10:,.0f}); raise it in ≤ 20% steps.")
    else:
        if spend_share < 0.5:
            nt, pct = step(target, 0.90)
            out.append(f"tROAS {target:.0f}% → {nt:.0f}% ({pct:+.0f}%): only {spend_share:.0%} of budget spent — target is choking delivery.")
        elif roas >= target * 0.9:
            nt, pct = step(target, 1.15 if roas >= target else 1.10)
            out.append(f"tROAS {target:.0f}% → {nt:.0f}% ({pct:+.0f}%) after ≥ 10–14 days at this target. "
                       f"Next budget change ≥ 3 days later: ₹{budget:,.0f} → ₹{budget * 1.2:,.0f} (+20%) if ROAS holds.")
        else:
            out.append(f"Hold tROAS {target:.0f}% and budget ₹{budget:,.0f}: ROAS {roas:.1f}% is below 90% of target.")
    return out


def main():
    p = argparse.ArgumentParser()
    p.add_argument("csv")
    p.add_argument("--gear", type=int, choices=[1, 2, 3], required=True)
    p.add_argument("--target", type=float, required=True)
    p.add_argument("--budget", type=float, required=True)
    p.add_argument("--days", type=float, default=7)
    p.add_argument("--spend-share", type=float)
    args = p.parse_args()

    items = load(args.csv)
    spend = sum(i["cost"] for i in items)
    installs = sum(i["installs"] for i in items)
    actions = sum(i["actions"] for i in items)
    value = sum(i["value"] for i in items)
    cpi = spend / installs if installs else 0.0
    cpa = spend / actions if actions else 0.0
    roas = value / spend * 100 if spend else 0.0
    spend_share = args.spend_share if args.spend_share is not None else (
        spend / args.days / args.budget if args.days and args.budget else 1.0)

    print("== KPIs ==")
    print(f"Spend ₹{spend:,.2f} over {args.days:g} days (₹{spend / args.days:,.2f}/day, {spend_share:.0%} of budget)")
    print(f"Installs {installs:,.0f} → CPI ₹{cpi:,.2f}" if installs else "Installs: column not found")
    print(f"Actions {actions:,.0f} ({actions / args.days:.1f}/day) → CPA ₹{cpa:,.2f}" if actions else "Actions: column not found")
    print(f"Conv. value ₹{value:,.2f} → ROAS {roas:.1f}%")
    print(f"Gap to 100% gross: {100 - roas:+.1f} pts | Gap to {BREAK_EVEN_ROAS:.0f}% real break-even: {BREAK_EVEN_ROAS - roas:+.1f} pts")

    pause_threshold = 2 * args.target if args.gear == 1 else 2 * (cpi or args.target)
    pause = [i for i in items if i["cost"] > pause_threshold and i["actions"] == 0 and i["installs"] == 0]
    print(f"\n== PAUSE (spend > ₹{pause_threshold:,.2f} and 0 conversions): {len(pause)} ==")
    for i in sorted(pause, key=lambda x: -x["cost"]):
        print(f"  - {i['name']}: wasted ₹{i['cost']:,.2f}")

    low = [i for i in items if i["perf"] == "low"]
    print(f"\n== LOW assets → write 3 replacements each (30/90-char limits): {len(low)} ==")
    for i in low:
        print(f"  - [{i['type'] or '?'}] {i['name']} ({len(i['name'])} chars)")

    best = [i for i in items if i["perf"] == "best"]
    print(f"\n== BEST assets → model replacements on these: {len(best)} ==")
    for i in best:
        print(f"  - [{i['type'] or '?'}] {i['name']}")

    print("\n== NEXT MOVE (max 20% per change) ==")
    for line in recommend(args.gear, args.target, args.budget, args.days, spend, installs,
                          actions, cpi, cpa, roas, spend_share):
        print(f"  * {line}")


if __name__ == "__main__":
    main()
