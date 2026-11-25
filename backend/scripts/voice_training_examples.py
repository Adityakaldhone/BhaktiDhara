"""Multilingual examples for supported voice routes and unsupported requests."""

from pathlib import Path
import runpy
import unicodedata
import json

_prompts = runpy.run_path(
    str(Path(__file__).resolve().parents[1] / "app/voice_agent/prompt.py")
)
SYSTEM_PROMPT = _prompts["SYSTEM_PROMPT"]
HOME_PROMPT = _prompts["HOME_PROMPT"]
HOME_CONTROL_PROMPT = _prompts["HOME_CONTROL_PROMPT"]
HOME_DATA = Path(__file__).resolve().parents[1] / "datasets/home"


def transcript_key(query):
    return " ".join(unicodedata.normalize("NFKC", query).casefold().strip(" ?!.,।").split())


def home_records(split):
    with (HOME_DATA / f"{split}.jsonl").open(encoding="utf-8") as source:
        return [json.loads(line) for line in source if line.strip()]


def home_evaluation_queries():
    return {transcript_key(row["messages"][1]["content"]) for row in home_records("held_out")}


FEATURE_EXAMPLES = (
    ("open_calendar", "calendar", ("Show the festival calendar", "इस महीने के त्योहार दिखाओ", "सणांची दिनदर्शिका उघडा", "aane wale tyohar dikhao", "udya konta san aahe")),
    ("open_jaap_stats", "jaap_stats", ("Show my chanting streak", "जाप का इतिहास खोलो", "माझ्या जपाची आकडेवारी दाखवा", "mere jap ka record dikhao", "maajhi sadhana dakhva", "show how many times I chanted")),

    ("open_horoscope", "horoscope", ("Open the horoscope screen", "आज का राशिफल खोलो", "आजचे राशीभविष्य उघडा")),
    ("open_panchang", "panchang", ("Show today’s Hindu calendar", "आज का पंचांग खोलो", "आजचे नक्षत्र सांगा", "aaj ka panchang dikhao")),
    ("open_mandir", "mandir", ("Take me to the shrine", "भगवान के दर्शन करने हैं", "देवघर दाखवा", "mandir mein darshan karna hai")),
    ("open_akhand_diya", "akhand_diya", ("Open the akhand diya", "अखंड ज्योत दिखाओ", "अखंड दिवा दाखवा")),
    ("open_granth", "granth", ("Show the sacred books library", "पवित्र ग्रंथ दिखाओ", "पोथ्यांची यादी दाखवा", "granth ki list kholo")),
    ("open_kundali", "kundali", ("I want to make my natal chart", "मेरी जन्मपत्री बनाओ", "माझी जन्मपत्रिका काढा", "meri kundli banao")),
    ("open_milan", "milan", ("Compare two birth charts for marriage", "विवाह के लिए गुण मिलाओ", "लग्नासाठी पत्रिका जुळवा", "shaadi ke liye gun milao")),
    ("open_ishta_devta", "ishta_devta", ("Find my personal deity", "मेरे इष्ट देव कौन हैं", "माझे उपास्य दैवत शोधा", "mera isht dev kaun hai")),
    ("open_greetings", "greetings", ("Show devotional greeting cards", "भक्ति शुभकामना कार्ड दिखाओ", "भक्ती शुभेच्छापत्रे दाखवा", "bhakti status card dikhao")),
    ("open_grahan", "grahan", ("Show lunar eclipse timings", "सूर्य ग्रहण का समय बताओ", "चंद्रग्रहणाची वेळ दाखवा", "agraha nahi, grahan ka samay batao")),
)

