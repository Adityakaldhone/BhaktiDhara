import '../../../domain/entities/horoscope.dart';
import '../data/voice_agent_service.dart';

/// On-device deterministic fallback when the FastAPI voice agent is unreachable.
/// Mirrors the high-priority intents from backend/app/voice_agent/intent_resolver.py.
class LocalVoiceIntentParser {
  static VoiceAgentResult parse(String text, {String localeHint = 'mr-IN'}) {
    final clean = text.trim();
    final locale = _detectLocale(clean, localeHint);
    final lower = clean.toLowerCase();

    final query = lower.replaceAll(RegExp(r'\s+'), ' ');
    if (_words('diya|दिवा|दीया|lamp|bell').hasMatch(query) &&
        _words('switch off|turn off|बंद करो|बंद करा|विझवा').hasMatch(query)) {
      return VoiceAgentResult(
        status: 'unsupported',
        transcript: clean,
        locale: locale,
        responseText: locale == 'en-IN'
            ? 'You can control the diya from the shrine.'
            : locale == 'hi-IN'
            ? 'दीये के नियंत्रण मंदिर में मिलेंगे।'
            : 'दिव्याची नियंत्रणे देवघरात आहेत.',
        action: const VoiceAction(type: 'none'),
        choices: const [],
      );
    }
    final explicitJaap = _jaapSignal.hasMatch(query);
    final counterTerm = _counterTerm.hasMatch(query);
    final jaapStats =
        _jaapStats.hasMatch(query) ||
        (explicitJaap && _jaapStatsDetail.hasMatch(query));
    final aboutJaap = !jaapStats && query.startsWith('what is ');
    if ((explicitJaap || counterTerm || jaapStats) &&
        (_unsupportedJaap.hasMatch(query) || aboutJaap)) {
      return VoiceAgentResult(
        status: 'unsupported',
        transcript: clean,
        locale: locale,
        responseText: locale == 'en-IN'
            ? 'You can ask me to open the jaap counter or show your jaap history.'
            : locale == 'hi-IN'
            ? 'आप मुझसे जप माला या जप का इतिहास खोलने को कह सकते हैं।'
            : 'तुम्ही जप माळ किंवा जपाचा इतिहास उघडायला सांगू शकता.',
        action: const VoiceAction(type: 'none'),
        choices: const [],
      );
    }

    VoiceAgentResult open(VoiceAction action, String en, String hi, String mr) {
      return VoiceAgentResult(
        status: 'action_ready',
        transcript: clean,
        locale: locale,
        responseText: locale == 'en-IN'
            ? en
            : locale == 'hi-IN'
            ? hi
            : mr,
        action: action,
        choices: const [],
      );
    }

    final cancelled = _words("do not|don['’]t|मत|नको").hasMatch(query);
    if (_reminderRequest.hasMatch(query) && !cancelled) {
      return open(
        const VoiceAction(type: 'open_aarti_reminders'),
        'Opening aarti reminder settings.',
        'आरती रिमाइंडर खोल रहे हैं।',
        'आरती आठवण उघडत आहे.',
      );
    }
    if (_languageRequest.hasMatch(query) ||
        query == 'language' ||
        query == 'भाषा') {
      if (cancelled) return VoiceAgentService.notFound(clean, locale);
      final languageText =
          RegExp(r'\bfrom .+? (?:to|into) (.+)').firstMatch(query)?.group(1) ??
          query;
      final codes = _voiceLanguages.entries
          .where((entry) => entry.value.hasMatch(languageText))
          .map((entry) => entry.key)
          .toList();
      if (codes.length == 1) {
        return open(
          VoiceAction(type: 'set_language', languageCode: codes.single),
          'Changing the app language.',
          'ऐप की भाषा बदल रहे हैं।',
          'अॅपची भाषा बदलत आहे.',
        );
      }
      if (codes.isEmpty && _words('to').hasMatch(query)) {
        return VoiceAgentService.notFound(clean, locale);
      }
      return open(
        const VoiceAction(type: 'open_language_settings'),
        'Choose Marathi, Hindi, or English.',
        'मराठी, हिंदी या अंग्रेज़ी चुनें।',
        'मराठी, हिंदी किंवा इंग्रजी निवडा.',
      );
    }

    if (_feedbackRequest.hasMatch(query)) {
      if (cancelled) return VoiceAgentService.notFound(clean, locale);
      return open(
        const VoiceAction(type: 'open_feedback'),
        'Opening the feedback form.',
        'सुझाव फ़ॉर्म खोल रहे हैं।',
        'अभिप्राय फॉर्म उघडत आहे.',
      );
    }

    if (jaapStats) {
      return open(
        const VoiceAction(type: 'open_jaap_stats', featureKey: 'jaap_stats'),
        'Opening your jaap history.',
        'जप का इतिहास खोल रहे हैं।',
        'जपाचा इतिहास उघडत आहे.',
      );
    }
    if (explicitJaap || _counterTerm.stringMatch(query) == query) {
      return open(
        VoiceAction(
          type: 'start_jaap',
          featureKey: 'jaap',
          mantraId: matchJaapMantra(query),
        ),
        'Opening the jaap counter.',
        'जप माला खोल रहे हैं।',
        'जप माळ उघडत आहे.',
      );
    }
    if (_calendarSignal.hasMatch(query) ||
        (_words('calendar').hasMatch(query) &&
            _words('festivals?').hasMatch(query))) {
      return open(
        const VoiceAction(type: 'open_calendar', featureKey: 'calendar'),
        'Opening the festival calendar.',
        'त्योहारों का कैलेंडर खोल रहे हैं।',
        'सणांची दिनदर्शिका उघडत आहे.',
      );
    }

    final rashi = matchRashiInText(clean);
    final wantsHoroscope = _hasAny(lower, const [
      'राशी',
      'राशि',
      'भविष्य',
      'rashifal',
      'horoscope',
      'राशिफल',
      'राशीचे',
      'rashi',
    ]);
    if (rashi != null &&
        (wantsHoroscope || clean.split(RegExp(r'\s+')).length <= 4)) {
      return horoscope(rashi, clean, locale);
    }

    if (wantsHoroscope &&
        _hasAny(lower, const [
          'daily',
          'today',
          'आज',
          'राशिफल',
          'राशीभविष्य',
          'राशिभविष्य',
        ])) {
      return open(
        const VoiceAction(type: 'open_horoscope', featureKey: 'horoscope'),
        "Opening today's horoscope.",
        'आज का राशिफल खोल रहे हैं।',
        'आजचे राशीभविष्य उघडत आहे.',
      );
    }

    const panchangFields = {
      'rahu_kaal': ['राहुकाळ', 'राहुकाल', 'rahu kaal', 'rahukaal'],
      'tithi': ['तिथी', 'तिथि', 'tithi'],
      'muhurat': ['मुहूर्त', 'muhurat', 'muhurta'],
      'nakshatra': ['नक्षत्र', 'nakshatra'],
      'sunrise': ['सूर्योदय', 'sunrise'],
      'sunset': ['सूर्यास्त', 'sunset'],
    };
    String? field;
    for (final entry in panchangFields.entries) {
      if (_hasAny(lower, entry.value)) {
        field = entry.key;
        break;
      }
    }
    if (field != null || _hasAny(lower, const ['पंचांग', 'panchang'])) {
      return VoiceAgentResult(
        status: 'action_ready',
        transcript: clean,
        locale: locale,
        responseText: locale.startsWith('en')
            ? 'Opening today’s panchang.'
            : locale.startsWith('hi')
            ? 'आज का पंचांग खोला जा रहा है।'
            : 'आजचे पंचांग उघडत आहे.',
        action: VoiceAction(
          type: 'open_panchang',
          field: field,
          featureKey: 'panchang',
        ),
        choices: const [],
      );
    }

    if (_diyaRequest.hasMatch(query)) {
      return open(
        const VoiceAction(type: 'open_akhand_diya', featureKey: 'akhand_diya'),
        'Opening the Akhand Diya.',
        'अखंड दीया खोल रहे हैं।',
        'अखंड दिवा उघडत आहे.',
      );
    }

    if (_shrineRequest.hasMatch(query)) {
      return open(
        const VoiceAction(type: 'open_mandir', featureKey: 'mandir'),
        'Opening the temple garbhagriha.',
        'मंदिर गर्भगृह दर्शन खोला जा रहा है।',
        'श्री मंदिर गर्भगृह दर्शन सुरू करत आहे.',
      );
    }

    if (_hasAny(lower, const [
      'holy books',
      'holy book',
      'scripture library',
      'पोथी',
      'पोथ्या',
      'ग्रंथ',
      'granth',
      'pothi',
      'gurucharitra',
      'dasbodh',
      'shivlilamrut',
      'गुरुचरित्र',
      'दासबोध',
      'शिवलीलामृत',
      'अध्याय',
    ])) {
      final chap = RegExp(r'(\d+)').firstMatch(clean);
      final chapter = int.tryParse(chap?.group(1) ?? '');
      return VoiceAgentResult(
        status: 'action_ready',
        transcript: clean,
        locale: locale,
        responseText: locale.startsWith('en')
            ? 'Opening the granth library.'
            : locale.startsWith('hi')
            ? 'ग्रंथ संग्रह खोल रहे हैं।'
            : 'ग्रंथ संग्रह उघडत आहे.',
        action: VoiceAction(
          type: 'open_granth',
          chapter: chapter,
          featureKey: 'granth',
        ),
        choices: const [],
      );
    }

    final comparingCharts =
        lower.contains('chart') &&
        RegExp(r'compar(?:e|ing)|match(?:ing)?').hasMatch(lower) &&
        RegExp(
          r'marriage|matrimony|couple|two (?:birth )?charts',
        ).hasMatch(lower);
    if (comparingCharts ||
        _hasAny(lower, const [
          'मिलन',
          'milan',
          'गुण मिलन',
          'gun milan',
          'guna milan',
          'कुंडली मिलन',
          'मिलान',
          'marriage compatibility',
          'पत्रिका जुळव',
          'गुण जुळ',
        ]) ||
        (lower.contains('पत्र्य') && lower.contains('जुळव'))) {
      return VoiceAgentResult(
        status: 'action_ready',
        transcript: clean,
        locale: locale,
        responseText: locale.startsWith('en')
            ? 'Opening kundali milan.'
            : locale.startsWith('hi')
            ? 'कुंडली मिलान खोला जा रहा है।'
            : 'कुंडली मिलन उघडत आहे.',
        action: const VoiceAction(type: 'open_milan', featureKey: 'milan'),
        choices: const [],
      );
    }

    final wantsKundali =
        _hasAny(lower, const [
          'कुंडली',
          'kundali',
          'kundli',
          'पत्रिका',
          'patrika',
          'birth chart',
          'natal chart',
          'natal horoscope',
          'kundali chart',
          'janma kundali',
          'janam kundali',
          'जन्म कुंडली',
        ]) ||
        (lower.contains('chart') &&
            _hasAny(lower, const [
              'open',
              'show',
              'birth',
              'kundali',
              'kundli',
            ]));
    if (wantsKundali) {
      return VoiceAgentResult(
        status: 'action_ready',
        transcript: clean,
        locale: locale,
        responseText: locale.startsWith('en')
            ? 'Opening your kundali chart.'
            : locale.startsWith('hi')
            ? 'कुंडली खोली जा रही है।'
            : 'कुंडली उघडत आहे.',
        action: const VoiceAction(type: 'open_kundali', featureKey: 'kundali'),
        choices: const [],
      );
    }

    if (_hasAny(lower, const [
      'इष्ट',
      'ishta',
      'कुलदैवत',
      'आराध्य दैवत',
      'उपास्य दैवत',
      'आराध्य देवता',
      'personal deity',
      'isht dev',
    ])) {
      return VoiceAgentResult(
        status: 'action_ready',
        transcript: clean,
        locale: locale,
        responseText: locale.startsWith('en')
            ? 'Opening Ishta Devta.'
            : locale.startsWith('hi')
            ? 'इष्ट देवता खोला जा रहा है।'
            : 'इष्ट देवता उघडत आहे.',
        action: const VoiceAction(
          type: 'open_ishta_devta',
          featureKey: 'ishta_devta',
        ),
        choices: const [],
      );
    }

    if (_hasAny(lower, const [
      'good morning cards',
      'cards that say good morning',
      'सुविचार',
      'शुभेच्छा',
      'greeting',
      'greetings',
      'शुभकामना',
      'सुप्रभात',
      'suvichar',
      'status card',
    ])) {
      return VoiceAgentResult(
        status: 'action_ready',
        transcript: clean,
        locale: locale,
        responseText: locale.startsWith('en')
            ? 'Opening greetings.'
            : locale.startsWith('hi')
            ? 'शुभकामनाएं खोली जा रही हैं।'
            : 'शुभेच्छा उघडत आहे.',
        action: const VoiceAction(
          type: 'open_greetings',
          featureKey: 'greetings',
        ),
        choices: const [],
      );
    }

    if (_hasAny(lower, const ['ग्रहण', 'grahan', 'eclipse'])) {
      return VoiceAgentResult(
        status: 'action_ready',
        transcript: clean,
        locale: locale,
        responseText: locale.startsWith('en')
            ? 'Opening grahan timings.'
            : locale.startsWith('hi')
            ? 'ग्रहण समय खोला जा रहा है।'
            : 'ग्रहण वेळ उघडत आहे.',
        action: const VoiceAction(type: 'open_grahan', featureKey: 'grahan'),
        choices: const [],
      );
    }

    // No strong feature match — keep existing aarti search behavior.
    return VoiceAgentResult(
      status: 'fallback_search',
      transcript: clean,
      locale: locale,
      responseText: '',
      action: VoiceAction(type: 'search_aarti', query: clean),
      choices: const [],
    );
  }

