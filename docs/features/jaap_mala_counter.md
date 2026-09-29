# Naam Jaap & Mala Counter — Feature Design Document

> **Status:** MVP (v1) implemented — volume-button counting and reminders pending · **Owner:** Product
> **Audience:** Devotees aged 50+ (primary), families, daily sadhaks
> **Languages:** Marathi, Hindi, English (same as the rest of the app)

---

## 1. Why this feature

Naam jaap (chanting a mantra on a 108-bead mala) is one of the most common daily practices among our users. Today people either use a physical mala and lose count, or use generic "tally counter" apps that feel cold and technical.

We want a **digital mala that feels like sitting in a mandir**: calm, sacred, simple enough to use with one thumb and without reading glasses.

**Business goals**

| Goal | How this feature helps |
|---|---|
| Daily habit / retention | A daily streak gives users a reason to open the app every morning |
| Premium conversion | Advanced stats, extra malas, mantras and sankalps are premium |
| Word of mouth | Shareable "milestone" cards (e.g. *1 Lakh Jaap Complete*) on WhatsApp |

**Success metrics (first 60 days)**

- 30% of weekly active users try the counter at least once
- 15% of those complete at least one full mala (108) per day for 7 days
- Day-7 retention for jaap users 2x that of non-jaap users
- 5% of regular jaap users (7+ day streak) start a premium trial

---

## 2. Design principles (for a 50+ audience)

1. **One big action.** The whole screen is the tap area. The user should never have to "find" the button.
2. **Nothing to learn.** Open → pick mantra (or continue last one) → tap. Maximum two taps before chanting starts.
3. **Big, bold, high-contrast.** Minimum body text 18sp, counter number 72sp+, touch targets 56dp+.
4. **Feel, don't read.** Every bead gives a soft haptic tick; each mala completion gives a temple-bell sound and a stronger vibration, so users can chant with eyes closed.
5. **Calm, never guilty.** No red warnings, no "You lost your streak!" shaming. Language is gentle and devotional.
6. **Works offline, always.** Jaap must never depend on network or login.
7. **Respect the tradition.** 108 beads + the Sumeru (guru) bead, correct mantra spellings, no ads while chanting.

---

## 3. Feature scope

### 3.1 MVP (v1) — Free

| # | Feature | Description |
|---|---|---|
| 1 | **108-bead digital mala** | Animated circular mala of 108 beads plus a larger Sumeru bead at the top. Tapping moves one bead. |
| 2 | **Tap anywhere to count** | Entire lower 70% of screen is the tap zone. Accidental double-taps within 250ms are ignored. |
| 3 | **Volume-button counting** | Optional: press the phone's volume-down key to count (great for eyes-closed chanting / pocket use). |
| 4 | **Mala completion** | At 108: bell sound + strong haptic + gentle golden glow; mala count +1; beads reset. |
| 5 | **Mantra selection** | 10 preset mantras (see §6) shown in Devanagari + transliteration. Last-used mantra remembered. |
| 6 | **Daily goal** | Default 1 mala/day; user can choose 1, 3, 5, 11, 21 malas (big buttons, no typing). |
| 7 | **Daily streak** | Streak increases when the daily goal is met. Shown as a lamp (diya) with the number of days. |
| 8 | **Lifetime jaap count** | Total jaaps ever, with Indian number formatting (1,08,000 / "1.08 Lakh"). |
| 9 | **Today summary** | Today's jaap count, malas completed, time spent. |
| 10 | **Screen stays on** | Wakelock while on the counter (package already in the app). |
| 11 | **Undo last bead** | Small "−1" button for mistaken taps. |
| 12 | **Sound & vibration toggles** | Tick sound on/off, bell on/off, vibration on/off. |
| 13 | **Offline + auto-save** | Count saved after every bead; app kill / phone call never loses progress. |

### 3.2 v2 — Engagement

