"""Validate screen-scoped model proposals before returning them to the device."""
import re

from .app_help import TOPICS, DECLINE


def validated_action(proposal, text):
    if not isinstance(proposal, dict):
        return None
    action = proposal.get("action")
    data = action if isinstance(action, dict) else proposal
    kind = data.get("type") or action
    cancelled_result = re.search(
        r"(?:leave|keep) .*(?:closed|alone|untouched)|रहने दो|रहने दे|राहू दे|rehne do|rahu de|उघडू नको",
        text.casefold(),
    )
    if DECLINE.search(text.casefold()) or cancelled_result:
        return None
    if kind == "answer_app_question":
        key = data.get("feature_key")
        if isinstance(key, str) and key.startswith("home_") and key in TOPICS:
            return {"type": kind, "feature_key": key}
    if kind in ("read_home_search", "read_home_region"):
        return {"type": kind}
    if re.search(r"\b(?:don't|don’t|never|not|mat|nako|nahi)\b|मत |नको|नहीं|नका|how (?:do|can|would|should) i|how to|tell me how|(?:keep|leave) .* (?:as it is|the way it was|unchanged)|kaise|kasa|kase|कसे|कैसे|कसा", text.casefold()):
        return None
    if kind == "filter_home" and data.get("region") in ("all", "gujarat", "rajasthan", "uttarakhand"):
        region = data["region"]
        aliases = {"gujarat": ("gujarat", "गुजरात"), "rajasthan": ("rajasthan", "राजस्थान"),
                   "uttarakhand": ("uttarakhand", "उत्तराखंड", "उत्तराखण्ड")}
        if region == "all":
            reset = r"\b(?:all|every|reset|clear|remove|off|undo|sab|saare|sagle|poori|hata\w*)\b|सर्व|सगळ|सभी|सब |पूरी|पूर्ण|हटा|काढ"
            if not re.search(reset, text.casefold()):
                return None
        elif not any(name in text.casefold() for name in aliases[region]):
            return None
        return {"type": kind, "region": region}
    if kind == "open_home_result":
        position = data.get("position")
        if type(position) is int and 1 <= position <= 10000 and data.get("section") in ("all", "books", "aartis"):
            # A spoken section name refers to its own list, even when the model
            # emits the generic section used for bare "result" requests.
            books = re.search(r"\b(?:books?|scriptures?|pothi|granth)\b|किताब|ग्रंथ|पोथी", text.casefold())
            aartis = re.search(r"\b(?:aartis?|hymns?)\b|आरती", text.casefold())
            section = data["section"]
            if books and not aartis:
                section = "books"
            elif aartis and not books:
                section = "aartis"
            return {"type": kind, "position": position, "section": section}
    if kind == "search_home":
        query = data.get("query")
        if isinstance(query, str) and len(query) <= 250:
            return {"type": kind, "query": query.strip()}
    return None
