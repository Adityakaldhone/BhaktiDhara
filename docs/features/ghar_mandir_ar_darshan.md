# Ghar Mandir (Virtual Home Temple) & AR Darshan — Feature Design Document

> **Status:** Proposal · **Owner:** Product · **Audience:** Devotees 50+ (primary), their children and grandchildren (secondary)
> **One-line pitch:** *"Your own small mandir in your phone — do a 1-minute puja every morning, and on festivals, bring Bappa into your home through the camera."*

---

## 1. Why this feature (and the honest risk)

### 1.1 What the market shows
- Apps such as **Shubh Darshan** (AR portal, virtual abhishek, diyas) and **Sanatan Sangam** / **Live Darshan India** (live darshan, daily darshan streak) launched in 2026 — virtual worship is an active space.
- Sri Mandir's most-used free surfaces are **Daily Darshan** and daily mantra; paid revenue comes later from puja and chadhava.
- Survey data (Vedic Sadhana Foundation): 89% want a spiritual app that is *"no ads, no noise, just peace."*

### 1.2 The honest risk
Pure AR ("point camera, see a 3D god in your room") is **exciting once and rarely opened again**. For users above 50 it is also physically awkward: hold the phone up, move it slowly, find the floor, grant camera permission.

### 1.3 Our answer — build it in three layers
| Layer | What it is | Why it brings users back |
|---|---|---|
| **1. Ghar Mandir (core)** | A beautiful, personal mandir screen with a 60-second daily puja: diya, agarbatti, flowers, bell, aarti | A daily ritual, a streak, and it mirrors what the user already does at home |
| **2. Tilt Darshan ("magic depth")** | The mandir gently moves in 3D when the phone tilts (layered images + gyroscope). No camera | Feels alive and divine, zero learning, works on every phone |
| **3. AR Darshan (occasional)** | "Bring Bappa home": place a 3D murti on your table or floor through the camera | Festival moments (Ganeshotsav, Navratri, Diwali), a family "wow", shareable photo |

The **daily habit lives in Layer 1**. Layer 2 makes it feel magical. Layer 3 is a festival treat, not the main product.

---

## 2. Design principles (for a 50+ audience)

1. **The mandir must look like a real home mandir** — wooden/marble shrine, brass, marigold, kumkum, diya glow. No sci-fi, no neon, no game look.
2. **One big action at a time.** The next step in the puja glows gently; everything else waits.
3. **Nothing is ever "wrong".** Tapping out of order still works; there is no fail state and no score.
4. **Touch, not gestures.** Only single taps and a slow "circle" for aarti (with a tap alternative). No pinch, no swipe-to-unlock.
5. **Big and calm.** Minimum text 18 sp, buttons 56 dp tall, soft animations (≥ 600 ms), no flashing.
6. **Sound is the soul.** Real bell, conch, soft tanpura — but always one tap to mute.
7. **Respect.** Deity images are never cropped at the feet, never used as a button background that gets "pressed on", never shown upside down in AR.
8. **Works offline.** Layers 1 and 2 need no internet.

---

## 3. Feature scope

### 3.1 MVP (v1) — Ghar Mandir + Tilt Darshan (Free)
- Choose **your deity** (Ishta Devata) from the 20 existing deity images; optional second and third deity side by side.
- The **daily puja** in five steps, ~60 seconds:
  1. **Deep prajwalan** — tap the diya, flame lights up.
  2. **Dhoop / agarbatti** — tap, smoke curls upward.
  3. **Pushpa arpan** — tap, marigold petals fall onto the deity's feet.
  4. **Ghanta naad** — tap the bell (reuse existing bell sound).
  5. **Aarti** — move the aarti thali in a circle with a finger, *or* tap "आरती करा" to let it circle automatically while a short aarti plays.
- **Tilt Darshan** — 4–5 parallax layers move with the phone's tilt.
- **Daily puja streak** ("Puja Din") shared with the jaap streak logic: 4 AM day boundary, one Kshama Din per month.
- **Morning prasad message** after puja: a short line from a saint (Tukaram, Dnyaneshwar, Tulsidas, Kabir) in the user's language.
- **Festival decoration** that changes automatically from the Panchang: toran on Gudi Padwa, modak plate on Ganesh Chaturthi, akhand jyoti in Navratri, rangoli and diyas on Diwali.
- Entry: a dashboard card, and a "ghar mandir" button inside every aarti screen.