  static RegExp _words(String pattern) => RegExp(
    '(?:^|[^\\w\\u0900-\\u097f])(?:$pattern)(?=\$|[^\\w\\u0900-\\u097f])',
  );

  static final _reminderRequest = RegExp(
    r'aarti (?:reminders?|alerts?|notifications?)|(?:reminders?|alerts?) for (?:my |the )?(?:daily )?aarti|'
    r'आरतीची आठवण|आरती आठवण|आरती (?:का )?रिमाइंडर',
  );
  static final _languageRequest = _words(
    r'(?:switch|set|change|use|make) .{0,32}(?:interface|menus)|make (?:the |this )?app (?:marathi|hindi|english)|switch (?:the )?menus to|'
    r'language settings|app language|(?:change|chnage|switch|set|select) (?:the )?language|'
    r'(?:switch|change) (?:to|from) (?:marathi|hindi|english)|(?:app|अॅप|ॲप) (?:मराठीत|हिंदीत|इंग्रजीत|(?:marathi|hindi|english) (?:mein|madhe))|'
    r'bhasha badlo|bhasha badla|language badlo|'
    r'(?:ऐप|एप) की भाषा|अॅपची भाषा|ॲपची भाषा|भाषा बदल[ाोणे]?|भाषा निवडा|भाषा चुनें|'
    r'(?:मराठी|हिंदी|हिन्दी|इंग्रजी|अंग्रेज़ी) (?:में बदलो|मध्ये बदला|करा)',
  );
  static final _voiceLanguages = {
    'mr': _words('marathi|मराठी|मराठीत'),
    'hi': _words('hindi|हिंदी|हिन्दी|हिंदीत'),
    'en': _words('english|इंग्रजी|इंग्रजीत|अंग्रेजी|अंग्रेज़ी'),
  };
  static final _feedbackRequest = _words(
    r'feedback|suggestions?|request (?:a deity|to add a deity)|report (?:a |an )?(?:problem|issue|bug)|'
    r'अभिप्राय|प्रतिक्रिया|फीडबैक|फीडबॅक|सूचना द्या|सुझाव|तक्रार|समस्या बताएं',
  );
  static final _shrineRequest = RegExp(
    r'^[\s,]*(?:please )?(?:(?:open|show|go to|take me to) (?:the |my )?)?'
    r'(?:virtual shrine|shrine|temple|mandir(?: darshan)?|garbhagriha|darshan|मंदिर|देवघर|दर्शन|गाभारा)'
    r'(?: (?:open|kholo|khol do|dikhao|please|उघडा|दाखवा|खोलो|दिखाओ|दर्शन खोलो))?[.!?।]*$'
    r'|देवघरात (?:घेऊन जा|घेऊन जाल)|(?:दर्शन|darshan) (?:घ्यायचे|करना है)',
  );
  static final _diyaRequest = RegExp(
    r'^(?:please )?(?:(?:open|show) (?:the )?)?'
    r'(?:akhand (?:diya|jyot|jyoti)|eternal lamp|अखंड (?:दिवा|दीया|दीप|ज्योत|ज्योति))'
    r'(?: (?:open|kholo|दाखवा|उघडा|खोलो|दिखाओ|का पन्ना खोलना))?[.!?।]*$',
  );