| # | Feature | Free / Premium |
|---|---|---|
| 14 | **Morning reminder** ("Jai Shri Ram 🙏 Time for today's naam jaap") at a user-chosen time | Free |
| 15 | **Milestones & badges** (108, 1,008, 11,000, 1 Lakh, 1.25 Lakh, 1 Crore) with shareable WhatsApp card | Free |
| 16 | **Calendar view** — month grid, each completed day shows a small lit diya | Free (current month), Premium (full history) |
| 17 | **Streak protector ("Kshama Din")** — 1 missed day per week forgiven automatically | Premium (Free users get 1 per month) |
| 18 | **Background chanting audio** — soft tanpura / mantra loop while counting | Premium |
| 19 | **Custom mantra** — user types their own guru mantra (stored only on device) | Premium |
| 20 | **Extra mala styles** — Rudraksha, Tulsi, Sphatik (crystal), Chandan (sandalwood), Kamal Gatta | 1 free (Rudraksha), rest Premium |

### 3.3 v3 — Deep practice

| # | Feature | Free / Premium |
|---|---|---|
| 21 | **Sankalp (vow) mode** — e.g. "1,25,000 Gayatri jaap in 40 days" with progress ring and daily target auto-calculated | Premium |
| 22 | **Voice counting** — app listens and counts each mantra utterance (uses `speech_to_text`, already a dependency) | Premium, beta |
| 23 | **Detailed stats** — weekly/monthly charts, best time of day, per-mantra totals | Premium |
| 24 | **Festival jaap drives** — e.g. "Navratri Durga Jaap: 9 days" with special mala and badge | Free to join, Premium rewards |
| 25 | **Family / Satsang group jaap** — shared collective goal ("Our family: 1 Lakh Ram Naam") | Premium (needs backend) |
| 26 | **Home-screen widget** — shows streak + tap-to-open counter | Free |

---

## 4. User flows

### 4.1 First-time user (≤ 3 screens, ≤ 20 seconds)

```
Dashboard ── tap "Naam Jaap" card ──▶ Welcome sheet (1 screen)
                                       "Choose your mantra" (big list, 10 items)
                                                 │
                                                 ▼
                                       "Daily goal?"  [1] [3] [5] [11] [21] malas
                                                 │   (default 1 pre-selected)
                                                 ▼
                                       Counter screen — "Tap anywhere to begin 🙏"
```

- Welcome sheet has a single **"Aarambh Karein / Start"** button. Skip = defaults.
- A one-time coach overlay shows a pulsing finger on the tap zone. Dismisses on first tap.

### 4.2 Returning user (1 tap)

```
Dashboard "Naam Jaap" card (shows 🪔 12-day streak · Today 1/3 mala)
        │ tap
        ▼
Counter screen — resumes exactly where they left off (same mantra, same bead)
```

### 4.3 Completing the daily goal

```
Bead 108 of final mala ─▶ Bell + glow ─▶ Full-screen "Sankalp Purna" card (3s, tap to dismiss)
                                          🪔  Day 13 streak!
                                          "Aapki bhakti swikar ho 🙏"
                                          [ Continue chanting ]  [ Done ]
```

User can keep chanting after the goal; extra jaaps still count toward lifetime totals.

### 4.4 Missed a day

- **No negative screens.** On next open: soft card — *"Welcome back 🙏 Every day is a new beginning. Start today's jaap."*
- If a Kshama Din (streak protector) is available, it's applied automatically and shown positively: *"Your streak is safe — Kshama Din used."*

---

## 5. Screens & UI

### 5.1 Dashboard entry card

```
┌───────────────────────────────────────────┐
│  📿  Naam Jaap                       ›     │
│                                           │
│  🪔 12 days      Today: ●●○  1 of 3 mala   │
│                                           │
│  [       Continue Jaap  🙏        ]        │
└───────────────────────────────────────────┘
```
- Background: existing card style (`cardBackground`, `cardBorder`) with a faint mandala watermark (`cardMandala`).
- The diya flame is animated (subtle flicker) only when today's goal is not yet done — a gentle nudge.

### 5.2 Counter screen (the heart of the feature)

