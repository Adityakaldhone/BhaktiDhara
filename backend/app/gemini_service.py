import asyncio
import json
import os
import re
from typing import Dict, Any, Optional

if __package__:
    from .horoscope_engine import configure_horoscope_gemini, generate_horoscope, get_cached_horoscope, horoscope_cache_key
else:
    from horoscope_engine import configure_horoscope_gemini, generate_horoscope, get_cached_horoscope, horoscope_cache_key
try:
    import google.generativeai as genai
except ImportError:
    genai = None

GEMINI_API_KEY = os.getenv("GEMINI_API_KEY", "").strip().strip('"').strip("'")
GEMINI_MODEL = os.getenv("GEMINI_MODEL", "gemini-3.1-flash-lite").strip()

if GEMINI_API_KEY and genai is not None:
    genai.configure(api_key=GEMINI_API_KEY)


def _clean_json_markdown(text: str) -> str:
    """Removes ```json and markdown code blocks if returned by the model."""
    cleaned = re.sub(r"^```[a-zA-Z]*\n", "", text.strip())
    cleaned = re.sub(r"\n```$", "", cleaned.strip())
    return cleaned.strip()


def _generate_with_fallback(prompt: str) -> str:
    if genai is None:
        raise RuntimeError("Install the existing google-generativeai dependency to use Gemini")
    try:
        model = genai.GenerativeModel(GEMINI_MODEL)
        response = model.generate_content(prompt)
        return response.text or "{}"
    except Exception as e:
        for alt in ["gemini-2.5-flash", "gemini-flash-lite-latest"]:
            if alt != GEMINI_MODEL:
                try:
                    model = genai.GenerativeModel(alt)
                    response = model.generate_content(prompt)
                    return response.text or "{}"
                except Exception:
                    pass
        raise e


configure_horoscope_gemini(_generate_with_fallback if GEMINI_API_KEY and genai is not None else None)


LANG_NAMES = {"mr": "Marathi (मराठी)", "hi": "Hindi (हिन्दी)", "en": "English"}

# Common in Marathi, rare or absent in Hindi.
_MARATHI_MARKERS = ("ळ", " आहे", " आणि ", "च्या ", "साठी", "ण्याची", " करा", " टाळा", "दुपारी", "संध्याकाळी", " वेळा")
_DEVANAGARI = re.compile(r"[\u0900-\u097F]")


def reading_matches_language(data: Dict[str, Any], lang_code: str) -> bool:
    """Check the response language before caching or serving a reading."""
    lang_code = lang_code.strip().lower().replace("_", "-").split("-")[0]
    if data.get("schemaVersion") == 2:
        return data.get("langCode") == lang_code
    text = " ".join(str(data.get(k, "")) for k in ("summary", "career", "health", "love", "cautionTitle"))
    if not text.strip():
        return True
    if lang_code == "hi":
        return sum(text.count(m) for m in _MARATHI_MARKERS) < 2
    if lang_code == "en":
        letters = [c for c in text if c.isalpha()]
        return not letters or len(_DEVANAGARI.findall(text)) / len(letters) < 0.3
    return True


