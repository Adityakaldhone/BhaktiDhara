# BhaktiDhara voice training and coverage

## What training requires

1. **Supported actions and arguments.** Each label must correspond to a Flutter route or operation. Use the real mantra, zodiac, and devotional media IDs. Match any optional arguments the screen can use.
2. **A dated catalog snapshot.** Combine Flutter and cached remote content. Keep localized titles, deity aliases, item IDs, and playback availability together so examples resolve to real content. Review duplicate titles before assigning a single target.
3. **Multilingual utterances.** Include Marathi, Hindi, English, Hinglish, and Romanized Marathi. Cover terse aliases, polite questions, mixed scripts, spelling and spacing variants, word order, ASR errors, ambiguous titles, cancellation, missing arguments, wrong features, and unsupported requests.
4. **Real speech data.** Supplement synthetic utterances with consented, de-identified recordings and corrected transcripts. Hold out speakers and recordings for evaluation. Measure recognition errors separately before checking the final action and arguments.
5. **Train and validation data.** Deduplicate normalized utterances, preserve every available training target when reducing media volume, and keep reviewed evaluation prompts outside both datasets. Save the base model, catalog, hyperparameters, and checkpoint with the run.
6. **Acceptance checks.** Compare candidate and current adapters on the same held-out commands. Check action, required IDs, unsupported results, and the online and offline app flows. Verify microphone recognition, spoken replies, route navigation, and actual playback on device separately.

## Voice request inventory

| Area | What users can say | What the app does |
| --- | --- | --- |
| Naam jaap | “jap”, “japa”, “naam jap”, “nam jaap”, “naamjaap”, “namjaap”, “chant”, “नाम जाप”, “जपमाळ” | Opens the counter. Supports spacing, case, and punctuation variants. |
| Choose a mantra | “chant Jai Shri Ram”, “Hare Krishna ka jap karna hai”, “गायत्रीचा नामजप लावा” | Opens the counter with the named mantra when resolved. Training covers all 17 mantra IDs in the app. |
| Jaap activity | “show my chanting streak”, “जाप का इतिहास खोलो”, “माझ्या जपाची आकडेवारी दाखवा” | Opens My Sadhana, which shows today's count, streak, totals, and other statistics available to the user. |
| Devotional media | “Play Hanuman Chalisa”, “गणपतीची आरती उघडा”, “कृष्ण भजन चलाओ”, “Read the lyrics of Gayatri Mantra”, “Pasaydan”, “Shani Dev arrti” | Opens the matched item. Listening requests attempt playback when available. Reading opens the item with autoplay off. |
| Horoscope | “rashi sanga”, then “सिंह” | Asks “कोणत्या राशीचं भविष्य सांगू?” in Marathi and listens for a sign. Opens today's horoscope for the supplied sign. All 12 can be selected by name. |
| Horoscope navigation | “Open the horoscope screen”, “आजचे मेष राशीभविष्य” | Opens the horoscope screen directly. A named sign selects its forecast. |
| Panchang and muhurat | “आज कौन सी तिथि है?”, “When is Rahu Kaal?”, “आजचे नक्षत्र सांगा” | Opens Panchang. Users can view tithi, nakshatra, Rahu Kaal, muhurat, sunrise, and other details there. |
| Festivals | “open the festival calendar”, “इस महीने के त्योहार दिखाओ”, “सणांची दिनदर्शिका उघडा” | Opens the festival calendar. |
| Mandir and Akhand Diya | “मंदिर दर्शन खोलो”, “देवघर दाखवा”, “Open the Akhand Diya” | Opens the virtual shrine. |
| Granth | “Show the sacred books library”, “गुरुचरित्र अध्याय ३”, “दासबोध उघडा” | Opens the granth library. Users select the book and chapter there. |
| Kundali | “Create my birth chart”, “माझी जन्मपत्रिका काढा” | Opens the birth details form. |
| Kundali Milan | “Compare two birth charts”, “shaadi ke liye gun milao” | Opens Kundali Milan. |
| Ishta Devta | “माझे इष्ट दैवत कोणते?”, “Find my personal deity” | Opens the Ishta Devta screen. |
| Greetings | “Show devotional greeting cards”, “आजचा सुविचार” | Opens greetings and daily quotes. |
| Grahan | “Show lunar eclipse timings”, “सूर्य ग्रहण का समय बताओ” | Opens the eclipse screen. |
| App language | “Change the app language to Marathi”, “भाषा निवडा” | Applies and saves the named language, or opens the picker for Marathi, Hindi, and English. |
| Feedback | “Feedback and suggestions”, “अभिप्राय द्या” | Opens the existing feedback form for the user to fill and submit. |
| App instructions | “How do I share a greeting?”, “Which languages are available?”, “जप कसा मोजायचा?” | Speaks instructions for 13 app topics in the active language and keeps the assistant open. |
| Catalog questions | “Who sang Pasaydan?”, “पसायदान बद्दल सांगा”, “Does Shani Dev aarti have audio?” | Reads the performer, duration, localized description or recording availability from the matched catalog entry. Missing metadata gets an explicit reply. |
| Video songs | “Play Namo Namo by Amit Trivedi” | Opens the matching entry in the existing video player. The catalog includes alternate spoken titles without parenthetical subtitles. |
| More and reminders | “Show the More menu”, “Open evening aarti reminders” | Opens More or its reminder settings. The user controls the reminder switches. |
| Notifications | “open notification”, “नव्या सूचना उघडा”, “मेरे नोटिफिकेशन खोलो” | Opens the home bell's inbox with announcements and in-app notifications. |
| Missing item or feature | “Play a hymn that isn’t in the catalog” | Gives a localized not-found reply and stays on the current screen. Mandir opens for a shrine request. |
| Cancelled or unrelated requests | “Don't start a chant”, “जप सुरू करू नका”, “What is the capital of Japan?” | Training uses `none`. Jaap cancellations and several unsupported jaap requests are also guarded in the app and backend. |