```
┌───────────────────────────────────────────┐
│  ‹ Back          ॐ नमः शिवाय ▾        ⚙    │  ← mantra chip opens picker
│                                           │
│               ॐ नमः शिवाय                  │  ← mantra in large Devanagari (28sp)
│            Om Namah Shivaya               │  ← transliteration (18sp, muted)
│                                           │
│          ◦ ◦ ◦ ◦ ● ◦ ◦ ◦ ◦                │
│        ◦                   ◦              │
│      ◦                       ◦            │
│     ◦          47             ◦           │  ← current bead number (80sp, gold)
│     ◦        of 108           ◦           │
│      ◦                       ◦            │
│        ◦                   ◦              │
│          ◦ ◦ ◦ ◦ ◦ ◦ ◦ ◦ ◦                │
│                                           │
│     Mala  2 / 3        🪔 12 days          │  ← today progress + streak
│                                           │
│        ~ ~ ~  Tap anywhere  ~ ~ ~         │  ← hint fades after first tap
│                                           │
│   [ −1 ]                        [ ⏸ ]      │  ← undo & pause (56dp)
└───────────────────────────────────────────┘
```

**Mala visual**
- 108 beads arranged in a circle/teardrop; Sumeru bead (larger, with a small tassel) at the top.
- On each tap, beads rotate by one position with a 180ms ease-out animation — it should feel like beads slipping through fingers.
- Completed beads on the current round are slightly brighter/warmer than pending ones.
- Crossing the Sumeru: traditionally one does not cross the guru bead; the animation reverses direction for the next mala (small detail devotees will appreciate).

**Background**
- Warm radial gradient: centre `#FFF3D6` → edge `#F6DDAF`, with a very faint rotating mandala (1 rotation / 120s, 6% opacity).
- Optional deity backdrop at 10–15% opacity matching the selected mantra (uses existing `MandirTheme.getDeityImageAsset`).

**Mantra picker** — bottom sheet, each row 72dp tall: deity thumbnail · Devanagari mantra · transliteration. Selected row has a gold border.

**Settings sheet (⚙)** — only big toggles, no nested menus:
- Tick sound · Bell on mala complete · Vibration · Count with volume button · Keep screen on · Daily goal · Reminder time

### 5.3 Completion celebration

- Soft golden particles (flower petals / pushpa) falling for 2 seconds — reuse `assets/aarti_screen/pushpa.png`.
- Bell sound (`ghanti`) — a short temple bell, not a loud game "ding".
- Text: **"Sankalp Purna 🙏"**, streak number with diya.
- Every 7th day and milestone days: slightly bigger celebration + optional share card.

### 5.4 Stats screen ("Meri Sadhana")

```
┌───────────────────────────────────────────┐
│  ‹         Meri Sadhana                    │
│                                           │
│   ┌─────────┐ ┌─────────┐ ┌─────────┐      │
│   │  🪔 12  │ │ 📿 2.4L │ │  🏆 31  │      │
│   │ Streak  │ │ Lifetime│ │  Best   │      │
│   └─────────┘ └─────────┘ └─────────┘      │
│                                           │
│   Today      324 jaap · 3 mala · 18 min    │
│   This week  ▂▅▇▃▆█▅                       │
│                                           │
│   September 2026                           │
│   S  M  T  W  T  F  S                      │
│   🪔 🪔 🪔 ○  🪔 🪔 🪔                        │
│   🪔 🪔 🪔 🪔 🪔 ·  ·                         │
│                                           │
│   Milestones                               │
│   ✅ 108   ✅ 1,008   ✅ 11,000   ⬜ 1 Lakh   │
│                                           │
│   🔒 Detailed charts & full history        │  ← premium blurred gate
└───────────────────────────────────────────┘
```

- Numbers use Indian formatting and Lakh/Crore words in all three languages.
- Premium sections reuse the existing `PremiumBlurredGate` widget for consistency.

---

## 6. Content — preset mantras (MVP)