# ── Authentic Vedic Planetary Profiles for 12 Rashis ─────────────────────────
RASHI_VEDIC_PROFILES: Dict[str, Dict[str, Any]] = {
    "aries": {
        "lord": "मंगळ (Mars)",
        "element": "अग्नी (Fire)",
        "symbol": "मेष (Ram)",
        "colors": "केशरी, लाल, तांबूस",
        "numbers": "९, १, ३",
        "strengths": "साहस, पुढाकार, ऊर्जा",
        "cautions": "राग, उतावळेपणा, डोकेदुखी किंवा अचानक खर्च",
    },
    "taurus": {
        "lord": "शुक्र (Venus)",
        "element": "पृथ्वी (Earth)",
        "symbol": "वृषभ (Bull)",
        "colors": "पांढरा, चमकीला गुलाबी, हलका निळा",
        "numbers": "६, २, ८",
        "strengths": "स्थैर्य, आर्थिक नियोजन, सहनशीलता",
        "cautions": "हट्टीपणा, सुस्ती, अनावश्यक खरेदी किंवा पचनाचे त्रास",
    },
    "gemini": {
        "lord": "बुध (Mercury)",
        "element": "वायू (Air)",
        "symbol": "मिथुन (Twins)",
        "colors": "पाचू हिरवा, फिकट पिवळा",
        "numbers": "५, ३, ७",
        "strengths": "संभाषण, व्यापार बुद्धी, बौद्धिक चातुर्य",
        "cautions": "मनाची द्विधा अवस्था, अफवांवर विश्वास, एकाग्रतेचा अभाव",
    },
    "cancer": {
        "lord": "चंद्र (Moon)",
        "element": "जल (Water)",
        "symbol": "कर्क (Crab)",
        "colors": "मोती पांढरा, चंदेरी, क्रीम",
        "numbers": "२, ४, ७",
        "strengths": "संवेदनशीलता, कौटुंबिक जिव्हाळा, अंतःप्रेरणा",
        "cautions": "अतिभावुकता, चिंता, कफ किंवा पोटाच्या तक्रारी, नकारात्मक विचार",
    },
    "leo": {
        "lord": "सूर्य (Sun)",
        "element": "अग्नी (Fire)",
        "symbol": "सिंह (Lion)",
        "colors": "सोनेरी, केशरी, तांबडा",
        "numbers": "१, ४, ९",
        "strengths": "आत्मविश्वास, प्रतिष्ठा, नेतृत्व गुण",
        "cautions": "अहंकार, वरिष्ठ किंवा वडिलांशी मतभेद, डोळ्यांचे किंवा उष्णतेचे विकार",
    },
    "virgo": {
        "lord": "बुध (Mercury)",
        "element": "पृथ्वी (Earth)",
        "symbol": "कन्या (Maiden)",
        "colors": "गडद हिरवा, खाकी, पिवळा",
        "numbers": "५, ६, २",
        "strengths": "सूक्ष्म नियोजन, हिशोब, कार्यक्षमता",
        "cautions": "अतिविचार, छोटी कामे लांबणे, पोटाचे विकार किंवा अस्वस्थता",
    },
    "libra": {
        "lord": "शुक्र (Venus)",
        "element": "वायू (Air)",
        "symbol": "तूळ (Scales)",
        "colors": "गुलाबी, पांढरा, आकाशी निळा",
        "numbers": "६, ७, २",
        "strengths": "न्यायप्रियता, समतोल, कला व भागीदारी",
        "cautions": "निर्णय घेण्यात द्विधा मनस्थिती, भागीदारीत गैरसमज, खर्चात वाढ",
    },
    "scorpio": {
        "lord": "मंगळ व केतू (Mars/Ketu)",
        "element": "जल (Water)",
        "symbol": "वृश्चिक (Scorpion)",
        "colors": "गडद लाल, महरून, जांभळा",
        "numbers": "९, ४, ८",
        "strengths": "गूढ शोध, दृढनिश्चय, एकाग्रता",
        "cautions": "संशयी वृत्ती, गुप्त शत्रू किंवा अचानक वादविवाद, वाहन चालवताना काळजी",
    },
    "sagittarius": {
        "lord": "गुरू (Jupiter)",
        "element": "अग्नी (Fire)",
        "symbol": "धनु (Archer)",
        "colors": "हळदी पिवळा, पितांबरी, सोनेरी",
        "numbers": "३, ९, ७",
        "strengths": "धार्मिक निष्ठा, उच्च शिक्षण, मार्गदर्शक दृष्टिकोन",
        "cautions": "अतिआत्मविश्वास, प्रवासात दगदग, नको तिथे उपदेश देणे",
    },
    "capricorn": {
        "lord": "शनी (Saturn)",
        "element": "पृथ्वी (Earth)",
        "symbol": "मकर (Sea-Goat)",
        "colors": "गडद निळा, काळा, राखाडी",
        "numbers": "८, ५, ६",
        "strengths": "कठोर परिश्रम, शिस्त, संघटना कौशल्य",
        "cautions": "कामात विलंब, कामाचा अतिरिक्त ताण, सांधेदुखी किंवा मानसिक थकवा",
    },
    "aquarius": {
        "lord": "शनी व राहु (Saturn/Rahu)",
        "element": "वायू (Air)",
        "symbol": "कुंभ (Water-Bearer)",
        "colors": "आकाशी निळा, जांभळा, काळा",
        "numbers": "८, ४, ७",
        "strengths": "नाविन्यता, समाजहित, व्यापक दृष्टिकोन",
        "cautions": "अचानक आर्थिक चढ-उतार, मित्रांकडून गैरसमज, अनिद्रा किंवा रक्तदाब",
    },
    "pisces": {
        "lord": "गुरू (Jupiter)",
        "element": "जल (Water)",
        "symbol": "मीन (Two Fishes)",
        "colors": "केशरी, पिवळा, हलका बदामी",
        "numbers": "३, ७, ९",
        "strengths": "अध्यात्म, दानधर्म, कल्पनाशक्ती, करुणा",
        "cautions": "आर्थिक बेफिकीरी, अतिविचार, आळस किंवा कामात लक्ष न लागणे",
    },
}