### 3.2 v2 — Engagement
- **Naivedya** — offer fruit, modak, laddu or tulsi (tap to place on the plate).
- **Abhishek** mode for Shiva, Vitthal and Ganesh: water / milk / panchamrit poured from a kalash.
- **Sankalp** — write a wish or prayer; it is placed at the deity's feet (private, stored on device only).
- **Family mandir** — share an invite link; family members see "आई ने आज पूजा केली 🪔" (mother did puja today). No chat, no feed.
- **Choose the mandir style** — wooden (Maharashtrian devghar), marble, brass, South Indian stone gopuram.
- **Share today's darshan** as a WhatsApp status card (see `whatsapp_status_cards.md`).

### 3.3 v3 — AR Darshan (Festival feature)
- **"बाप्पाला घरी आणा" / "Bring Bappa home"** — place a 3D Ganesh murti on a table or floor through the camera, lit by a soft glow.
- Do the same five-step puja **in AR**: tapping the screen lights a virtual diya next to the real-world murti.
- **Photo with Bappa** — take a family photo with the virtual murti and share it.
- Launch first for **Ganeshotsav**; later add Lakshmi (Diwali), Durga (Navratri), Krishna (Janmashtami), Vitthal (Ashadhi Ekadashi).
- Premium: extra murtis and decorations; free: one murti per festival.

### 3.4 Explicitly out of scope
- Paid "virtual chadhava" that pretends to reach a real temple. If we ever offer offerings at real temples, that is a separate, fully transparent service.
- Leaderboards or comparing devotion between users.
- Any animation of the deity's face or body (blinking, talking) — many users find it disrespectful.

---

## 4. User flows

### 4.1 First time (≤ 3 screens, ≤ 30 seconds)
```
Dashboard card "🛕 माझे घर मंदिर"  →  "तुमचे आराध्य दैवत निवडा"
   (big grid of 6 popular deities + "सर्व देव पहा")
→ Tap Ganesh  →  Mandir appears with the doors opening slowly (1.2 s, conch sound)
→ The diya glows with a hint: "दिवा लावण्यासाठी स्पर्श करा"
```
No sign-up, no permissions, no tutorial slides. The first puja *is* the tutorial.

### 4.2 Every morning (1 tap to start, ~60 s)
```
Dashboard card shows "आजची पूजा बाकी आहे 🪔"  →  tap
→ Doors open  →  diya glows (step 1)  →  dhoop  →  flowers  →  bell  →  aarti
→ Completion: soft petal shower, shankh, "आजची पूजा पूर्ण 🙏", streak +1,
  today's saint vachan, [ WhatsApp वर शेअर करा ] [ बंद करा ]
```

### 4.3 Festival morning
```
Panchang says "गणेश चतुर्थी"  →  dashboard card turns festive:
"आज गणेश चतुर्थी — बाप्पाची विशेष पूजा करा"
→ Mandir is already decorated (toran, modak, durva)
→ After puja: "बाप्पाला तुमच्या घरात आणायचे? 📷" (AR offer, only on AR-capable phones)
```

### 4.4 AR Darshan (v3)
```
Tap "बाप्पाला घरी आणा"
→ Friendly explanation screen with a picture (not text):
  "फोन टेबलकडे धरा आणि हळूहळू हलवा"  [ कॅमेरा सुरू करा ]
→ Camera permission (system dialog)
→ Surface found → a glowing circle appears → big button "येथे बाप्पा ठेवा"
→ Murti appears with a gentle golden glow and a conch sound
→ Bottom bar: [🪔 दिवा] [🌼 फुले] [🔔 घंटा] [📷 फोटो] [✕ बाहेर]
```
**Fallback:** if AR is unsupported, or no surface is found in 15 s, show "हरकत नाही — तुमच्या मंदिरात दर्शन घ्या" and open the Tilt Darshan view instead. The user never sees an error screen.

### 4.5 Missed a day
Same as the jaap feature — no guilt. "पुन्हा स्वागत आहे 🙏 आज पूजा करूया." Kshama Din protects one missed day per month.

