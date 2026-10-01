import asyncio
import json
import os
import re
from typing import Dict, Any, Optional
import google.generativeai as genai

GEMINI_API_KEY = os.getenv("GEMINI_API_KEY", "").strip().strip('"').strip("'")
GEMINI_MODEL = os.getenv("GEMINI_MODEL", "gemini-3.1-flash-lite").strip()

if GEMINI_API_KEY:
    genai.configure(api_key=GEMINI_API_KEY)



def _clean_json_markdown(text: str) -> str:
    """Removes ```json and markdown code blocks if returned by the model."""
    cleaned = re.sub(r"^```[a-zA-Z]*\n", "", text.strip())
    cleaned = re.sub(r"\n```$", "", cleaned.strip())
    return cleaned.strip()


def _generate_with_fallback(prompt: str) -> str:
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


async def generate_horoscope(
    rashi_name: str,
    period: str,
    lang_code: str,
    date_text: str,
    rashi_id: Optional[str] = None,
) -> Dict[str, Any]:
    """Generates authentic, nuanced Vedic Horoscope reading via Google Gemini."""
    if not GEMINI_API_KEY:
        raise ValueError("GEMINI_API_KEY is not configured on the server")

    clean_id = _resolve_rashi_id(rashi_name, rashi_id)
    profile = RASHI_VEDIC_PROFILES.get(clean_id, RASHI_VEDIC_PROFILES["aries"])

    lang_instruction = {
        "mr": "Strictly respond in pure, authentic Marathi (मराठी) with proper Devanagari script, as written in respected Panchangs & newspapers.",
        "hi": "Strictly respond in pure, dignified Hindi (हिन्दी) with authentic Vedic Devanagari terminology.",
        "en": "Respond in English with authentic Vedic astrology principles and terminology."
    }.get(lang_code, "Strictly respond in Marathi.")

    prompt = f"""
You are an authentic, honest Vedic Astrologer (ज्येष्ठ ज्योतिषाचार्य) writing daily rashibhavishya (राशीभविष्य).
Real Vedic astrology is balanced, pragmatic, and nuanced. NOT EVERY DAY IS "अत्यंत शुभ".
Readers want TRUTHFUL, practical astrological guidance, NOT generic fake positivity!

Target Rashi: {rashi_name} ({clean_id.upper()})
Ruling Planet (राशी स्वामी): {profile['lord']}
Vedic Element (तत्व): {profile['element']}
Natural Strengths: {profile['strengths']}
Vulnerabilities & Cautions: {profile['cautions']}
Reference Date: {date_text}
Period: {period} (today/tomorrow/weekly)
Language Requirement: {lang_instruction}

STRICT ASTROLOGICAL RULES - AVOID TOXIC POSITIVITY & REPETITION:
1. TRUTHFUL & BALANCED REALISM:
   - Provide a genuinely differentiated forecast: discuss real planetary transit energies including favorable opportunities alongside realistic challenges, cautions, delays, or stress.
   - If the day has friction: explicitly warn the reader (उदा. "कामात विलंब संभवतो", "खर्चावर तातडीने नियंत्रण ठेवा", "वादविवादापासून लांब राहा", "कागदपत्रांची पडताळणी करा").
   - DO NOT repeat generic cliché opening lines like "आजचा दिवस अत्यंत शुभ आणि फलदायी राहील".
2. CAREER & FINANCE:
   - Specific advice for jobs, business, investments, or office dealings. Mention whether decisions should be made today or postponed.
3. HEALTH (आरोग्य):
   - Specific bodily indicators matching {profile['cautions']} and {profile['element']} (उदा. डोकेदुखी, पित्त, सांधेदुखी, थकवा, पचनक्रिया, उष्णता).
4. FAMILY & RELATIONSHIPS:
   - Genuine guidance on where patience or restraint of speech is needed with spouse, elders, or colleagues.
5. AUSPICIOUS PERCENTAGE (शुभ टक्केवारी):
   - MUST vary realistically based on today's planetary transit between 42% and 94% (e.g. 52%, 64%, 78%, 86%, 58%, etc.). DO NOT default to 85%!
6. LUCKY NUMBER & COLOR:
   - Number: Choose an authentic Vedic number from: {profile['numbers']}.
   - Color: Choose an authentic color from: {profile['colors']}.
7. VEDIC REMEDY (उपाय):
   - A specific sacred mantra, stotra, or deed honoring {profile['lord']}.
8. CAUTION & AVOIDANCE (सावधगिरीचा इशारा - काय टाळावे?):
   - cautionTitle: 1 punchy, attention-grabbing headline in {lang_code} (e.g. "दुपारी २:३० ते ५:०० दरम्यान वादाचे प्रसंग व मोठी खरेदी टाळा")
   - cautionDetail: 1-2 practical sentences explaining planetary risk and specific trap/pitfall to avoid today.
   - cautionWindow: Specific sensitive time window (e.g. "दुपारी १२:०० - ०३:३०" or "सकाळी १०:३० - १२:००")
9. HOURLY TIME-SLOTS (वेळेनुसार ३-काळ):
   - timeSlots: An object containing:
     - morning: 1-2 practical sentences on morning mindset, worship, and priority tasks (06:00 AM - 12:00 PM)
     - afternoon: 1-2 sentences on career decisions, trade, negotiation, and alertness (12:00 PM - 05:00 PM)
     - evening: 1-2 sentences on relationships, health unwinding, and peaceful reflection (05:00 PM - 10:00 PM)
10. DAILY COMPATIBILITY & DEITY (अनुकूल मैत्री रास व इष्टदेवता मंत्र):
   - compatibleRashi: 1-2 signs favoring collaboration today in {lang_code} (e.g. "सिंह व धनु")
   - cautionRashi: 1 sign where caution in communication is needed in {lang_code} (e.g. "वृश्चिक")
   - compatibilityTip: 1-2 sentences on handling partnership and avoiding debate today
   - rulingDeity: Divine deity for today's planetary transit in {lang_code}
   - deityMantra: Sacred Beej Mantra with count in {lang_code} (e.g. "ॐ गं गणपतये नमः (२१ वेळा जप)")
   - mantraBenefit: 1 sentence on the spiritual benefit of this mantra today

Respond ONLY with a valid, raw JSON object (no markdown, no ```json tags, no explanations).
JSON Schema:
{{
  "summary": "2-3 honest, realistic sentences discussing planetary transit energy, opportunities, and necessary cautions",
  "career": "1-2 sentences with concrete guidance on work, trade, expenses, or dealings",
  "health": "1 sentence on health caution and physical energy",
  "love": "1 sentence on family harmony and where patience is required",
  "cautionTitle": "1 short punchy alert on what to avoid today",
  "cautionDetail": "1-2 sentences on specific planetary transit risk and avoidance advice",
  "cautionWindow": "Specific hours of the day where caution is most required",
  "timeSlots": {{
    "morning": "Morning guidance in {lang_code}",
    "afternoon": "Afternoon guidance in {lang_code}",
    "evening": "Evening guidance in {lang_code}"
  }},
  "compatibleRashi": "1-2 compatible signs today in {lang_code}",
  "cautionRashi": "1 sign to avoid conflict with today in {lang_code}",
  "compatibilityTip": "Practical guidance on synergy and handling debate in {lang_code}",
  "rulingDeity": "Sacred deity for today in {lang_code}",
  "deityMantra": "Beej mantra with count in {lang_code}",
  "mantraBenefit": "Spiritual benefit in {lang_code}",
  "luckyNumber": "Auspicious numeral from {profile['numbers']}",
  "luckyColor": "Auspicious color from {profile['colors']}",
  "remedy": "Vedic remedy linked to {profile['lord']}",
  "auspiciousPercentage": 65
}}
"""

    # The Gemini SDK call is blocking; run it off the event loop.
    raw_text = await asyncio.to_thread(_generate_with_fallback, prompt)
    cleaned = _clean_json_markdown(raw_text)

    try:
        data = json.loads(cleaned)
        data["isAiGenerated"] = True
    except Exception:
        # Fallback dictionary if JSON parsing fails
        data = {
            "summary": f"{rashi_name} राशीच्या जातकांसाठी आज संयम आणि सावधगिरी बाळगण्याचा दिवस आहे. ग्रहांच्या स्थितीनुसार कामात नियोजित वेळेपेक्षा अधिक वेळ लागू शकतो.",
            "career": "कामाच्या ठिकाणी वादाचे प्रसंग टाळा आणि वरिष्ठांच्या सूचनेनुसार वाटचाल करा. आर्थिक देवाणघेवाणीत दक्षता ठेवा.",
            "health": "मानसिक थकवा जाणवू शकतो; ध्यानधारणा आणि संतुलित आहारावर भर द्या.",
            "love": "कुटुंबात सामंजस्याने वागा, रागावर नियंत्रण ठेवल्यास कौटुंबिक सौख्य टिकून राहील.",
            "cautionTitle": f"{rashi_name} राशीने आज दुपारी घाईगडबडीत आर्थिक निर्णय किंवा वादविवाद टाळावेत.",
            "cautionDetail": f"{profile['lord']} च्या प्रभावामुळे आज {profile['cautions']} बाबत विशेष दक्षता बाळगणे गरजेचे आहे. कोणावरही आंधळा विश्वास ठेवू नका.",
            "cautionWindow": "दुपारी १२:०० - ०३:३०",
            "timeSlots": {
                "morning": f"सकाळी ६ ते १२: दिवसाचा प्रारंभ ईष्टदेवतेच्या चिंतनाने करा. नवीन योजना आखण्यासाठी सकाळचा काळ शुभ आहे.",
                "afternoon": f"दुपारी १२ ते ५: कामाच्या ठिकाणी संयम ठेवा. आर्थिक निर्णय व महत्त्वाच्या बैठकांमध्ये विचारपूर्वक बोला.",
                "evening": f"संध्याकाळी ५ ते १०: कुटुंबासमवेत शांततेत वेळ घालवा. कामाचा ताण दूर ठेवून सात्त्विक आहाराला प्राधान्य द्या.",
            },
            "compatibleRashi": "सिंह व धनु",
            "cautionRashi": "वृश्चिक",
            "compatibilityTip": "सिंह व धनु राशीच्या सहकाऱ्यांशी कामात सहकार्य लाभेल. वृश्चिक राशीशी संवाद साधताना शांतता ठेवा.",
            "rulingDeity": f"श्री {profile['lord'].split('(')[0].strip()}",
            "deityMantra": "ॐ गं गणपतये नमः (२१ वेळा जप)",
            "mantraBenefit": "या मंत्राने ग्रहांची अनिष्ट पीडा दूर होऊन आत्मविश्वासात वाढ होईल.",
            "luckyNumber": profile['numbers'].split(',')[0].strip(),
            "luckyColor": profile['colors'].split(',')[0].strip(),
            "remedy": f"श्री {profile['lord'].split('(')[0].strip()} चे स्मरण किंवा जप करावा.",
            "auspiciousPercentage": 62,
            "isAiGenerated": False,
        }

    return data


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