  static final _jaapSignal = _words(
    r'jaap|jap|japa|naamjaap|namjaap|naamjap|namjap|naam jaap|nam jaap|'
    r'naam jap|nam jap|जप|जाप|जपमाळ|जपमाला|नामजप|नाम जप|नामजाप|नाम जाप|'
    r'जपाचा|जपाची|जपाचे|जपासाठी|नामजपासाठी|नामजपाचा|नामजपाची|chant|chanting|'
    r'mala open|open mala|mala kholo|जप माळ|माळ उघडा|माला खोलो',
  );
  static final _counterTerm = _words('mala|माळ|माला|mantra|मंत्र');
  static final _jaapStats = _words(
    r'(?:jaap|jap|japa|chanting) (?:stats|history|streak)|meri sadhana|'
    r'maajhi sadhana|मेरी साधना|माझी साधना|जपाचा इतिहास|जपाची आकडेवारी|'
    r'जाप का इतिहास|जप किती|जाप कितने|किती जप|कितना जप|कितनी बार नाम जपा|'
    r'नामस्मरणाची मोजणी|नामजपाचा इतिहास',
  );
  static final _jaapStatsDetail = _words(
    'history|stats|streak|record|lifetime count',
  );
  static final _unsupportedJaap = RegExp(
    r"\b(?:don['’]t|do not|never|stop|cancel|pause|reset|resume|delete|clear|remind|"
    r"meaning|mean|translate|translation|explain|benefits|mat karo|"
    r"mat karna|nako|set|target|goal|automatically|export|and then)\b"
    r"|(?:और फिर|आणि मग|मत |नको|करू नका|काढून टाका|मिटवा|मिटाओ|बंद करा|बंद करो|रीसेट|अर्थ|मतलब|लक्ष्य)"
    r"|[0-9०-९]+\s*(?:times|repetitions|rounds|जप|जाप|बार|वेळा|माळा)",
  );
  static final _calendarSignal = _words(
    r'festival calendar|festival dates|upcoming festivals|tyohar|san utsav|'
    r'दिनदर्शिका|कॅलेंडर|सणवार|सण उत्सव|त्योहार|त्योहारों|त्यौहार|त्यौहारों|पर्व|कैलेंडर|सण',
  );

