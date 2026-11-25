import argparse
import json
from pathlib import Path

from app.voice_agent.mlx_classifier import classify_with_mlx

CASES = (
    ("Could we do japa for Hare Krishna now?", "en-IN", "start_jaap", "mantra_id", "hare_krishna"),
    ("namjaap mein Ganpati chahiye", "hi-IN", "start_jaap", "mantra_id", "ganesha"),
    ("गायत्रीचा नामजप लावा", "mr-IN", "start_jaap", "mantra_id", "gayatri"),
    ("नाम जाप चालू कर दो", "hi-IN", "start_jaap", None, None),
    ("Could you let me chant for a little while?", "en-IN", "start_jaap", None, None),
    ("माझ्यासाठी आज कुंभ राशीचे फळ काढा", "mr-IN", "open_horoscope", "rashi_id", "aquarius"),
    ("I'd like to see my natal horoscope chart", "en-IN", "open_kundali", None, None),
    ("जन्मपत्र्या लग्नासाठी जुळवून पाहायच्या आहेत", "mr-IN", "open_milan", None, None),
    ("aaj ka nakshatra dekhna hai", "hi-IN", "open_panchang", None, None),
    ("देवघरात घेऊन जाल का?", "mr-IN", "open_mandir", None, None),
    ("अखंड दीप का पन्ना खोलना", "hi-IN", "open_akhand_diya", None, None),
    ("I'd like to browse the pothi collection", "en-IN", "open_granth", None, None),
    ("माझे आराध्य दैवत शोधायचे आहे", "mr-IN", "open_ishta_devta", None, None),
    ("सुबह की भक्ति वाली शुभकामनाएं दिखाओ", "hi-IN", "open_greetings", None, None),
    ("When can I see the next grahan?", "en-IN", "open_grahan", None, None),
    ("क्या आप हनुमान चालीसा सुना सकते हैं?", "hi-IN", "play_aarti", None, None),
    ("I'd like to read the Ganesh aarti lyrics", "en-IN", "open_aarti", None, None),
    ("Search for flights to Japan", "en-IN", "none", None, None),
    ("जप मत शुरू करना", "hi-IN", "none", None, None),
    ("माझ्या फोनचा आवाज कमी करा", "mr-IN", "none", None, None),
)


COVERAGE_CASES = (
    ("Take me to the calendar where festivals are marked", "en-IN", "open_calendar", None, None),
    ("अगले महीने की त्योहार सूची दिखाइए", "hi-IN", "open_calendar", None, None),
    ("या महिन्यात कोणकोणते सण आहेत?", "mr-IN", "open_calendar", None, None),
    ("I'd like to see how long my jaap streak is", "en-IN", "open_jaap_stats", None, None),
    ("अब तक कितनी बार नाम जपा है?", "hi-IN", "open_jaap_stats", None, None),
    ("माझ्या नामस्मरणाची मोजणी दाखवा", "mr-IN", "open_jaap_stats", None, None),
    ("Let's do nam jaap together", "en-IN", "start_jaap", "mantra_id", None),
    ("नामजपासाठी स्वामी समर्थ लावा", "mr-IN", "start_jaap", "mantra_id", "swami_samarth"),
    ("Can I chant Om Namah Shivay?", "en-IN", "start_jaap", "mantra_id", "om_namah_shivaya"),
    ("शनीच्या मंत्राचा जप करू या", "mr-IN", "start_jaap", "mantra_id", "shani_mantra"),
    ("start namjaap for Vitthal please", "en-IN", "start_jaap", "mantra_id", "vitthal"),
    ("Humein Durga ka naam jap karna hai", "hi-IN", "start_jaap", "mantra_id", "durga"),
    ("मीन राशीला आजचा दिवस कसा जाईल?", "mr-IN", "open_horoscope", "rashi_id", "pisces"),
    ("Aaj vrishabh rashi ka din kaisa hai?", "hi-IN", "open_horoscope", "rashi_id", "taurus"),
    ("Can I change my app language by voice?", "en-IN", "answer_app_question", "feature_key", "language"),
    ("Switch off the temple diya", "en-IN", "none", None, None),
    ("अभी जाप शुरू मत करो", "hi-IN", "none", None, None),
    ("माझा सगळा जप डेटा काढून टाका", "mr-IN", "none", None, None),
)



