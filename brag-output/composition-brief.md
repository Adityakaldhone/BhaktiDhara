# Hyperframes Composition Brief: BhaktiDhara

## Objective
Create a short launch-style brag video for BhaktiDhara (भक्तिधारा), the daily aarti and devotional app.

## Output
- Composition directory: `brag-output/composition/`
- Rendered video: `brag-output/brag.mp4`
- Format: landscape — 1920x1080, 30 fps
- Duration: 21 seconds

## Source Material
- Project root: `nitya_aarti/` (Flutter app + landing site in `backend/app/static/`)
- Primary files read: `backend/app/static/index.html` (hero, features, CTA, `:root` palette), `pubspec.yaml`, `assets/` (deity art, bell, sounds, fonts), `lib/presentation/screens/greetings_screen.dart` (app type: Mukta)
- Product name: BhaktiDhara (भक्तिधारा)
- Tagline / strongest claim: "Your Sacred Daily Temple, Aarti Sangrah & Holy Granths"
- Key UI or visual moment to recreate: the hero aarti card (banner, Shree Hanuman Chalisa, LIVE AARTI, highlighted Devanagari lyrics, Ring Ghanti / Blow Shankh / Shower Flowers)
- Copy that must appear verbatim:
  - Your Sacred Daily Temple
  - Aarti Sangrah & Holy Granths
  - Synced Auto-Scrolling Lyrics
  - Sing effortlessly with zero manual screen touching
  - Shree Hanuman Chalisa / Shankar Mahadevan • 9:48 min / LIVE AARTI
  - Ring Ghanti / Blow Shankh / Shower Flowers
  - 25+ Sacred Deities
  - Daily Vedic Panchang / Holy Granth & Pothi Reader / 100% Offline Ready
  - Bring the Sacred Temple into Your Home
  - GET IT ON Google Play

## Creative Direction
- Tone preset: polished
- Creative direction: a quiet sunrise puja film: warm brass, marigold and maroon, reverent and unhurried
- Interpretation: long settled holds, soft object-caused transitions, no hype language, the real ritual sounds carry the emotion
- Angle: "The temple rings first." The film opens on the app's own recorded ghanti and treats the product with the calm of a morning puja, letting the real rituals inside the app do the bragging.
- Hook: the golden bell swings in and strikes with the real ghanti; "Your Sacred Daily Temple" arrives word by word.
- Outro / punchline: colour flood to maroon; app icon on the 17.47 s beat; "Bring the Sacred Temple into Your Home"; Google Play badge.
- Avoid:
  - Generic SaaS language
  - Abstract filler visuals
  - Unrelated visual redesign

## Visual Identity
- Background: `#FFFBF5`; warm panels `#FFF7ED`, `#FEF3E2`; border `#FED7AA`
- Text: `#1C1917`; secondary `#57534E`
- Accent: `#D97706` (fills/glows), `#B45309` (accent text), `#EA580C`; outro ground `#5C1A0B` / `#7C2D12`
- Display font: Mukta 700 (`assets/fonts/Mukta-Bold.ttf`, from the app)
- Body font: Mukta 400; Devanagari lyrics in Tiro Devanagari Marathi (both from the app)
- Visual references from the project: hero aarti card, `bell.png`, deity cutouts in `assets/bhakti/`, app icon `logo.png`, `hero_banner.jpg`
- LOOK: ground `#FFFBF5` with a 20% `#D97706` radial glow; ink `#1C1917`; accent text `#B45309`; cards `#FFFFFF` with 1px `#FED7AA` border, 28px radius, warm shadow; outro ground `#5C1A0B`. BANNED: blue/purple gradients, glassmorphism, neon, Inter-only type, floating/pulsing idle loops on titles.

## Storyboard
Use the storyboard in `brag-output/brag-plan.md` as the creative contract.

1. The bell — 4.0s — bell swings in and strikes; "Your Sacred Daily Temple" word by word; "Aarti Sangrah & Holy Granths"
2. The aarti, live — 7.0s — hero aarti card with auto-scrolling lyric highlight; taps on Ring Ghanti, Blow Shankh, Shower Flowers; captions on the left
3. 25+ Sacred Deities — 5.6s — eight deity cards on the beat; three feature labels that then hold together
4. Bring the temple home — 4.4s — maroon flood, app icon, name in both scripts, closing line, Play badge, fade

## Audio
- Audio role: warm bed plus the app's own ritual sounds
- Audio arc: bell first; music settles under; ghanti and shankh answer the taps; soft rhythm under the deities; resolve and fade under the icon
- Music: `assets/music/happy-beats-business-moves-vol-12-by-ende-dot-app.mp3`
- Music treatment: ~0.28 volume, 1.5 s fade-out at the end
- Music cue guidance: bundled preset `assets/music/cues/happy-beats-business-moves-vol-12-by-ende-dot-app.music-cues.json`; strong cues 17.47 s (icon) and 18.56 s (badge); beat grid from 12.02 s for the deity row
- Audio-reactive treatment: subtle; RMS drives the warm glow behind the bell (Scene 1) and behind the icon (Scene 4)
- Audio-coupled moments:
  - Scene 1 bell strike — real `ghanti.mp3`
  - Scene 2 taps — `ghanti.mp3`, `shankh_dhun.mp3`, a light tap on Shower Flowers
  - Scene 3 deity row — soft drop on the first and last card
  - Scene 4 icon — soft warm impact
- SFX selection guidance: only sounds with a visible cause; low high-frequency-risk files
- SFX analysis guidance: `/tmp/brag-skill/skills/brag/assets/sfx/sfx-analysis.md`
- Exact SFX choice: chosen during composition against the implemented animation
- Audio files: copied into `brag-output/composition/assets/`

## Hyperframes Instructions
Built with the `hyperframes` contract (format, motion, look references), `hyperframes-cli` for check/snapshot/render. The brag plan and this brief replace the storyline step and SPEC.md. `check` is the gate.

Requirements:
- Show at least one real UI, copy, or visual element from the source project.
- Keep all text readable in the final render.
- Keep the video within 15-25 seconds.
- Include the planned music/SFX layer.
- Run `hyperframes check` before render.
- Keep creation and rendering local.