  static String? matchJaapMantra(String lower) {
    const mantraAliases = <(String, List<String>)>[
      ('radha', ['radha', 'raadha', 'राधा', 'राधे', 'radhe', 'radhe radhe']),
      ('swami_samarth', ['swami samarth', 'स्वामी समर्थ', 'samarth']),
      (
        'shri_ram',
        ['shri ram', 'shree ram', 'sri ram', 'श्री राम', 'श्रीराम', 'sitaram'],
      ),
      (
        'ganesha',
        [
          'ganesha',
          'ganesh',
          'ganpati',
          'ganapataye',
          'गणपतये',
          'गणेश',
          'गणपती',
          'गणपति',
        ],
      ),
      (
        'om_namah_shivaya',
        [
          'om namah shivaya',
          'namah shivaya',
          'mahadev',
          'शिव',
          'शिवाय',
          'नमः शिवाय',
          'om namah shivay',
        ],
      ),
      (
        'vasudevaya',
        ['vasudevaya', 'vasudeva', 'वासुदेवाय', 'विष्णु', 'विष्णू', 'vishnu'],
      ),
      (
        'jai_shri_ram',
        ['jai shri ram', 'jai sri ram', 'जय श्री राम', 'जय श्रीराम'],
      ),
      ('hare_krishna', ['hare krishna', 'हरे कृष्ण', 'mahamantra']),
      ('om_namo_narayanaya', ['narayanaya', 'narayana', 'नारायण', 'नारायणाय']),
      ('gayatri', ['gayatri', 'bhur bhuvah svah', 'भूर्भुवः स्वः', 'गायत्री']),
      (
        'shani_mantra',
        ['shani', 'neelanjana samabhasam', 'नीलांजन समाभासं', 'शनि', 'शनी'],
      ),
      ('hanuman', ['hanuman', 'हनुमान', 'bajrang', 'hanumate', 'हनुमते']),
      ('durga', ['durga', 'दुर्गा', 'ambaji', 'ambe', 'durgayai', 'दुर्गायै']),
      ('datta', ['datta', 'दत्त', 'dattatreya']),
      (
        'vitthal',
        [
          'vitthal',
          'vithoba',
          'विठ्ठल',
          'pandurang',
          'ram krishna hari',
          'राम कृष्ण हरी',
          'विट्ठल',
        ],
      ),
      (
        'sai_ram',
        [
          'sai',
          'sai ram',
          'साई',
          'saibaba',
          'sai baba',
          'साईबाबा',
          'साईं बाबा',
        ],
      ),
      (
        'mahamrityunjaya',
        [
          'mahamrityunjaya',
          'महामृत्युंजय',
          'tryambakam',
          'त्र्यम्बकं',
          'त्र्यंबकं',
        ],
      ),
    ];
    String? match;
    var longestMatch = 0;
    for (final (mantraId, aliases) in mantraAliases) {
      for (final alias in aliases) {
        if (alias.length > longestMatch &&
            _words(
              '${RegExp.escape(alias)}(?:चा|ची|चे|च्या|नाम)?',
            ).hasMatch(lower)) {
          longestMatch = alias.length;
          match = mantraId;
        }
      }
    }
    return match;
  }