def _resolve_rashi_id(rashi_name: str, explicit_id: Optional[str] = None) -> str:
    """Helper to get standardized rashi ID like 'aries', 'capricorn'."""
    if explicit_id and explicit_id.lower() in RASHI_VEDIC_PROFILES:
        return explicit_id.lower()

    name_lower = rashi_name.lower().strip()
    name_map = {
        "मेष": "aries", "aries": "aries",
        "वृषभ": "taurus", "taurus": "taurus",
        "मिथुन": "gemini", "gemini": "gemini",
        "कर्क": "cancer", "cancer": "cancer",
        "सिंह": "leo", "leo": "leo",
        "कन्या": "virgo", "virgo": "virgo",
        "तूळ": "libra", "तुला": "libra", "libra": "libra",
        "वृश्चिक": "scorpio", "scorpio": "scorpio",
        "धनु": "sagittarius", "sagittarius": "sagittarius",
        "मकर": "capricorn", "capricorn": "capricorn",
        "कुंभ": "aquarius", "aquarius": "aquarius",
        "मीन": "pisces", "pisces": "pisces",
    }
    for k, v in name_map.items():
        if k in name_lower:
            return v
    return "aries"


async def generate_panchang(city_name: str, date_str: str, lang_code: str) -> Dict[str, Any]:
    """Generates Vedic Panchang calculation & insights via Google Gemini."""
    if not GEMINI_API_KEY:
        raise ValueError("GEMINI_API_KEY is not configured on the server")

    lang_instruction = {
        "mr": "Strictly respond in pure Marathi (मराठी) using authentic Vedic Sanskrit terminology.",
        "hi": "Strictly respond in pure Hindi (हिन्दी) using authentic Vedic Sanskrit terminology.",
        "en": "Respond in English with authentic Vedic astronomical terms transliterated."
    }.get(lang_code, "Strictly respond in Marathi.")

    prompt = f"""
You are a revered Vedic Jyotishacharya (astronomer and Vedic scholar).
Provide high-precision, authentic Vedic Panchang (पञ्चाङ्ग) data for:
City: {city_name}
Date: {date_str}
Language Requirement: {lang_instruction}

Respond ONLY with a valid, raw JSON object (no markdown, no ```json tags, no explanations).
JSON Schema:
{{
  "formattedDate": "Human readable date string",
  "dayName": "Name of the weekday (e.g. रविवार / Sunday)",
  "vikramSamvat": "२०८३",
  "shakaSamvat": "१९४८",
  "samvatsara": "कालयुक्त",
  "ayana": "दक्षिणायन",
  "ritu": "शरद",
  "maas": "भाद्रपद",
  "paksha": "शुक्ल पक्ष",
  "tithi": "चतुर्थी",
  "tithiEndTime": "०२:३० PM",
  "vaar": "रविवार",
  "vaarGraha": "सूर्य",
  "nakshatra": "अनुराधा",
  "nakshatraEndTime": "०४:१५ PM",
  "yoga": "शुक्ल",
  "yogaEndTime": "११:२० AM",
  "karana": "वणिज",
  "karanaEndTime": "०२:३० PM",
  "sunrise": "०६:१२ AM",
  "sunset": "०६:२२ PM",
  "moonrise": "०५:३० PM",
  "moonset": "०५:०८ AM",
  "suryaRashi": "कन्या",
  "chandraRashi": "वृश्चिक",
  "abhijitMuhurat": "११:४८ AM - १२:३६ PM",
  "amritKaal": "०६:१५ AM - ०७:४५ AM",
  "brahmaMuhurat": "०४:३५ AM - ०५:२३ AM",
  "vijayaMuhurat": "०२:१२ PM - ०३:०० PM",
  "godhuliMuhurat": "०६:१० PM - ०६:३५ PM",
  "rahuKaal": "१०:३० AM - १२:०० PM",
  "yamaganda": "०३:०० PM - ०४:३० PM",
  "gulikaKaal": "०७:३० AM - ०९:०० AM",
  "durmuhurat": "०८:३५ AM - ०९:२४ AM",
  "bhadra": "नाही",
  "festivalName": "Name of any festival or vrat today, or empty",
  "vrat": "Any fast observance or empty",
  "festivalDescription": "1-2 sentences on today's spiritual significance",
  "dailyMantra": "ॐ नमो भगवते वासुदेवाय",
  "specialGuidance": "Daily spiritual guidance for devotees"
}}
"""

    raw_text = await asyncio.to_thread(_generate_with_fallback, prompt)
    cleaned = _clean_json_markdown(raw_text)

    try:
        data = json.loads(cleaned)
        data["isAiGenerated"] = True
    except Exception:
        data = {
            "formattedDate": date_str,
            "dayName": "रविवार",
            "vikramSamvat": "२०८३",
            "shakaSamvat": "१९४८",
            "samvatsara": "कालयुक्त",
            "ayana": "दक्षिणायन",
            "ritu": "शरद",
            "maas": "भाद्रपद",
            "paksha": "शुक्ल पक्ष",
            "tithi": "चतुर्थी",
            "tithiEndTime": "०२:३० PM",
            "vaar": "रविवार",
            "vaarGraha": "सूर्य",
            "nakshatra": "अनुराधा",
            "nakshatraEndTime": "०४:१५ PM",
            "yoga": "शुक्ल",
            "yogaEndTime": "११:२० AM",
            "karana": "वणिज",
            "karanaEndTime": "०२:३० PM",
            "sunrise": "०६:१२ AM",
            "sunset": "०६:२२ PM",
            "moonrise": "०५:३० PM",
            "moonset": "०५:०८ AM",
            "suryaRashi": "कन्या",
            "chandraRashi": "वृश्चिक",
            "abhijitMuhurat": "११:४८ AM - १२:३६ PM",
            "amritKaal": "०६:१५ AM - ०७:४५ AM",
            "brahmaMuhurat": "०४:३५ AM - ०५:२३ AM",
            "vijayaMuhurat": "०२:१२ PM - ०३:०० PM",
            "godhuliMuhurat": "०६:१० PM - ०६:३५ PM",
            "rahuKaal": "१०:३० AM - १२:०० PM",
            "yamaganda": "०३:०० PM - ०४:३० PM",
            "gulikaKaal": "०७:३० AM - ०९:०० AM",
            "durmuhurat": "०८:३५ AM - ०९:२४ AM",
            "bhadra": "नाही",
            "festivalName": "",
            "vrat": "",
            "festivalDescription": "आजचा दिवस अत्यंत शुभ असून कुलदैवत व श्री गणेशाचे स्मरण करावे.",
            "dailyMantra": "ॐ नमो भगवते वासुदेवाय",
            "specialGuidance": "सत्कर्म व दानधर्म केल्यास विशेष पुण्य लाभेल.",
            "isAiGenerated": False,
        }

    data["cityName"] = city_name
    return data