---

## 5. Screens & UI

### 5.1 Dashboard entry card
```
┌────────────────────────────────────────────┐
│  🛕  माझे घर मंदिर                      ›   │
│  [small deity thumbnail]                    │
│  आजची पूजा बाकी आहे 🪔   ·  🔥 12 दिवस      │
│         [  पूजा सुरू करा  ]                  │
└────────────────────────────────────────────┘
```
After puja: "आजची पूजा पूर्ण ✅ · उद्या भेटूया" and the card becomes quieter (less saturated) so it does not nag.

### 5.2 Mandir screen (the heart)
```
┌─────────────────────────────────────────────┐
│ ←  माझे घर मंदिर                  🔊   ⚙︎     │
│                                             │
│   ╔═══════ carved wooden arch ═══════╗       │
│   ║   toran / marigold garland        ║      │
│   ║                                   ║      │
│   ║          [ DEITY IMAGE ]          ║      │
│   ║        soft halo behind           ║      │
│   ║                                   ║      │
│   ║   🪔          🌼🌼          🪔      ║      │
│   ╚═══════════════════════════════════╝      │
│        brass plate · kalash · agarbatti      │
│                                             │
│   ○ ○ ○ ○ ○   (5 step dots, current glows)   │
│                                             │
│   ┌───────────────────────────────────────┐ │
│   │   🪔  दिवा लावा                        │ │  ← one big action button
│   └───────────────────────────────────────┘ │
└─────────────────────────────────────────────┘
```
- The user can tap **either** the object in the mandir (diya, bell) **or** the big action button — both do the same. The button is for users who are not sure where to tap.
- The five step dots show progress without numbers or text.
- The top bar has only **back**, **sound**, and **settings**.

### 5.3 Tilt Darshan — how the depth is built
Layers, back to front:
1. Temple wall / sky gradient (moves the least)
2. Carved arch and pillars
3. Deity with halo
4. Diyas, flowers, kalash
5. Foreground: hanging garland and bells (moves the most)

Max movement ±12 px for the back layer, ±28 px for the front; smoothed with a low-pass filter so it never shakes. A **"stop movement"** switch in settings for users who feel dizzy (and it respects the system "reduce motion" setting).

### 5.4 Aarti step
- A brass aarti thali with a live flame appears near the bottom.
- **Primary:** drag it in a circle — each full circle brightens the halo a little.
- **Alternative:** a big button "आरती करा ▶" — the thali circles by itself for one short aarti (30–45 s) from the existing aarti audio; the user just watches and folds hands.
- The lyrics of the aarti's first stanza scroll slowly under the mandir (large, 20 sp).

### 5.5 Completion
- Petal shower (reuse `petal_shower.dart`), shankh sound, a gentle golden light sweep across the deity.
- Card: "आजची पूजा पूर्ण 🙏" + streak + saint vachan.
- Two buttons: **WhatsApp वर शेअर करा** (primary) and **बंद करा**.

### 5.6 AR screen (v3)
- Full-screen camera with a thin saffron frame at the edges (so the user feels they are "inside the app").
- One instruction line at the top, in large text, with an animated hand-and-phone illustration.
- Bottom action bar with five round buttons (64 dp) and labels under each.
- Photo mode hides all UI and adds a small, tasteful watermark "BhaktiDhara · घर मंदिर".

---

## 6. Content

### 6.1 Deities (MVP uses existing assets in `assets/decorations/`)
Ganesh, Mahadev, Vitthal, Datta, Sai Baba, Hanuman, Rama, Krishna, Lakshmi, Durga, Venkatesh, Vishnu, Khandoba, Gajanan Maharaj, Santoshi Mata, Shani, Tulsi, Sant.
Each needs: a **clean transparent cut-out** at 1024 px+ and a **halo colour** (e.g. Ganesh — saffron, Shiva — pale blue-white, Vitthal — deep blue-gold, Lakshmi — rose-gold).

### 6.2 Day-wise suggestion (used when the user has not chosen, and for festivals)
| Day | Deity |
|---|---|
| Monday | Mahadev |
| Tuesday | Ganesh / Hanuman / Devi |
| Wednesday | Vitthal / Ganesh |
| Thursday | Datta / Sai Baba / Guru |
| Friday | Lakshmi / Devi |
| Saturday | Hanuman / Shani |
| Sunday | Surya / Khandoba |

