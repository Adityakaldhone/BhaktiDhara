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

Respond ONLY with a valid JSON object matching this exact schema:
{
  "summary": "2-3 honest, realistic sentences discussing transit energy, opportunities, and necessary cautions",
  "career": "1-2 sentences with concrete guidance on work, trade, expenses, or dealings",
  "health": "1 sentence on health caution and physical vitality",
  "love": "1 sentence on family harmony and where patience is required",
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
}