APP_CASES = (
    ("What kinds of things can I ask you for here?", "en-IN", "answer_app_question", "feature_key", "capabilities"),
    ("ये ऐप किन भाषाओं में मिलता है?", "hi-IN", "answer_app_question", "feature_key", "language"),
    ("Which languages can the menus display?", "en-IN", "answer_app_question", "feature_key", "language"),
    ("भाषा कशी बदलायची ते सांगा", "mr-IN", "answer_app_question", "feature_key", "language"),
    ("How would I tell your team about a broken feature?", "en-IN", "answer_app_question", "feature_key", "feedback"),
    ("आरतीची आठवण कशी लावायची?", "mr-IN", "answer_app_question", "feature_key", "reminders"),
    ("How do I record each repetition in the counter?", "en-IN", "answer_app_question", "feature_key", "jaap"),
    ("What does the Panchang screen show me?", "en-IN", "answer_app_question", "feature_key", "panchang"),
    ("कुंडली बनाने के लिए कौन सी जानकारी चाहिए?", "hi-IN", "answer_app_question", "feature_key", "kundali"),
    ("Please switch the interface into Hindi", "en-IN", "set_language", "language_code", "hi"),
    ("मुझे सुझाव भेजना है", "hi-IN", "open_feedback", None, None),
    ("आरती आठवण सेटिंग्ज दाखवा", "mr-IN", "open_aarti_reminders", None, None),
    ("I'd like the settings for my daily aarti alerts", "en-IN", "open_aarti_reminders", None, None),
    ("Can we read Pasaydan please?", "en-IN", "open_aarti", "aarti_id", "pasayadan"),
    ("shani dev ki arrti sunao", "hi-IN", "play_aarti", "aarti_id", "shani_aarti"),
    ("Do not change my interface to English", "en-IN", "none", None, None),
    ("Which languages does my keyboard support?", "en-IN", "none", None, None),
    ("Have you already sent my feedback?", "en-IN", "none", None, None),
    ("Please set a reminder for my dentist appointment", "en-IN", "none", None, None),
)

KNOWLEDGE_CASES = (
    ("How would I share one of the greeting cards from here?", "en-IN", "answer_app_question", "feature_key", "greetings"),
    ("मेरी साधना में क्या मिलता है?", "hi-IN", "answer_app_question", "feature_key", "jaap_stats"),
    ("ग्रंथ संग्रहात पोथी कशी वाचू?", "mr-IN", "answer_app_question", "feature_key", "granth"),
    ("How can we use Kundali Milan for two profiles?", "en-IN", "answer_app_question", "feature_key", "milan"),
    ("अधिकमध्ये माझे इष्ट दैवत कसे निवडू?", "mr-IN", "answer_app_question", "feature_key", "ishta_devta"),
    ("How do we check dates in the festival calendar?", "en-IN", "answer_app_question", "feature_key", "calendar"),
    ("Who performs Pasaydan?", "en-IN", "answer_app_question", "field", "singer"),
    ("पसायदान बद्दल सांगा", "mr-IN", "answer_app_question", "field", "about"),
    ("Is Shani dev arrti available here?", "en-IN", "answer_app_question", "field", "availability"),
    ("Is there a recording of Pasaydaan?", "en-IN", "answer_app_question", "field", "audio"),
    ("How long is Hanuman Chalisa?", "en-IN", "answer_app_question", "field", "duration"),
    ("Could you show me how to turn on evening aarti reminders?", "en-IN", "answer_app_question", "feature_key", "reminders"),
    ("Take me to the More page", "en-IN", "open_more", None, None),
    ("Let me browse the sacred collection", "en-IN", "open_bhajans", None, None),
    ("Please don't open the birth chart", "en-IN", "none", None, None),
    ("Who sang the fictional Silver Comet hymn?", "en-IN", "none", None, None),
    ("What's my weather forecast for Saturday?", "en-IN", "none", None, None),
)


