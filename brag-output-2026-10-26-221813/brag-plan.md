# Brag plan — BhaktiDhara mobile app feature tour

- Format: vertical 1080x1920 (Reels / Shorts / Status)
- Duration: 45s. Deliberately over the 15–25s default because the brief is "explain all the features in our app"; each feature gets one ~4–7s beat-cut scene.
- Tone: warm devotional, clean product. Cream ground `#FFFBF5`, saffron accent `#B45309`, deep maroon outro `#5C1A0B`.
- Music: happy-beats-business-moves vol-12 (110 BPM, beat ≈ 0.546s), scene cuts on beats.
- Type: Mukta (UI), Tiro Devanagari Marathi (lyrics / mantras), from the app's own bundled fonts.

## Story (each claim is grounded in app copy)

| # | Time | Feature | On-screen copy | Source |
|---|------|---------|----------------|--------|
| 1 | 0.00–3.82 | Hook | "Your whole puja, in one app." BhaktiDhara · Aarti Sangrah | `appTitle`, `appSubtitle` |
| 2 | 3.82–10.93 | Aarti player | "Read & Play every Aarti" · auto-scrolling lyrics · Bell / Conch / Flowers · "Screen stays awake automatically" | `readAndPlay`, `screenAwake`, `playBell`, `blowConch`, website features |
| 3 | 10.93–15.84 | 25+ deities + search | "Search Aarti, Chalisa, Bhajan..." · Voice Search | `searchHint`, `voiceSearch`, `sacredCollection` |
| 4 | 15.84–20.19 | Bhakti Sangrah videos | "Bhajans, Mantras, Stotras & Chants" | `bhajanSangrah`, `bhajanSubtitle` |
| 5 | 20.19–24.56 | Holy Granth & Pothi reader | Bhagavad Gita, Dasbodh, Shiva Purana, Bhagavata Purana | `granth_meta.dart` |
| 6 | 24.56–30.01 | Naam Jaap digital mala | "Tap anywhere", count to 108, "Mala complete 🙏", streak | `jaap_strings.dart` |
| 7 | 30.01–35.47 | Panchang + Rashifal | Tithi / Nakshatra / Yoga / Karana / Sunrise; 12 rashis | `panchang_strings.dart`, `horoscope.dart` |
| 8 | 35.47–39.82 | Greetings | "Greetings", one-tap WhatsApp share | `greeting_strings.dart`, website |
| 9 | 39.82–45.00 | Outro | Logo, tagline, हिंदी · मराठी · English, 100% Offline Ready, Google Play | `appTagline`, website |

Panchang values and the jaap streak count are illustrative UI states, not live data.