| Deity | Devanagari | Transliteration |
|---|---|---|
| Shri Ram | श्री राम जय राम जय जय राम | Shri Ram Jai Ram Jai Jai Ram |
| Shiva | ॐ नमः शिवाय | Om Namah Shivaya |
| Ganesha | ॐ गं गणपतये नमः | Om Gam Ganapataye Namah |
| Krishna | हरे कृष्ण महामंत्र | Hare Krishna Mahamantra (full text shown) |
| Vishnu | ॐ नमो भगवते वासुदेवाय | Om Namo Bhagavate Vasudevaya |
| Gayatri | ॐ भूर्भुवः स्वः ... | Gayatri Mantra (full text shown) |
| Hanuman | ॐ हं हनुमते नमः | Om Ham Hanumate Namah |
| Durga | ॐ दुं दुर्गायै नमः | Om Dum Durgayai Namah |
| Datta | श्री गुरुदेव दत्त | Shri Gurudev Datta |
| Vitthal | राम कृष्ण हरी | Ram Krishna Hari |
| Sai Baba | ॐ साई राम | Om Sai Ram |
| Mahamrityunjaya | ॐ त्र्यम्बकं यजामहे ... | Mahamrityunjaya Mantra (full text) |

> All mantra texts must be proof-read by a Sanskrit/Marathi reviewer before release.
> Long mantras (Gayatri, Mahamrityunjaya, Hare Krishna) show the full text in a scrollable card above the mala at 22sp.

---

## 7. Visual design system

Built on the existing `MandirTheme` — no new brand colours, only a few additions for the mala.

### 7.1 Colours

| Token | Hex | Use |
|---|---|---|
| `primarySaffron` (existing) | `#D84315` | Primary buttons, active states |
| `secondaryMaroon` (existing) | `#7B1E1E` | Headings, mantra text |
| `goldenAccent` (existing) | `#C58B25` | Counter number, Sumeru bead, borders |
| `backgroundCream` (existing) | `#FCF6E8` | Page background |
| **new** `jaapGlowGold` | `#FFD27A` | Completion glow, active bead halo |
| **new** `beadRudraksha` | `#6D3B1F` | Default bead colour |
| **new** `beadDone` | `#A0522D` | Beads already counted in current round |
| **new** `diyaFlame` | `#FF9F1C` | Streak flame |
| **new** `sandalGradientStart` / `End` | `#FFF3D6` / `#F6DDAF` | Counter background |

Contrast: all text ≥ 4.5:1 against its background (WCAG AA); counter number ≥ 7:1.

### 7.2 Typography

Uses Mukta (already in the theme via Google Fonts; supports Devanagari well).

| Element | Size | Weight |
|---|---|---|
| Counter number | 80sp | 800 |
| Mantra (Devanagari) | 28sp | 700 |
| Transliteration | 18sp | 500 |
| Section headings | 22sp | 700 |
| Body / labels | 18sp | 500 |
| Minimum anywhere | 16sp | — |

Respect the phone's system font scale up to 1.5x without layout breaking.

### 7.3 Motion

| Moment | Animation | Duration |
|---|---|---|
| Bead tap | Beads rotate one step, active bead scales 1.0 → 1.15 → 1.0 | 180ms |
| Mala complete | Golden radial glow + petals | 1.5–2s |
| Goal complete | Card fades/scales in | 400ms |
| Diya flame | Gentle flicker loop | continuous, subtle |
| Background mandala | Slow rotation | 120s / turn |

Honour the OS "reduce motion" setting: disable petals and mandala rotation, keep haptics.

### 7.4 Sound & haptics

| Event | Sound | Haptic |
|---|---|---|
| Each bead | Soft wooden bead "tock" (very quiet, optional) | `HapticFeedback.lightImpact` |
| Mala complete (108) | Temple bell (`ghanti`) | `heavyImpact` ×2 |
| Daily goal complete | Shankh (`assets/sounds/shankh_dhun.mp3`, short 2s clip) | `heavyImpact` ×3 |

Sounds must respect the phone's silent mode and never play over an active phone call.

---

## 8. Accessibility checklist (50+ users)

- [ ] Tap zone covers ≥ 70% of screen; no precision needed
- [ ] All buttons ≥ 56×56dp with text labels, not just icons
- [ ] Volume-button counting works with the screen dimmed
- [ ] Works fully with eyes closed (haptics + sounds convey progress)
- [ ] Text scales to 150% without clipping
- [ ] Screen reader (TalkBack/VoiceOver) announces "Bead 47 of 108, Mala 2" every 10 beads, not every bead
- [ ] No time-limited popups; celebration cards wait for a tap or auto-dismiss gently
- [ ] No ads on the counter screen, ever
- [ ] Pocket-mode guard: ignore touches if proximity sensor is covered (v2)
- [ ] Undo is always visible so mistakes aren't scary