## Request families that need more app capability

| Request family | Examples | Capability required |
| --- | --- | --- |
| Jaap controls | “Set a goal of 108”, “pause the chant”, “remind me at 6 AM”, “delete my jaap history” | Voice arguments and actions for goals, sessions, reminders, and data changes. |
| Playback and library management | “Skip to the next bhajan”, “resume at two minutes”, “save to favourites”, “download this” | Player controls and voice actions tied to the current item. |
| Specific books and chapters | “Read chapter 3 of Gurucharitra”, “continue where I left off in Dasbodh”, “open Gita chapter 2 verse 47” | Book, chapter, verse, and resume routing across the supported readers. |
| Personalized astrology and calendar | “Tomorrow's Panchang for Pune”, “show my saved Kundali”, “when is the next eclipse visible in Mumbai?” | City, date, saved profile, and field selection. |
| Shrine interactions | “Show Krishna in the mandir”, “ring the bell”, “light the diya” | Deity selection and explicit shrine controls. |
| Social and settings | “Share today's greeting on WhatsApp”, “increase text size”, “manage premium” | Screen-specific voice actions and the applicable platform UI. |
| Devotional answers | “What does the Gayatri mantra mean?”, “who wrote this stotra?”, “explain this Gita verse” | A reviewed knowledge source, citations, and an answer mode. |
| Conversation context | “The other aarti”, “play it in Marathi”, “open Panchang and then start the jaap” | Follow-up context, clarification, and sequencing across actions. |

## Run and verify

From the repository root, build, train, and evaluate a candidate with `bash backend/scripts/train_mlx_lora.sh`. Set `BHAKTI_REFRESH_KNOWLEDGE=0` to use the cached catalog. Each run stores its prepared data alongside the checkpoints. The script uses the cached Apple Silicon MLX environment when available. Set `HF_HUB_OFFLINE=1` for a cached base model.

Evaluate a candidate directly using the same chat template as the backend.

```sh
PYTHONPATH=backend BHAKTI_MLX_ADAPTER=/absolute/path/to/adapter \
  backend/.venv-mlx/bin/python backend/scripts/evaluate_voice_adapter.py
```

Run API resolver and on-device parser regressions from the repository root.

```sh
PYTHONPATH=backend backend/.venv-mlx/bin/python -m unittest discover \
  -s backend/tests -p test_voice_intents.py
flutter test --no-pub test/voice_agent_flow_test.dart
```

## Local training results

The first pass used catalog snapshot `3ee177b5f56a9eb7`. It generated 2,671 unique utterances and prepared 1,313 training rows and 195 validation rows. The training split included 16 action labels, all 17 mantra IDs, all 12 zodiac IDs, and 265 media IDs. Two catalog entries shared titles with other entries and had no unique generated utterance. The second pass continued from the saved step-400 weights for another 160 steps using 32 training rows per action. Neither run included any of the 38 benchmark utterances in training or validation.

| Model configuration | Core commands | Expanded commands |
| --- | --- | --- |
| Previously installed setup | 8 / 20 | |
| Saved step-400 checkpoint | 10 / 20 | 14 / 18 |
| Action-balanced follow-up | 15 / 20 | 13 / 18 |