### 6.3 Saint vachan library (MVP: 90 lines, 30 per language)
Short, verified, public-domain lines: Tukaram abhang, Dnyaneshwari ovi, Namdev, Tulsidas doha, Kabir doha, Gita shlokas. **Every line must be proof-read before release** (same rule as mantras in the jaap feature).

### 6.4 Festival decorations (from Panchang festival name)
Gudi Padwa, Ram Navami, Hanuman Jayanti, Ashadhi Ekadashi, Guru Purnima, Shravan Somvar, Janmashtami, Ganesh Chaturthi (10 days), Navratri (9 days), Dussehra, Diwali (5 days), Kartiki Ekadashi, Datta Jayanti, Maha Shivaratri.

---

## 7. Visual design system

### 7.1 Colours
| Token | Hex | Use |
|---|---|---|
| Sandal cream | `#FFF8EC` | Screen background |
| Temple wood | `#6B3A1E` | Arch, shrine frame |
| Brass gold | `#C9A227` | Plate, kalash, borders |
| Marigold | `#F59E0B` | Garlands, highlights |
| Kumkum | `#B91C1C` | Tilak dots, active step |
| Diya glow | `#FFD27A` (radial, 40% alpha) | Halo, flame light |
| Deep maroon | `#7A1F1F` | Titles, primary button |

The same palette as the jaap feature (`jaap_colors.dart`) so the app feels like one family.

### 7.2 Typography
- Titles: **Yatra One** (Devanagari display) 24–28 sp.
- Body: **Mukta** 18–20 sp; saint vachan in **Noto Serif Devanagari** 20 sp, italic-free.
- English: Mukta as well (matches Devanagari weight).

### 7.3 Motion
| Moment | Animation | Duration |
|---|---|---|
| Doors open | Two carved doors swing outward | 1200 ms, ease-out |
| Diya lights | Flame grows from a spark, glow fades in | 800 ms |
| Dhoop | Smoke curls up, 3 slow wisps, loops softly | 4 s loop |
| Flowers | 12–18 petals fall on curved paths | 1500 ms |
| Aarti | Thali circles, halo brightens per circle | 3 s per circle |
| Completion | Golden light sweep left to right across the deity | 1400 ms |

All animations are off when "reduce motion" is on — the states still change, just without movement.

### 7.4 Sound
- Existing: `playBell()`, `playConch()`, `shankh_dhun.mp3`.
- New: soft tanpura drone (loop, 20% volume), matchstick strike for the diya, gentle "whoosh" for petals.
- A single mute button; remembered.

### 7.5 Haptics
Light tick for each step; a double soft pulse when the puja completes. Off if vibration is disabled in settings.

---

## 8. Accessibility checklist (50+ users)
- [ ] All text ≥ 18 sp; scales with system font up to 200% without clipping (use `FittedBox`/wrapping).
- [ ] Every tap target ≥ 56 × 56 dp.
- [ ] Every action reachable by the big bottom button — no need to find small objects.
- [ ] Colour is never the only signal (step dots also change size).
- [ ] Screen-reader labels on every object ("दिवा, लावण्यासाठी दोनदा टॅप करा").
- [ ] Reduce-motion respected; tilt can be switched off.
- [ ] Works in bright sunlight (contrast ≥ 4.5:1 for text).
- [ ] AR is always optional and has an automatic fallback.

---

## 9. Streak & habit rules
- A day counts when **all five steps** are done (or when the auto-aarti finishes).
- Day boundary 4 AM (same as jaap). One **Kshama Din** per month (premium: one per week).
- The streak is shared visually with jaap in "Meri Sadhana" as a second row: "पूजा दिवस 🔥 12" under "जप दिवस 🔥 30".
- Milestones: 7, 21, 40 (mandala), 108, 365 days — each unlocks a new decoration (not a badge), e.g. a silver kalash at 40 days, a brass bell at 108.

---

## 10. Free vs Premium

