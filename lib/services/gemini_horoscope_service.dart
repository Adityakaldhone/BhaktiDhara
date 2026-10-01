import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../domain/entities/horoscope.dart';
import 'backend_service.dart';

/// Gemini AI Service for fetching personalized Vedic Horoscope predictions.
class GeminiHoroscopeService {
  /// Default API key configurable via compile-time environment or runtime setter.
  static String apiKey = const String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');

  /// In-memory cache to prevent redundant API calls during the session.
  final Map<String, HoroscopeReading> _cache = {};

  /// Fetches the horoscope for the given [rashi] and [period] ('today', 'tomorrow', 'weekly').
  Future<HoroscopeReading> getHoroscope({
    required Rashi rashi,
    required String period,
    required String langCode,
    bool forceRefresh = false,
  }) async {
    BackendService.trackEvent('horoscope_view', item: rashi.id, props: {'period': period});
    final cacheKey = '${rashi.id}_${period}_$langCode';
    if (!forceRefresh && _cache.containsKey(cacheKey)) {
      return _cache[cacheKey]!;
    }

    final dateText = _getFormattedDateText(period, langCode);

    // 1. Try Hetzner backend cache first (5ms, saves Gemini quota)
    if (!forceRefresh) {
      final backendReading = await BackendService.fetchCachedHoroscope(
        rashi: rashi,
        period: period,
        langCode: langCode,
      );
      if (backendReading != null) {
        _cache[cacheKey] = backendReading;
        return backendReading;
      }
    }

    // 2. If an API key is available, try Gemini API directly
    if (apiKey.trim().isNotEmpty) {
      try {
        final reading = await _fetchFromGemini(
          rashi: rashi,
          period: period,
          langCode: langCode,
          dateText: dateText,
        );
        _cache[cacheKey] = reading;
        return reading;
      } catch (_) {
        // Fallback to local Vedic knowledge engine on network or key issue
      }
    }

    // 3. Local authentic Vedic astrology engine fallback
    final fallbackReading = _generateVedicFallback(
      rashi: rashi,
      period: period,
      langCode: langCode,
      dateText: dateText,
    );
    _cache[cacheKey] = fallbackReading;
    return fallbackReading;
  }

  Future<HoroscopeReading> _fetchFromGemini({
    required Rashi rashi,
    required String period,
    required String langCode,
    required String dateText,
  }) async {
    final model = GenerativeModel(
      model: 'gemini-3.1-flash-lite',
      apiKey: apiKey.trim(),
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json',
        temperature: 0.7,
      ),
    );

    final langName = langCode == 'hi'
        ? 'Hindi'
        : (langCode == 'mr' ? 'Marathi' : 'English');