---

## 9. Streak rules

Clear rules prevent user frustration and support tickets.

1. A **day** runs from 4:00 AM to 3:59 AM next day (local time) — Brahma muhurta start, and people chanting past midnight don't lose their day.
2. A day **counts** when the user reaches their daily goal (default 1 mala = 108 jaap).
3. **Current streak** = consecutive counted days ending today or yesterday.
4. **Best streak** is stored separately and never decreases.
5. **Kshama Din (streak protector):** Premium users get 1 per week; free users 1 per month. Applied automatically to a single missed day.
6. Changing the daily goal takes effect **tomorrow** (so users can't lose today's progress by raising it).
7. Changing the phone's clock/timezone must not grant or remove streak days — store dates as local date strings and ignore future dates.

---

## 10. Free vs Premium summary

| Capability | Free | Premium |
|---|---|---|
| 108-bead counter, tap & volume counting | ✅ | ✅ |
| Preset mantras | 12 | 12 + custom mantras |
| Daily goal, streak, lifetime count | ✅ | ✅ |
| Reminder notification | ✅ | ✅ |
| Milestone badges & share cards | ✅ | ✅ |
| Calendar history | Current month | Full history |
| Streak protector | 1 / month | 1 / week |
| Mala styles | Rudraksha | + Tulsi, Sphatik, Chandan, Kamal Gatta |
| Background chanting audio | — | ✅ |
| Sankalp (vow) mode | — | ✅ |
| Detailed stats & charts | — | ✅ |
| Voice counting (beta) | — | ✅ |
| Cloud backup / multi-device | — | ✅ (v3) |

**Upsell moments (soft, never blocking the chant):**
- After a 7-day streak celebration: "Protect your streak with Kshama Din — try Premium free for 7 days."
- Tapping a locked mala style shows a live preview of it for 10 beads, then the paywall.
- Stats screen blurred section.

---

## 11. Technical design

### 11.1 Architecture (fits current clean-architecture layout)

```
lib/
├── domain/entities/
│   ├── jaap_mantra.dart          // id, deity, devanagari, transliteration, isPremium
│   ├── jaap_session.dart         // mantraId, startedAt, beadCount, malasCompleted
│   └── jaap_stats.dart           // lifetimeCount, streak, bestStreak, dailyLog
├── data/
│   ├── datasources/jaap_mantra_catalog.dart
│   └── repositories/jaap_repository.dart   // persistence
├── presentation/
│   ├── providers/jaap_providers.dart       // Riverpod StateNotifiers
│   ├── screens/jaap_counter_screen.dart
│   ├── screens/jaap_stats_screen.dart
│   └── widgets/
│       ├── mala_ring.dart                  // CustomPainter, 108 beads + sumeru
│       ├── jaap_dashboard_card.dart
│       ├── diya_streak_badge.dart
│       └── jaap_celebration_overlay.dart
└── services/jaap_feedback_service.dart     // sound + haptics
```

### 11.2 Data model

```dart
class JaapStats {
  final int lifetimeCount;
  final int currentStreak;
  final int bestStreak;
  final int dailyGoalMalas;
  final String? lastCompletedDay;          // 'yyyy-MM-dd' (4 AM boundary)
  final Map<String, int> dailyLog;          // day -> jaap count
  final Map<String, int> perMantraTotals;   // mantraId -> count
  final int protectorsRemaining;
}

class JaapSession {
  final String mantraId;
  final int beadIndex;        // 0..107
  final int malasToday;
  final DateTime startedAt;
}
```

### 11.3 Persistence

- **MVP:** `shared_preferences` (already used) storing JSON for `JaapStats` and the active `JaapSession`. Write after every bead is cheap enough; debounce to every 5 beads + on app pause for safety.
- **v2+:** If daily logs grow large (years of history), migrate to `hive` or `sqflite`.
- **v3:** Optional cloud backup through the existing FastAPI backend (`backend/`), premium only.

