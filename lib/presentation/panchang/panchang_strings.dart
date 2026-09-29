import '../../domain/logic/panchang_timing.dart';

/// Panchang screen copy in Marathi, Hindi and English.
class PanchangStrings {
  const PanchangStrings(this.lang);

  final String lang;

  String _t(String mr, String hi, String en) =>
      lang == 'en' ? en : (lang == 'hi' ? hi : mr);

  String get title => _t('दैनिक पंचांग', 'दैनिक पंचांग', 'Daily Panchang');
  String get subtitle => _t(
        'शुभ वेळ, अशुभ वेळ व सण',
        'शुभ समय, अशुभ समय व त्योहार',
        'Good times, times to avoid & festivals',
      );
  String get refreshing =>
      _t('पंचांग अद्यतन होत आहे...', 'पंचांग अपडेट हो रहा है...', 'Updating Panchang...');
  String get loading => _t(
        'आपल्या शहराचे पंचांग तयार होत आहे...',
        'आपके शहर का पंचांग तैयार हो रहा है...',
        'Preparing Panchang for your city...',
      );
  String get loadError => _t(
        'पंचांग माहिती लोड करता आली नाही.',
        'पंचांग जानकारी लोड नहीं हो सकी।',
        'Could not load the Panchang.',
      );
  String get retry => _t('पुन्हा प्रयत्न करा', 'फिर से कोशिश करें', 'Try again');

  String get location => _t('पंचांग स्थान:', 'पंचांग स्थान:', 'Location:');
  String get prev => _t('काल', 'पिछला', 'Prev');
  String get today => _t('आज', 'आज', 'Today');
  String get next => _t('उद्या', 'अगला', 'Next');
  String get goToday => _t('(आजवर जा)', '(आज पर जाएँ)', '(Go to today)');

  // Hero
  String get bestTime => _t('सर्वोत्तम शुभ वेळ', 'सबसे शुभ समय', 'Best time');
  String get avoidTime => _t('ही वेळ टाळा', 'यह समय टालें', 'Avoid this time');
  String nowAvoid(String name) =>
      _t('आत्ता $name चालू आहे', 'अभी $name चल रहा है', '$name is on now');
  String nowAvoidSub(String end) => _t(
        'नवीन किंवा शुभ काम $end नंतर करा',
        'नया या शुभ काम $end के बाद करें',
        'Start new or auspicious work after $end',
      );
  String nowGood(String name) =>
      _t('आत्ता शुभ वेळ — $name', 'अभी शुभ समय — $name', 'Good time now — $name');
  String until(String end) => _t('$end पर्यंत', '$end तक', 'Until $end');
  String nextGood(String name) =>
      _t('पुढील शुभ वेळ — $name', 'अगला शुभ समय — $name', 'Next good time — $name');
  String from(String start) => _t('$start पासून', '$start से', 'From $start');

  // Schedule
  String get scheduleTitle =>
      _t('शुभ व अशुभ वेळा', 'शुभ व अशुभ समय', 'Good & bad times');
  String get good => _t('शुभ', 'शुभ', 'Good');
  String get avoid => _t('टाळा', 'टालें', 'Avoid');
  String get best => _t('सर्वोत्तम', 'सर्वोत्तम', 'Best');
  String get most => _t('महत्त्वाचे', 'महत्वपूर्ण', 'Important');
  String get now => _t('आत्ता', 'अभी', 'Now');
  String get over => _t('संपले', 'समाप्त', 'Over');