    final prompt = '''
You are an authentic, honest Vedic Astrologer (ज्येष्ठ ज्योतिषाचार्य).
Generate a realistic, balanced, and pragmatic Vedic Horoscope (राशीभविष्य/राशिफल) for:
- Rashi: ${rashi.nameMr} (${rashi.nameEn})
- Ruling Planet: ${rashi.rulingPlanet}
- Element: ${rashi.element}
- Period: $period ($dateText)
- Language: $langName

CRITICAL INSTRUCTIONS - AVOID FAKE REPETITIVE POSITIVITY:
1. Real Vedic astrology is honest and pragmatic. NOT every day is 100% positive.
2. Discuss genuine opportunities alongside realistic obstacles, cautions, delays, and stresses.
3. If planetary transit is challenging, warn the user honestly (e.g. avoid hasty investments, watch health/fatigue, keep temper under control).
4. Auspicious percentage MUST realistically reflect transit energy between 45% and 92% (DO NOT default to 85%).
5. Choose lucky numbers and colors authentic to ${rashi.nameEn} and its ruler ${rashi.rulingPlanet}.
6. Caution & Avoidance (काय टाळावे? / सावधगिरीचा इशारा):
   - "cautionTitle": 1 punchy, attention-grabbing alert on what to avoid today (e.g. "दुपारी २:३० ते ५:०० दरम्यान वादाचे प्रसंग व मोठी खरेदी टाळा").
   - "cautionDetail": 1-2 realistic sentences explaining the planetary transit vulnerability, specific danger or trap to avoid, and safe alternative approach.
   - "cautionWindow": Sensitive time range requiring utmost caution (e.g. "दुपारी ०२:३० - ०५:००").
7. Hourly Time-Slots (वेळेनुसार ३-काळ):
   - "timeSlots": {
       "morning": "1-2 practical sentences on morning energy, worship, and focus (06:00 AM - 12:00 PM)",
       "afternoon": "1-2 sentences on career decisions, trade, negotiation, and alertness (12:00 PM - 05:00 PM)",
       "evening": "1-2 sentences on relationships, health unwinding, and peaceful reflection (05:00 PM - 10:00 PM)"
     }
8. Daily Rashi Compatibility & Deity/Mantra (अनुकूल मैत्री रास व इष्टदेवता मंत्र):
   - "compatibleRashi": 1-2 zodiac signs that bring high luck, synergy, or business profit today (e.g. "सिंह व धनु (Leo & Sagittarius)")
   - "cautionRashi": 1 zodiac sign where misunderstanding or debate may arise today (e.g. "वृश्चिक (Scorpio)")
   - "compatibilityTip": 1-2 practical sentences on why today's planetary transit favors collaboration with compatible signs and how to avoid friction with caution sign.
   - "rulingDeity": Divine Vedic deity to honor today (e.g. "श्री विघ्नहर्ता गणेश / सूर्यदेव / पवनपुत्र हनुमान")
   - "deityMantra": Sacred Beej Mantra with count (e.g. "ॐ गं गणपतये नमः (२१ वेळा जप)")
   - "mantraBenefit": 1 practical sentence on the spiritual & psychological shield this mantra provides today

Respond ONLY with a valid JSON object matching this exact schema:
{
  "summary": "2-3 honest, realistic sentences discussing transit energy, opportunities, and necessary cautions",
  "career": "1-2 sentences with concrete guidance on work, trade, expenses, or dealings",
  "health": "1 sentence on health caution and physical vitality",
  "love": "1 sentence on family harmony and where patience is required",
  "cautionTitle": "short punchy alert on what mistake or conflict to avoid today",
  "cautionDetail": "1-2 sentences on specific planetary transit trap to avoid and caution needed",
  "cautionWindow": "specific hours of highest caution (e.g. दुपारी ०२:०० - ०४:३०)",
  "timeSlots": {
    "morning": "morning forecast in $langName",
    "afternoon": "afternoon forecast in $langName",
    "evening": "evening forecast in $langName"
  },
  "compatibleRashi": "1-2 compatible rashis today in $langName",
  "cautionRashi": "1 rashi to be careful with today in $langName",
  "compatibilityTip": "practical advice on partnerships and avoiding friction in $langName",
  "rulingDeity": "sacred deity in $langName",
  "deityMantra": "beej mantra with chant count in $langName",
  "mantraBenefit": "benefit of mantra in $langName",
  "luckyNumber": "numeral matching this sign",
  "luckyColor": "auspicious color in $langName",
  "remedy": "specific Vedic Upay or mantra honoring ${rashi.rulingPlanet}",
  "auspiciousPercentage": 65
}
''';

    final response = await model.generateContent([Content.text(prompt)]);
    final rawText = response.text;
    if (rawText == null || rawText.isEmpty) {
      throw Exception('Empty response from Gemini');
    }

