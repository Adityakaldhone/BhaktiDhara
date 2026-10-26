---
name: google-ads-troas
description: Plans, launches, audits and optimizes Google Ads App Campaigns (UAC) for BhaktiDhara using a 3-gear tCPI → tCPA → tROAS progression toward 118% net break-even ROAS, generates 30/90-character ad assets, and runs weekly money-recovery audits on Google Ads CSV exports or screenshots. Use when the user says "Audit my ads", drops a Google Ads CSV/screenshot, or asks to create, write, audit, review, scale, or optimize Google Ads, app campaigns, UAC, tROAS, tCPA, tCPI, ROAS, CPI, CPA, ad headlines/descriptions, ad spend, bids, or budgets.
---

# Google Ads 3-Gear tROAS System

Act as a Senior Mobile Growth Engineer + Google Ads quantitative strategist. Every recommendation is numeric, tied to a gear, and presented **for approval** — never claim a change was applied to the live account.

Project context (BhaktiDhara, `com.kaldhone.bhaktidhara`, INR): the click-by-click runbook is `marketing/google_ads_launch_plan.md` (tick its checkboxes as steps complete); event names live in `lib/core/analytics/analytics_service.dart`. Read both before advising.

## Conversion events (all shipped in one build)

| Gear | Event | Fired from | Value |
|---|---|---|---|
| 1 | `first_open`, `session_start` (auto) | `AnalyticsService.init()` in `main()` | — |
| 2 · main | `paywall_view` | paywall sheet (`premium_blurred_gate.dart`), locked greeting (`greetings_screen.dart`) | — |
| 2 · volume | `aarti_completed` | `altar_screen.dart` — video ended or 3 min foreground dwell | — |
| 2 · deepest | `begin_checkout` | `subscription_service.dart` `buyPlan()` | intent only — import **without** value |
| 2 · bridge | `trial_start` | purchase stream, free-trial offer | none |
| 3 | `purchase` (app, first charge) | purchase stream, paid offer | exact charge, `currency`, `transaction_id` |
| 3 | `purchase` (server, renewals + trial→paid) | backend RTDN → GA4 Measurement Protocol (`backend/app/ga4_forwarder.py`) | plan price INR |
| 3 | `paid_ad_revenue` | AdMob `onPaidEvent` (banner + rewarded) | micros / 1e6 |

Never import auto `in_app_purchase` or auto `ad_impression` as Primary — they duplicate `purchase` / `paid_ad_revenue`.

## The 3-Gear Progression

Every gear is a **new campaign**; never switch a running campaign's bid strategy. Overlap old and new ≥ 7 days. **Max 20% change rule:** no budget or target moves more than 20% at once; leave ≥ 3 days between a target change and a budget change so learning doesn't reset.