  static VoiceAgentResult horoscope(Rashi rashi, String clean, String locale) {
    final name = rashi.localizedName(
      locale.startsWith('hi')
          ? 'hi'
          : locale.startsWith('en')
          ? 'en'
          : 'mr',
    );
    final reply = locale.startsWith('hi')
        ? '$name राशि का आज का राशिफल खोला जा रहा है।'
        : locale.startsWith('en')
        ? "Opening today's horoscope for ${rashi.nameEn}."
        : '$name राशीचे आजचे राशीभविष्य उघडत आहे.';
    return VoiceAgentResult(
      status: 'action_ready',
      transcript: clean,
      locale: locale,
      responseText: reply,
      action: VoiceAction(
        type: 'open_horoscope',
        rashiId: rashi.id,
        rashiName: name,
        featureKey: 'horoscope',
      ),
      choices: const [],
    );
  }

  static Rashi? matchRashiInText(String text) {
    final lower = text.toLowerCase();
    // Prefer longer aliases first so "वृषभ" wins over "वृष".
    final aliases = kRashiAliasToId.keys.toList()
      ..sort((a, b) => b.length.compareTo(a.length));
    for (final alias in aliases) {
      final pattern = RegExp.escape(alias.toLowerCase());
      if (_words('$pattern(?:च्या|चे|ला)?').hasMatch(lower)) {
        return resolveRashi(alias);
      }
    }
    return null;
  }

  static String _detectLocale(String text, String hint) {
    if (hint == 'mr-IN' || hint == 'hi-IN' || hint == 'en-IN') return hint;
    final lower = text.toLowerCase();
    const hi = ['दिखाओ', 'खोलो', 'सुनाओ', 'बताओ', 'राशिफल', 'चलाओ'];
    for (final m in hi) {
      if (lower.contains(m)) return 'hi-IN';
    }
    const mr = ['दाखवा', 'उघडा', 'लावा', 'सांगा', 'राशीचे', 'वाजवा'];
    for (final m in mr) {
      if (lower.contains(m)) return 'mr-IN';
    }
    final hasDevanagari = text.runes.any((r) => r >= 0x0900 && r <= 0x097F);
    return hasDevanagari ? 'mr-IN' : 'en-IN';
  }

  static bool _hasAny(String haystack, List<String> needles) {
    for (final n in needles) {
      if (haystack.contains(n.toLowerCase())) return true;
    }
    return false;
  }
}
