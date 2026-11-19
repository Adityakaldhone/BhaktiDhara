import 'dart:convert';
import 'dart:math' as math;

import 'package:google_generative_ai/google_generative_ai.dart';

import '../domain/entities/horoscope.dart';
import 'backend_service.dart';

part 'horoscope_presentation.dart';

/// Return the horoscope JSON body from your existing backend endpoint.
typedef HoroscopeBackendLoader = Future<Map<String, dynamic>?> Function({
  required Rashi rashi,
  required String period,
  required String langCode,
  HoroscopeCity? city,
  required bool forceRefresh,
});

/// Bhaktidhara's general Janma Rashi readings and Vedic AI consultation.
class GeminiHoroscopeService {
  GeminiHoroscopeService({
    DateTime Function()? clock,
    HoroscopeEphemeris? ephemeris,
    HoroscopeBackendLoader? backendLoader,
  }) : _clock = clock ?? DateTime.now,
       _ephemeris = ephemeris ?? const _ApproximateLahiriEphemeris(),
       // ignore: prefer_initializing_formals
       _backendLoader = backendLoader;

  /// Used by the existing consultation flow only.
  static String apiKey = const String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: '',
  );

  final DateTime Function() _clock;
  final HoroscopeEphemeris _ephemeris;
  final HoroscopeBackendLoader? _backendLoader;
  final _cache = <(String, String, String, DateTime), _HoroscopeContent>{};
  final _transitsByDay = <DateTime, _LunarTransit>{};
  final _moonByDay = <DateTime, List<_MoonSample>>{};
  DateTime? _cacheDay;

  /// Reads the given birth Moon sign for today, tomorrow, or Monday–Sunday.
  /// All calendar periods use IST, independently of the device's time zone.
  Future<HoroscopeReading> getHoroscope({
    required Rashi rashi,
    required String period,
    required String langCode,
    bool forceRefresh = false,
  }) async {
    final today = _calendarDayInIndia(_clock());
    final serverPage = await _loadServerPage(
      rashi,
      period,
      langCode,
      null,
      forceRefresh,
      today,
    );
    if (serverPage != null) return serverPage.reading;
    return _getContent(rashi, period, langCode, forceRefresh, today).reading;
  }

  /// Structured content for the full detail page and the compact summary card.
  Future<HoroscopePage> getHoroscopePage({
    required Rashi rashi,
    required String period,
    required String langCode,
    HoroscopeCity? city,
    bool forceRefresh = false,
  }) async {
    final today = _calendarDayInIndia(_clock());
    final serverPage = await _loadServerPage(
      rashi,
      period,
      langCode,
      city,
      forceRefresh,
      today,
    );
    if (serverPage != null) return serverPage;
    final content = _getContent(rashi, period, langCode, forceRefresh, today);
    final start = content.start;
    final dayStartUtc = start.subtract(_istOffset);
    final transit = _transitsByDay.putIfAbsent(
      start,
      () => _lunarTransit(dayStartUtc, _ephemeris),
    );
    final lastDaySign = content.days.length == 7
        ? content.days.last[1].sign
        : null;
    final muhurat =
        city == null ||
            period == 'weekly' ||
            start.weekday == DateTime.wednesday
        ? null
        : _abhijitWindow(_ephemeris, dayStartUtc, city);
    return _buildPage(
      content: content,
      transit: transit,
      lastDaySign: lastDaySign,
      city: city,
      muhurat: muhurat,
      source: _ephemeris.name,
    );
  }

  Future<HoroscopePage?> _loadServerPage(
    Rashi rashi,
    String period,
    String langCode,
    HoroscopeCity? city,
    bool forceRefresh,
    DateTime today,
  ) async {
    final load = _backendLoader;
    if (load == null) return null;

    final language = _language(langCode);
    final signId = _rashiAliases[_indexOfRashi(rashi)].first;
    final start = _periodStart(today, period);
    final end = period == 'weekly' ? start.add(const Duration(days: 6)) : start;
    Map<String, dynamic>? data;
    try {
      data = await load(
        rashi: rashi,
        period: period,
        langCode: language,
        city: city,
        forceRefresh: forceRefresh,
      );
    } on Exception {
      return null;
    }
    if (data == null ||
        data['schemaVersion'] != 2 ||
        data['rashiId'] != signId ||
        data['period'] != period ||
        data['langCode'] != language ||
        data['forecastDate'] != _isoDate(start) ||
        data['forecastEndDate'] != _isoDate(end)) {
      return null;
    }

    final HoroscopePage page;
    try {
      page = _serverHoroscopePage(data, rashi, period, city);
    } on FormatException {
      return null;
    } on TypeError {
      return null;
    } on ArgumentError {
      return null;
    }

    BackendService.trackEvent(
      'horoscope_view',
      item: rashi.id,
      props: {'period': period},
    );
    return page;
  }

  _HoroscopeContent _getContent(
    Rashi rashi,
    String period,
    String langCode,
    bool forceRefresh,
    DateTime today,
  ) {
    final start = _periodStart(today, period);
    final language = _language(langCode);
    final rashiIndex = _indexOfRashi(rashi);

    BackendService.trackEvent(
      'horoscope_view',
      item: rashi.id,
      props: {'period': period},
    );

    if (_cacheDay != today) {
      _cache.clear();
      _moonByDay.clear();
      _transitsByDay.clear();
      _cacheDay = today;
    }

    final key = (rashi.id.toString(), period, language, start);
    if (!forceRefresh) {
      final cached = _cache[key];
      if (cached != null) return cached;
    }

    // Generate here so a legacy backend response cannot replace this
    // transit-based reading. Online and offline use the same inputs.
    final days = List.generate(period == 'weekly' ? 7 : 1, (index) {
      final day = start.add(Duration(days: index));
      return _moonByDay.putIfAbsent(day, () => _sampleMoon(day, _ephemeris));
    });
    final reading = _buildReading(
      rashi: rashi,
      rashiIndex: rashiIndex,
      period: period,
      language: language,
      start: start,
      days: days,
    );
    _cache[key] = reading;
    return reading;
  }

  _HoroscopeContent _buildReading({
    required Rashi rashi,
    required int rashiIndex,
    required String period,
    required String language,
    required DateTime start,
    required List<List<_MoonSample>> days,
  }) {
    final weekly = days.length == 7;
    _HouseReading themeFor(_MoonSample moon) =>
        _houseReadings[(moon.sign - rashiIndex) % 12];

    // A daily reading leads with the afternoon house. A weekly reading
    // covers the Monday, Thursday, and Sunday themes in chronological order.
    final lead = themeFor(days.first[1]);
    final representativeDay = days[weekly ? 3 : 0];
    final middle = themeFor(representativeDay[1]);
    final last = themeFor(days.last[weekly ? 1 : 2]);
    final outlook = weekly
        ? _weekOutlook(lead, middle, last, language)
        : lead.outlook.inLanguage(language);
    final shift = !weekly && themeFor(days.first[0]) != last
        ? _shiftOutlook(themeFor(days.first[0]), last, language)
        : '';
    final nakshatra = days.first[1].nakshatra;
    final dailyNote = _nakshatraNotes[nakshatra % _nakshatraNotes.length];
    final overview = [
      outlook,
      shift,
      if (!weekly) dailyNote.inLanguage(language),
    ].where((line) => line.isNotEmpty).join(' ');
    final body = [
      overview,
      '${_doLabel.inLanguage(language)}\n${lead.action.inLanguage(language)}',
      '${_avoidLabel.inLanguage(language)}\n${lead.avoid.inLanguage(language)}',
    ].join('\n\n');

    // Existing API requires an integer. This is a UI index of the sampled
    // lunar houses under the rules below, with no statistical interpretation.
    final samples = days.expand((day) => day).toList(growable: false);
    final score =
        samples.fold<int>(
          0,
          (total, moon) => total + _traditionalIndex(moon, rashiIndex),
        ) /
        samples.length;
    final devotion = _devotions[start.weekday - DateTime.monday];
    final ruler = _rulerForSign(rashiIndex);

    final reading = HoroscopeReading(
      rashiId: rashi.id,
      period: period,
      dateText: weekly
          ? '${_formatDate(start, language)} – '
                '${_formatDate(start.add(const Duration(days: 6)), language)}'
          : _formatDate(start, language),
      summary: body,
      career: weekly && lead != last
          ? '${lead.career.inLanguage(language)} ${last.career.inLanguage(language)}'
          : middle.career.inLanguage(language),
      health: middle.wellness.inLanguage(language),
      love: middle.relationships.inLanguage(language),
      luckyNumber: '${ruler.number}',
      luckyColor: ruler.color.inLanguage(language),
      remedy:
          '${ruler.remedy.inLanguage(language)}. ${_devotionalOption.inLanguage(language)}',
      // The summary already includes a specific What to avoid section.
      cautionTitle: '',
      cautionDetail: '',
      cautionWindow: '',
      timeSlots: TimeSlotForecast(
        morning: themeFor(representativeDay[0]).action.inLanguage(language),
        afternoon: middle.career.inLanguage(language),
        evening: themeFor(representativeDay[2]).relationships
            .inLanguage(language),
      ),
      compatibleRashi: '',
      cautionRashi: '',
      compatibilityTip: '',
      rulingDeity: devotion.deity.inLanguage(language),
      deityMantra: devotion.mantra.inLanguage(language),
      mantraBenefit: _devotionalReflection.inLanguage(language),
      auspiciousPercentage: score.round(),
      isAiGenerated: false,
    );
    return _HoroscopeContent(
      reading: reading,
      rashi: rashi,
      rashiIndex: rashiIndex,
      language: language,
      start: start,
      days: days,
      lead: lead,
      overview: overview,
    );
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

    final prompt =
        '''
You are an authentic, honest Vedic Astrologer (ज्येष्ठ ज्योतिषाचार्य).
A seeker has asked this personal life question:
Question: "$question"
Seeker Zodiac: ${rashi.nameMr} (${rashi.nameEn})
Ruling Planet: ${rashi.rulingPlanet}
Seeker Name Initial: ${initial ?? 'N/A'}
Language: $langName

Provide honest, compassionate, and uplifting Vedic astrological guidance:
1. Explain the planetary influence relevant to this matter (${rashi.rulingPlanet}).
2. Provide encouraging, practical, and solution-oriented advice that empowers the seeker.
3. Recommend an authentic Vedic remedy (Mantra, deed, or auspicious direction) to overcome obstacles.
4. Give a favorable window for action with positive spiritual reassurance.

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
      if (qLower.contains('नौकरी') ||
          qLower.contains('व्यवसाय') ||
          qLower.contains('job')) {
        return VedicAiConsultation(
          headline: 'कर्म भाव में ग्रहों की स्थिति अनुकूल; धैर्य से लिया निर्णय फलदायी होगा।',
          astrologicalAspect:
              '${rashi.planetShortName('hi')} के प्रभाव से कार्यक्षेत्र में नए अवसर और मान-सम्मान के योग बन रहे हैं।',
          guidance: 'हड़बड़ी में कोई नया अनुबंध न करें। वरिष्ठजनों की सलाह से कार्य में गति आएगी और रुका हुआ काम बनेगा।',
          remedy:
              'रोज सुबह सूर्य नमस्कार करें और "ॐ घृणि सूर्याय नमः" का जप करें।',
          favorableTiming:
              'सुबह ०९:०० से ११:३० का समय महत्वपूर्ण निर्णय के लिए उत्तम है।',
          isAiGenerated: false,
        );
      } else if (qLower.contains('विवाह') ||
          qLower.contains('शादी') ||
          qLower.contains('marriage')) {
        return VedicAiConsultation(
          headline: 'सप्तम भाव में शुभ ग्रहों की दृष्टि; विवाह संबंधी बातचीत में प्रगति के योग।',
          astrologicalAspect:
              'गुरु व ${rashi.planetShortName('hi')} के गोचर से रिश्ते तय होने के अनुकूल संकेत मिल रहे हैं।',
          guidance: 'संवाद में पारदर्शिता रखें। पारिवारिक समन्वय से लिए गए निर्णय दीर्घकालिक सुख देंगे।',
          remedy: 'गुरुवार को भगवान विष्णु या कुलदेवता को पीले पुष्प अर्पित कर प्रार्थना करें।',
          favorableTiming:
              'आगामी २ से ४ सप्ताह में शुभ समाचार मिलने की प्रबल संभावना है।',
          isAiGenerated: false,
        );
      } else if (qLower.contains('कर्ज') ||
          qLower.contains('धन') ||
          qLower.contains('पैसा') ||
          qLower.contains('finance')) {
        return VedicAiConsultation(
          headline: 'आर्थिक स्थिति में क्रमिक सुधार होगा; अनावश्यक खर्चों पर नियंत्रण रखें।',
          astrologicalAspect: 'द्वितीय व एकादश भाव के प्रभाव से धन आगमन के नए मार्ग प्रशस्त होंगे।',
          guidance: 'बड़ा निवेश सोच-समझकर करें। योजनाबद्ध तरीके से कर्ज मुक्ति का मार्ग निकलेगा।',
          remedy: 'प्रतिदिन श्री महालक्ष्मी अष्टकम् का पाठ करें व जरूरतमंद को अन्नदान करें।',
          favorableTiming:
              'दोपहर १२:०० से ०२:०० बजे आर्थिक योजनाओं के लिए शुभ रहेगा।',
          isAiGenerated: false,
        );
      }
      return VedicAiConsultation(
        headline: 'ग्रह स्थिति सकारात्मक दृष्टिकोण और एकाग्रता बनाए रखने का संकेत दे रही है।',
        astrologicalAspect:
            '${rashi.planetShortName('hi')} की कृपा से आपके प्रयासों को उचित दिशा व सफलता मिलेगी।',
        guidance: 'सकारात्मक सोच के साथ आगे बढ़ें। स्वास्थ्य का ध्यान रखें और मन को शांत रखने के लिए ध्यान करें।',
        remedy: 'हनुमान चालीसा का पाठ करें और घर में सुगंधित धूप जलाएं।',
        favorableTiming:
            'प्रातःकाल ०७:३० से १०:०० का समय अत्यंत शुभ व फलदायी है।',
        isAiGenerated: false,
      );
    }

    if (langCode == 'en') {
      if (qLower.contains('job') ||
          qLower.contains('career') ||
          qLower.contains('business')) {
        return VedicAiConsultation(
          headline: 'Planetary alignments favor steady progress in your professional sphere.',
          astrologicalAspect:
              'The transit of ${rashi.planetShortName('en')} indicates upcoming recognition and opportunities for advancement.',
          guidance: 'Avoid impulsive career changes. Seek counsel from mentors and maintain diplomatic relations with colleagues.',
          remedy: 'Offer water to the rising Sun daily and chant "Om Suryaya Namaha" 11 times.',
          favorableTiming: '09:00 AM to 11:30 AM is an auspicious window for major discussions.',
          isAiGenerated: false,
        );
      } else if (qLower.contains('marriage') ||
          qLower.contains('love') ||
          qLower.contains('relationship')) {
        return VedicAiConsultation(
          headline: 'Benefic planetary aspects bring harmony and auspicious matchmaking prospects.',
          astrologicalAspect: 'Influences on your 7th house suggest fruitful developments in relationship matters.',
          guidance: 'Prioritize open communication and mutual respect. Patience will help align the right life partnership.',
          remedy:
              'Light a pure ghee lamp before your family deity on Thursdays.',
          favorableTiming: 'Evenings between 05:00 PM and 07:30 PM favor positive family discussions.',
          isAiGenerated: false,
        );
      } else if (qLower.contains('debt') ||
          qLower.contains('money') ||
          qLower.contains('finance')) {
        return VedicAiConsultation(
          headline: 'Financial resilience will strengthen through disciplined budgeting.',
          astrologicalAspect: 'Aspects to your 2nd and 11th houses point towards gradual recovery of pending dues.',
          guidance: 'Avoid speculative ventures. Structured repayment plans will alleviate mental stress effectively.',
          remedy: 'Chant the sacred Lakshmi Gayatri Mantra 21 times at dusk.',
          favorableTiming:
              'The coming 2-3 weeks indicate favorable financial clarity.',
          isAiGenerated: false,
        );
      }
      return VedicAiConsultation(
        headline: 'Celestial currents encourage patience and focused devotion toward your goals.',
        astrologicalAspect:
            'The strength of ${rashi.planetShortName('en')} protects your endeavors from adverse planetary vibrations.',
        guidance: 'Maintain clarity of thought. Balance your physical wellbeing with daily mindful meditation.',
        remedy: 'Chant sacred Gayatri Mantra 11 times every morning.',
        favorableTiming: 'Early mornings (07:00 AM - 09:30 AM) radiate maximum auspicious energy.',
        isAiGenerated: false,
      );
    }

    // Default Marathi
    if (qLower.contains('नोकरी') ||
        qLower.contains('व्यवसाय') ||
        qLower.contains('job') ||
        qLower.contains('career')) {
      return VedicAiConsultation(
        headline: 'कर्मस्थानी ग्रहांचे संक्रमण अनुकूल; संयमाने घेतलेला निर्णय लाभदायक ठरेल.',
        astrologicalAspect:
            '${rashi.rulingPlanet} च्या संक्रमणामुळे आगामी काळात कार्यक्षेत्रात नवी संधी व सन्मान मिळण्याचे योग आहेत.',
        guidance: 'नवीन संधीचे स्वागत करताना घाईगडबड न करता सहकाऱ्यांशी योग्य समन्वय ठेवा. वरिष्ठ व्यक्तींचा सल्ला घेतल्यास कामात गती येईल.',
        remedy: 'रोज सकाळी सूर्यदेवाला अर्घ्य देऊन "ॐ सूर्याय नमः" चा ११ वेळा जप करावा.',
        favorableTiming: 'सकाळी ०९:०० ते १२:०० ही वेळ महत्त्वपूर्ण चर्चा व निर्णयांसाठी शुभ राहील.',
        isAiGenerated: false,
      );
    } else if (qLower.contains('विवाह') ||
        qLower.contains('लग्ना') ||
        qLower.contains('marriage')) {
      return VedicAiConsultation(
        headline: 'सप्तम भावातील ग्रहांची दृष्टी शुभ; योग्य स्थळांचे योग लवकरच जुळतील.',
        astrologicalAspect:
            'गुरु व ${rashi.rulingPlanet} च्या कृपेने वैवाहिक चर्चेत सकारात्मक प्रगती होण्याची शक्यता आहे.',
        guidance: 'नात्यांमध्ये संवाद आणि परस्पर समजूतदारपणा ठेवा. घरातील वडीलधाऱ्यांचा सल्ला घेऊनच निर्णय घ्यावा.',
        remedy: 'दर गुरुवारी कुलदेवतेसमोर तुपाचा दिवा लावून प्रार्थना करावी व पिवळ्या फुलांचे अर्पण करावे.',
        favorableTiming: 'संध्याकाळी ०५:०० ते ०७:३० दरम्यान अनुकूल चर्चा व भेटीगाठी होऊ शकतात.',
        isAiGenerated: false,
      );
    } else if (qLower.contains('कर्ज') ||
        qLower.contains('धन') ||
        qLower.contains('पैसा') ||
        qLower.contains('finance')) {
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
      headline:
          'ग्रहस्थिती संयम आणि आत्मविश्वासाने पुढे जाण्याची प्रेरणा देत आहे.',
      astrologicalAspect:
          '${rashi.rulingPlanet} च्या प्रभावामुळे आपल्या प्रयत्नांना योग्य फळ मिळण्याचे शुभ योग आहेत.',
      guidance: 'सकारात्मक विचार आणि योग्य दिनचर्या ठेवा. आरोग्याकडे दुर्लक्ष न करता रोज थोडे ध्यान केल्यास मानसिक शांतता लाभेल.',
      remedy: 'दर मंगळवारी किंवा शनिवारी श्री हनुमान चालीसा पठण करावे.',
      favorableTiming: 'सकाळी ०७:३० ते १०:३० ही वेळ अत्यंत मंगलकारी राहील.',
      isAiGenerated: false,
    );
  }
}

const _istOffset = Duration(hours: 5, minutes: 30);

DateTime _calendarDayInIndia(DateTime instant) {
  final india = instant.toUtc().add(_istOffset);
  return DateTime.utc(india.year, india.month, india.day);
}

DateTime _periodStart(DateTime today, String period) => switch (period) {
  'today' => today,
  'tomorrow' => today.add(const Duration(days: 1)),
  'weekly' => today.subtract(Duration(days: today.weekday - DateTime.monday)),
  _ => throw ArgumentError.value(
    period,
    'period',
    'Use today, tomorrow, or weekly',
  ),
};

String _isoDate(DateTime date) => date.toIso8601String().split('T').first;

String _language(String code) {
  final base = code.trim().toLowerCase().split(RegExp(r'[-_]')).first;
  return switch (base) {
    'hi' => 'hi',
    'mr' => 'mr',
    _ => 'en',
  };
}

class _LocalizedText {
  const _LocalizedText(this.en, this.hi, this.mr);

  final String en;
  final String hi;
  final String mr;

  String inLanguage(String language) => switch (language) {
    'hi' => hi,
    'mr' => mr,
    _ => en,
  };
}

const _rashiAliases = [
  ['aries', 'mesha', 'mesh', 'मेष'],
  [
    'taurus',
    'vrishabha',
    'vrishabh',
    'vrushabha',
    'vrushabh',
    'rishabha',
    'वृषभ',
  ],
  ['gemini', 'mithuna', 'mithun', 'मिथुन'],
  ['cancer', 'karka', 'kark', 'karkata', 'karkat', 'कर्क', 'कर्कट'],
  ['leo', 'simha', 'simh', 'sinha', 'sinh', 'सिंह'],
  ['virgo', 'kanya', 'कन्या'],
  ['libra', 'tula', 'तुला', 'तूळ', 'तुळ'],
  ['scorpio', 'vrishchika', 'vrishchik', 'vrushchika', 'vrushchik', 'वृश्चिक'],
  ['sagittarius', 'dhanu', 'dhanus', 'धनु', 'धनू'],
  ['capricorn', 'makara', 'makar', 'मकर'],
  ['aquarius', 'kumbha', 'kumbh', 'कुंभ', 'कुम्भ'],
  ['pisces', 'meena', 'meen', 'mina', 'मीन'],
];

int _indexOfRashi(Rashi rashi) {
  for (final value in [rashi.nameEn, rashi.nameHi, rashi.nameMr, rashi.id]) {
    final words = value.toString().trim().toLowerCase().split(
      RegExp(r'[^a-z\u0900-\u097f]+'),
    );
    final index = _rashiAliases.indexWhere(
      (aliases) => words.any(aliases.contains),
    );
    if (index >= 0) return index;
  }
  throw ArgumentError.value(rashi.id, 'rashi', 'Unknown Janma Rashi');
}

const _months = [
  _LocalizedText('Jan', 'जनवरी', 'जानेवारी'),
  _LocalizedText('Feb', 'फरवरी', 'फेब्रुवारी'),
  _LocalizedText('Mar', 'मार्च', 'मार्च'),
  _LocalizedText('Apr', 'अप्रैल', 'एप्रिल'),
  _LocalizedText('May', 'मई', 'मे'),
  _LocalizedText('Jun', 'जून', 'जून'),
  _LocalizedText('Jul', 'जुलाई', 'जुलै'),
  _LocalizedText('Aug', 'अगस्त', 'ऑगस्ट'),
  _LocalizedText('Sep', 'सितंबर', 'सप्टेंबर'),
  _LocalizedText('Oct', 'अक्टूबर', 'ऑक्टोबर'),
  _LocalizedText('Nov', 'नवंबर', 'नोव्हेंबर'),
  _LocalizedText('Dec', 'दिसंबर', 'डिसेंबर'),
];

String _formatDate(DateTime day, String language) =>
    '${day.day} ${_months[day.month - 1].inLanguage(language)} ${day.year}';

class _MoonSample {
  const _MoonSample({
    required this.sign,
    required this.nakshatra,
    required this.waxing,
  });

  final int sign;
  final int nakshatra;
  final bool waxing;
}

List<_MoonSample> _sampleMoon(
  DateTime indiaDay,
  HoroscopeEphemeris ephemeris,
) => [
  for (final minutes in [9 * 60, 14 * 60 + 30, 19 * 60 + 30])
    _moonAt(
      indiaDay.add(Duration(minutes: minutes)).subtract(_istOffset),
      ephemeris,
    ),
];

_MoonSample _moonAt(DateTime utc, HoroscopeEphemeris ephemeris) {
  final positions = ephemeris.siderealLongitudes(utc);
  final moon = _degrees(positions.moon);
  final elongation = _degrees(moon - positions.sun);
  return _MoonSample(
    sign: (moon / 30).floor(),
    nakshatra: (moon / (360 / 27)).floor().clamp(0, 26),
    waxing: elongation < 180,
  );
}

class _ApproximateLahiriEphemeris extends HoroscopeEphemeris {
  const _ApproximateLahiriEphemeris();

  @override
  String get name => 'Meeus / approximate Lahiri';

  @override
  ({double sun, double moon}) siderealLongitudes(DateTime timeUtc) {
    final utcDays =
        timeUtc.difference(_j2000Utc).inMicroseconds /
        Duration.microsecondsPerDay;
    // TT is approximately UTC + 69 seconds for present-day civil dates.
    final t = (utcDays + 69.184 / Duration.secondsPerDay) / 36525;
    final ayanamsa = _lahiriAyanamsa(t);
    return (
      sun: _degrees(_sunLongitude(t) - ayanamsa),
      moon: _degrees(_moonLongitude(t) - ayanamsa),
    );
  }
}

final _j2000Utc = DateTime.utc(2000, 1, 1, 12);
const _rad = math.pi / 180;

double _degrees(double value) => value % 360;
double _sinDegrees(double angle) => math.sin(_degrees(angle) * _rad);

// Approximate Lahiri using its J2000 anchor and IAU 2006 general precession.
double _lahiriAyanamsa(double t) =>
    23 + 51 / 60 + (25.532 + t * (5028.796195 + 1.1054348 * t)) / 3600;

// Meeus, Astronomical Algorithms (2nd ed.), chapter 25. Mean equinox of date.
double _sunLongitude(double t) {
  final meanLongitude = 280.46646 + t * (36000.76983 + 0.0003032 * t);
  final anomaly = 357.52911 + t * (35999.05029 - 0.0001537 * t);
  return _degrees(
    meanLongitude +
        (1.914602 - t * (0.004817 + 0.000014 * t)) * _sinDegrees(anomaly) +
        (0.019993 - 0.000101 * t) * _sinDegrees(2 * anomaly) +
        0.000289 * _sinDegrees(3 * anomaly),
  );
}

// Meeus, chapter 47 and Table 47.A. Geocentric longitude, mean equinox of date.
double _moonLongitude(double t) {
  final meanLongitude = _degrees(
    218.3164477 +
        t *
            (481267.88123421 +
                t * (-0.0015786 + t * (1 / 538841 - t / 65194000))),
  );
  final elongation = _degrees(
    297.8501921 +
        t *
            (445267.1114034 +
                t * (-0.0018819 + t * (1 / 545868 - t / 113065000))),
  );
  final sunAnomaly = _degrees(
    357.5291092 + t * (35999.0502909 + t * (-0.0001536 + t / 24490000)),
  );
  final moonAnomaly = _degrees(
    134.9633964 +
        t * (477198.8675055 + t * (0.0087414 + t * (1 / 69699 - t / 14712000))),
  );
  final latitudeArgument = _degrees(
    93.2720950 +
        t *
            (483202.0175233 +
                t * (-0.0036539 + t * (-1 / 3526000 + t / 863310000))),
  );
  final eccentricity = 1 - t * (0.002516 + 0.0000074 * t);
  var correction =
      3958 * _sinDegrees(119.75 + 131.849 * t) +
      1962 * _sinDegrees(meanLongitude - latitudeArgument) +
      318 * _sinDegrees(53.09 + 479264.29 * t);
  for (final (d, m, mp, f, coefficient) in _longitudeTerms) {
    final factor = switch (m.abs()) {
      1 => eccentricity,
      2 => eccentricity * eccentricity,
      _ => 1.0,
    };
    final argument =
        d * elongation +
        m * sunAnomaly +
        mp * moonAnomaly +
        f * latitudeArgument;
    correction += coefficient * factor * _sinDegrees(argument);
  }
  return _degrees(meanLongitude + correction / 1000000);
}

// Multipliers of (D, M, M′, F), followed by microdegrees of longitude.
const _longitudeTerms = [
  (0, 0, 1, 0, 6288774),
  (2, 0, -1, 0, 1274027),
  (2, 0, 0, 0, 658314),
  (0, 0, 2, 0, 213618),
  (0, 1, 0, 0, -185116),
  (0, 0, 0, 2, -114332),
  (2, 0, -2, 0, 58793),
  (2, -1, -1, 0, 57066),
  (2, 0, 1, 0, 53322),
  (2, -1, 0, 0, 45758),
  (0, 1, -1, 0, -40923),
  (1, 0, 0, 0, -34720),
  (0, 1, 1, 0, -30383),
  (2, 0, 0, -2, 15327),
  (0, 0, 1, 2, -12528),
  (0, 0, 1, -2, 10980),
  (4, 0, -1, 0, 10675),
  (0, 0, 3, 0, 10034),
  (4, 0, -2, 0, 8548),
  (2, 1, -1, 0, -7888),
  (2, 1, 0, 0, -6766),
  (1, 0, -1, 0, -5163),
  (1, 1, 0, 0, 4987),
  (2, -1, 1, 0, 4036),
  (2, 0, 2, 0, 3994),
  (4, 0, 0, 0, 3861),
  (2, 0, -3, 0, 3665),
  (0, 1, -2, 0, -2689),
  (2, 0, -1, 2, -2602),
  (2, -1, -2, 0, 2390),
  (1, 0, 1, 0, -2348),
  (2, -2, 0, 0, 2236),
  (0, 1, 2, 0, -2120),
  (0, 2, 0, 0, -2069),
  (2, -2, -1, 0, 2048),
  (2, 0, 1, -2, -1773),
  (2, 0, 0, 2, -1595),
  (4, -1, -1, 0, 1215),
  (0, 0, 2, 2, -1110),
  (3, 0, -1, 0, -892),
  (2, 1, 1, 0, -810),
  (4, -1, -2, 0, 759),
  (0, 2, -1, 0, -713),
  (2, 2, -1, 0, -700),
  (2, 1, -2, 0, 691),
  (2, -1, 0, -2, 596),
  (4, 0, 1, 0, 549),
  (0, 0, 4, 0, 537),
  (4, -1, 0, 0, 520),
  (1, 0, -2, 0, -487),
  (2, 1, 0, -2, -399),
  (0, 0, 2, -2, -381),
  (1, 1, 1, 0, 351),
  (3, 0, -2, 0, -340),
  (4, 0, -3, 0, 330),
  (2, -1, 2, 0, 327),
  (0, 2, 1, 0, -323),
  (1, 1, -1, 0, 299),
  (2, 0, 3, 0, 294),
];

int _traditionalIndex(_MoonSample moon, int rashiIndex) {
  final house = (moon.sign - rashiIndex) % 12 + 1;
  if (const {1, 3, 6, 7, 10, 11}.contains(house)) return 80;
  final phaseSupportsHouse = moon.waxing
      ? const {2, 5, 9}.contains(house)
      : const {4, 8, 12}.contains(house);
  return phaseSupportsHouse ? 72 : 64;
}

class _HouseReading {
  const _HouseReading({
    required this.topic,
    required this.outlook,
    required this.action,
    required this.avoid,
    required this.career,
    required this.wellness,
    required this.relationships,
  });

  final _LocalizedText topic;
  final _LocalizedText outlook;
  final _LocalizedText action;
  final _LocalizedText avoid;
  final _LocalizedText career;
  final _LocalizedText wellness;
  final _LocalizedText relationships;
}

const _doLabel = _LocalizedText('What to do', 'क्या करें', 'काय करावे');
const _avoidLabel = _LocalizedText(
  'What to avoid',
  'क्या न करें',
  'काय टाळावे',
);

String _weekOutlook(
  _HouseReading first,
  _HouseReading middle,
  _HouseReading last,
  String language,
) {
  final early = first.topic.inLanguage(language);
  final midweek = middle.topic.inLanguage(language);
  final weekend = last.topic.inLanguage(language);
  return switch (language) {
    'hi' =>
      'सप्ताह की शुरुआत में $early पर ध्यान रहेगा। सप्ताह के बीच में '
          '$midweek और सप्ताहांत में $weekend के लिए समय निकालें।',
    'mr' =>
      'आठवड्याच्या सुरुवातीला $early यावर भर राहील. मध्यावर '
          '$midweek आणि शेवटी $weekend यासाठी वेळ द्या.',
    _ =>
      'Early in the week, focus on $early. Make room for $midweek '
          'around midweek and for $weekend over the weekend.',
  };
}

String _shiftOutlook(
  _HouseReading morning,
  _HouseReading evening,
  String language,
) {
  final before = morning.topic.inLanguage(language);
  final later = evening.topic.inLanguage(language);
  return switch (language) {
    'hi' => 'सुबह $before को समय दें। शाम तक $later पर ध्यान जा सकता है।',
    'mr' =>
      'सकाळी $before यासाठी वेळ द्या. संध्याकाळी $later याकडे लक्ष जाऊ शकते.',
    _ => 'Start with $before. By evening, your focus may turn to $later.',
  };
}

// Nakshatra-lord cycle, starting with Ashwini (Ketu). These are editorial prompts
// for reflection. The index is calculated from the Moon's sidereal longitude.
const _nakshatraNotes = [
  _LocalizedText(
    'Leave a little room to work independently.',
    'अपने ढंग से काम करने के लिए थोड़ा समय रखें।',
    'स्वतःच्या पद्धतीने काम करण्यासाठी थोडा वेळ ठेवा.',
  ),
  _LocalizedText(
    'Give one activity you enjoy your full attention.',
    'अपनी पसंद की किसी एक गतिविधि को पूरा समय दें।',
    'आवडीच्या एखाद्या गोष्टीला निवांत वेळ द्या.',
  ),
  _LocalizedText(
    'Set a clear priority and take ownership of the next step.',
    'अपनी प्राथमिकता तय करें और अगला कदम खुद उठाएँ।',
    'आपले प्राधान्य ठरवा आणि पुढचे पाऊल स्वतः उचला.',
  ),
  _LocalizedText(
    'Give familiar routines and close connections some unhurried time.',
    'अपनी दिनचर्या और करीबी लोगों के लिए थोड़ा सुकून भरा समय रखें।',
    'दिनक्रमासाठी आणि जवळच्या माणसांसाठी निवांत वेळ काढा.',
  ),
  _LocalizedText(
    'A small hands-on effort can help you get started.',
    'खुद किया हुआ छोटा प्रयास शुरुआत को आसान बना सकता है।',
    'स्वतः केलेला छोटा प्रयत्न सुरुवात सोपी करू शकतो.',
  ),
  _LocalizedText(
    'Try one new approach on a manageable scale.',
    'कोई नया तरीका छोटे स्तर पर आज़माएँ।',
    'एखादी नवी पद्धत छोट्या प्रमाणावर आजमावा.',
  ),
  _LocalizedText(
    'A thoughtful question can give you a broader perspective.',
    'सोच-समझकर पूछा गया एक सवाल नया नज़रिया दे सकता है।',
    'विचारपूर्वक विचारलेला एक प्रश्न नवी दृष्टी देऊ शकतो.',
  ),
  _LocalizedText(
    'Give your attention to one commitment you can realistically finish.',
    'उस एक ज़िम्मेदारी पर ध्यान दें जिसे आप पूरा कर सकते हैं।',
    'पूर्ण करता येईल अशा एका जबाबदारीवर लक्ष केंद्रित करा.',
  ),
  _LocalizedText(
    'Writing down a decision can make the next step clearer.',
    'किसी फैसले को लिख लेने से अगला कदम साफ़ हो सकता है।',
    'निर्णय लिहून ठेवल्याने पुढचे पाऊल स्पष्ट होऊ शकते.',
  ),
];

const _devotionalOption = _LocalizedText(
  'If it is part of your practice, set aside a quiet moment for prayer.',
  'अपनी श्रद्धा के अनुसार कुछ समय प्रार्थना के लिए रखें।',
  'आपल्या श्रद्धेनुसार काही वेळ प्रार्थनेसाठी ठेवा.',
);
const _devotionalReflection = _LocalizedText(
  'Use the chant as a moment of reflection.',
  'जप के लिए कुछ शांत पल निकालें।',
  'जपासाठी काही शांत क्षण राखून ठेवा.',
);

const _devotions = [
  (
    deity: _LocalizedText('Shiva', 'भगवान शिव', 'भगवान शिव'),
    mantra: _LocalizedText('Om Namah Shivaya', 'ॐ नमः शिवाय', 'ॐ नमः शिवाय'),
  ),
  (
    deity: _LocalizedText('Hanuman', 'श्री हनुमान', 'श्री हनुमान'),
    mantra: _LocalizedText('Om Hanumate Namah', 'ॐ हनुमते नमः', 'ॐ हनुमते नमः'),
  ),
  (
    deity: _LocalizedText('Ganesha', 'श्री गणेश', 'श्री गणेश'),
    mantra: _LocalizedText(
      'Om Gam Ganapataye Namah',
      'ॐ गं गणपतये नमः',
      'ॐ गं गणपतये नमः',
    ),
  ),
  (
    deity: _LocalizedText('Vishnu', 'भगवान विष्णु', 'भगवान विष्णू'),
    mantra: _LocalizedText(
      'Om Namo Narayanaya',
      'ॐ नमो नारायणाय',
      'ॐ नमो नारायणाय',
    ),
  ),
  (
    deity: _LocalizedText('Lakshmi', 'माँ लक्ष्मी', 'महालक्ष्मी'),
    mantra: _LocalizedText(
      'Om Shri Mahalakshmyai Namah',
      'ॐ श्री महालक्ष्म्यै नमः',
      'ॐ श्री महालक्ष्म्यै नमः',
    ),
  ),
  (
    deity: _LocalizedText('Shani', 'शनिदेव', 'शनिदेव'),
    mantra: _LocalizedText(
      'Om Shanaishcharaya Namah',
      'ॐ शनैश्चराय नमः',
      'ॐ शनैश्चराय नमः',
    ),
  ),
  (
    deity: _LocalizedText('Surya', 'सूर्यदेव', 'सूर्यदेव'),
    mantra: _LocalizedText(
      'Om Suryaya Namah',
      'ॐ सूर्याय नमः',
      'ॐ सूर्याय नमः',
    ),
  ),
];

// Whole-sign houses counted from the selected birth Moon sign. Text is
// authored in each language so the same calculation works completely offline.
const _houseReadings = [
  _HouseReading(
    topic: _LocalizedText(
      'personal priorities',
      'अपनी प्राथमिकताओं',
      'स्वतःच्या प्राधान्यक्रम',
    ),
    outlook: _LocalizedText(
      'You may find it easier to decide what deserves your attention. A small task you take ownership of can set the pace for the rest of the day.',
      'अपनी प्राथमिकताएँ तय करना आसान हो सकता है। जिस काम की शुरुआत आप खुद करेंगे, उसी से दिन को अच्छी दिशा मिल सकती है।',
      'स्वतःची प्राधान्ये ठरवणे सोपे जाऊ शकते. स्वतःहून हाती घेतलेले एखादे काम दिवसाला चांगली दिशा देऊ शकते.',
    ),
    action: _LocalizedText(
      'Start the task you have been putting off.',
      'जिस काम को टाल रहे हैं, उसकी शुरुआत करें।',
      'लांबणीवर पडलेले एखादे काम सुरू करा.',
    ),
    avoid: _LocalizedText(
      'Avoid scheduling several commitments for the same time.',
      'एक ही समय पर कई काम तय न करें।',
      'सकाळी एकाच वेळेस अनेक कामे ठरवू नका.',
    ),
    career: _LocalizedText(
      'Give your team a short update on one result you own.',
      'जिस काम की ज़िम्मेदारी आपकी है, उसकी प्रगति टीम को बताएँ।',
      'आपल्या जबाबदारीतील कामाची प्रगती सहकाऱ्यांना सांगा.',
    ),
    wellness: _LocalizedText(
      'Take a short break after your first block of focused work.',
      'लगातार काम के पहले दौर के बाद थोड़ा आराम करें।',
      'सलग कामाच्या पहिल्या टप्प्यानंतर थोडी विश्रांती घ्या.',
    ),
    relationships: _LocalizedText(
      'Tell someone close to you what kind of help would be useful.',
      'किसी करीबी को साफ़ बताएँ कि आपको किस तरह की मदद चाहिए।',
      'तुम्हाला कोणत्या प्रकारची मदत हवी आहे, हे जवळच्या व्यक्तीला सांगा.',
    ),
  ),
  _HouseReading(
    topic: _LocalizedText('household spending', 'घर के खर्च', 'घरखर्च'),
    outlook: _LocalizedText(
      'The pace may be steady. A practical conversation about shared spending or household plans can clear up a decision that has been lingering.',
      'दिन सहज गति से आगे बढ़ सकता है। घर के खर्च या किसी साझा योजना पर बात करने से अटका हुआ फैसला आसान हो सकता है।',
      'दिवसाची गती स्थिर राहू शकते. घरखर्च किंवा एखाद्या सामायिक योजनेवर बोलल्याने रखडलेला निर्णय घेणे सोपे जाऊ शकते.',
    ),
    action: _LocalizedText(
      'Look through your upcoming bills and household plans.',
      'आने वाले बिल और घर की योजनाएँ एक बार देख लें।',
      'येणारी बिले आणि घरातील नियोजन एकदा पाहून घ्या.',
    ),
    avoid: _LocalizedText(
      'Leave optional purchases for when you have checked what you already have.',
      'घर में क्या है, यह देखे बिना अतिरिक्त खरीदारी न करें।',
      'घरात काय आहे हे पाहिल्याशिवाय जादा खरेदी करू नका.',
    ),
    career: _LocalizedText(
      'Confirm the quantities and dates in a quote or request.',
      'किसी ऑर्डर या अनुरोध की मात्रा और तारीख की पुष्टि करें।',
      'एखाद्या मागणीतील प्रमाण आणि तारीख पुन्हा तपासा.',
    ),
    wellness: _LocalizedText(
      'Make time to eat without working through your meal.',
      'भोजन के समय काम से थोड़ा विराम लें।',
      'जेवताना कामातून थोडी विश्रांती घ्या.',
    ),
    relationships: _LocalizedText(
      'Ask what the household needs before making a shared plan.',
      'घर की साझा योजना तय करने से पहले सबकी ज़रूरत पूछें।',
      'घरातील सामायिक योजना ठरवण्यापूर्वी प्रत्येकाची गरज जाणून घ्या.',
    ),
  ),
  _HouseReading(
    topic: _LocalizedText(
      'conversations and follow-ups',
      'बातचीत और लंबित जवाबों',
      'संवाद आणि पाठपुरावा',
    ),
    outlook: _LocalizedText(
      'A call or a well-timed follow-up may get things moving. Short conversations are likely to be more useful than a packed schedule.',
      'किसी को फ़ोन करने या समय पर जवाब माँगने से अटका काम आगे बढ़ सकता है। छोटी और स्पष्ट बातचीत ज़्यादा काम आ सकती है।',
      'एखादा फोन किंवा वेळेवर घेतलेला पाठपुरावा रखडलेले काम पुढे नेऊ शकतो. थोडक्यात आणि स्पष्ट बोलणे उपयोगी ठरू शकते.',
    ),
    action: _LocalizedText(
      'Call the person who can answer your open question.',
      'उस व्यक्ति को फ़ोन करें जो आपके सवाल का जवाब दे सकता है।',
      'तुमच्या प्रश्नाचे उत्तर देऊ शकणाऱ्या व्यक्तीला फोन करा.',
    ),
    avoid: _LocalizedText(
      'Avoid sending several messages where one clear request would do.',
      'जहाँ एक साफ़ संदेश काफ़ी हो, वहाँ बार-बार संदेश न भेजें।',
      'एक स्पष्ट संदेश पुरेसा असेल तर वारंवार संदेश पाठवू नका.',
    ),
    career: _LocalizedText(
      'Close one handoff by agreeing on who will do what and by when.',
      'काम सौंपते समय तय करें कि कौन क्या करेगा और कब तक करेगा।',
      'काम सोपवताना कोण काय आणि कधीपर्यंत करणार ते ठरवा.',
    ),
    wellness: _LocalizedText(
      'Step away from messages for a short walk.',
      'संदेशों से थोड़ी देर दूर होकर टहल लें।',
      'संदेशांपासून थोडा विराम घेऊन फेरफटका मारा.',
    ),
    relationships: _LocalizedText(
      'Check in with a sibling or friend you have not heard from recently.',
      'किसी भाई, बहन या दोस्त का हाल पूछें जिससे हाल में बात नहीं हुई।',
      'बऱ्याच दिवसांत बोलणे झाले नाही अशा भावंडाची किंवा मित्राची विचारपूस करा.',
    ),
  ),
  _HouseReading(
    topic: _LocalizedText(
      'home and family routines',
      'घर और परिवार की दिनचर्या',
      'घर आणि कुटुंबाचा दिनक्रम',
    ),
    outlook: _LocalizedText(
      'Home and familiar routines may need a little more of your time. Sorting out one domestic matter could make the rest of the day feel less crowded.',
      'घर और परिवार की दिनचर्या पर कुछ अतिरिक्त समय देना पड़ सकता है। घर का एक लंबित काम निपटने से बाकी दिन हल्का लग सकता है।',
      'घर आणि कुटुंबाच्या दिनक्रमासाठी थोडा जास्त वेळ द्यावा लागू शकतो. घरातील एक रखडलेले काम उरकल्याने बाकीचा दिवस मोकळा वाटू शकतो.',
    ),
    action: _LocalizedText(
      'Resolve one small task at home or make time to listen to a family member.',
      'घर का एक छोटा काम पूरा करें या किसी परिजन की बात सुनने के लिए समय निकालें।',
      'घरातील एखादे छोटे काम उरका किंवा कुटुंबातील एखाद्याचे निवांत ऐका.',
    ),
    avoid: _LocalizedText(
      'Keep some space between errands and work calls.',
      'घर के काम और दफ़्तर की कॉल एक ही समय पर न रखें।',
      'घरची कामे आणि कार्यालयातील फोन एकाच वेळेस ठरवू नका.',
    ),
    career: _LocalizedText(
      'Block out one stretch of uninterrupted time for work that needs attention.',
      'ध्यान माँगने वाले काम के लिए बिना रुकावट वाला समय तय करें।',
      'लक्ष देऊन कराव्या लागणाऱ्या कामासाठी सलग वेळ राखून ठेवा.',
    ),
    wellness: _LocalizedText(
      'Give yourself a quiet break between work and household tasks.',
      'काम और घरेलू ज़िम्मेदारियों के बीच थोड़ा आराम करें।',
      'कार्यालयीन आणि घरच्या कामांदरम्यान थोडी विश्रांती घ्या.',
    ),
    relationships: _LocalizedText(
      'Let a family conversation continue at its own pace.',
      'घर की बातचीत में सामने वाले को अपनी बात पूरी करने दें।',
      'घरातील संभाषणात समोरच्याला आपले म्हणणे पूर्ण करू द्या.',
    ),
  ),
  _HouseReading(
    topic: _LocalizedText(
      'creativity and learning',
      'रचनात्मक काम और सीखने',
      'सर्जनशील काम आणि शिकणे',
    ),
    outlook: _LocalizedText(
      'A new way of approaching a familiar task may come to mind. There is room to experiment with an idea and see what it can become.',
      'किसी परिचित काम को करने का नया तरीका सूझ सकता है। छोटे स्तर पर किसी विचार को आज़माने के लिए दिन में गुंजाइश रहेगी।',
      'ओळखीचे काम करण्याची नवी पद्धत सुचू शकते. एखादी कल्पना छोट्या प्रमाणावर आजमावण्यासाठी वेळ मिळू शकतो.',
    ),
    action: _LocalizedText(
      'Put a rough version of your idea on paper.',
      'अपने विचार का पहला रूप कागज़ पर उतारें।',
      'आपल्या कल्पनेचा प्राथमिक आराखडा कागदावर उतरवा.',
    ),
    avoid: _LocalizedText(
      'Keep the first draft simple and skip polishing it too early.',
      'पहले मसौदे को शुरू से ही बिल्कुल सही बनाने में न उलझें।',
      'पहिलाच मसुदा निर्दोष करण्याच्या प्रयत्नात अडकू नका.',
    ),
    career: _LocalizedText(
      'Show a small prototype and ask one specific question about it.',
      'एक छोटा नमूना दिखाएँ और उस पर एक साफ़ सवाल पूछें।',
      'एक छोटा नमुना दाखवा आणि त्याबद्दल एक नेमका प्रश्न विचारा.',
    ),
    wellness: _LocalizedText(
      'Make room for a hobby you enjoy for its own sake.',
      'किसी ऐसे शौक के लिए समय रखें जिसे करने में आपको आनंद आता है।',
      'निखळ आनंद देणाऱ्या एखाद्या छंदासाठी वेळ काढा.',
    ),
    relationships: _LocalizedText(
      'Share an activity you both enjoy or ask about someone’s current interest.',
      'साथ में कोई पसंदीदा काम करें या किसी की नई रुचि के बारे में पूछें।',
      'आवडीची एखादी गोष्ट एकत्र करा किंवा समोरच्याच्या नव्या आवडीची चौकशी करा.',
    ),
  ),
  _HouseReading(
    topic: _LocalizedText(
      'routine tasks and follow-through',
      'रोज़मर्रा के कामों और लंबित ज़िम्मेदारियों',
      'दैनंदिन आणि प्रलंबित कामे',
    ),
    outlook: _LocalizedText(
      'An ordinary workday can turn productive once you clear a small backlog. An organised routine gives you room for the work you value most.',
      'दिन साधारण ढंग से शुरू हो सकता है। कुछ छोटे लंबित काम निपटाने से ज़रूरी काम के लिए समय निकल सकता है।',
      'दिवस नेहमीसारखा सुरू होऊ शकतो. काही छोटी प्रलंबित कामे उरकल्याने महत्त्वाच्या कामासाठी मोकळा वेळ मिळू शकतो.',
    ),
    action: _LocalizedText(
      'Set a short timer and clear one group of similar tasks.',
      'थोड़ा समय तय करके एक जैसे कुछ लंबित काम पूरे करें।',
      'ठरावीक वेळ राखून एकाच प्रकारची काही प्रलंबित कामे पूर्ण करा.',
    ),
    avoid: _LocalizedText(
      'Avoid reorganising your entire routine in one sitting.',
      'एक ही बार में पूरी दिनचर्या बदलने की कोशिश न करें।',
      'एकाच बैठकीत संपूर्ण दिनक्रम बदलण्याचा प्रयत्न करू नका.',
    ),
    career: _LocalizedText(
      'Fix the recurring issue that causes the most rework.',
      'उस बार-बार आने वाली दिक्कत को ठीक करें जिससे सबसे ज़्यादा दोबारा काम करना पड़ता है।',
      'ज्या अडचणीमुळे काम पुन्हा करावे लागते, ती आधी सोडवा.',
    ),
    wellness: _LocalizedText(
      'Keep a water break in your schedule when tasks stack up.',
      'काम बढ़ने पर बीच में पानी पीने का समय भी रखें।',
      'कामे वाढली तरी मध्ये पाणी पिण्यासाठी वेळ ठेवा.',
    ),
    relationships: _LocalizedText(
      'Offer help with a concrete task someone is already handling.',
      'किसी करीबी के हाथ में जो काम है, उसमें एक ठोस मदद दें।',
      'जवळच्या व्यक्तीच्या हातातील एखाद्या कामात नेमकी मदत द्या.',
    ),
  ),
  _HouseReading(
    topic: _LocalizedText('shared decisions', 'साझा फैसलों', 'सामायिक निर्णय'),
    outlook: _LocalizedText(
      'A one-to-one conversation could move a shared decision forward. There may be more common ground once both sides state what they need.',
      'आमने-सामने की बातचीत से कोई साझा फैसला आगे बढ़ सकता है। अपनी ज़रूरतें खुलकर रखने पर बीच का रास्ता मिलने की गुंजाइश है।',
      'समोरासमोरच्या बोलण्यातून एखादा सामायिक निर्णय पुढे जाऊ शकतो. दोघांनी आपापल्या गरजा मांडल्यावर मधला मार्ग सापडू शकतो.',
    ),
    action: _LocalizedText(
      'Agree on one next step with the person involved.',
      'संबंधित व्यक्ति के साथ मिलकर अगला एक कदम तय करें।',
      'संबंधित व्यक्तीबरोबर पुढचे एक पाऊल ठरवा.',
    ),
    avoid: _LocalizedText(
      'Avoid committing on behalf of someone else.',
      'किसी और की ओर से वादा न करें।',
      'दुसऱ्याच्या वतीने शब्द देऊ नका.',
    ),
    career: _LocalizedText(
      'Write down the agreement after a meeting with a client or teammate.',
      'ग्राहक या सहकर्मी से बात के बाद तय हुई बातें लिख लें।',
      'ग्राहक किंवा सहकाऱ्याशी बोलल्यानंतर ठरलेल्या गोष्टी लिहून ठेवा.',
    ),
    wellness: _LocalizedText(
      'Leave a little space between meetings so you can reset.',
      'दो मुलाकातों के बीच थोड़ा खाली समय रखें।',
      'दोन भेटींमध्ये थोडा मोकळा वेळ ठेवा.',
    ),
    relationships: _LocalizedText(
      'Make a plan that gives each person a clear say.',
      'योजना बनाते समय दोनों की पसंद को जगह दें।',
      'योजना ठरवताना दोघांच्या पसंतीला जागा द्या.',
    ),
  ),
  _HouseReading(
    topic: _LocalizedText(
      'pending details and shared responsibilities',
      'अधूरी बातों और साझा ज़िम्मेदारियों',
      'राहिलेले तपशील आणि सामायिक जबाबदाऱ्या',
    ),
    outlook: _LocalizedText(
      'The day may be quieter on the surface and useful for work that needs a closer look. A detail about a bill, handoff, or household responsibility could come into focus.',
      'दिन की रफ़्तार धीमी लग सकती है, लेकिन किसी अधूरे काम की बारीकियाँ समझने के लिए समय मिल सकता है। कोई बिल या साझा ज़िम्मेदारी स्पष्ट हो सकती है।',
      'दिवसाची गती संथ वाटू शकते, पण अपुऱ्या कामाचे तपशील पाहायला वेळ मिळू शकतो. एखादे बिल किंवा सामायिक जबाबदारी स्पष्ट होऊ शकते.',
    ),
    action: _LocalizedText(
      'Review a pending item and write down what is still open.',
      'कोई एक लंबित काम देखें और जो बाकी है उसे लिख लें।',
      'एक प्रलंबित काम पाहा आणि नेमके काय राहिले आहे ते लिहा.',
    ),
    avoid: _LocalizedText(
      'Avoid drawing a conclusion from a partial update.',
      'अधूरी जानकारी से निष्कर्ष न निकालें।',
      'अर्धवट माहितीवरून निष्कर्ष काढू नका.',
    ),
    career: _LocalizedText(
      'Use a quiet work block to investigate one recurring issue.',
      'शांत समय में बार-बार लौटने वाली किसी दिक्कत को समझें।',
      'शांत वेळेत वारंवार उद्भवणारी एखादी अडचण समजून घ्या.',
    ),
    wellness: _LocalizedText(
      'Stand up and stretch when you finish a long stretch at your desk.',
      'लंबे समय तक बैठकर काम करने के बाद उठकर थोड़ा चलें।',
      'बराच वेळ बसून काम केल्यावर उठून थोडे चाला.',
    ),
    relationships: _LocalizedText(
      'Ask about a shared responsibility that has been vague.',
      'जिस साझा ज़िम्मेदारी को लेकर स्पष्टता कम है, उस पर बात करें।',
      'ज्या सामायिक जबाबदारीबद्दल स्पष्टता कमी आहे, त्यावर बोला.',
    ),
  ),
  _HouseReading(
    topic: _LocalizedText(
      'new perspectives and learning',
      'नया नज़रिया और सीखने के मौके',
      'नवी दृष्टी आणि शिकणे',
    ),
    outlook: _LocalizedText(
      'A conversation, a lesson, or a change of scene may put a familiar problem in perspective. There is room to explore an option you had overlooked.',
      'बातचीत, पढ़ाई या जगह बदलने से किसी पुराने सवाल को नए ढंग से देखने का मौका मिल सकता है। पहले छूटा कोई विकल्प अब ध्यान में आ सकता है।',
      'एखादे संभाषण, अभ्यास किंवा ठिकाण बदलल्याने जुन्या प्रश्नाकडे नव्या दृष्टीने पाहता येऊ शकते. आधी नजरेतून सुटलेला पर्याय लक्षात येऊ शकतो.',
    ),
    action: _LocalizedText(
      'Ask someone with experience how they approached a similar choice.',
      'किसी अनुभवी व्यक्ति से पूछें कि उसने ऐसी स्थिति में क्या किया था।',
      'अशाच प्रसंगी त्यांनी काय केले होते, हे एखाद्या अनुभवी व्यक्तीला विचारा.',
    ),
    avoid: _LocalizedText(
      'Give one useful idea time before jumping to a second one.',
      'एक उपयोगी विचार को समझे बिना अगले विचार पर न जाएँ।',
      'एक उपयुक्त कल्पना समजून घेण्यापूर्वी दुसरीकडे वळू नका.',
    ),
    career: _LocalizedText(
      'Try applying one thing you learned to a current task.',
      'हाल में सीखी किसी एक बात को मौजूदा काम में आज़माएँ।',
      'अलीकडे शिकलेली एक गोष्ट सध्याच्या कामात वापरून पाहा.',
    ),
    wellness: _LocalizedText(
      'If your day allows, take a short walk in a different setting.',
      'समय मिले तो किसी अलग जगह पर थोड़ी देर टहलें।',
      'वेळ मिळाला तर वेगळ्या ठिकाणी थोडा फेरफटका मारा.',
    ),
    relationships: _LocalizedText(
      'Make time for an exchange of ideas with someone you respect.',
      'किसी ऐसे व्यक्ति से विचार साझा करें जिसकी राय की आप कद्र करते हैं।',
      'ज्यांच्या मताचा आदर करता अशा व्यक्तीशी विचारांची देवाणघेवाण करा.',
    ),
  ),
  _HouseReading(
    topic: _LocalizedText(
      'professional priorities',
      'काम की प्राथमिकताओं',
      'कामातील प्राधान्यक्रम',
    ),
    outlook: _LocalizedText(
      'A task with a clear finish line may give the day momentum. Visible progress is possible when you put your effort into the part that others are waiting for.',
      'जिस काम का लक्ष्य साफ़ है, उसमें अच्छी गति मिल सकती है। जिस हिस्से का दूसरे इंतज़ार कर रहे हैं, उसे आगे बढ़ाने से प्रगति दिखाई दे सकती है।',
      'निकाल स्पष्ट असलेल्या कामाला गती मिळू शकते. इतर ज्या भागाची वाट पाहत आहेत, त्यावर लक्ष दिल्यास प्रगती जाणवू शकते.',
    ),
    action: _LocalizedText(
      'Finish one deliverable or put it in front of the person who needs it.',
      'कोई एक काम पूरा करें या जिस व्यक्ति को उसकी ज़रूरत है, उसे दिखाएँ।',
      'एक काम पूर्ण करा किंवा ज्यांना त्याची गरज आहे त्यांच्यासमोर ते ठेवा.',
    ),
    avoid: _LocalizedText(
      'Leave extra commitments open until you know your available time.',
      'अपना समय देखे बिना कोई अतिरिक्त ज़िम्मेदारी स्वीकार न करें।',
      'उपलब्ध वेळ पाहिल्याशिवाय जादा जबाबदारी घेऊ नका.',
    ),
    career: _LocalizedText(
      'Show the result and state exactly what decision or feedback you need.',
      'काम का नतीजा दिखाएँ और बताएँ कि कौन-सा फैसला या सुझाव चाहिए।',
      'कामाचा निकाल दाखवा आणि कोणता निर्णय किंवा अभिप्राय हवा ते स्पष्ट सांगा.',
    ),
    wellness: _LocalizedText(
      'Choose a realistic time to wrap up work for the day.',
      'काम समाप्त करने का ऐसा समय तय करें जिसे आप निभा सकें।',
      'दिवसाचे काम आवरण्यासाठी पाळता येईल अशी वेळ ठरवा.',
    ),
    relationships: _LocalizedText(
      'Let people at home know if your schedule shifts.',
      'काम का समय बदले तो घर पर बता दें।',
      'कामाची वेळ बदलल्यास घरी कळवा.',
    ),
  ),
  _HouseReading(
    topic: _LocalizedText(
      'friends and group projects',
      'दोस्तों और सामूहिक काम',
      'मित्र आणि गटातील कामे',
    ),
    outlook: _LocalizedText(
      'A friend, colleague, or group conversation may help connect two pieces of a plan. Shared work can move faster when everyone knows what they can contribute.',
      'किसी दोस्त, सहकर्मी या समूह से बातचीत योजना के दो हिस्सों को जोड़ सकती है। जब सबको अपनी भूमिका पता हो, तो मिलकर किया जाने वाला काम आगे बढ़ सकता है।',
      'मित्र, सहकारी किंवा गटातील संभाषणातून योजनेचे दोन भाग जोडले जाऊ शकतात. प्रत्येकाला आपली भूमिका कळल्यावर सामूहिक काम पुढे जाऊ शकते.',
    ),
    action: _LocalizedText(
      'Send one clear request to a person or group that can help.',
      'जिस व्यक्ति या समूह से मदद मिल सकती है, उसे अपनी ज़रूरत साफ़ बताएँ।',
      'मदत करू शकणाऱ्या व्यक्तीला किंवा गटाला नेमकी गरज सांगा.',
    ),
    avoid: _LocalizedText(
      'Avoid assuming that everyone has already read the plan.',
      'यह मानकर न चलें कि सभी ने योजना पढ़ ली है।',
      'सर्वांनी योजना वाचली आहे असे गृहीत धरू नका.',
    ),
    career: _LocalizedText(
      'Share a short progress note and invite a specific contribution.',
      'प्रगति की छोटी जानकारी दें और किसी एक काम में योगदान माँगें।',
      'प्रगतीचा थोडक्यात आढावा द्या आणि एखाद्या विशिष्ट कामासाठी मदत मागा.',
    ),
    wellness: _LocalizedText(
      'Choose a social plan that leaves time for rest.',
      'मिलने-जुलने की योजना में आराम के लिए भी समय रखें।',
      'भेटीगाठींचे नियोजन करताना विश्रांतीलाही वेळ ठेवा.',
    ),
    relationships: _LocalizedText(
      'Reconnect with a friend through a small plan you can both keep.',
      'किसी दोस्त के साथ ऐसा छोटा कार्यक्रम तय करें जो दोनों के लिए आसान हो।',
      'दोघांनाही जमेल अशी छोटी भेट एखाद्या मित्राबरोबर ठरवा.',
    ),
  ),
  _HouseReading(
    topic: _LocalizedText(
      'rest and unfinished work',
      'आराम और अधूरे काम',
      'विश्रांती आणि अपुरी कामे',
    ),
    outlook: _LocalizedText(
      'A quieter pace could suit you. Closing a loose end and leaving some time unscheduled may make it easier to start fresh afterward.',
      'थोड़ी खाली जगह वाला दिन आपके लिए सहज रह सकता है। कोई अधूरा काम पूरा करके कुछ समय अपने लिए छोड़ें।',
      'थोडा मोकळा वेळ असलेला दिवस अधिक सहज वाटू शकतो. एखादे अपुरे काम उरकून काही वेळ स्वतःसाठी राखून ठेवा.',
    ),
    action: _LocalizedText(
      'Put one finished task away and leave a genuine break in your plans.',
      'एक लंबित काम पूरा करें और उसके बाद थोड़ा खाली समय रखें।',
      'एक प्रलंबित काम उरका आणि त्यानंतर काही वेळ मोकळा ठेवा.',
    ),
    avoid: _LocalizedText(
      'Keep late hours free of optional work.',
      'देर रात गैरज़रूरी काम न रखें।',
      'रात्री उशिरा टाळता येणारी कामे ठेवू नका.',
    ),
    career: _LocalizedText(
      'Document where you stopped, so the next work session starts smoothly.',
      'काम कहाँ तक हुआ, यह लिख लें ताकि अगली बार शुरुआत आसान हो।',
      'काम कुठपर्यंत झाले ते लिहा, म्हणजे पुढच्या वेळी सहज सुरुवात होईल.',
    ),
    wellness: _LocalizedText(
      'Allow your evening routine to end at an unhurried pace.',
      'शाम की दिनचर्या बिना जल्दबाज़ी के पूरी करें।',
      'संध्याकाळचा दिनक्रम घाई न करता आटपा.',
    ),
    relationships: _LocalizedText(
      'Tell someone close to you when you need a little time to yourself.',
      'जब अपने लिए थोड़ा समय चाहिए, तो किसी करीबी को बता दें।',
      'स्वतःसाठी थोडा वेळ हवा असेल तर जवळच्या व्यक्तीला सांगा.',
    ),
  ),
];