These scores use the action and any checked arguments from direct model output. In the app, the resolver handles explicit jaap commands and cancellations before consulting the adapter. With the selected adapter and resolver together, the FastAPI endpoint passed all 38 benchmark cases. Use `--runtime` to reproduce the endpoint check. Microphone transcription and audio playback need device checks.

The earlier action-balanced follow-up was installed in `backend/data/training/mlx_adapters` before app-question training. The previous active files are in `backend/data/training/mlx_previous_before_expanded_voice`. Both training runs retain their datasets and benchmark logs in their candidate directories.

## November 24 app-question training

The local Qwen3-4B LoRA received 100 additional updates on multilingual feature instructions, settings and actions, followed by 120 updates on a corpus rebuilt from the Flutter collection. The second corpus contained 6,524 unique transcripts. Action and topic balancing produced 866 training rows and 451 validation rows for that pass. Both passes used a batch size of two, 16 adapted layers and a maximum sequence length of 512. MLX reported truncation on an overlength sequence. The first pass used a learning rate of 0.00008 and the second used 0.000055.

The active catalog combines 494 bundled devotional items with 14 valid remote entries in snapshot `3ee177b5f56a9eb7`. The video lookup covers 2,473 recordings in 23 song collections. The Flutter voice modal and dispatcher use the Sacred Collection provider. The backend exporter evaluates the Dart catalog builders, including regional entries created from templates. Feature instructions come from the reviewed English, Hindi and Marathi answers in `backend/app/voice_agent/app_help.json`. Performer, duration and description answers use the matched recording's metadata.

Run the following checks from the repository root. The first checks actions and selected arguments, the second checks additional natural phrasing, and the third checks every distinct localized devotional title against its valid catalog IDs.

```sh
PYTHONPATH=backend backend/.venv-mlx/bin/python backend/scripts/evaluate_voice_adapter.py --runtime
PYTHONPATH=backend backend/.venv-mlx/bin/python backend/scripts/evaluate_voice_adapter.py --runtime --suite paraphrase
PYTHONPATH=backend backend/.venv-mlx/bin/python backend/scripts/evaluate_voice_adapter.py --runtime --suite titles
```

The 74 comparison prompts and 16 additional paraphrases have zero exact normalized overlap with either training or validation split. Runtime routing was developed against these regression cases. The checks use transcripts. Microphone recognition, speaker variation and live video availability require device testing.

| Direct model output, action and checked arguments | Previous adapter | New adapter |
| --- | ---: | ---: |
| Feature and catalog questions | 2/17 | 13/17 |
| App questions and actions | 3/19 | 11/19 |
| Original core commands | 15/20 | 11/20 |
| Expanded commands, with language help scored as supported | 12/18 | 9/18 |
| Total | 32/74 | 44/74 |

The new adapter improved app questions and regressed on earlier navigation commands. The local installation in `backend/data/training/mlx_adapters` therefore has both. The resolver uses the new weights for app questions and new intents, and the earlier weights and training prompt for model-assisted legacy navigation. The two checkpoints share one base model. Exact titles, known commands and reviewed replies also work on device. The full previous checkpoint is preserved in `backend/data/training/mlx_previous_before_app_questions_20261124`.

The installed API passed 74/74 comparison cases and 16/16 additional paraphrases. On the snapshot it opened the right item for all 448 distinct English, 448 Hindi and 449 Marathi titles. These counts allow any matching ID when multiple recordings share a display title. Direct model evaluation and installed runtime logs are in `backend/data/training/mlx_catalog_answers_v3`.

## Horoscope follow-ups and the Notifications inbox

The next local run continued from the catalog-answer weights for 64 LoRA updates with a batch size of two and learning rate of 0.000045. Its 128 sampled rows include corrections for missing signs and the notifications inbox, plus examples of other actions. MLX truncated several examples at the 512-token limit. The two user-reported phrases appear in training. The 12 additional conversation prompts have zero normalized transcript overlap with the training and validation splits.

The installed model returned `ask_rashi` with “कोणत्या राशीचं भविष्य सांगू?” for “rashi sanga” and `open_notifications` for “open notification”. It got 9/12 additional conversation cases correct on its own. It confused an explicit horoscope tab request, a named sign, and an external email inbox. The app handles those distinctions before executing an action. On the older 74-case direct-model benchmark, the focused adapter scored 35/74 against 44/74 for the previous catalog-answer adapter. The installed resolver therefore keeps the previous app-question and navigation weights for their respective requests.

