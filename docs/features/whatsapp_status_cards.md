# Shubh Sandesh — WhatsApp Status & Greeting Cards — Feature Design Document

> **Status:** Proposal · **Owner:** Product · **Audience:** Devotees 50+ (primary)
> **One-line pitch:** *"Every morning, a beautiful, correct, ready-made शुभ सकाळ card with today's god, tithi and a sacred line — sent to your family in one tap."*

---

## 1. Why this feature

### 1.1 The behaviour already exists
- Sending "Good morning" god images on WhatsApp every morning is one of the most common digital habits of Indian users above 50. Today they get these images from random forwards, Google search, or ad-heavy "status maker" apps.
- Play Store status apps (e.g. *BHAKT — God AI Status Maker*, *Kattar Hindu God Video Status*) and darshan apps (e.g. *Live Darshan India* — "make your own devotional status in seconds") show strong demand.
- What these apps get wrong: blurry images, wrong festival dates, spelling mistakes in Marathi, heavy ads, and no connection to the user's actual daily worship.

### 1.2 Why it matters for BhaktiDhara
| Benefit | How |
|---|---|
| **Free growth** | Every shared card carries a small, beautiful "BhaktiDhara" mark and a link. One user's status is seen by 50–200 contacts every day. |
| **Daily habit** | A fresh card every morning is a reason to open the app daily, like the jaap and puja streaks. |
| **Trust** | Our cards show **correct** tithi, festival and Rahu Kaal from the Panchang — people forward what they trust. |
| **Connects existing features** | Panchang, aarti, jaap milestones and Ghar Mandir puja all become shareable. |

### 1.3 What we will not do
- No spammy content ("forward to 10 people or…"), no fake miracles, no political or divisive slogans.
- No auto-posting or reading the user's contacts. The user always chooses to share.
- No copyrighted images from the internet — only our own or properly licensed artwork.

---

## 2. Design principles (for a 50+ audience)

1. **Ready before they ask.** Today's card is already made when the app opens. Zero design work needed.
2. **One big green button.** "WhatsApp वर पाठवा" — the only action most users will ever use.
3. **Editing is optional and simple.** Three choices at most, each a big picture, never a text editor with fonts and stickers.
4. **Correct and respectful.** Proof-read text, accurate Panchang data, deity always fully visible and dignified.
5. **Beautiful at phone size.** Big Devanagari text readable in a WhatsApp status preview; high-resolution, no blur.
6. **Personal touch.** The sender's name ("— आदित्य काका") makes it feel like their own greeting, not an ad.
7. **The brand is a whisper, not a shout.** Small logo at the bottom; the card must look like a gift, not a banner ad.

---

## 3. Feature scope

