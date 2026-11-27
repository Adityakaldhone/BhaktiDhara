import json
import sqlite3
import tempfile
import unittest
from contextlib import closing
from pathlib import Path
from unittest.mock import AsyncMock, patch

from app.voice_agent.intent_resolver import resolve_voice_turn


class VoiceIntentTest(unittest.IsolatedAsyncioTestCase):
    def setUp(self):
        temp = tempfile.TemporaryDirectory()
        self.addCleanup(temp.cleanup)
        database = Path(temp.name) / "catalog.db"
        with closing(sqlite3.connect(database)) as conn, conn:
            conn.execute(
                "CREATE TABLE aartis (id, title, title_hi, title_mr, deity, deity_hi, "
                "deity_mr, youtube_video_id, has_audio)"
            )
            conn.executemany(
                "INSERT INTO aartis VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)",
                (
                    ("hanuman_aarti", "Hanuman Aarti", "हनुमान आरती", "हनुमान आरती",
                     "Hanuman", "हनुमान", "हनुमान", "aarti-video", 1),
                    ("hanuman_chalisa", "Hanuman Chalisa", "हनुमान चालीसा", "हनुमान चालीसा",
                     "Hanuman", "हनुमान", "हनुमान", "chalisa-video", 1),
                    ("pasayadan", "Pasayadan", "पसायदान", "पसायदान",
                     "Sant", "संत", "संत", "pasayadan-video", 1),
                    ("shani_aarti", "Shree Shani Deva Aarti", "श्री शनि देव आरती", "श्री शनिदेवाची आरती",
                     "Lord Shani", "शनि देव", "शनि देव", "shani-video", 1),
                    ("gayatri_mantra", "Gayatri Mantra", "गायत्री मंत्र", "गायत्री मंत्र",
                     "Gayatri", "गायत्री", "गायत्री", None, 0),
                ),
            )
        self.enterContext(patch("app.voice_agent.intent_resolver.DB_PATH", database))
        self.enterContext(patch("app.voice_agent.intent_resolver._KNOWLEDGE_CACHE", {
            "rashis": [{
                "id": "kumbh", "app_id": "aquarius", "aliases": ["kumbh", "aquarius", "कुंभ"],
                "name_en": "Aquarius", "name_hi": "कुंभ", "name_mr": "कुंभ",
            }],
        }))
        self.enterContext(patch(
            "app.voice_agent.intent_resolver.resolve_with_local_llm", new=AsyncMock(return_value=None)
        ))

    async def test_home_api_returns_only_valid_screen_controls(self):
        from app.voice_agent.router import TextCommandRequest, home_control

        for query, proposal, expected in (
            ("Narrow the list to Gujarat", {"type": "filter_home", "region": "gujarat"}, "filter_home"),
            ("Narrow the list to Gujarat", {"type": "filter_home", "region": "rajasthan"}, "none"),
            ("Show Maharashtra aartis", {"type": "filter_home", "region": "all"}, "none"),
            ("Show all regions", {"type": "filter_home", "region": "all"}, "filter_home"),
            ("Open the next result", {"type": "open_home_result", "position": 0, "section": "all"}, "none"),
            ("Keep the fourth result closed", {"type": "open_home_result", "position": 4, "section": "all"}, "none"),
            ("Read the second book", {"type": "open_home_result", "position": 2, "section": "books"}, "open_home_result"),
            ("Don't change my search", {"type": "search_home", "query": ""}, "none"),
            ("How do I choose Gujarat?", {"type": "filter_home", "region": "gujarat"}, "none"),
            ("Which chip is active?", {"type": "read_home_region"}, "read_home_region"),
            ("How can I restore all regions?", {"type": "answer_app_question", "feature_key": "home_region"}, "answer_app_question"),
        ):
            with self.subTest(query=query, proposal=proposal), patch(
                "app.voice_agent.router.resolve_with_local_llm", new=AsyncMock(return_value={"action": proposal})
            ) as model:
                result = await home_control(TextCommandRequest(text=query, locale_hint="en-IN"))
                self.assertEqual(result["action"], proposal if expected != "none" else {"type": "none"})
                model.assert_awaited_once_with(query, "en-IN", home_screen=True)

    def test_numbered_hymn_refers_to_aartis_even_if_books_are_also_visible(self):
        from app.voice_agent.home_controls import validated_action

        proposal = {"action": "open_home_result", "position": 2, "section": "all"}
        action = validated_action(proposal, "Open hymn number two on this page")
        self.assertEqual(action, {"type": "open_home_result", "position": 2, "section": "aartis"})
        self.assertEqual(validated_action(proposal, "open result number two")["section"], "all")

    async def test_jaap_aliases_select_counter_without_a_model(self):
        for query in (
            "jap", "japa", "naam jap", "nam jaap", "naamjaap", "namjaap",
            "Chant!", "Start nam   jap", "नाम जाप", "जपमाळ",
        ):
            with self.subTest(query=query):
                result = await resolve_voice_turn(query, "en-IN")
                self.assertEqual(result["action"]["type"], "start_jaap")
                self.assertIsNone(result["action"].get("mantra_id"))

    async def test_mantra_and_related_intents(self):
        cases = (
            ("जप श्री राम", "start_jaap", "shri_ram"),
            ("chant Jai Shri Ram", "start_jaap", "jai_shri_ram"),
            ("गायत्रीचा नामजप लावा", "start_jaap", "gayatri"),
            ("japa with Hare Krishna", "start_jaap", "hare_krishna"),
            ("chant Om Gam Ganapataye Namah", "start_jaap", "ganesha"),
            ("ॐ हं हनुमते नमः जप करा", "start_jaap", "hanuman"),
            ("show my naamjaap history", "open_jaap_stats", None),
            ("What is my japa streak?", "open_jaap_stats", None),
            ("अखंड दिवा दाखवा", "open_akhand_diya", None),
            ("open the festival calendar", "open_calendar", None),
            ("kumbh rashifal", "open_horoscope", None),
        )
        for query, expected_action, expected_mantra in cases:
            with self.subTest(query=query):
                result = await resolve_voice_turn(query, "en-IN")
                self.assertEqual(result["action"]["type"], expected_action)
                self.assertEqual(result["action"].get("mantra_id"), expected_mantra)

    async def test_unsupported_jaap_requests_do_not_open_counter(self):
        for query in (
            "जप मत शुरू करना", "Don't start a chant", "नामजप सुरू करू नका",
            "What does the Gayatri mantra mean?", "What is japa?",
            "Set 108 jaap repetitions automatically", "Clear chanting history",
            "Start a chant and then open Panchang", "What is the capital of Japan?",
        ):
            with self.subTest(query=query):
                result = await resolve_voice_turn(query, "en-IN")
                self.assertEqual(result["action"]["type"], "none")

    async def test_unrelated_requests_get_guided_capabilities_tip(self):
        result = await resolve_voice_turn("What is the capital of Japan?", "en-IN")
        self.assertEqual(result["action"]["type"], "none")
        self.assertEqual(result["status"], "not_found")
        self.assertIn("match", result["response_text"].lower())
        self.assertTrue(
            any(word in result["response_text"].lower() for word in ("aarti", "jaap", "horoscope", "pasayadan")),
        )

    async def test_panchang_field_and_granth_chapter_are_passed_through(self):
        rahu = await resolve_voice_turn("When is Rahu Kaal?", "en-IN")
        self.assertEqual(rahu["action"]["type"], "open_panchang")
        self.assertEqual(rahu["action"]["field"], "rahu_kaal")
        self.assertIn("Rahu", rahu["response_text"])
        granth = await resolve_voice_turn("गुरुचरित्र अध्याय ३", "mr-IN")
        self.assertEqual(granth["action"]["type"], "open_granth")
        self.assertEqual(granth["action"]["chapter"], 3)
        self.assertIn("3", granth["response_text"])

    async def test_in_app_fulfillment_for_premium_request_book_and_deity_list(self):
        premium = await resolve_voice_turn("Show premium plans", "en-IN")
        self.assertEqual(premium["action"]["type"], "open_premium")
        request = await resolve_voice_turn("Request a missing deity", "en-IN")
        self.assertEqual(request["action"]["type"], "open_request_deity")
        gita = await resolve_voice_turn("Open the Bhagavad Gita", "en-IN")
        self.assertEqual(gita["action"]["type"], "open_granth_book")
        self.assertEqual(gita["action"]["book_slug"], "bhagavad-gita")
        durga = await resolve_voice_turn("Show all Durga aartis", "en-IN")
        self.assertEqual(durga["action"]["type"], "open_deity_aarti_list")
        self.assertEqual(durga["action"]["deity_key"], "Goddess Durga")
        wake = await resolve_voice_turn("Turn on Hey Bhakti", "en-IN")
        self.assertEqual(wake["action"]["type"], "set_wake_word")
        self.assertTrue(wake["action"]["enabled"])

    async def test_generic_shiv_aarti_opens_deity_list(self):
        for query in (
            "open shiv aarti",
            "shiv aarti kholo",
            "शिव आरती खोलो",
            "ओपन शिव आरती",  # Hindi STT of “open shiv aarti”
            "open shivarti",  # glued STT
            "शिव आरती ओपन करो",
        ):
            with self.subTest(query=query):
                result = await resolve_voice_turn(query, "hi-IN")
                self.assertEqual(result["action"]["type"], "open_deity_aarti_list")
                self.assertEqual(result["action"]["deity_key"], "Lord Shiva")

    async def test_media_title_wins_over_the_deity(self):
        for query, expected_action, title in (
            ("Play Hanuman Chalisa", "play_aarti", "chalisa"),
            ("क्या आप हनुमान चालीसा सुना सकते हैं?", "play_aarti", "chalisa"),
            ("Read the lyrics of Gayatri Mantra", "open_aarti", "gayatri"),
        ):
            with self.subTest(query=query):
                result = await resolve_voice_turn(query, "en-IN")
                self.assertEqual(result["action"]["type"], expected_action)
                self.assertIn(title, result["action"]["aarti_id"])


    async def test_voice_aliases_resolve_catalog_ids(self):
        for query, kind, catalog_id in (
            ("pasaydan", "open_aarti", "pasayadan"),
            ("Play Pasaydaan", "play_aarti", "pasayadan"),
            ("shani dev arrti", "open_aarti", "shani_aarti"),
            ("शनिदेवाची आरती लावा", "play_aarti", "shani_aarti"),
        ):
            with self.subTest(query=query):
                response = await resolve_voice_turn(query, "en-IN")
                self.assertEqual(response["action"]["type"], kind)
                self.assertEqual(response["action"]["aarti_id"], catalog_id)

    async def test_language_and_feedback_are_explicit_actions(self):
        cases = (
            ("chnage the app language to marathi", "set_language", "mr"),
            ("ऐप की भाषा अंग्रेज़ी में बदलो", "set_language", "en"),
            ("language settings", "open_language_settings", None),
            ("change app language to Tamil", "none", None),
            ("feedback and suggestions", "open_feedback", None),
            ("open Mandir", "open_mandir", None),
        )
        for query, action, language in cases:
            with self.subTest(query=query):
                response = await resolve_voice_turn(query, "en-IN")
                self.assertEqual(response["action"]["type"], action)
                self.assertEqual(response["action"].get("language_code"), language)

    async def test_unknown_requests_and_unrelated_model_routes_stay_put(self):
        with patch("app.voice_agent.intent_resolver.resolve_with_local_llm",
                   new=AsyncMock(return_value={"action": "open_mandir", "response_text": "Opening Mandir."})):
            for query in ("play fictional hymn", "play imaginary Hanuman aarti", "unknown mandir recording", "unavailable scripture"):
                with self.subTest(query=query):
                    response = await resolve_voice_turn(query, "en-IN")
                    self.assertEqual(response["status"], "not_found")
                    self.assertEqual(response["action"]["type"], "none")
                    self.assertIn("find", response["response_text"])

    async def test_reviewed_app_answers_and_commands_are_distinct(self):
        for query, locale, kind, detail in (
            ("Which languages can the app display?", "en-IN", "answer_app_question", "Marathi"),
            ("How do I report a bug?", "en-IN", "answer_app_question", "Submit"),
            ("अॅपची भाषा मराठी करा", "mr-IN", "set_language", "भाषा"),
            ("आरती आठवण दाखवा", "mr-IN", "open_aarti_reminders", "आठवण"),
            ("more tab", "en-IN", "open_more", "More"),
            ("Compare our charts for matrimony", "en-IN", "open_milan", "milan"),
            ("who has already received my feedback?", "en-IN", "none", "find"),
            ("Can we look at the eclipses page?", "en-IN", "open_grahan", "eclipse"),
            ("Can I change the language used by my work email?", "en-IN", "none", "find"),
            ("Which languages can my keyboard display?", "en-IN", "none", "find"),
        ):
            with self.subTest(query=query):
                result = await resolve_voice_turn(query, locale)
                self.assertEqual(result["action"]["type"], kind)
                self.assertIn(detail, result["response_text"])

    async def test_catalog_facts_use_the_record_and_stay_on_the_current_screen(self):
        item = {"id": "pasayadan", "title": "Pasayadan", "titleMr": "पसायदान",
                "singer": "Catalog performer", "aboutMr": "संग्रहातील वर्णन."}
        with patch("app.voice_agent.intent_resolver._KNOWLEDGE_CACHE", {"aartis": [item]}):
            for query, locale, detail in (
                ("Who sings Pasaydan?", "en-IN", "Catalog performer"),
                ("पसायदान बद्दल सांगा", "mr-IN", "संग्रहातील वर्णन."),
                ("How long is Pasayadan?", "en-IN", "doesn’t list"),
            ):
                result = await resolve_voice_turn(query, locale)
                self.assertEqual(result["status"], "answered")
                self.assertEqual(result["action"]["aarti_id"], "pasayadan")
                self.assertIn(detail, result["response_text"])

            mock = AsyncMock(return_value={"action": "answer_app_question", "feature_key": "catalog",
                             "field": "singer", "query": "Pasaydan", "response_text": "Invented credit"})
            with patch("app.voice_agent.intent_resolver.resolve_with_local_llm", mock):
                answer = await resolve_voice_turn("Whose voice is on Pasaydan?", "en-IN")
                self.assertIn("Catalog performer", answer["response_text"])
                missing = await resolve_voice_turn("Whose voice is on Lost Comet?", "en-IN")
                self.assertEqual(missing["status"], "not_found")

    async def test_missing_rashi_prompts_and_followup_can_switch_topics(self):
        question = await resolve_voice_turn("rashi sanga", "mr-IN")
        self.assertEqual(question["action"], {"type": "ask_rashi"})
        self.assertEqual(question["status"], "needs_clarification")
        self.assertEqual(question["response_text"], "कोणत्या राशीचं भविष्य सांगू?")
        for reply in ("कुंभ", "माझी रास कुंभ आहे", "My zodiac sign is Aquarius"):
            result = await resolve_voice_turn(reply, "mr-IN", pending_action="ask_rashi")
            self.assertEqual(result["action"].get("rashi_id"), "aquarius", reply)
            self.assertEqual(result["transcript"], reply)
        changed = await resolve_voice_turn("open notification", "en-IN", pending_action="ask_rashi")
        self.assertEqual(changed["action"]["type"], "open_notifications")
        for text in ("Turn off all notifications", "Open Gmail notifications"):
            result = await resolve_voice_turn(text, "en-IN")
            self.assertEqual(result["action"]["type"], "none", text)

    async def test_published_voice_route_examples_work_without_the_model(self):
        from app.voice_agent.app_help import ROUTES
        for expected, spec in ROUTES.items():
            for example in spec["examples"]:
                with self.subTest(example=example):
                    result = await resolve_voice_turn(example, "en-IN")
                    self.assertEqual(result["action"]["type"], expected)
                    self.assertEqual(result["status"], spec.get("status", "action_ready"))

    async def test_birth_rashi_conversations(self):
        fixtures = Path(__file__).resolve().parents[2] / "test/fixtures/birth_rashi_conversations.json"
        for case in json.loads(fixtures.read_text()):
            state, pending = None, None
            for text, expected in case["turns"]:
                with self.subTest(text=text):
                    result = await resolve_voice_turn(text, case["locale"], pending_action=pending, birth_details=state)
                    action = result["action"]
                    state = result.get("birth_details")
                    pending = action["type"] if result["status"] == "needs_clarification" else None
                    actual = ((state or {}).get("step") or action.get("rashi_id")
                              or ("answered" if action["type"] == "none" else action["type"]))
                    self.assertEqual(actual, expected)
                    if expected == "answered":
                        self.assertEqual(result["status"], "answered")
                    if action.get("rashi_id"):
                        self.assertIn(action["rashi_name"], result["response_text"])
                        self.assertIsNone(state)

    async def test_feature_help_and_navigation_pairs(self):
        from app.voice_agent.app_help import TOPICS
        for key, info in TOPICS.items():
            for lang in ("en", "hi", "mr"):
                locale = lang + "-IN"
                for query in info["examples"]:
                    with self.subTest(query=query, locale=locale):
                        result = await resolve_voice_turn(query, locale)
                        self.assertEqual(result["action"].get("feature_key"), key)
                        self.assertEqual(result["response_text"], info["reply"][lang])
                name = info["labels"][lang]
                if expected := info.get("screen_action"):
                    query = {"en": f"Could you bring up {name}?", "hi": f"{name} खोल दो",
                             "mr": f"{name} उघडून द्या"}[lang]
                    with self.subTest(query=query):
                        result = await resolve_voice_turn(query, locale)
                        self.assertEqual(result["action"]["type"], expected)

    async def test_mandir_api_validates_proposals_and_falls_back_deterministically(self):
        from app.voice_agent.router import TextCommandRequest, mandir_control

        for query, proposal, expected in (
            ("माझा दिवा तुपाने भरा", {"type": "offer_ghee"}, "offer_ghee"),
            ("नैवेद्य ठेवू नका", {"type": "explain_food"}, "cancel"),
            ("Leave the conch quiet", {"type": "blow_conch"}, "cancel"),
            ("Book a real temple visit for tomorrow", {"type": "other"}, "unavailable"),
            ("Switch the app to English", {"type": "other"}, "other"),
        ):
            with self.subTest(query=query, proposal=proposal), patch(
                "app.voice_agent.router.resolve_with_local_llm", new=AsyncMock(return_value={"action": proposal})
            ) as model:
                result = await mandir_control(TextCommandRequest(text=query, locale_hint="mr-IN"))
                self.assertEqual(result["action"]["type"], expected)
                model.assert_awaited_once_with(query, "mr-IN", mandir_screen=True)

        # Fallback when no local LLM is available
        for query, expected in (
            ("Ring the temple bells", "ring_bell"),
            ("How much ghee is left?", "read_ghee"),
            ("ज्योत शिल्लक", "read_ghee"),
            ("ज्योत", "clarify_jyot"),
            ("diya", "clarify_jyot"),
            ("आरती", "clarify_aarti"),
            ("थाली बंद", "stop_aarti"),
            ("भोग", "clarify_food"),
            ("नैवेद्य ठेवा", "offer_food"),
            ("देवता", "clarify_deity"),
            ("which deity", "read_deity"),
            ("When will the current ghee run out?", "read_time"),
            ("What is my lamp streak?", "read_streak"),
            ("Sound the conch", "blow_conch"),
            ("Offer flowers", "offer_flowers"),
            ("Place naivedya", "offer_food"),
            ("Start the aarti thali", "start_aarti"),
            ("Close the aarti thali", "stop_aarti"),
            ("Which deity is seated here?", "read_deity"),
            ("Open my horoscope", "other"),
        ):
            with self.subTest(fallback_query=query), patch(
                "app.voice_agent.router.resolve_with_local_llm", new=AsyncMock(return_value=None)
            ):
                result = await mandir_control(TextCommandRequest(text=query, locale_hint="en-IN"))
                self.assertEqual(result["action"]["type"], expected)

        # Multi-turn: bare ज्योत → clarify, then short follow-up resolves without LLM.
        for follow_up, expected in (
            ("शिल्लक", "read_ghee"),
            ("भरो", "offer_ghee"),
            ("streak", "read_streak"),
            ("किती वेळ", "read_time"),
        ):
            with self.subTest(follow_up=follow_up), patch(
                "app.voice_agent.router.resolve_with_local_llm", new=AsyncMock(return_value=None)
            ) as model:
                result = await mandir_control(
                    TextCommandRequest(
                        text=follow_up,
                        locale_hint="mr-IN",
                        pending_action="clarify_jyot",
                    )
                )
                self.assertEqual(result["action"]["type"], expected)
                model.assert_not_awaited()