    final decoded = jsonDecode(rawText) as Map<String, dynamic>;
    return HoroscopeReading.fromJson(
      decoded,
      rashiId: rashi.id,
      period: period,
      dateText: dateText,
      isAiGenerated: true,
    );
  }

  /// Authentic Vedic astrology knowledge engine (runs offline or without API key).
  HoroscopeReading _generateVedicFallback({
    required Rashi rashi,
    required String period,
    required String langCode,
    required String dateText,
  }) {
    if (langCode == 'hi') {
      return HoroscopeReading(
        rashiId: rashi.id,
        period: period,
        dateText: dateText,
        summary:
            '${rashi.nameHi} राशि के लिए आज का दिन सकारात्मक और शुभ ऊर्जा से भरा रहेगा। आपके स्वामी ग्रह ${rashi.rulingPlanet} की कृपा से महत्वपूर्ण कार्यों में सफलता के योग हैं।',
        career:
            'कार्यक्षेत्र में नई जिम्मेदारियां मिल सकती हैं। व्यापार में धन लाभ के योग बन रहे हैं। सहकर्मियों का पूरा सहयोग मिलेगा।',
        health:
            'मानसिक शांति बनी रहेगी। योग और प्राणायाम से स्वास्थ्य उत्तम रहेगा। खानपान पर संयम रखें।',
        love:
            'परिवार में सुख-शांति का वातावरण रहेगा। प्रियजनों के साथ मधुर संबंध बने रहेंगे।',
        luckyNumber: '९',
        luckyColor: 'पीला एवं केशरी',
        remedy: 'भगवान श्री गणेश को दूर्वा अर्पित करें एवं "ॐ नमः शिवाय" का जप करें।',
        cautionTitle:
            'दोपहर १२:०० से ०३:३० के बीच जल्दबाजी में धन निवेश और व्यर्थ विवाद से बचें।',
        cautionDetail:
            '${rashi.rulingPlanet} के प्रभाव से वाणी में उग्रता आ सकती है। वरिष्ठों या साझेदारों के साथ धैर्य बनाए रखें और किसी भी नए अनुबंध पर हस्ताक्षर करने से पहले विचार करें।',
        cautionWindow: 'दोपहर १२:०० - ०३:३०',
        timeSlots: const TimeSlotForecast(
          morning:
              'सुबह ६ से १२: दिन का प्रारंभ ईष्टदेव के स्मरण एवं सकारात्मक ऊर्जा के साथ करें। नए कार्यों के चिंतन के लिए यह समय शुभ है।',
          afternoon:
              'दोपहर १२ से ५: कार्यक्षेत्र में विवेकपूर्ण निर्णय लें। व्यापारिक सौदों और धन से जुड़े मामलों में सतर्कता बरतें।',
          evening:
              'शाम ५ से १०: परिजनों के साथ आनंदमय समय व्यतीत होगा। तनाव से दूर रहकर संध्या आरती एवं विश्राम पर ध्यान दें।',
        ),
        compatibleRashi: 'सिंह व धनु (Leo & Sagittarius)',
        cautionRashi: 'वृश्चिक (Scorpio)',
        compatibilityTip:
            'सिंह और धनु राशि के व्यक्तियों के साथ कार्ययोजना और संवाद से बड़ा लाभ होगा। वृश्चिक राशि से व्यर्थ वाद-विवाद टालें।',
        rulingDeity: 'भगवान श्री गणेश एवं सूर्य नारायण',
        deityMantra: 'ॐ गं गणपतये नमः (२१ बार जप)',
        mantraBenefit:
            'इस पवित्र मंत्र के जप से मानसिक स्पष्टता प्राप्त होगी और कार्यों में विघ्न समाप्त होंगे।',
        auspiciousPercentage: 88,
        isAiGenerated: false,
      );
    }

    if (langCode == 'mr') {
      return HoroscopeReading(
        rashiId: rashi.id,
        period: period,
        dateText: dateText,
        summary:
            '${rashi.nameMr} राशीसाठी आजचा काळ अत्यंत फलदायी आणि मंगलमय आहे. आपले स्वामी ग्रह ${rashi.rulingPlanet} च्या प्रभावाने रखडलेली कामे मार्गी लागतील.',
        career:
            'नोकरी व व्यवसायात प्रगतीचे नवे मार्ग खुले होतील. आर्थिक प्राप्तीचे समाधानकारक योग आहेत. आत्मविश्वासाने घेतलेले निर्णय फायदेशीर ठरतील.',
        health:
            'शारीरिक व मानसिक उत्साह उत्तम राहील. ध्यानसाधनेने मन शांत ठेवावे. हलका व सात्त्विक आहार घ्यावा.',
        love:
            'कुटुंबातील सदस्यांचे पूर्ण सहकार्य लाभेल. जोडीदारासोबतचे संबंध अधिक दृढ होतील.',
        luckyNumber: '५',
        luckyColor: 'सोनेरी व केशरी (Golden Saffron)',
        remedy: 'सकाळी सूर्यदेवाला अर्घ्य द्यावे व "श्री गणेशाय नमः" मंत्राचा ११ वेळा जप करावा.',
        cautionTitle:
            'दुपारी १२:०० ते ०३:३० दरम्यान घाईगडबडीत आर्थिक निर्णय व वादविवाद टाळा.',
        cautionDetail:
            '${rashi.rulingPlanet} च्या प्रभावामुळे आज भावनात्मक किंवा रागाच्या भरात निर्णय घेतल्यास नुकसान संभवते. महत्त्वाच्या कागदपत्रांची पडताळणी केल्याशिवाय स्वाक्षरी करू नका.',
        cautionWindow: 'दुपारी १२:०० - ०३:३०',
        timeSlots: const TimeSlotForecast(
          morning:
              'सकाळी ६ ते १२: दिवसाची सुरुवात शांत चित्ताने व इष्टदेवतेच्या आराधनेने करा. नवीन संकल्प व महत्त्वपूर्ण नियोजनासाठी सकाळची वेळ अत्यंत फलदायी आहे.',
          afternoon:
              'दुपारी १२ ते ५: कामाच्या ठिकाणी सहकाऱ्यांशी समन्वय ठेवा. आर्थिक देवाणघेवाण व बैठकांमध्ये संयम बाळगल्यास उत्तम यश मिळेल.',
          evening:
              'संध्याकाळी ५ ते १०: कौटुंबिक सौख्य वाढेल. कामाचा अतिरिक्त ताण विसरून कुटुंबीयांसमवेत वेळ घालवा व सात्त्विक आहारावर भर द्या.',
        ),
        compatibleRashi: 'सिंह व धनु (Leo & Sagittarius)',
        cautionRashi: 'वृश्चिक (Scorpio)',
        compatibilityTip:
            'सिंह व धनु राशीच्या सहकाऱ्यांशी बोलणी किंवा संयुक्त कामे अत्यंत फायदेशीर ठरतील. वृश्चिक राशीच्या व्यक्तींशी मतभेद टाळण्यासाठी नम्रता बाळगा.',
        rulingDeity: 'श्री विघ्नहर्ता गणेश व सूर्यदेव',
        deityMantra: 'ॐ गं गणपतये नमः (२१ वेळा जप)',
        mantraBenefit:
            'या मंत्राच्या पठणाने आज कामातील अडथळे दूर होतील आणि निर्णयक्षमता तीक्ष्ण होईल.',
        auspiciousPercentage: 91,
        isAiGenerated: false,
      );
    }

    return HoroscopeReading(
      rashiId: rashi.id,
      period: period,
      dateText: dateText,
      summary:
          'Today brings auspicious planetary alignments for ${rashi.nameEn}. Ruled by ${rashi.rulingPlanet}, you will experience clarity, positive energy, and spiritual focus.',
      career:
          'Promising developments in career and professional pursuits. Financial gains are favored with thoughtful planning.',
      health:
          'Vitality remains high. Maintain balance with light meditation and mindful hydration.',
      love:
          'Harmonious interactions with family and loved ones bring joy and emotional peace.',
      luckyNumber: '7',
      luckyColor: 'Auspicious Saffron & Gold',
      remedy: 'Offer prayers to Lord Ganesha and chant "Om Gam Ganapataye Namaha".',
      cautionTitle:
          'Avoid hasty financial commitments and heated arguments between 12:00 PM and 03:30 PM.',
      cautionDetail:
          'Due to intense planetary transit of ${rashi.rulingPlanet}, impulsive reactions may lead to misunderstandings or financial leaks. Double-check all documents before signing.',
      cautionWindow: '12:00 PM - 03:30 PM',
      timeSlots: const TimeSlotForecast(
        morning:
            '06:00 AM - 12:00 PM: Start your day with positive spiritual affirmations. Early hours are auspicious for planning, prayers, and clear focus.',
        afternoon:
            '12:00 PM - 05:00 PM: Navigate professional responsibilities with patience. Double-check contracts and exercise prudence in meetings.',
        evening:
            '05:00 PM - 10:00 PM: Unwind with family and loved ones. Dedicate peaceful moments to gratitude, light dining, and rejuvenation.',
      ),
      compatibleRashi: 'Leo & Sagittarius (सिंह व धनु)',
      cautionRashi: 'Scorpio (वृश्चिक)',
      compatibilityTip:
          'Collaborations with Leo and Sagittarius yield fruitful progress. Maintain calm dialogue with Scorpio to avoid unnecessary debate.',
      rulingDeity: 'Lord Ganesha & Lord Surya',
      deityMantra: 'Om Gam Ganapataye Namaha (Chant 21 times)',
      mantraBenefit:
          'Chanting this sacred mantra dispels obstacles and sharpens your focus for today\'s challenges.',
      auspiciousPercentage: 89,
      isAiGenerated: false,
    );
  }

  String _getFormattedDateText(String period, String langCode) {
    final now = DateTime.now();
    DateTime target = now;
    if (period == 'tomorrow') {
      target = now.add(const Duration(days: 1));
    }

    final monthsMr = [
      'जानेवारी', 'फेब्रुवारी', 'मार्च', 'एप्रिल', 'मे', 'जून',
      'जुलै', 'ऑगस्ट', 'सप्टेंबर', 'ऑक्टोबर', 'नोव्हेंबर', 'डिसेंबर'
    ];
    final monthsHi = [
      'जनवरी', 'फरवरी', 'मार्च', 'अप्रैल', 'मई', 'जून',
      'जुलाई', 'अगस्त', 'सितंबर', 'अक्टूबर', 'नवंबर', 'दिसंबर'
    ];
    final monthsEn = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];

    if (period == 'weekly') {
      return langCode == 'mr'
          ? 'चालू आठवडा'
          : (langCode == 'hi' ? 'यह सप्ताह' : 'This Week');
    }

    final day = target.day;
    final year = target.year;
    final monthIndex = target.month - 1;

    if (langCode == 'hi') {
      return '$day ${monthsHi[monthIndex]} $year';
    }
    if (langCode == 'mr') {
      return '$day ${monthsMr[monthIndex]} $year';
    }
    return '$day ${monthsEn[monthIndex]} $year';
  }

  /// Consults Vedic AI for personalized answers to user's questions.
  Future<VedicAiConsultation> consultVedicAi({
    required Rashi rashi,
    required String question,
    required String langCode,
    String? initial,
  }) async {
    BackendService.trackEvent(
      'vedic_ai_consult',
      item: rashi.id,
      props: {'question': question},
    );

    // 1. Try Hetzner backend first (fast & reliable)
    final backendResult = await BackendService.consultVedicAi(
      rashi: rashi,
      question: question,
      langCode: langCode,
      initial: initial,
    );
    if (backendResult != null) return backendResult;

    // 2. Direct Gemini call if API key is configured
    if (apiKey.trim().isNotEmpty) {
      try {
        return await _fetchVedicAiConsultation(
          rashi: rashi,
          question: question,
          langCode: langCode,
          initial: initial,
        );
      } catch (_) {
        // Fall back to local Vedic engine
      }
    }

    // 3. Authentic Vedic local fallback
    return _generateVedicAiFallback(
      rashi: rashi,
      question: question,
      langCode: langCode,
      initial: initial,
    );
  }

  Future<VedicAiConsultation> _fetchVedicAiConsultation({
    required Rashi rashi,
    required String question,
    required String langCode,
    String? initial,
  }) async {
    final model = GenerativeModel(
      model: 'gemini-3.1-flash-lite',
      apiKey: apiKey.trim(),
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json',
        temperature: 0.7,
      ),
    );

    final langName = langCode == 'hi'
        ? 'Hindi'
        : (langCode == 'mr' ? 'Marathi' : 'English');

    final prompt = '''
You are an authentic, honest Vedic Astrologer (ज्येष्ठ ज्योतिषाचार्य).
A seeker has asked this personal life question:
Question: "$question"
Seeker Zodiac: ${rashi.nameMr} (${rashi.nameEn})
Ruling Planet: ${rashi.rulingPlanet}
Seeker Name Initial: ${initial ?? 'N/A'}
Language: $langName

Provide honest, compassionate Vedic astrological guidance:
1. Explain the planetary influence relevant to this matter (${rashi.rulingPlanet}).
2. Provide realistic, practical advice (not fake miracles).
3. Recommend an authentic Vedic remedy (Mantra, deed, or auspicious direction).
4. Give a favorable window for action.

Respond ONLY with a valid raw JSON object matching this schema:
{
  "headline": "Short 1-sentence respectful summary or auspicious signal",
  "astrologicalAspect": "1-2 sentences on relevant planetary transit/aspect",
  "guidance": "2-3 practical, encouraging and pragmatic advice sentences",
  "remedy": "Specific sacred mantra or deed",
  "favorableTiming": "Auspicious timing or direction"
}
''';

    final response = await model.generateContent([Content.text(prompt)]);
    final rawText = response.text?.trim() ?? '{}';
    final cleaned = rawText
        .replaceAll(RegExp(r'^```json\s*', multiLine: true), '')
        .replaceAll(RegExp(r'^```\s*', multiLine: true), '')
        .trim();

    final data = jsonDecode(cleaned) as Map<String, dynamic>;
    return VedicAiConsultation.fromJson(data);
  }

  VedicAiConsultation _generateVedicAiFallback({
    required Rashi rashi,
    required String question,
    required String langCode,
    String? initial,
  }) {
    final qLower = question.toLowerCase();

    if (langCode == 'hi') {
      if (qLower.contains('नौकरी') || qLower.contains('व्यवसाय') || qLower.contains('job')) {
        return VedicAiConsultation(
          headline: 'कर्म भाव में ग्रहों की स्थिति अनुकूल; धैर्य से लिया निर्णय फलदायी होगा।',
          astrologicalAspect: '${rashi.rulingPlanet} के प्रभाव से कार्यक्षेत्र में नए अवसर और मान-सम्मान के योग बन रहे हैं।',
          guidance: 'हड़बड़ी में कोई नया अनुबंध न करें। वरिष्ठजनों की सलाह से कार्य में गति आएगी और रुका हुआ काम बनेगा।',
          remedy: 'रोज सुबह सूर्य नमस्कार करें और "ॐ घृणि सूर्याय नमः" का जप करें।',
          favorableTiming: 'सुबह ०९:०० से ११:३० का समय महत्वपूर्ण निर्णय के लिए उत्तम है।',
          isAiGenerated: false,
        );
      } else if (qLower.contains('विवाह') || qLower.contains('शादी') || qLower.contains('marriage')) {
        return VedicAiConsultation(
          headline: 'सप्तम भाव में शुभ ग्रहों की दृष्टि; विवाह संबंधी बातचीत में प्रगति के योग।',
          astrologicalAspect: 'गुरु व ${rashi.rulingPlanet} के गोचर से रिश्ते तय होने के अनुकूल संकेत मिल रहे हैं।',
          guidance: 'संवाद में पारदर्शिता रखें। पारिवारिक समन्वय से लिए गए निर्णय दीर्घकालिक सुख देंगे।',
          remedy: 'गुरुवार को भगवान विष्णु या कुलदेवता को पीले पुष्प अर्पित कर प्रार्थना करें।',
          favorableTiming: 'आगामी २ से ४ सप्ताह में शुभ समाचार मिलने की प्रबल संभावना है।',
          isAiGenerated: false,
        );
      } else if (qLower.contains('कर्ज') || qLower.contains('धन') || qLower.contains('पैसा') || qLower.contains('finance')) {
        return VedicAiConsultation(
          headline: 'आर्थिक स्थिति में क्रमिक सुधार होगा; अनावश्यक खर्चों पर नियंत्रण रखें।',
          astrologicalAspect: 'द्वितीय व एकादश भाव के प्रभाव से धन आगमन के नए मार्ग प्रशस्त होंगे।',
          guidance: 'बड़ा निवेश सोच-समझकर करें। योजनाबद्ध तरीके से कर्ज मुक्ति का मार्ग निकलेगा।',
          remedy: 'प्रतिदिन श्री महालक्ष्मी अष्टकम् का पाठ करें व जरूरतमंद को अन्नदान करें।',
          favorableTiming: 'दोपहर १२:०० से ०२:०० बजे आर्थिक योजनाओं के लिए शुभ रहेगा।',
          isAiGenerated: false,
        );
      }
      return VedicAiConsultation(
        headline: 'ग्रह स्थिति सकारात्मक दृष्टिकोण और एकाग्रता बनाए रखने का संकेत दे रही है।',
        astrologicalAspect: '${rashi.rulingPlanet} की कृपा से आपके प्रयासों को उचित दिशा व सफलता मिलेगी।',
        guidance: 'सकारात्मक सोच के साथ आगे बढ़ें। स्वास्थ्य का ध्यान रखें और मन को शांत रखने के लिए ध्यान करें।',
        remedy: 'हनुमान चालीसा का पाठ करें और घर में सुगंधित धूप जलाएं।',
        favorableTiming: 'प्रातःकाल ०७:३० से १०:०० का समय अत्यंत शुभ व फलदायी है।',
        isAiGenerated: false,
      );
    }

    if (langCode == 'en') {
      if (qLower.contains('job') || qLower.contains('career') || qLower.contains('business')) {
        return VedicAiConsultation(
          headline: 'Planetary alignments favor steady progress in your professional sphere.',
          astrologicalAspect: 'The transit of ${rashi.rulingPlanet} indicates upcoming recognition and opportunities for advancement.',
          guidance: 'Avoid impulsive career changes. Seek counsel from mentors and maintain diplomatic relations with colleagues.',
          remedy: 'Offer water to the rising Sun daily and chant "Om Suryaya Namaha" 11 times.',
          favorableTiming: '09:00 AM to 11:30 AM is an auspicious window for major discussions.',
          isAiGenerated: false,
        );
      } else if (qLower.contains('marriage') || qLower.contains('love') || qLower.contains('relationship')) {
        return VedicAiConsultation(
          headline: 'Benefic planetary aspects bring harmony and auspicious matchmaking prospects.',
          astrologicalAspect: 'Influences on your 7th house suggest fruitful developments in relationship matters.',
          guidance: 'Prioritize open communication and mutual respect. Patience will help align the right life partnership.',
          remedy: 'Light a pure ghee lamp before your family deity on Thursdays.',
          favorableTiming: 'Evenings between 05:00 PM and 07:30 PM favor positive family discussions.',
          isAiGenerated: false,
        );
      } else if (qLower.contains('debt') || qLower.contains('money') || qLower.contains('finance')) {
        return VedicAiConsultation(
          headline: 'Financial resilience will strengthen through disciplined budgeting.',
          astrologicalAspect: 'Aspects to your 2nd and 11th houses point towards gradual recovery of pending dues.',
          guidance: 'Avoid speculative ventures. Structured repayment plans will alleviate mental stress effectively.',
          remedy: 'Chant the sacred Lakshmi Gayatri Mantra 21 times at dusk.',
          favorableTiming: 'The coming 2-3 weeks indicate favorable financial clarity.',
          isAiGenerated: false,
        );
      }
      return VedicAiConsultation(
        headline: 'Celestial currents encourage patience and focused devotion toward your goals.',
        astrologicalAspect: 'The strength of ${rashi.rulingPlanet} protects your endeavors from adverse planetary vibrations.',
        guidance: 'Maintain clarity of thought. Balance your physical wellbeing with daily mindful meditation.',
        remedy: 'Chant sacred Gayatri Mantra 11 times every morning.',
        favorableTiming: 'Early mornings (07:00 AM - 09:30 AM) radiate maximum auspicious energy.',
        isAiGenerated: false,
      );
    }

    // Default Marathi
    if (qLower.contains('नोकरी') || qLower.contains('व्यवसाय') || qLower.contains('job') || qLower.contains('career')) {
      return VedicAiConsultation(
        headline: 'कर्मस्थानी ग्रहांचे संक्रमण अनुकूल; संयमाने घेतलेला निर्णय लाभदायक ठरेल.',
        astrologicalAspect: '${rashi.rulingPlanet} च्या संक्रमणामुळे आगामी काळात कार्यक्षेत्रात नवी संधी व सन्मान मिळण्याचे योग आहेत.',
        guidance: 'नवीन संधीचे स्वागत करताना घाईगडबड न करता सहकाऱ्यांशी योग्य समन्वय ठेवा. वरिष्ठ व्यक्तींचा सल्ला घेतल्यास कामात गती येईल.',
        remedy: 'रोज सकाळी सूर्यदेवाला अर्घ्य देऊन "ॐ सूर्याय नमः" चा ११ वेळा जप करावा.',
        favorableTiming: 'सकाळी ०९:०० ते १२:०० ही वेळ महत्त्वपूर्ण चर्चा व निर्णयांसाठी शुभ राहील.',
        isAiGenerated: false,
      );
    } else if (qLower.contains('विवाह') || qLower.contains('लग्ना') || qLower.contains('marriage')) {
      return VedicAiConsultation(
        headline: 'सप्तम भावातील ग्रहांची दृष्टी शुभ; योग्य स्थळांचे योग लवकरच जुळतील.',
        astrologicalAspect: 'गुरु व ${rashi.rulingPlanet} च्या कृपेने वैवाहिक चर्चेत सकारात्मक प्रगती होण्याची शक्यता आहे.',
        guidance: 'नात्यांमध्ये संवाद आणि परस्पर समजूतदारपणा ठेवा. घरातील वडीलधाऱ्यांचा सल्ला घेऊनच निर्णय घ्यावा.',
        remedy: 'दर गुरुवारी कुलदेवतेसमोर तुपाचा दिवा लावून प्रार्थना करावी व पिवळ्या फुलांचे अर्पण करावे.',
        favorableTiming: 'संध्याकाळी ०५:०० ते ०७:३० दरम्यान अनुकूल चर्चा व भेटीगाठी होऊ शकतात.',
        isAiGenerated: false,
      );
    } else if (qLower.contains('कर्ज') || qLower.contains('धन') || qLower.contains('पैसा') || qLower.contains('finance')) {
      return VedicAiConsultation(
        headline: 'धनभावातील ग्रहस्थिती हळूहळू सुधारेल; अनावश्यक खर्चावर नियंत्रण ठेवा.',
        astrologicalAspect: 'द्वितीय व एकादश भावातील भ्रमणामुळे थकीत येणी किंवा नवीन उत्पन्नाचे मार्ग सुरू होण्याचे योग आहेत.',
        guidance: 'मोठी गुंतवणूक करताना जाणकारांचा सल्ला घ्या. कर्जफेडीसाठी टप्प्याटप्प्याने नियोजन केल्यास ताण कमी होईल.',
        remedy: 'रोज संध्याकाळी "ॐ श्रीं महालक्ष्म्यै नमः" चा जप करावा व भुकेल्या व्यक्तीला अन्न द्यावे.',
        favorableTiming: 'आगामी २ ते ३ आठवड्यांत आर्थिक व्यवहारांमध्ये सकारात्मक प्रगती दिसून येईल.',
        isAiGenerated: false,
      );
    }

    return VedicAiConsultation(
      headline: 'ग्रहस्थिती संयम आणि आत्मविश्वासाने पुढे जाण्याची प्रेरणा देत आहे.',
      astrologicalAspect: '${rashi.rulingPlanet} च्या प्रभावामुळे आपल्या प्रयत्नांना योग्य फळ मिळण्याचे शुभ योग आहेत.',
      guidance: 'सकारात्मक विचार आणि योग्य दिनचर्या ठेवा. आरोग्याकडे दुर्लक्ष न करता रोज थोडे ध्यान केल्यास मानसिक शांतता लाभेल.',
      remedy: 'दर मंगळवारी किंवा शनिवारी श्री हनुमान चालीसा पठण करावे.',
      favorableTiming: 'सकाळी ०७:३० ते १०:३० ही वेळ अत्यंत मंगलकारी राहील.',
      isAiGenerated: false,
    );
  }
}