FEATURE_PARAPHRASES = {
    "horoscope": ("Show the zodiac signs page", "राशिफल का पेज खोलो", "राशीभविष्य विभाग उघडा", "horoscope tab kholo", "rashi page ughda"),
    "panchang": ("When does today's auspicious window begin?", "आज के सूर्योदय का समय बताना", "आजचा सूर्यास्त किती वाजता", "aaj ki tithi aur nakshatra kya hai", "aajcha rahukal kiti vajta"),
    "mandir": ("I'd like to have darshan", "गर्भगृह में ले चलो", "देवाचे दर्शन घ्यायचे आहे", "garbhagriha khol dijiye", "devgharat jauya"),
    "akhand_diya": ("Take me to the eternal lamp", "अखंड दीपक वाले पेज पर जाओ", "अखंड ज्योत बघायची आहे", "akhand jyoti wala page kholo", "akhand diva dakhva"),
    "granth": ("Where are the scriptures in the app?", "गीता की पुस्तक कहाँ मिलेगी", "मला पोथ्या वाचायच्या आहेत", "adhyatmik pustak dikhaiye", "pothyanche pustakalay dakhva"),
    "kundali": ("Take me to the birth details form for my natal chart", "जन्म की कुंडली निकालनी है", "जन्मकुंडली बघायची आहे", "janam patrika banana hai", "maajhi janmapatrika kadha"),
    "milan": ("Where can I check marriage compatibility?", "शादी के लिए कुंडली मिलान खोलिए", "लग्नासाठी गुण किती जुळतात ते पाहायचे आहेत", "dono ki kundli milao", "patrika julvaychi aahe"),
    "ishta_devta": ("Which deity is my Ishta Devta?", "मेरे आराध्य देवता पता करो", "माझे इष्टदैवत शोधण्याचे पान दाखवा", "ishta devta calculator kholna", "mazha ishta dev kon"),
    "greetings": ("I'd like to browse good morning cards", "सुप्रभात कार्ड खोलिए", "शुभ सकाळची शुभेच्छापत्रे बघूया", "aaj ka suvichar wala page", "shubh sakal cards dakhva"),
    "grahan": ("Is there a solar eclipse coming up?", "अगला चंद्रग्रहण कब है", "पुढचे सूर्यग्रहण केव्हा आहे", "chandra grahan kab lagega", "surya grahanachi vel dakhva"),
    "calendar": ("Where can I see dates for upcoming festivals?", "पर्वों की सूची खोलो", "या महिन्यातले सण दाखवा", "festival ki dates batao", "ya mahinyache san dakhva"),
    "jaap_stats": ("Where can I find my japa history?", "मैंने कुल कितना जप किया", "मी आज किती जप केला", "naam jap history kholo", "majhya japachi nond dakhva"),
}

JAAP_ALIASES = (
    "jap", "japa", "jaap", "naam jap", "nam jaap", "naamjaap", "namjaap",
    "naam jaap", "nam jap", "naamjap", "namjap", "chant", "chanting",
    "नामजप", "नाम जप", "नामजाप", "नाम जाप", "जप", "जाप", "जपमाळ", "जपमाला",
)

MANTRAS = (
    ("radha", "Radhe Radhe", "राधे राधे"),
    ("swami_samarth", "Swami Samarth", "स्वामी समर्थ"),
    ("shri_ram", "Shri Ram", "श्री राम"),
    ("ganesha", "Ganpati", "गणपती"),
    ("om_namah_shivaya", "Om Namah Shivaya", "ॐ नमः शिवाय"),
    ("vasudevaya", "Om Namo Bhagavate Vasudevaya", "ॐ नमो भगवते वासुदेवाय"),
    ("jai_shri_ram", "Jai Shri Ram", "जय श्री राम"),
    ("hare_krishna", "Hare Krishna", "हरे कृष्ण"),
    ("om_namo_narayanaya", "Om Namo Narayanaya", "ॐ नमो नारायणाय"),
    ("gayatri", "Gayatri mantra", "गायत्री मंत्र"),
    ("shani_mantra", "Shani mantra", "शनि मंत्र"),
    ("hanuman", "Hanuman mantra", "हनुमान मंत्र"),
    ("durga", "Durga mantra", "दुर्गा मंत्र"),
    ("datta", "Datta mantra", "दत्त मंत्र"),
    ("vitthal", "Vitthal", "विठ्ठल"),
    ("sai_ram", "Sai Ram", "साई राम"),
    ("mahamrityunjaya", "Mahamrityunjaya mantra", "महामृत्युंजय मंत्र"),
)