  String slotName(PanchangSlotKind k) => switch (k) {
        PanchangSlotKind.brahma =>
          _t('ब्रह्म मुहूर्त', 'ब्रह्म मुहूर्त', 'Brahma Muhurat'),
        PanchangSlotKind.abhijit =>
          _t('अभिजीत मुहूर्त', 'अभिजीत मुहूर्त', 'Abhijit Muhurat'),
        PanchangSlotKind.amrit => _t('अमृत काळ', 'अमृत काल', 'Amrit Kaal'),
        PanchangSlotKind.vijaya =>
          _t('विजय मुहूर्त', 'विजय मुहूर्त', 'Vijaya Muhurat'),
        PanchangSlotKind.godhuli =>
          _t('गोधूलि मुहूर्त', 'गोधूलि मुहूर्त', 'Godhuli Muhurat'),
        PanchangSlotKind.rahu => _t('राहु काळ', 'राहु काल', 'Rahu Kaal'),
        PanchangSlotKind.yamaganda => _t('यमगंड', 'यमगंड', 'Yamaganda'),
        PanchangSlotKind.gulika => _t('गुलिक काळ', 'गुलिक काल', 'Gulika Kaal'),
        PanchangSlotKind.durmuhurat =>
          _t('दुर्मुहूर्त', 'दुर्मुहूर्त', 'Durmuhurat'),
        PanchangSlotKind.bhadra => _t('भद्रा काळ', 'भद्रा काल', 'Bhadra'),
      };

  String slotMeaning(PanchangSlotKind k) => switch (k) {
        PanchangSlotKind.brahma => _t(
            'ध्यान, पूजा व साधनेसाठी उत्तम',
            'ध्यान, पूजा व साधना के लिए उत्तम',
            'Best for meditation and puja',
          ),
        PanchangSlotKind.abhijit => _t(
            'नवीन कामाच्या सुरुवातीसाठी सर्वोत्तम',
            'नए काम की शुरुआत के लिए सबसे अच्छा',
            'Best time to start new work',
          ),
        PanchangSlotKind.amrit =>
          _t('अत्यंत शुभ वेळ', 'अत्यंत शुभ समय', 'A very auspicious time'),
        PanchangSlotKind.vijaya => _t(
            'कामात यश मिळते',
            'काम में सफलता मिलती है',
            'Brings success in work',
          ),
        PanchangSlotKind.godhuli => _t(
            'संध्याकाळचा दिवा लावण्यासाठी',
            'शाम का दीपक जलाने के लिए',
            'For lighting the evening lamp',
          ),
        PanchangSlotKind.rahu => _t(
            'नवीन व शुभ काम सुरू करू नका',
            'नया व शुभ काम शुरू न करें',
            'Do not start new or auspicious work',
          ),
        PanchangSlotKind.yamaganda => _t(
            'प्रवास व नवीन काम टाळा',
            'यात्रा व नया काम टालें',
            'Avoid travel and new work',
          ),
        PanchangSlotKind.gulika => _t(
            'महत्त्वाचे काम टाळा',
            'महत्वपूर्ण काम टालें',
            'Avoid important work',
          ),
        PanchangSlotKind.durmuhurat => _t(
            'शुभ कार्य टाळा',
            'शुभ कार्य टालें',
            'Avoid auspicious work',
          ),
        PanchangSlotKind.bhadra => _t(
            'या काळात शुभ कार्य टाळा',
            'इस समय शुभ कार्य टालें',
            'Avoid auspicious work in this period',
          ),
      };

  // Sun & moon
  String get sunMoonTitle => _t('सूर्य व चंद्र', 'सूर्य व चंद्र', 'Sun & Moon');
  String get sunrise => _t('सूर्योदय', 'सूर्योदय', 'Sunrise');
  String get sunset => _t('सूर्यास्त', 'सूर्यास्त', 'Sunset');
  String get moonrise => _t('चंद्रोदय', 'चंद्रोदय', 'Moonrise');
  String get moonset => _t('चंद्रास्त', 'चंद्रास्त', 'Moonset');

  // Festival & mantra
  String get festivalTitle =>
      _t('सण, व्रत व मंत्र', 'त्योहार, व्रत व मंत्र', 'Festival, vrat & mantra');
  String get vrat => _t('व्रत', 'व्रत', 'Vrat');
  String get mantra => _t('॥ आजचा मंत्र ॥', '॥ आज का मंत्र ॥', '॥ Mantra of the day ॥');
  String get copyMantra => _t('मंत्र कॉपी करा', 'मंत्र कॉपी करें', 'Copy mantra');
  String get mantraCopied =>
      _t('मंत्र कॉपी केला!', 'मंत्र कॉपी हो गया!', 'Mantra copied!');
  String get tip => _t('टीप', 'सुझाव', 'Tip');