PARAPHRASE_CASES = (
    ("Is it possible to see the menus in a different language?", "en-IN", "answer_app_question", "feature_key", "language"),
    ("मुझे भक्तिधारा में बग की शिकायत करनी है", "hi-IN", "open_feedback", None, None),
    ("How do I count the mantras I've said?", "en-IN", "answer_app_question", "feature_key", "jaap"),
    ("I want to look through the cards that say good morning", "en-IN", "open_greetings", None, None),
    ("Is there a way to look at the holy books?", "en-IN", "open_granth", None, None),
    ("ऐप की भाषा हिंदी में कर दो", "hi-IN", "set_language", "language_code", "hi"),
    ("थोडा वेळ हरे कृष्ण नामजप करूया", "mr-IN", "start_jaap", "mantra_id", "hare_krishna"),
    ("I need instructions for Kundali Milan", "en-IN", "answer_app_question", "feature_key", "milan"),
    ("भजन संग्रह दाखवा", "mr-IN", "open_bhajans", None, None),
    ("Could we hear the Pasayadan?", "en-IN", "play_aarti", "aarti_id", "pasayadan"),
    ("I'd like to know the singer on Pasayadan", "en-IN", "answer_app_question", "field", "singer"),
    ("Who sings the missing blue moon remix of Pasaydan?", "en-IN", "none", None, None),
    ("मेरे फ़ोन की भाषा बदल दो", "hi-IN", "none", None, None),
    ("Show me the menu for today's aarti notifications", "en-IN", "open_aarti_reminders", None, None),
    ("What voice commands could I try out?", "en-IN", "answer_app_question", "feature_key", "capabilities"),
    ("खेळाच्या सामन्याचा स्कोअर दाखवा", "mr-IN", "none", None, None),
)


def evaluate(cases, classify):
    type_hits = exact_hits = valid = 0
    for query, locale, kind, field, value in cases:
        result = classify(query, locale) or {}
        actual = result.get("action")
        valid += actual is not None
        type_hits += actual == kind
        matched = actual == kind and (field is None or result.get(field) == value)
        exact_hits += matched
        expected = f" {field}={value!r}" if field else ""
        observed = f" {field}={result.get(field)!r}" if field else ""
        print(f"{'PASS' if matched else 'FAIL'} {query} | expected {kind}{expected} | got {actual}{observed}", flush=True)
    count = len(cases)
    print(f"Action {type_hits}/{count} | Action and checked arguments {exact_hits}/{count} | Parsed {valid}/{count}")


CONVERSATION_CASES = (
    ("raashi saanga please", "mr-IN", "ask_rashi", "rashi_id", None),
    ("मला आजचं माझं राशीभविष्य सांगा", "mr-IN", "ask_rashi", "rashi_id", None),
    ("मुझे आज का राशिफल बताओ", "hi-IN", "ask_rashi", "rashi_id", None),
    ("Can you read my horoscope for today?", "en-IN", "ask_rashi", "rashi_id", None),
    ("Take me to the horoscope tab", "en-IN", "open_horoscope", "rashi_id", None),
    ("कुंभ राशीचं भविष्य सांग", "mr-IN", "open_horoscope", "rashi_id", "aquarius"),
    ("Show me the notification centre", "en-IN", "open_notifications", None, None),
    ("नव्या सूचना उघडा", "mr-IN", "open_notifications", None, None),
    ("मेरे नोटिफिकेशन खोलो", "hi-IN", "open_notifications", None, None),
    ("Open today's aarti notification settings", "en-IN", "open_aarti_reminders", None, None),
    ("Clear my unread notifications", "en-IN", "none", None, None),
    ("Show me my email inbox", "en-IN", "none", None, None),
)