### 3.1 MVP (v1) — Free
**Card types:**
1. **Shubh Sakal (Good morning) card** — auto-made daily:
   - Deity of the day (weekday rule or the user's Ishta Devata)
   - Greeting: "शुभ सकाळ" / "सुप्रभात" / "Good Morning"
   - Today's day, date, tithi (from Panchang)
   - One sacred line (abhang / doha / shloka), proof-read
   - Sender's name (optional)
   - Small BhaktiDhara mark
2. **Festival card** — replaces the morning card on festival days ("गणेश चतुर्थीच्या हार्दिक शुभेच्छा"), with a festival-specific design.
3. **Aaj ka Panchang card** — a clean summary: tithi, nakshatra, sunrise, sunset, best time, Rahu Kaal. Many elders forward this every morning.

**Formats:**
- **Status (9:16, 1080 × 1920)** — default, for WhatsApp Status and Instagram Stories.
- **Square (1:1, 1080 × 1080)** — for sending in family groups.

**Sharing:**
- "WhatsApp वर पाठवा" opens the system share sheet with the image and a short caption: "🙏 शुभ सकाळ 🙏 — BhaktiDhara ॲप: <link>".
- "इतर ॲपवर पाठवा" (other apps) and "फोटो सेव्ह करा" (save to phone) as secondary actions.

**Personalisation (all optional):**
- Name ("तुमचे नाव कार्डवर दिसेल") — asked once, remembered.
- Change deity (swipe or pick from a grid of 6–8).
- Change greeting line (3 choices).

### 3.2 v2 — More moments
- **Jaap milestone card** — "मी आज 1,008 राम नाम जप पूर्ण केला 📿" with the mala ring graphic. Shown after milestones in the jaap feature.
- **Puja complete card** — "आजची पूजा पूर्ण 🪔" with the user's Ghar Mandir deity (see `ghar_mandir_ar_darshan.md`).
- **Aarti card** — a stanza of the aarti the user just listened to, with the deity image.
- **Occasion cards** — birthday blessing (with deity), anniversary, griha pravesh, "शुभ रात्री" (good night).
- **Morning reminder** — optional 6:30 AM notification: "आजचे शुभ सकाळ कार्ड तयार आहे 🌅".
- **Own photo frame** — put the user's family photo inside a festival frame (e.g. Diwali diyas border).

### 3.3 v3 — Short video status
- 10–15 second vertical video: slow zoom on the deity, falling petals, the diya flame, with a few seconds of aarti or mantra audio.
- Festival video templates (Ganeshotsav, Navratri, Diwali).
- Technical risk: on-device video encoding in Flutter needs a native encoder (see 11.5). Build only if image sharing shows strong usage.

### 3.4 Out of scope
- AI-generated deity images (quality and respect risks; many users object to "AI gods").
- A social feed inside the app.
- Scheduled auto-posting to WhatsApp (not allowed by WhatsApp and not wanted).

---

## 4. User flows

### 4.1 First time (≤ 2 screens)
```
Dashboard card "🌅 आजचे शुभ सकाळ कार्ड"  →  full-screen preview of today's card
→ Bottom: [ 🟢 WhatsApp वर पाठवा ]   ( बदला ✏️ )
→ First tap on WhatsApp only: small sheet
   "कार्डवर तुमचे नाव लिहायचे?"  [ नाव लिहा ]  [ नको, असेच पाठवा ]
→ Share sheet opens with WhatsApp first
```

### 4.2 Every day (2 taps)
```
Open app → dashboard card already shows today's card thumbnail
→ tap → preview → WhatsApp वर पाठवा → pick status or contact
```

### 4.3 Changing the card (optional)
```
Preview → "बदला ✏️" → one sheet with three big rows:
   1. देव निवडा      [ Ganesh ] [ Vitthal ] [ Shiva ] [ Sai ] [ Devi ] …  (horizontal, big images)
   2. शुभेच्छा निवडा  ( शुभ सकाळ ) ( जय श्री राम ) ( राम कृष्ण हरी )
   3. तुमचे नाव       [ आदित्य काका          ]
→ Preview updates live → "पूर्ण" → back to preview
```

### 4.4 Festival day
```
Panchang festival detected → dashboard card turns festive (gold border, small diya)
"आज गणेश चतुर्थी — शुभेच्छा कार्ड पाठवा"
→ Festival card preview; the regular morning card is one swipe away
```

### 4.5 After a jaap milestone or puja (v2)
```
Celebration dialog → new secondary button "📤 कुटुंबाला सांगा"
→ Milestone card preview → WhatsApp
```

---

## 5. Screens & UI

### 5.1 Dashboard card
```
┌────────────────────────────────────────────┐
│  🌅 आजचे शुभ सकाळ कार्ड                     │
│  ┌──────┐  मंगळवार · भाद्रपद शुद्ध एकादशी    │
│  │ card │  गणपती बाप्पा मोरया 🙏              │
│  │thumb │                                   │
│  └──────┘  [ 🟢 WhatsApp वर पाठवा ]           │
└────────────────────────────────────────────┘
```
The WhatsApp button works **directly from the dashboard** — sharing takes one tap for returning users.

### 5.2 Preview screen
```
┌──────────────────────────────────────┐
│ ←  शुभेच्छा कार्ड              ⋯      │
│                                      │
│   ┌──────────────────────────────┐   │
│   │                              │   │
│   │      (full card preview,     │   │
│   │       9:16, rounded)         │   │
│   │                              │   │
│   └──────────────────────────────┘   │
│    ● ○ ○   (swipe: morning / festival / panchang)
│                                      │
│  [ 🟢  WhatsApp वर पाठवा           ]  │  56 dp, full width
│  [ ✏️ बदला ]   [ ⬇️ सेव्ह ]   [ ↗︎ इतर ] │  48 dp
└──────────────────────────────────────┘
```

### 5.3 Card layout — Shubh Sakal (9:16)
```
┌──────────────────────────────────┐
│  ✦ mandala corner      mandala ✦ │
│                                  │
│         शुभ सकाळ                  │  Yatra One, 96 px, maroon with gold outline
│      ─────── ✦ ───────           │
│                                  │
│        [  DEITY IMAGE  ]          │  ~45% of height, soft halo glow behind
│          (full figure)            │
│                                  │
│   मंगळवार, २९ सप्टेंबर २०२६        │  Mukta 44 px
│   भाद्रपद शुद्ध एकादशी              │  Mukta Bold 52 px, saffron
│                                  │
│   " विठ्ठल विठ्ठल जय हरी विठ्ठल "   │  Noto Serif Devanagari 46 px
│        — संत तुकाराम               │
│                                  │
│        — आदित्य काका 🙏            │  sender name, 40 px
│                                  │
│   🪷 BhaktiDhara ॲप               │  32 px, 70% opacity, bottom
└──────────────────────────────────┘
```
Safe zones: keep all text 120 px away from top and bottom (WhatsApp status shows the sender's name and reply bar over the image).

### 5.4 Card layout — Aaj ka Panchang (9:16)
```
   आजचे पंचांग  ·  पुणे
   मंगळवार, २९ सप्टेंबर २०२६
   ─────────────────────────
   तिथी        एकादशी (शुक्ल)
   नक्षत्र      श्रवण
   🌅 सूर्योदय   ०६:१२ AM
   🌇 सूर्यास्त   ०६:२२ PM
   ✅ शुभ वेळ    ११:४८ – १२:३६
   ⛔ राहु काळ   ०३:०० – ०४:३०
   ─────────────────────────
   🪷 BhaktiDhara — संपूर्ण पंचांग ॲपमध्ये
```
Uses the same data and good/avoid colours as the simplified Panchang screen.

### 5.5 Template styles (MVP: 6)
| Style | Look | Best for |
|---|---|---|
| **Sandal & Gold** | Cream background, gold mandala corners | Daily default |
| **Temple Dusk** | Deep maroon-to-saffron gradient, diya glow | Evening / Shiva / Devi |
| **Marigold** | Marigold garland top border, warm yellow | Ganesh, festivals |
| **Tulsi Green** | Soft green with tulsi leaves | Vitthal, Krishna, Ekadashi |
| **Royal Blue** | Deep blue with silver stars | Vishnu, Venkatesh, Rama |
| **Plain Paper** | Handmade-paper texture, red border | Panchang card, abhang |

The style is picked automatically from the deity and day. Users never have to choose one.

---

## 6. Content

### 6.1 Deity of the day
Same weekday rule as Ghar Mandir (Mon Mahadev, Tue Ganesh/Hanuman, Wed Vitthal, Thu Datta/Sai, Fri Lakshmi/Devi, Sat Hanuman/Shani, Sun Surya/Khandoba). If the user has set an Ishta Devata, it is used on every day except festivals.

### 6.2 Greeting lines (per language, MVP: 10 each)
- Marathi: शुभ सकाळ · राम कृष्ण हरी · गणपती बाप्पा मोरया · जय श्री राम · ॐ नमः शिवाय · श्री स्वामी समर्थ · जय हरी विठ्ठल · जय माता दी · दत्त दिगंबर · सुप्रभात
- Hindi: सुप्रभात · जय श्री राम · राधे राधे · हर हर महादेव · जय माता दी · …
- English: Good Morning · Jai Shri Ram · Om Namah Shivaya · …

### 6.3 Sacred lines (MVP: 365 lines — one per day of year, per language)
From public-domain sources: Tukaram, Dnyaneshwar, Namdev, Eknath, Ramdas (Manache Shlok), Tulsidas, Kabir, Surdas, Bhagavad Gita. Each line stored with: text, source/saint, language, suitable deities. **Every line proof-read before release.**

### 6.4 Festival calendar
Driven by the Panchang festival name; each festival maps to a template, a greeting ("…च्या हार्दिक शुभेच्छा") and a deity.

---

## 7. Visual design system

### 7.1 Colours
Same family as jaap and Ghar Mandir:
| Token | Hex | Use |
|---|---|---|
| Sandal cream | `#FFF8EC` | Default background |
| Deep maroon | `#7A1F1F` | Greeting text |
| Brass gold | `#C9A227` | Borders, dividers, outlines |
| Saffron | `#E8740C` | Tithi, highlights |
| Kumkum | `#B91C1C` | Small accents |
| WhatsApp green | `#25D366` | Only the share button |

### 7.2 Typography on cards
| Element | Font | Size at 1080 px width |
|---|---|---|
| Greeting | Yatra One | 88–100 px |
| Tithi | Mukta Bold | 50–56 px |
| Date | Mukta | 42–46 px |
| Sacred line | Noto Serif Devanagari | 44–48 px |
| Sender name | Mukta Medium | 38–42 px |
| Brand | Mukta | 30–32 px |

Fonts must be **bundled in the app** (not downloaded at runtime) so cards render correctly offline and always look the same.

### 7.3 Quality rules
- Export at 1080 × 1920 (or 1080 × 1080), PNG for text-heavy cards, high-quality JPEG (90%) for photo-heavy ones; keep under 1.5 MB so WhatsApp compression does not destroy text.
- Minimum contrast 4.5:1 between text and background, checked on every template.
- Deity image never overlapped by text; never cropped at the feet or crown.

---

## 8. Accessibility checklist (50+ users)
- [ ] The share button is the largest element on screen and says what it does in words, not just an icon.
- [ ] Today's card loads instantly (pre-rendered in the background at app start).
- [ ] Editing uses pictures and big buttons; typing is only for the name.
- [ ] Works with system font up to 200% in the app UI (the card image itself is fixed-size).
- [ ] Screen reader reads the card content ("शुभ सकाळ कार्ड, गणपती, भाद्रपद शुद्ध एकादशी").
- [ ] If WhatsApp is not installed, the share sheet still works with other apps.

---

## 9. Growth mechanics (ethical)
- **Brand mark:** "🪷 BhaktiDhara ॲप" at the bottom of every card — small, elegant, always present on free cards.
- **Caption link:** the share caption includes a short link to the Play Store page with a referral tag (Play Install Referrer) so installs from cards can be measured.
- **Invite, don't push:** after the 5th share, one gentle line: "तुमच्या कुटुंबालाही हे कार्ड रोज मिळावे असे वाटते? ॲप शेअर करा" — shown once, never again if dismissed.
- **No rewards for sharing** (no coins, no unlocks) — it would attract spam and cheapen the feature.

---

## 10. Free vs Premium

| Feature | Free | Premium |
|---|---|---|
| Daily Shubh Sakal card | ✅ | ✅ |
| Festival cards | ✅ | ✅ |
| Aaj ka Panchang card | ✅ | ✅ |
| Name on card | ✅ | ✅ |
| Templates | 6 | 20+ incl. gold-foil and seasonal |
| Deity choice | All | All |
| Own photo in frame (v2) | 1 frame | All frames |
| Occasion cards — birthday, anniversary (v2) | 2 designs | All |
| Video status (v3) | 1 per week | Unlimited |
| Brand mark | Small mark | Smaller, corner-only mark |

**Rule:** the daily card and festival cards are always free. The brand mark is **never fully removed** (it is part of the gift's authenticity and our growth), only made smaller for premium.

---

## 11. Technical design

### 11.1 Architecture
```
lib/
  domain/
    entities/greeting_card.dart          # type, deityId, greeting, line, date, tithi, sender
    logic/card_of_the_day.dart           # picks deity, template, line for a date
  data/
    datasources/sacred_line_catalog.dart # 365 × 3 lines
    datasources/card_template_catalog.dart
    repositories/greeting_prefs_repository.dart  # name, ishta devata, last shared day
  presentation/
    providers/greeting_card_providers.dart
    screens/greeting_card_preview_screen.dart
    widgets/greeting/
      card_canvas.dart                   # the card widget (fixed 1080×1920 logical layout)
      template_sandal_gold.dart, template_temple_dusk.dart, …
      greeting_dashboard_card.dart
      greeting_edit_sheet.dart
  services/
    card_renderer.dart                   # widget → PNG bytes
    card_share_service.dart              # temp file → share sheet
```

### 11.2 Data model
```dart
enum CardType { morning, festival, panchang, jaapMilestone, pujaDone, aarti, occasion }

class GreetingCard {
  final CardType type;
  final String deityId;
  final String templateId;
  final String greeting;
  final String? sacredLine;
  final String? lineSource;
  final DateTime date;
  final String? tithiText;
  final String? festivalName;
  final String? senderName;
  final String lang;
}
```

### 11.3 Rendering (widget → image)
1. Build `CardCanvas` inside a `RepaintBoundary` at a fixed logical size (e.g. 360 × 640) inside an off-screen `Overlay` entry.
2. `boundary.toImage(pixelRatio: 3.0)` → 1080 × 1920.
3. `image.toByteData(format: ImageByteFormat.png)`.
4. Wait for images and fonts to be ready first (`precacheImage` for the deity; bundled fonts).
5. Cache today's rendered PNG in memory and on disk (`path_provider` temp dir), keyed by date + deity + template + name + language, so sharing is instant.

### 11.4 Sharing
- `share_plus`: `Share.shareXFiles([XFile(path, mimeType: 'image/png')], text: caption)`.
- Android: the system sheet lists WhatsApp first if used recently; no special WhatsApp API needed.
- iOS: the same share sheet; WhatsApp shows "Status" and chats.
- Web: `share_plus` uses the Web Share API where available, otherwise downloads the image.
- "Save to phone": use the share sheet's "Save image" (iOS) / a gallery-save package on Android — avoid asking for broad storage permission.

### 11.5 Video status (v3) — options
| Option | Notes |
|---|---|
| Native encoder via platform channel (Android `MediaCodec`/`MediaMuxer`, iOS `AVAssetWriter`) | Most reliable long-term; more code |
| An FFmpeg-based Flutter package | Quick to prototype; check maintenance status and licence (LGPL/GPL) before shipping |
| Server-side rendering on the existing backend | Simple app code; costs server CPU and needs internet |

Decide only after v1/v2 usage data.

### 11.6 Packages
| Package | Purpose |
|---|---|
| `share_plus` | Share image + caption |
| `path_provider` | Temp file for the PNG |
| Bundled fonts (`pubspec.yaml` `fonts:`) | Yatra One, Mukta, Noto Serif Devanagari offline |
| Existing Panchang providers | Tithi, festival, timings |

### 11.7 Performance
- Pre-render today's card 2 s after app start, in the background, only once per day.
- Deity images optimised (≤ 1024 px WebP) — current PNG assets should be compressed first.
- Render time target: < 400 ms on a mid-range Android phone.

---

## 12. Localization
`GreetingStrings(lang)` class for UI text; card text comes from the catalogs in each language.

| Key | मराठी | हिंदी | English |
|---|---|---|---|
| dashboardTitle | आजचे शुभ सकाळ कार्ड | आज का सुप्रभात कार्ड | Today's Good Morning card |
| sendWhatsApp | WhatsApp वर पाठवा | WhatsApp पर भेजें | Send on WhatsApp |
| change | बदला | बदलें | Change |
| save | सेव्ह करा | सेव करें | Save |
| other | इतर ॲप | अन्य ऐप | Other apps |
| askName | कार्डवर तुमचे नाव लिहायचे? | कार्ड पर आपका नाम लिखें? | Add your name to the card? |
| chooseDeity | देव निवडा | भगवान चुनें | Choose deity |
| chooseGreeting | शुभेच्छा निवडा | शुभकामना चुनें | Choose greeting |
| tellFamily | कुटुंबाला सांगा | परिवार को बताएँ | Tell your family |

Numbers on Marathi/Hindi cards use Devanagari digits (२९ सप्टेंबर), matching the Panchang.

---

## 13. Assets needed
- High-resolution transparent deity cut-outs (shared with Ghar Mandir).
- 6 template backgrounds (MVP) + 14 festival backgrounds, designed at 1080 × 1920 and 1080 × 1080.
- Mandala corners, dividers, garland borders as separate transparent layers (reuse `corner_mandala.png`, `horizontal_bar_trimmed.png`).
- BhaktiDhara lotus mark (small, single-colour).
- Bundled font files.

---

## 14. Analytics events
`card_preview_open {type}`, `card_edit {field}`, `card_share {type, target_hint}`, `card_save`, `card_name_added`, `card_share_from_dashboard`, `card_festival_shown {festival}`, `install_from_card` (via referrer).

**Success metrics:**
- ≥ 25% of daily active users share at least one card per week.
- ≥ 10% of new installs attributed to card links within 3 months.
- Shares per sharing user per week ≥ 3.

---

## 15. Acceptance criteria (MVP)
- [ ] Today's card is ready on the dashboard within 3 s of app start, offline.
- [ ] Returning user can share today's card in **one tap** from the dashboard.
- [ ] Tithi, date and festival on the card always match the Panchang screen.
- [ ] Card text is sharp after WhatsApp compression (checked on Android and iOS status).
- [ ] No text in the top/bottom 120 px safe zones.
- [ ] Marathi, Hindi and English cards reviewed by native speakers; zero spelling errors.
- [ ] Works without WhatsApp installed (falls back to the normal share sheet).
- [ ] Brand mark and link present on every free card.

---

## 16. Rollout plan
1. **Week 1:** Card canvas + 3 templates + renderer + share; morning card only.
2. **Week 2:** Festival and Panchang cards, name, deity/greeting change, 365-line catalog (proof-read).
3. **Week 3:** Test with 10 users above 55: can they share without help? Fix every hesitation.
4. **Release v1** 1–2 weeks **before a major festival** (e.g. Navratri or Diwali) so the first shares ride festival demand.
5. **v2:** jaap/puja milestone cards, occasion cards, morning reminder.
6. **v3:** video status, only if ≥ 25% weekly sharing is reached.

---

## 17. Decisions (recommended)

### 17.1 Images first, video later
Images are fast, sharp, small and reliable on every phone. Video adds encoder complexity and large files; build it only after image sharing proves itself.

### 17.2 Our own artwork only — no AI-generated gods
AI deity images often have errors (wrong hands, wrong symbols) and many devout users object to them. Use commissioned or properly licensed art.

### 17.3 Brand mark always present, never loud
It is the growth engine, but the card must feel like a personal blessing. Small lotus + name at the bottom, ~70% opacity.

### 17.4 The daily card is always free
It is the daily habit and the growth loop. Premium adds variety (templates, frames, video), never access.

### 17.5 Proof-reading is a release blocker
Every greeting, sacred line and festival name is checked by a native speaker of each language before release. One wrong spelling forwarded to thousands of families would damage trust badly.

### 17.6 Link Shubh Sandesh to Ghar Mandir and Jaap
Cards should be the "share" step of existing rituals (after puja, after a jaap milestone), not a separate island — this keeps the app one connected daily practice.