async def consult_vedic_ai(
    rashi_id: str,
    question: str,
    lang_code: str = "mr",
    initial: Optional[str] = None,
) -> Dict[str, Any]:
    """Provides personalized Vedic astrological consultation on user question."""
    clean_id = _resolve_rashi_id(rashi_id, rashi_id)
    profile = RASHI_VEDIC_PROFILES.get(clean_id, RASHI_VEDIC_PROFILES["aries"])

    if not GEMINI_API_KEY:
        return {
            "headline": "ग्रहांच्या अनुकूलतेनुसार संयमाने घेतलेले निर्णय यशस्वी ठरतील.",
            "astrologicalAspect": f"{profile['lord']} च्या प्रभावामुळे आपल्या प्रयत्नांना योग्य दिशा मिळण्याचे योग आहेत.",
            "guidance": "आपण विचारलेल्या प्रश्नासंदर्भात घाईगडबड न करता योग्य नियोजन करा. वरिष्ठ किंवा जाणकार व्यक्तीचा सल्ला घेतल्यास यश नक्की मिळेल.",
            "remedy": f"रोज सकाळी 'ॐ श्री गणेशाय नमः' चा २१ वेळा जप करावा व कुलदेवतेचे स्मरण करावे.",
            "favorableTiming": "सकाळी ०८:०० ते ११:०० ही वेळ महत्त्वपूर्ण निर्णयांसाठी उत्तम आहे.",
            "isAiGenerated": False,
        }

    lang_instruction = {
        "mr": "Strictly respond in respectful, compassionate Marathi (मराठी).",
        "hi": "Strictly respond in respectful, compassionate Hindi (हिन्दी).",
        "en": "Respond in English with authentic Vedic astrology terminology."
    }.get(lang_code, "Strictly respond in Marathi.")

    prompt = f"""
You are an authentic, wise Vedic Astrologer (ज्येष्ठ ज्योतिषाचार्य).
A seeker has asked this personal life question:
Question: "{question}"
Seeker Zodiac: {clean_id.upper()}
Ruling Planet: {profile['lord']}
Seeker Name Initial: {initial or 'N/A'}
Language: {lang_instruction}

Provide honest, compassionate Vedic astrological guidance:
1. Explain the planetary influence relevant to this matter ({profile['lord']}).
2. Provide realistic, practical advice (not fake miracles).
3. Recommend an authentic Vedic remedy (Mantra, deed, or auspicious direction).
4. Give a favorable window for action.

Respond ONLY with a valid raw JSON object matching this schema:
{{
  "headline": "Short 1-sentence respectful summary or auspicious signal",
  "astrologicalAspect": "1-2 sentences on relevant planetary transit/aspect",
  "guidance": "2-3 practical, encouraging and pragmatic advice sentences",
  "remedy": "Specific sacred mantra or deed (e.g. श्री हनुमानाची उपासना किंवा जप)",
  "favorableTiming": "Auspicious timing or direction (e.g. आगामी ३ आठवडे किंवा उत्तर दिशा)"
}}
"""

    raw_text = await asyncio.to_thread(_generate_with_fallback, prompt)
    cleaned = _clean_json_markdown(raw_text)

    try:
        data = json.loads(cleaned)
        data["isAiGenerated"] = True
    except Exception:
        data = {
            "headline": "ग्रहांच्या अनुकूलतेनुसार संयमाने घेतलेले निर्णय यशस्वी ठरतील.",
            "astrologicalAspect": f"{profile['lord']} च्या प्रभावामुळे आपल्या प्रयत्नांना योग्य दिशा मिळण्याचे योग आहेत.",
            "guidance": "आपण विचारलेल्या प्रश्नासंदर्भात घाईगडबड न करता योग्य नियोजन करा. वरिष्ठ किंवा जाणकार व्यक्तीचा सल्ला घेतल्यास यश नक्की मिळेल.",
            "remedy": f"रोज सकाळी 'ॐ श्री गणेशाय नमः' चा २१ वेळा जप करावा व कुलदेवतेचे स्मरण करावे.",
            "favorableTiming": "सकाळी ०८:०० ते ११:०० ही वेळ महत्त्वपूर्ण निर्णयांसाठी उत्तम आहे.",
            "isAiGenerated": False,
        }

    return data