# Contrast how-to questions with requests to visit the same feature.
FEATURE_CASES = (
    ("Where in the app can I read the notices you send?", "en-IN", "answer_app_question", "feature_key", "notifications"),
    ("Take me straight to the notification inbox", "en-IN", "open_notifications", None, None),
    ("देवघरात कोणकोणत्या गोष्टी करता येतात?", "mr-IN", "answer_app_question", "feature_key", "mandir"),
    ("मला देवघर उघडून द्या", "mr-IN", "open_mandir", None, None),
    ("What is the ghee indicator in the shrine for?", "en-IN", "answer_app_question", "feature_key", "akhand_diya"),
    ("Can you bring up the eternal lamp for me?", "en-IN", "open_akhand_diya", None, None),
    ("ग्रहण विभाग कैसे इस्तेमाल करते हैं?", "hi-IN", "answer_app_question", "feature_key", "grahan"),
    ("मला चंद्रग्रहणाचं पान पाहायचं आहे", "mr-IN", "open_grahan", None, None),
    ("How can I switch to the weekly horoscope view?", "en-IN", "answer_app_question", "feature_key", "horoscope"),
    ("Please take me to the horoscope page", "en-IN", "open_horoscope", "rashi_id", None),
    ("भजन संग्रहात काय पाहायला मिळतं?", "mr-IN", "answer_app_question", "feature_key", "bhajans"),
    ("Can you bring up the bhajan collection?", "en-IN", "open_bhajans", None, None),
    ("What does pinning my daily aarti actually do?", "en-IN", "answer_app_question", "feature_key", "daily_aarti"),
    ("अधिक मेनू में क्या देख सकते हैं?", "hi-IN", "answer_app_question", "feature_key", "more"),
    ("I would like to visit the More tab", "en-IN", "open_more", None, None),
    ("Walk me through the app's feedback form", "en-IN", "answer_app_question", "feature_key", "feedback"),
    ("Please bring up the feedback form for me", "en-IN", "open_feedback", None, None),
    ("How can I use the festival calendar here?", "en-IN", "answer_app_question", "feature_key", "calendar"),
    ("Show the marriage matching screen please", "en-IN", "open_milan", None, None),
    ("What is available under chanting statistics?", "en-IN", "answer_app_question", "feature_key", "jaap_stats"),
    ("Could you open the app language picker?", "en-IN", "open_language_settings", None, None),
    ("Tell me how to share a devotional greeting card", "en-IN", "answer_app_question", "feature_key", "greetings"),
    ("Could you show the aarti reminder options?", "en-IN", "open_aarti_reminders", None, None),
    ("Please purchase ghee for my kitchen", "en-IN", "none", None, None),
    ("Don't go to the notifications screen", "en-IN", "none", None, None),
    ("What is my debit card PIN?", "en-IN", "none", None, None),
    ("Open notifications in Gmail for me", "en-IN", "none", None, None),
    ("I'd like a weather map of the next eclipse", "en-IN", "none", None, None),
)


FEATURE_PARAPHRASES = (
    ("Can you explain how the bell inbox works?", "en-IN", "answer_app_question", "feature_key", "notifications"),
    ("I would love to browse the sacred books", "en-IN", "open_granth", None, None),
    ("मुझे भजन संग्रह पर ले चलो", "hi-IN", "open_bhajans", None, None),
    ("Where can I see my pinned aartis?", "en-IN", "answer_app_question", "feature_key", "daily_aarti"),
    ("Could you open the app's feedback form?", "en-IN", "open_feedback", None, None),
    ("प्रीमियम योजना दाखव", "mr-IN", "open_premium", None, None),
    ("How can I read the weekly horoscope in this app?", "en-IN", "answer_app_question", "feature_key", "horoscope"),
    ("Can we look at the eclipses page?", "en-IN", "open_grahan", None, None),
    ("Can I change the language used by my work email?", "en-IN", "none", None, None),
    ("माझ्या बँक खात्यात किती पैसे आहेत?", "mr-IN", "none", None, None),
)