def coverage_examples():
    help_file = Path(__file__).resolve().parents[1] / "app/voice_agent/app_help.json"
    guide = json.loads(help_file.read_text(encoding="utf-8"))
    topics = guide["topics"]
    for kind, route in guide["routes"].items():
        for query in route["examples"]:
            replies = route["reply"]
            if kind == "ask_rashi":
                lang = ("mr" if any(word in query for word in ("sang", "सांग"))
                        else "hi" if any(word in query for word in ("bata", "बता")) else "en")
                yield query, {"type": kind}, replies[lang]
            else:
                yield query, {"type": kind}, localized(query, replies["en"], replies["hi"], replies["mr"])
    for topic, info in topics.items():
        for query in info["examples"]:
            # The app renders the reviewed answer for this topic in its active locale.
            yield query, {"type": "answer_app_question", "feature_key": topic}, localized(
                query, "Here is how it works.", "इसकी जानकारी यहाँ है।", "याची माहिती इथे आहे."
            )

    for code, english, native in (("mr", "Marathi", "मराठी"), ("hi", "Hindi", "हिंदी"), ("en", "English", "इंग्रजी")):
        for query in (f"Make the app {english}", f"change the app language to {english}",
                      f"use {english} for the interface", f"switch the menus to {english}",
                      f"set language to {english}", f"अॅपची भाषा {native} करा",
                      f"ऐप की भाषा {native} में बदलो", f"app {english} mein dikhao"):
            yield query, {"type": "set_language", "language_code": code}, localized(
                query, "Changing the app language.", "ऐप की भाषा बदल रहे हैं।", "अॅपची भाषा बदलत आहे."
            )
    for kind, queries, replies in (
        ("open_feedback", ("I have a suggestion", "feedback and suggestions", "report a bug",
            "I want to send you feedback", "request a new deity", "सुझाव भेजना है", "तक्रार नोंदवा", "abh feedback dena hai"),
         ("Opening the feedback form.", "सुझाव फ़ॉर्म खोल रहे हैं।", "अभिप्राय फॉर्म उघडत आहे.")),
        ("open_language_settings", ("language picker", "let me pick a language", "change language", "language settings",
            "भाषा निवडा", "भाषा चुनें", "bhasha badlo"),
         ("Choose Marathi, Hindi or English.", "मराठी, हिंदी या अंग्रेज़ी चुनें।", "मराठी, हिंदी किंवा इंग्रजी निवडा.")),
        ("open_aarti_reminders", ("Open my aarti reminder preferences", "evening aarti reminder settings",
            "manage daily aarti alerts", "take me to aarti reminders", "आरती रिमाइंडर खोलो", "आरती आठवण उघडा",
            "aarti reminder kholo"),
         ("Opening aarti reminders.", "आरती रिमाइंडर खोल रहे हैं।", "आरती आठवण उघडत आहे.")),
    ):
        for query in queries:
            yield query, {"type": kind}, localized(query, *replies)

    for query, item, kind in (
        ("pasaydan", "pasayadan", "open_aarti"), ("pasaydaan lyrics", "pasayadan", "open_aarti"),
        ("listen to pasaydan", "pasayadan", "play_aarti"), ("shani dev arrti", "shani_aarti", "open_aarti"),
        ("play shanidev arti", "shani_aarti", "play_aarti"), ("शनी देवाची आरती उघड", "shani_aarti", "open_aarti"),
    ):
        yield query, {"type": kind, "aarti_id": item}, localized(
            query, "Opening the requested title.", "रचना खोल रहे हैं।", "रचना उघडत आहे."
        )

    for action_type, feature, queries in FEATURE_EXAMPLES:
        for query in (*queries, *FEATURE_PARAPHRASES[feature]):
            yield query, {"type": action_type, "feature_key": feature}, localized(
                query, "Opening the requested screen.", "मांगा गया पृष्ठ खोल रहे हैं।", "संबंधित पान उघडत आहे."
            )

    jaap = {"type": "start_jaap", "feature_key": "jaap"}
    for alias in JAAP_ALIASES:
        if alias.isascii():
            for query in (alias, f"start {alias}", f"{alias} shuru karo", f"Can I do {alias}?", f"open {alias} counter"):
                yield query, jaap, "Opening the jaap counter."
        else:
            for query in (alias, f"{alias} शुरू करो", f"{alias} सुरू करा", f"मला {alias} करायचा आहे"):
                yield query, jaap, localized(
                    query, "Opening the jaap counter.", "जप काउंटर खोल रहे हैं।", "जप मोजणी उघडत आहे."
                )

    for mantra_id, latin, native in MANTRAS:
        action = {**jaap, "mantra_id": mantra_id}
        yield f"chant {latin}", action, f"Opening jaap for {latin}."
        yield f"{latin} ka jap karna hai", action, f"Opening jaap for {latin}."
        yield f"{native} का जाप शुरू करो", action, f"{native} का जाप खोल रहे हैं।"
        yield f"start naam jaap with {latin}", action, f"Opening jaap for {latin}."
        yield f"{latin} cha jap lava", action, f"Opening jaap for {latin}."
        yield f"{native} नामजप सुरू करा", action, f"{native} नामजप उघडत आहे."

    for query in (
        "What is the capital of Japan?", "Open my camera", "Open Gmail notifications", "Disable all phone notifications", "Delete my entire inbox", "Did you receive my complaint?", "Has my feedback been submitted yet?",
        "What languages are supported by my phone keyboard?", "Do not switch to Marathi",
        "Remind me to buy milk", "Which languages does Netflix have?", "Cancel the language change", "Change my password",
        "Order a puja kit", "Set 108 jaap repetitions automatically", "Don't start a chant",
        "What does the Gayatri mantra mean?", "Open it", "Play something",
        "ट्रेन टिकट बुक करो", "मंत्र का अर्थ समझाओ", "माझा जप इतिहास मिटवा", "जप सुरू करू नका", "Nam jap mat karo", "Reset my mantra count",
        "Pause my chant", "Clear chanting history", "Set my jaap goal to 108", "Play my chant and then open Panchang",
        "Export my jaap history as CSV", "Remind me to chant at 6 AM", "Change the app language to Tamil",
        "Skip to the next bhajan", "Download every Hanuman song", "Share this to WhatsApp now",
        "Explain the meaning of this stotra", "Write a new shloka for me", "Tell me tomorrow's weather",
        "क्या इस मंत्र का मतलब बता सकते हो", "मंत्राचा अर्थ काय आहे", "माझे खाते हटवा",
        "कॉल लावा", "Share my birth chart publicly", "book a temple visit",
        "Can you order flowers?", "Find a hotel near my temple",
    ):
        yield query, {"type": "none"}, localized(
            query, "I couldn’t find a matching item or feature in BhaktiDhara.",
            "मुझे भक्तिधारा में इसका कोई विकल्प नहीं मिला।", "भक्तिधारामध्ये यासाठी काही सापडले नाही."
        )


def localized(query, english, hindi, marathi):
    if query.isascii() or not any("\u0900" <= ch <= "\u097f" for ch in query):
        return english
    return hindi if any(word in query for word in ("का ", "करो", "हैं", "दिखाओ", "बताओ", "मेरी", "मेरे", "खोलो", "बनाओ", "समझाओ")) else marathi