  // Full panchang
  String get detailsTitle =>
      _t('संपूर्ण पंचांग पहा', 'संपूर्ण पंचांग देखें', 'See full Panchang');
  String get detailsHint => _t(
        'तिथी, नक्षत्र, योग, करण, राशी व संवत',
        'तिथि, नक्षत्र, योग, करण, राशि व संवत',
        'Tithi, nakshatra, yoga, karana, rashi & samvat',
      );
  String get limbsSection =>
      _t('पंचांगाची ५ अंगे', 'पंचांग के ५ अंग', 'The 5 parts of Panchang');
  String get rashiSection => _t('राशी', 'राशि', 'Rashi (signs)');
  String get yearSection => _t('वर्ष व ऋतू', 'वर्ष व ऋतु', 'Year & season');

  String get tithi => _t('तिथी', 'तिथि', 'Tithi');
  String get tithiMeaning => _t('चंद्राचा दिवस', 'चंद्र का दिन', 'Lunar day');
  String get vaar => _t('वार', 'वार', 'Weekday');
  String vaarMeaning(String graha) =>
      _t('स्वामी ग्रह: $graha', 'स्वामी ग्रह: $graha', 'Ruling planet: $graha');
  String get nakshatra => _t('नक्षत्र', 'नक्षत्र', 'Nakshatra');
  String get nakshatraMeaning =>
      _t('चंद्राचा तारा', 'चंद्र का तारा', "Moon's star");
  String get yoga => _t('योग', 'योग', 'Yoga');
  String get yogaMeaning =>
      _t('सूर्य-चंद्र योग', 'सूर्य-चंद्र योग', 'Sun–moon combination');
  String get karana => _t('करण', 'करण', 'Karana');
  String get karanaMeaning => _t('अर्धी तिथी', 'आधी तिथि', 'Half of a tithi');
  String get suryaRashi => _t('सूर्य राशी', 'सूर्य राशि', 'Sun sign');
  String get chandraRashi => _t('चंद्र राशी', 'चंद्र राशि', 'Moon sign');
  String get maas => _t('महिना', 'मास', 'Month');
  String get paksha => _t('पक्ष', 'पक्ष', 'Paksha');
  String get vikramSamvat => _t('विक्रम संवत', 'विक्रम संवत', 'Vikram Samvat');
  String get shakaSamvat => _t('शक संवत', 'शक संवत', 'Shaka Samvat');
  String get samvatsara => _t('संवत्सर', 'संवत्सर', 'Samvatsara');
  String get ritu => _t('ऋतू', 'ऋतु', 'Season');
  String get ayana => _t('अयन', 'अयन', 'Ayana');

  String get aiSource =>
      _t('Gemini AI द्वारे गणना', 'Gemini AI द्वारा गणना', 'Calculated with Gemini AI');

  // City sheet
  String get selectCity =>
      _t('स्थान / शहर निवडा', 'स्थान / शहर चुनें', 'Select City / Location');
  String get useGps =>
      _t('सध्याचे स्थान वापरा (GPS)', 'वर्तमान स्थान उपयोग करें (GPS)', 'Use Current Location (GPS)');
  String get useGpsHint => _t(
        'स्थानिक सूर्योदय, सूर्यास्त व मुहूर्त स्वयंचलित सेट करा',
        'स्थानीय सूर्योदय, सूर्यास्त व मुहूर्त अपने आप सेट करें',
        'Auto-detect exact sunrise, sunset & muhurat',
      );
  String get searchCity => _t(
        'शहर शोधा (उदा. पुणे, मुंबई, काशी, अयोध्या)...',
        'शहर खोजें (जैसे पुणे, मुंबई, काशी, अयोध्या)...',
        'Search city (e.g. Pune, Mumbai, Kashi)...',
      );
  String locationFound(String city) =>
      _t('📍 स्थान शोधले: $city', '📍 स्थान मिला: $city', '📍 Location found: $city');
  String get locationFailed => _t(
        'स्थान शोधण्यात अडचण आली. कृपया सूचीमधून निवडा.',
        'स्थान नहीं मिल सका। कृपया सूची से चुनें।',
        'Could not detect location. Please pick from the list.',
      );
  String citySelected(String city) =>
      _t('📍 शहर: $city निवडले!', '📍 शहर: $city चुना गया!', '📍 City: $city selected!');
}