The installed endpoint passed all 12 conversation cases, the 74 earlier comparison cases and 16 additional paraphrases. All 12 Marathi sign names also worked as replies to the clarification on the endpoint and in Flutter. The Flutter widget test opens the actual notification sheet. These tests use text transcripts. Live microphone recognition and speech playback require a device check.

Run the new check with `PYTHONPATH=backend backend/.venv-mlx/bin/python backend/scripts/evaluate_voice_adapter.py --runtime --suite conversation`. Omit `--runtime` to test the local model directly. The saved run and evaluation logs are in `backend/data/training/mlx_voice_followup_20261124_150554`.

## Finding an unknown birth rashi

When the speaker cannot name their sign, Bhakti asks for their birth date and birthplace and accepts the details over several turns. A name is optional. The date and the birthplace's historical time zone determine the interval to check. If the Moon crossed a sign boundary that day, Bhakti asks for local birth time. If the speaker cannot supply it, Bhakti names both possibilities. An unfamiliar place prompts a request for the country or time zone.

Flutter calculates the Moon sign on device with the Kundali engine. The API uses its configured Lahiri ephemeris. API clients carry the returned `birth_details` and pending action into the next request for that conversation. The Flutter modal clears these details when the lookup finishes or the user changes tasks. The local classifier can interpret an indirect answer in the context of the previous sign question. This feature uses runtime calculation and requires no additional model training.

The shared transcript scenarios in `test/fixtures/birth_rashi_conversations.json` exercise both entry points. They cover multilingual details, a historical birth time, ambiguous dates, a daylight-saving clock gap, missing information and topic changes. Run `flutter test --no-pub test/voice_agent_flow_test.dart test/kundali_engine_test.dart` and `PYTHONPATH=backend backend/.venv-mlx/bin/python -m unittest discover -s backend/tests -p test_voice_intents.py`.

## Feature questions and screen commands

The local Qwen3-4B feature adapter learned paired examples such as asking how the notification inbox works and asking to open it. Training covered 21 topics in English, Hindi, Marathi and transliterated speech. The runtime guide also covers Premium plans, bringing it to 22 reviewed topics and 20 screen actions. Premium prices are shown by the app's plan selector. Questions about today's jaap count, the lifetime count and the current chanting streak read the phone's saved progress. A standalone API request for those values opens My Sadhana, where the progress is available.

On November 24, the first training pass ran 64 updates at a learning rate of 0.00006 with a batch size of four and 727 training rows. A second pass ran 36 updates at 0.00005 with a batch size of two and 231 rows, including requests about other apps and unsupported operations. Both used rank eight on 16 layers. The second pass alone rejected too many valid commands. The installed weights interpolate the first pass and the corrected pass with weights 0.67 and 0.33. The training script selects this corpus with `BHAKTI_MLX_FEATURE_INTENTS=1` and the corrective sampling with `BHAKTI_MLX_FEATURE_NEGATIVES=1`.

| Direct model on 28 feature requests, including topic or arguments | Correct |
| --- | ---: |
| Previous app-question adapter | 22/28 |
| First pass | 23/28 |
| Corrective pass alone | 7/28 |
| Installed combination | 24/28 |

The 28 prompts had zero normalized transcript matches in either pass's training or validation split. They were used to select the checkpoint. The installed adapter alone confused a pinning question with reminders and mishandled three unsupported or cancelled requests. The app checks the matched feature and the available actions before navigating, and supplies the localized answer from the guide. Ten further paraphrases were tried after selecting the weights. Two surfaced routing issues involving screen names and external-app settings, now included in the regression suite.

Run these from the repository root to compare model output with actions returned by the local API.

```sh
PYTHONPATH=backend backend/.venv-mlx/bin/python backend/scripts/evaluate_voice_adapter.py --suite features
PYTHONPATH=backend backend/.venv-mlx/bin/python backend/scripts/evaluate_voice_adapter.py --runtime --suite features
PYTHONPATH=backend backend/.venv-mlx/bin/python backend/scripts/evaluate_voice_adapter.py --runtime --suite feature-paraphrase
```

The selected checkpoint and benchmark are in `backend/data/training/mlx_feature_20261124_170441_average`. The voice server loads the installed copy from `mlx_adapters/feature_intents.safetensors` with `mlx_adapters/feature_intents_prompt.txt`.

Final verification through the FastAPI text endpoint passed 140/140 regression transcripts and resolved all 448 English, 448 Hindi and 449 Marathi distinct catalog titles in the local snapshot. The Flutter voice and Kundali suites passed 40 tests. The service was also exercised over HTTP on localhost with a two-turn rashi question and both forms of the notifications request. Speech recognition and playback on a physical device remain unverified.