### 11.4 Packages

| Need | Package | Status |
|---|---|---|
| State | `flutter_riverpod` | Already in app |
| Storage | `shared_preferences` | Already in app |
| Keep screen on | `wakelock_plus` | Already in app |
| Sounds | `audioplayers` | Already in app |
| Voice counting | `speech_to_text` | Already in app |
| Haptics | `HapticFeedback` (Flutter SDK) | Built-in |
| Volume button counting | `volume_controller` or platform channel | New |
| Reminders | `flutter_local_notifications` | New |
| Share cards | `share_plus` + `screenshot` | New |
| Home widget (v3) | `home_widget` | New |

### 11.5 Performance

- Mala ring drawn with a single `CustomPainter`; only the rotation angle animates (no 108 separate widgets).
- Preload bead/bell sounds into a low-latency audio pool so rapid tapping (3–4 taps/sec) never lags.
- Target: tap-to-feedback latency < 50ms, 60fps on low-end Android (2GB RAM).

---

## 12. Localization

All strings go into `app_en.arb`, `app_hi.arb`, `app_mr.arb`. Key strings:

| Key | English | Hindi | Marathi |
|---|---|---|---|
| `jaapTitle` | Naam Jaap | नाम जप | नामजप |
| `jaapTapToBegin` | Tap anywhere to begin | कहीं भी टैप करें | कुठेही टॅप करा |
| `jaapMala` | Mala | माला | माळ |
| `jaapStreakDays` | {n} day streak | {n} दिन लगातार | सलग {n} दिवस |
| `jaapGoalComplete` | Sankalp complete | संकल्प पूर्ण | संकल्प पूर्ण |
| `jaapWelcomeBack` | Welcome back. Every day is a new beginning. | स्वागत है। हर दिन नई शुरुआत है। | पुन्हा स्वागत. प्रत्येक दिवस नवी सुरुवात आहे. |
| `jaapLifetime` | Lifetime jaap | कुल जप | एकूण जप |
| `jaapMySadhana` | My Sadhana | मेरी साधना | माझी साधना |

Numbers: use `intl` `NumberFormat.decimalPattern('en_IN')` and show Lakh/Crore words (लाख / कोटी).

---

## 13. Assets needed

| Asset | Notes |
|---|---|
| Bead textures (Rudraksha, Tulsi, Sphatik, Chandan, Kamal Gatta) | Small PNG/WebP, 64×64 @3x, transparent |
| Sumeru bead + tassel | Matching each mala style |
| Diya icon (lit / unlit) | Vector preferred; flame as separate layer for animation |
| Soft mandala watermark | Reuse `assets/aarti_list/mandala_thumb.png` if suitable |
| Petal particle | Reuse `assets/aarti_screen/pushpa.png` |
| Bead tick sound | < 100ms, soft wooden click, ~20KB |
| Bell sound | Reuse `ghanti` asset or short 1.5s temple bell |
| Milestone badges | 6 badges, gold/maroon, lotus motif |
| Share card template | 1080×1920, includes app logo + Play Store link |

---

## 14. Analytics events

| Event | Properties |
|---|---|
| `jaap_opened` | source (dashboard / notification / widget) |
| `jaap_mantra_selected` | mantra_id, is_custom |
| `jaap_mala_completed` | mantra_id, mala_number_today, duration_sec |
| `jaap_goal_completed` | streak, goal_malas |
| `jaap_streak_broken` | previous_streak, protector_available |
| `jaap_milestone_reached` | milestone |
| `jaap_share_tapped` | milestone |
| `jaap_premium_gate_viewed` | gate (mala_style / stats / protector / sankalp) |
| `jaap_input_method` | tap / volume / voice |

---

## 15. Acceptance criteria (MVP)