| Feature | Free | Premium |
|---|---|---|
| Ghar Mandir with 1 deity | ✅ | ✅ |
| Up to 3 deities side by side | — | ✅ |
| 5-step daily puja, streak, saint vachan | ✅ | ✅ |
| Tilt Darshan | ✅ | ✅ |
| Festival decorations | Major 6 festivals | All festivals + extra styles |
| Mandir styles (wood, marble, brass, stone) | Wood | All |
| Naivedya, abhishek, sankalp (v2) | Basic | Full |
| Family mandir (v2) | ✅ (up to 4 members) | ✅ (up to 12) |
| AR Darshan (v3) | 1 murti per festival | All murtis, all year |
| Kshama Din | 1 / month | 1 / week |

**Rule:** the daily puja itself is **never** locked. Premium adds beauty and choice, not devotion.

---

## 11. Technical design

### 11.1 Architecture (fits the current clean-architecture folders)
```
lib/
  domain/
    entities/ghar_mandir_state.dart     # chosen deities, style, streak, today's steps
    logic/puja_streak.dart              # reuse JaapCalendar / JaapStreak helpers
  data/
    datasources/deity_catalog.dart      # id, image, halo colour, names (mr/hi/en)
    datasources/saint_vachan_catalog.dart
    repositories/ghar_mandir_repository.dart   # SharedPreferences JSON
  presentation/
    providers/ghar_mandir_providers.dart
    screens/ghar_mandir_screen.dart
    screens/ghar_mandir_picker_screen.dart
    screens/ar_darshan_screen.dart      # v3
    widgets/ghar_mandir/
      mandir_scene.dart                 # layered Stack
      tilt_parallax.dart                # gyroscope → offsets
      diya_flame.dart, dhoop_smoke.dart, aarti_thali.dart, temple_doors.dart
      ghar_mandir_dashboard_card.dart
```

### 11.2 Data model
```dart
class GharMandirState {
  final List<String> deityIds;       // 1..3
  final String style;                // 'wood' | 'marble' | 'brass' | 'stone'
  final Map<String, int> stepsDone;  // dayKey -> bitmask of 5 steps
  final Set<String> completedDays;
  final Set<String> protectedDays;
  final int bestStreak;
  final bool soundOn, tiltOn;
}
```

### 11.3 Tilt Darshan implementation
- Package: `sensors_plus` (gyroscope/accelerometer).
- Low-pass filter: `smoothed = smoothed * 0.9 + raw * 0.1`, clamp to ±1.
- Each layer: `Transform.translate(offset: Offset(x * depth, y * depth))`.
- Pause the sensor stream when the screen is not visible (battery).
- Web / devices without a gyroscope: fall back to a very slow automatic "breathing" drift.

### 11.4 AR Darshan implementation (v3) — recommended approach
| Option | How | Pros | Cons |
|---|---|---|---|
| **A. `model_viewer_plus` + system AR (recommended)** | Show a `.glb` model; the "View in your space" button opens **Scene Viewer** (Android, ARCore) or **Quick Look** (iOS, `.usdz`) | Very stable, maintained by Google/Apple, tiny code | Limited custom UI inside AR (no in-AR diya buttons) |
| B. `ar_flutter_plugin` / ARCore + ARKit plugins | Full custom AR scene in Flutter | Custom buttons in AR | Plugins lag behind OS updates; much more code and testing |
| C. Native Unity module | Unity AR Foundation embedded | Best visuals | Heavy app size (+40–80 MB), complex build |

**Recommendation:** start with **Option A** for Ganeshotsav (placement + photo), measure usage, and only move to B if users ask for in-AR puja.

**3D assets:** each murti needs a respectful, high-quality `.glb` (Android/web) and `.usdz` (iOS) under ~5 MB, commissioned from an artist or properly licensed. Budget roughly ₹15,000–50,000 per murti depending on detail. Download on demand (not bundled) to keep the app small.

### 11.5 Packages
| Package | Purpose | Layer |
|---|---|---|
| `sensors_plus` | Tilt Darshan | v1 |
| `audioplayers` (existing) | Bell, conch, tanpura | v1 |
| `shared_preferences` (existing) | State | v1 |
| `share_plus` + `path_provider` | Share darshan card | v2 |
| `model_viewer_plus` | AR Darshan | v3 |

