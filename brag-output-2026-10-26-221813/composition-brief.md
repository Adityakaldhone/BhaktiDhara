# Composition brief — BhaktiDhara feature tour (vertical)

- Canvas 1080x1920, 30fps, 45s. Root `composition/index.html` mounts 9 scene sub-compositions on track 1.
- Every feature scene shares one grammar: numbered saffron kicker, 76px bold title revealed word by word, a one-line body, and a 720x1300 phone rising into frame. Inside the phone, one real interaction happens (tap, scroll, count, share), with a touch dot marking every tap.
- Exits are a 0.22s blur-out on the scene stage, cut on the music beat.
- Screens are rebuilt in HTML from the app's own assets: deity webp art, `aarti_screen` ritual icons, logo, bundled Mukta and Tiro Devanagari fonts.
- Audio: music bed vol-12 at 0.26 with a 1.8s fade-out. SFX come from the app (`ghanti.mp3`, `shankh_dhun.mp3`, `jaap_tick.mp3`) plus soft UI clicks and drops, each landing one frame after its visual.
- Frame 0 is the outro poster (`brag.jpg`, taken at 43.6s), baked in for social thumbnails.