**Gear 1 — Advanced tCPI (Days 1–7)**
- App promotion → App installs · Location option **Presence: People in or regularly in your targeted locations**.
- Install volume, **tCPI ₹10–₹15**, ✅ "users most likely to perform an in-app action" → `paywall_view`.
- Daily budget **30–50 × tCPI** (₹300–₹500). No edits for 7 days.
- Gear up when the main Gear 2 event reaches **10–15 actions/day** (use `aarti_completed` if `paywall_view` can't get there).

**Gear 2 — tCPA (Weeks 2–4)**
- `Starting tCPA = Historical CPA × 1.20`, where `Historical CPA = Total Spend / Actions` over the last 7–14 days.
- Daily budget **10 × tCPA**. If CPA > 130% of target for 7 days, raise tCPA 10%; if CPA ≤ target, budget +20%.
- Gear up when **30–50+ conversion-value events in 30 days** (`purchase` + `paid_ad_revenue`) **and** `purchase` ≥ 10 — ad impressions alone don't prove buyers.

**Gear 3 — tROAS (Week 4+), the money-recovery engine**
- Fresh App campaign → bidding focus **In-app action value (Target ROAS)** → `purchase` + `paid_ad_revenue`.
- `ROAS₁₄ = Conv. value / Cost × 100` (last 14 days). **Initial tROAS = ROAS₁₄ × 0.90–0.95** (5–10% below).
- Step up **+10–15% (relative) every 10–14 days**, only if the last window hit ≥ 90% of target and volume fell < 20%. If < 50% of budget is spent for 3 days, drop the target 10%. If volume falls > 30% after a step, roll back and hold 14 days.
- Finish line: **118–120%+ ROAS** = real break-even after Play's 15% cut (100 / 0.85 = 117.6%).

## "Audit my ads" — weekly command

Trigger: the user says "Audit my ads" (or similar) and attaches a Google Ads CSV export or screenshot. Do all of this without asking for permission first:

1. **Get the numbers.**
   - CSV → run:
     ```bash
     python3 .cursor/skills/google-ads-troas/scripts/audit_csv.py <file.csv> --gear <1|2|3> --target <tCPI ₹ | tCPA ₹ | tROAS %> --budget <₹/day> --days <days in export>
     ```
     If gear/target/budget are unknown, infer from the runbook's recorded values or ask in one line.
   - Screenshot → read Cost, Installs, In-app actions/Conversions, Conv. value, and asset Performance labels from the image; compute the same formulas by hand and show the arithmetic.
2. **Report KPIs:** `CPI = Cost / Installs`, `CPA = Cost / Actions`, `ROAS = Conv. value / Cost × 100`, and the gap to **118%** (and to 100%).
3. **Pause list:** spend > 2 × tCPI with 0 conversions.
4. **Fix "Low" assets:** for every asset labelled Low, write **3 replacements** modeled on the "Best" assets, same type (headline ≤ 30, description ≤ 90). Validate before showing:
   ```bash
   python3 .cursor/skills/google-ads-troas/scripts/check_assets.py --headline "..." --description "..."
   ```
5. **Next move:** exactly one bid or budget change (the script's NEXT MOVE), within the max-20% rule, with the date of the following review. Flag if the data says to gear up.
6. Update the runbook's tracking tables if the user confirms the numbers.

Output template:

```markdown
## Ads audit — [date range] · Gear [N]
| CPI | CPA | ROAS | Gap to 118% |
|---|---|---|---|
| ₹X | ₹Y | Z% | +G pts |

### Pause now
| Asset / ad group | Spend | Conv. |

### Replace "Low" assets
| Low asset | Replacement 1 (chars) | Replacement 2 (chars) | Replacement 3 (chars) |

### Next move (awaiting approval)
[Campaign]: [current] → [proposed] ([±%]) — [rule]. Next review: [date].
```

## Ad Asset Rules (App Campaigns)

- Exactly **5 Headlines (≤ 30 chars)** and **5 Descriptions (≤ 90 chars)**, grouped by theme: **Core Utility**, **Pain-Point Resolver**, **Social Proof/Speed**.
- High-intent, benefit-driven, one idea per asset, each stands alone. Descriptions carry a CTA ("Install free").
- Only claim features that exist (e.g. lyrics are large and readable, *not* auto-synced). No "#1"/"best"/ratings/user counts without a source.
- Always validate counts with `check_assets.py` and present as `# | Theme | Asset | Chars`.

## Guardrails

- Before value bidding, `purchase` and `paid_ad_revenue` must appear in Firebase with numeric `value` + `currency`.
- Server renewals reach GA4 only if `GA4_API_SECRET` is set on the backend and the Play RTDN Pub/Sub push points at `/api/v1/subscription/webhook?auth=<RTDN_PUSH_TOKEN>`. If not, warn that ROAS under-reports lifetime value.
- Primary = events a running campaign bids on. While gears overlap, both stay Primary; demote the old one only after its campaign is paused.
- State the currency (₹) on every number.
