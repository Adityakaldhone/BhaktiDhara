VOICE_ACTIONS = (
    "open_horoscope",
    "ask_rashi",
    "open_notifications",
    "open_panchang",
    "open_mandir",
    "open_akhand_diya",
    "start_jaap",
    "open_granth",
    "open_kundali",
    "open_milan",
    "open_ishta_devta",
    "open_greetings",
    "open_grahan",
    "open_calendar",
    "open_jaap_stats",
    "open_aarti",
    "play_aarti",
    "answer_app_question",
    "open_feedback",
    "open_bhajans",
    "open_more",
    "set_language",
    "open_language_settings",
    "open_aarti_reminders",
    "none",
)

SYSTEM_PROMPT = (
    "Classify a BhaktiDhara voice command in English, Hindi, Marathi or mixed script. "
    "Return only JSON with an action object containing type and relevant fields, "
    "and response_text in the user's language. "
    f"Allowed types: {', '.join(VOICE_ACTIONS)}. "
    "For a horoscope reading without a named sign use ask_rashi and ask which sign. Never infer a sign. "
    "Use open_horoscope for a named sign or an explicit request to open the horoscope screen. "
    "Use open_notifications for the app inbox, open_aarti_reminders for aarti reminder settings. "
    "Use Flutter zodiac IDs in rashi_id. Use mantra_id for a known jaap mantra. "
    "For instructions or questions about the app, use answer_app_question with feature_key "
    "capabilities, language, feedback, reminders, jaap, jaap_stats, panchang, kundali, milan, greetings, ishta_devta, granth, calendar or catalog. For Home questions also use "
    "home_region, home_search, home_books, home_cards, home_request, home_empty, home_bells, home_scroll, home_back, home_microphone, home_ads, home_offer, home_update, home_maintenance, home_tabs, home_jaap_card, home_loading, home_order. For catalog questions supply field (singer, duration, audio, availability or about) and query with the title. "
    "For a requested language change, set language_code to mr, hi or en. "
    "Feedback and reminder settings open forms. Never claim to submit a form or schedule a reminder. "
    "Use none for unrelated, ambiguous, cancelled or unsupported commands. "
    "Use open_aarti for reading and play_aarti for listening. Use query for the requested media title or deity."
)

# Used only when a sign is missing. Keep the historical classifier prompts intact.
RASHI_FOLLOWUP_PROMPT = (
    "You are the BhaktiDhara app. Interpret the answer to your previous question. "
    "If the speaker does not know their sign or wants you to find it, return JSON "
    'with action {"type":"find_birth_rashi"} and response_text asking for birth date including year '
    "and birthplace, with birth time if known. If they name a sign, use open_horoscope with "
    "its English zodiac ID. For a change of subject classify the new request. "
    "Never invent birth details or a sign. Reply in the requested locale."
)


def feature_prompt(topics):
    labels = ", ".join(key + ("/" + info["screen_action"] if "screen_action" in info else "")
                       for key, info in topics.items())
    return ("Route a BhaktiDhara utterance in English, Hindi, Marathi or mixed script. Return only JSON "
              "containing action.type. For questions about using a feature, use answer_app_question and "
              "action.feature_key. For a request to visit it, select the screen action. A polite request "
              "can be a command. Use none for cancellations, unrelated questions and unsupported operations. "
              "Topic/screen pairs: " + labels)

HOME_PROMPT = (
    "Classify a BhaktiDhara command on the Home screen (English, Hindi, Marathi or mixed). "
    "Return JSON with action and response_text. Use filter_home with region all, gujarat, "
    "rajasthan or uttarakhand. Use search_home with query (empty string clears it). "
    "Use open_home_result with one-based integer position and section all, books or aartis. "
    "Use read_home_region or read_home_search for current values; the device supplies the answer. "
    "For how-to questions use answer_app_question with feature_key. Never act on a cancellation. "
    "Use none for unclear or unsupported requests. Other available actions: " + ", ".join(VOICE_ACTIONS)
)

# The Home-only adapter predicts the action. Flutter constructs the spoken reply.
HOME_CONTROL_PROMPT = (
    "Classify a BhaktiDhara Home command. Reply only with JSON containing action. "
    "A numbered or ordinal item in displayed results uses open_home_result, with integer position "
    "(first=1, second=2, third=3, fourth=4, fifth=5) and section books for a scripture, "
    "aartis for a hymn, all for an unspecified result. Do not guess the item's ID. "
    "Opening the library itself uses open_granth. Cancelling or asking not to act uses none. "
    "Use search_home with query, filter_home with region, read_home_search or read_home_region. "
    "Questions about using the app use answer_app_question with feature_key. "
    "For other app requests use their ordinary voice action."
)
