"""Reviewed answers shared with the on-device assistant."""
import json
import re
from pathlib import Path

_GUIDE = json.loads(Path(__file__).with_suffix(".json").read_text(encoding="utf-8"))
BIRTH_RASHI = _GUIDE["birth_rashi"]
JAAP_VALUES = {key: re.compile(spec["pattern"]) for key, spec in _GUIDE["jaap_values"].items()}
TOPICS = _GUIDE["topics"]
ROUTES = _GUIDE["routes"]
# Phrases published as examples are also valid commands, even without the model.
def _spoken_key(text):
    return " ".join(text.casefold().strip(" ?!.।").split())


_QUESTION_EXAMPLES = {_spoken_key(q): key for key, topic in TOPICS.items() for q in topic["examples"]}
_SCREEN_NAMES = {
    _spoken_key(name): key for key, topic in TOPICS.items() if topic.get("screen_action")
    for name in (*topic["labels"].values(), *topic.get("aliases", ()))
}
_SCREEN_REQUESTS = [re.compile(pattern) for pattern in _GUIDE["feature_screen_patterns"]]
FEATURE_EXPLANATION = re.compile(_GUIDE["feature_explanation"])
APP_SCOPE = re.compile(_GUIDE["app_scope"])
FEATURE_NAVIGATION = re.compile(_GUIDE["feature_navigation_hint"])
FEATURE_INQUIRY = re.compile(_GUIDE["feature_inquiry"])


def screen_topic(query):
    for pattern in _SCREEN_REQUESTS:
        match = pattern.fullmatch(query)
        if match and (key := _SCREEN_NAMES.get(_spoken_key(match[1]))):
            return key
    return None


_ROUTE_EXAMPLES = {
    _spoken_key(example): kind
    for kind, route in ROUTES.items() for example in route["examples"]
}


def match_route(query):
    if kind := _ROUTE_EXAMPLES.get(_spoken_key(query)):
        return kind
    return next((kind for kind, route in ROUTES.items() if re.search(route["pattern"], query)), None)

RASHI_ANSWER = re.compile(_GUIDE["rashi_answer"])
DECLINE = re.compile(_GUIDE["decline"])
EXCLUDE = re.compile(_GUIDE["exclude"])
MODEL_QUESTION = re.compile(_GUIDE["model_questions"])


def _words(text):
    return {w for w in re.findall(r"[a-z0-9\u0900-\u097f]+", text.lower()) if len(w) >= 4}


# Words unique to a feature's reviewed answer can ground unfamiliar app questions.
_ANSWER_WORDS = {key: _words(" ".join(info["reply"].values())) for key, info in TOPICS.items()}
_UNIQUE_WORDS = {key: words - set().union(*(other for k, other in _ANSWER_WORDS.items() if k != key))
                 for key, words in _ANSWER_WORDS.items()}


def matching_topics(query):
    if EXCLUDE.search(query):
        return []
    matches = [key for key, topic in TOPICS.items() if re.search(topic["terms"], query)]
    for name, key in _SCREEN_NAMES.items():
        if key not in matches and re.search(r"(?:^|[ ,])" + re.escape(name) + r"(?:$|[ ,.?!।])", query):
            matches.append(key)
    for specific, general in _GUIDE["topic_priority"]:
        if specific in matches and general in matches:
            matches.remove(general)
    if len(matches) > 1 and "more" in matches:
        matches.remove("more")
    if not matches and APP_SCOPE.search(query):
        words = _words(query)
        matches.extend(key for key, anchors in _UNIQUE_WORDS.items() if len(words & anchors) >= 2)
    return matches


def direct_topic(query, candidates):
    if not EXCLUDE.search(query) and (key := _QUESTION_EXAMPLES.get(_spoken_key(query))):
        return key
    return next((key for key in candidates if re.search(TOPICS[key]["questions"], query)), None)


def catalog_question(query):
    for field, patterns in _GUIDE["catalog_questions"].items():
        for pattern in patterns:
            match = re.fullmatch(pattern, query.strip(" ?!।."))
            if match:
                return field, next(text for text in match.groups() if text)
    return None


def catalog_reply(field, item, lang):
    suffix = {"mr": "Mr", "hi": "Hi", "en": ""}[lang]
    title = item.get("title" + suffix) or item["title"]
    if field == "audio":
        field = "audio_yes" if item.get("youtubeVideoId") else "audio_no"
    value = item.get({"singer": "singer", "about": "about" + suffix, "duration": "durationText"}.get(field))
    if field in ("singer", "about", "duration") and not value:
        field = "missing"
    return _GUIDE["catalog_replies"][field][lang].format(title=title, value=value)


def catalog_clues(query):
    return {key for key, pattern in _GUIDE["catalog_clues"].items() if re.search(pattern, query)}


def find_catalog_item(requested, items, aliases, lang):
    def normalize(value):
        return " ".join(re.findall(r"[\w\u0900-\u097f]+", value.lower()))

    name = re.sub(r"\b(?:a+r+ti|aarati)\b", "aarti", normalize(requested))
    if not name:
        return None
    alias = aliases.get(name)
    preferred = {"mr": "titleMr", "hi": "titleHi", "en": "title"}[lang]
    for row in items:
        if row["id"] == alias or normalize(row.get(preferred) or "") == name:
            return row
    return next((row for row in items if any(
        normalize(row.get(key) or "") == name for key in ("title", "titleHi", "titleMr")
    )), None)