def run_suites(suite, classify):
    if suite == "feature-paraphrase":
        evaluate(FEATURE_PARAPHRASES, classify)
    if suite == "features":
        evaluate(FEATURE_CASES, classify)
    if suite == "conversation":
        evaluate(CONVERSATION_CASES, classify)
    if suite == "paraphrase":
        print("Additional natural phrasing")
        evaluate(PARAPHRASE_CASES, classify)
    if suite in ("knowledge", "all"):
        print("Feature and catalog questions")
        evaluate(KNOWLEDGE_CASES, classify)
    if suite in ("app", "all"):
        print("App questions and actions")
        evaluate(APP_CASES, classify)
    if suite in ("core", "all"):
        print("Core benchmark")
        evaluate(CASES, classify)
    if suite in ("coverage", "all"):
        print("Expanded coverage benchmark")
        evaluate(COVERAGE_CASES, classify)


def check_catalog_titles(classify):
    from collections import defaultdict
    from app.voice_agent.intent_resolver import get_knowledge

    items = get_knowledge().get("aartis", [])
    if not items:
        raise SystemExit("The catalog is empty. Run extract_voice_knowledge.py first.")
    failures = 0
    for lang, field in (("en", "title"), ("hi", "titleHi"), ("mr", "titleMr")):
        titles = defaultdict(set)
        for item in items:
            title = (item.get(field) or item["title"]).casefold().strip()
            titles[title].add(item["id"])
        hits = 0
        for title, ids in titles.items():
            result = classify(title, lang + "-IN")
            if result.get("action") == "open_aarti" and result.get("aarti_id") in ids:
                hits += 1
            else:
                print(f"FAIL {lang} {title!r}: {result}")
        failures += len(titles) - hits
        print(f"{lang}: {hits}/{len(titles)} distinct catalog titles")
    if failures:
        raise SystemExit(1)


def evaluate_home():
    """Score the prediction before any on-device shortcuts or UI execution."""
    from app.voice_agent.intent_resolver import detect_locale

    path = Path(__file__).resolve().parents[1] / "datasets/home/held_out.jsonl"
    correct = total = parsed = 0
    for line in path.read_text(encoding="utf-8").splitlines():
        _, user, assistant = json.loads(line)["messages"]
        text = user["content"]
        expected = json.loads(assistant["content"])["action"]
        result = classify_with_mlx(text, detect_locale(text), home_screen=True) or {}
        parsed += isinstance(result.get("action"), str)
        actual = {"type": result.get("action"), **{k: result.get(k) for k in expected
                  if k not in ("type", "title", "has_audio")}}
        target = {k: v for k, v in expected.items() if k not in ("title", "has_audio")}
        total += 1
        if actual == target:
            correct += 1
        else:
            print(f"FAIL {text!r}: expected {target}, got {actual}")
    print(f"Home held-out action and arguments: {correct}/{total}")
    if not parsed:
        raise SystemExit("Home evaluation received no structured model predictions.")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--suite", choices=("core", "coverage", "app", "knowledge", "paraphrase", "conversation", "features", "feature-paraphrase", "titles", "home", "all"), default="all")
    parser.add_argument("--runtime", action="store_true", help="Call the FastAPI voice endpoint")
    args = parser.parse_args()
    if args.suite == "home":
        if args.runtime:
            parser.error("--suite home evaluates direct model predictions")
        evaluate_home()
        return
    if args.suite == "titles" and not args.runtime:
        parser.error("--suite titles requires --runtime")
    if not args.runtime:
        if args.suite in ("features", "feature-paraphrase"):
            run_suites(args.suite, lambda q, locale: classify_with_mlx(q, locale, feature_intents=True))
        else:
            run_suites(args.suite, classify_with_mlx)
        return

    from fastapi import FastAPI
    from fastapi.testclient import TestClient
    from app.voice_agent.router import router

    app = FastAPI()
    app.include_router(router)
    with TestClient(app) as client:
        def classify(text, locale):
            response = client.post(
                "/api/v1/voice-agent/text", json={"text": text, "locale_hint": locale}
            )
            response.raise_for_status()
            action = response.json()["action"]
            return {**action, "action": action["type"]}

        if args.suite == "titles":
            check_catalog_titles(classify)
        else:
            run_suites(args.suite, classify)


if __name__ == "__main__":
    main()