- [ ] From dashboard, a returning user starts chanting in **one tap**
- [ ] Tapping anywhere in the tap zone increments exactly one bead; taps within 250ms are debounced
- [ ] At 108 the bell plays, mala count increments, beads reset — within 100ms
- [ ] Killing the app mid-mala and reopening restores the exact bead and mala
- [ ] Streak increments only when the daily goal is met, using the 4 AM day boundary
- [ ] Missing a day never shows a negative/red message
- [ ] Lifetime count displays in Indian format in all three languages
- [ ] Screen stays awake on the counter and releases on exit
- [ ] Counter works in airplane mode
- [ ] Tested at 150% system font size on a 5.5" device with no clipping
- [ ] Unit tests: streak calculation (normal, missed day, protector, timezone change, 4 AM boundary)
- [ ] Widget tests: tap increments, undo, mala completion, goal completion

---

## 16. Rollout plan

| Phase | Scope | Duration |
|---|---|---|
| Sprint 1 | Data model, streak logic + tests, counter screen, mala painter, haptics/sound | 1 week |
| Sprint 2 | Dashboard card, mantra picker, stats screen (basic), localization, polish | 1 week |
| Beta | Release to 10–20 real users aged 50+ (family, temple groups); observe them using it | 1 week |
| v2 | Reminders, milestones & sharing, calendar, mala styles, premium gates | 2 weeks |
| v3 | Sankalp mode, voice counting, family jaap, widget, cloud backup | 3–4 weeks |

**Usability test with real elders before launch** — watch 5 people aged 55+ use it without help. If anyone can't start chanting within 20 seconds, simplify further.

---

## 17. Decisions

### 17.1 Default mantra — suggest once, then remember

- On the **first-time welcome sheet only**, pre-select the mantra of the deity whose aartis the user opens most (e.g. mostly Ganpati aartis → *ॐ गं गणपतये नमः*). The user just taps **Start**.
- After that, the counter **always opens the last-used mantra**. The app never switches the mantra on its own — changing things silently confuses older users.
- New users with no aarti history default to **श्री राम जय राम जय जय राम**, which suits most Marathi and Hindi households.

### 17.2 Mala size (27 / 54 / 108) — v2 setting, 108 default

- **108 stays the default** and the choice is **not** shown on the welcome sheet — most users use 108 and an extra choice at the start only adds confusion.
- In v2, add a Settings option with three big buttons: **27 · 54 · 108**.
- Rule: daily goal, streak and lifetime count are always tracked in **jaaps**, not malas, so stats stay correct when a user switches mala size. The UI can still say "1 mala" meaning one round of the chosen size.

### 17.3 Reminder time — ask the user, pre-select 6:00 AM

- Ask **after the user completes their first full mala** (they are happy and more likely to say yes), not when the app first opens.
- One screen: *"When would you like a daily reminder?"* with big buttons: **5 AM · 6 AM (pre-selected) · 7 AM · Evening (7 PM) · No thanks**.
- Request OS notification permission only at this moment — this gets far more users to allow notifications.
- Why not 5 AM by default: many elders do wake at Brahma muhurta, but a 5 AM alert for those who don't feels intrusive and leads them to turn off notifications permanently.

### 17.4 Family jaap — no login, WhatsApp invite codes

- **No login required.** OTP/password/email screens are where many 50+ users give up.
- Flow:
  1. One person creates a group, e.g. *"Kaldhone Parivar – 1 Lakh Ram Naam"*.
  2. The app generates a **6-digit code + WhatsApp share link**.
  3. Family members tap the link and join with just a display name.
  4. Behind the scenes, each device gets an **anonymous ID** from the backend.
- Later, premium users can **optionally link a phone number** for backup and multi-device — offered as a benefit, never as a barrier.

### 17.5 Mantra proof-reading — must be done before MVP release

- A wrong letter in a mantra is a matter of faith for users and will bring angry reviews, so this is a **release blocker**.
- Get the 12 preset mantras checked by a **local pandit or Sanskrit teacher** (one-time, low cost), in Devanagari and all transliterations.
- Cross-check against trusted sources: **Gita Press** texts, **ISKCON** official Hare Krishna Mahamantra.
- Add a **"Report a correction"** option on the mantra card so users can flag mistakes.
- Keep mantras in a **data file** (`jaap_mantra_catalog.dart`, later remote JSON) so fixes don't require code changes.