### 11.6 Performance
- Deity PNGs resized to max 1024 px and compressed (WebP) — current decoration PNGs should be optimised first.
- Smoke and flame drawn with `CustomPainter`, not video, to keep the app light.
- Target 60 fps on a ₹10,000 Android phone; test on a 3 GB RAM device.

---

## 12. Localization
All strings in Marathi, Hindi and English via a `GharMandirStrings(lang)` class (same pattern as `JaapStrings` and `PanchangStrings`).

| Key | मराठी | हिंदी | English |
|---|---|---|---|
| title | माझे घर मंदिर | मेरा घर मंदिर | My Home Mandir |
| lightDiya | दिवा लावा | दीया जलाएँ | Light the diya |
| dhoop | धूप दाखवा | धूप दिखाएँ | Offer dhoop |
| flowers | फुले अर्पण करा | फूल चढ़ाएँ | Offer flowers |
| bell | घंटा वाजवा | घंटी बजाएँ | Ring the bell |
| aarti | आरती करा | आरती करें | Do aarti |
| done | आजची पूजा पूर्ण 🙏 | आज की पूजा पूर्ण 🙏 | Today's puja is complete 🙏 |
| arInvite | बाप्पाला घरी आणा | बप्पा को घर लाएँ | Bring Bappa home |

---

## 13. Assets needed
- Clean transparent cut-outs of all deities (1024 px, WebP).
- Mandir frame sets for four styles (arch, pillars, doors, base) as separate layers.
- Diya, agarbatti stand, kalash, aarti thali, marigold garland, toran, rangoli — each as transparent layers.
- Festival overlays (14 festivals).
- Sounds: tanpura loop, matchstick, petal whoosh.
- v3: `.glb` + `.usdz` murtis (Ganesh first).

---

## 14. Analytics events
`mandir_open`, `mandir_deity_selected {deity}`, `puja_step {step}`, `puja_complete {streak}`, `puja_share`, `tilt_disabled`, `ar_offer_shown`, `ar_started`, `ar_placed`, `ar_photo_taken`, `ar_fallback {reason}`.

**Success metrics:**
- Day-7 return rate of mandir users ≥ 35%.
- ≥ 50% of users who start a puja complete all five steps.
- AR: ≥ 20% of offered users try it during Ganeshotsav; ≥ 10% share a photo.

---

## 15. Acceptance criteria (MVP)
- [ ] A new user can pick a deity and finish the first puja in under 90 seconds without instructions.
- [ ] Every step can be completed with the big bottom button alone.
- [ ] Puja completion updates the streak with the 4 AM boundary; missed day protection works.
- [ ] Festival decoration appears automatically on at least 6 major festivals.
- [ ] Tilt works on Android and iOS, can be turned off, and respects reduce-motion.
- [ ] Works fully offline; no crash with sound off or vibration off.
- [ ] Marathi, Hindi, English complete; no English inside Marathi screens.
- [ ] 60 fps on a mid-range Android phone.

---

## 16. Rollout plan
1. **Week 1–2:** Deity asset clean-up, mandir scene, 5-step puja, streak, dashboard card.
2. **Week 3:** Tilt Darshan, festival decorations, saint vachan library (proof-read).
3. **Week 4:** Internal testing with 5–10 people above 55; fix every place they hesitated.
4. **Release v1** before the next big festival.
5. **v2** (naivedya, abhishek, family mandir) after 4 weeks of usage data.
6. **v3 AR** timed for **Ganeshotsav**, Ganesh murti only; expand if ≥ 20% try it.

---

## 17. Decisions (recommended)

### 17.1 AR is a festival feature, not the core
Build the Ghar Mandir first. AR is offered only on festival days and after a completed puja, so it feels like a gift instead of a gimmick.

### 17.2 No face animation
Deities never blink, talk or move their face. Only light, flowers, smoke and flame move. This avoids offending devout users.

### 17.3 Tilt instead of camera for daily use
Tilt Darshan gives most of the "3D magic" of AR with none of its difficulty, so it is the daily experience.

### 17.4 Puja is never paywalled
Only decoration, choice and extra murtis are premium. Locking worship itself would damage trust with this audience.

### 17.5 Proof-reading is a release blocker
All saint vachans, aarti snippets and festival names must be checked by someone fluent in each language before release.
