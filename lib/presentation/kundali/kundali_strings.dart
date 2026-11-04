import '../../services/kundali/vedic_astro_engine.dart';

/// Kundali screen copy and astrological names in Marathi, Hindi and English.
class KundaliStrings {
  const KundaliStrings(this.lang);

  final String lang;

  bool get isEn => lang == 'en';

  String _t(String mr, String hi, String en) =>
      lang == 'en' ? en : (lang == 'hi' ? hi : mr);

  // ── Screen copy ──────────────────────────────────────────────────────────
  String get title => _t('जन्मकुंडली', 'जन्म कुंडली', 'Janam Kundali');
  String get subtitle => _t(
        'जन्मतारीख, वेळ व ठिकाणावरून वैदिक कुंडली',
        'जन्म तिथि, समय और स्थान से वैदिक कुंडली',
        'Vedic birth chart from date, time & place of birth',
      );
  String get newKundali => _t('नवीन कुंडली बनवा', 'नई कुंडली बनाएँ', 'Create new Kundali');
  String get savedKundalis => _t('जतन केलेल्या कुंडल्या', 'सहेजी गई कुंडलियाँ', 'Saved Kundalis');
  String get emptySaved => _t(
        'अजून कोणतीही कुंडली नाही. स्वतःची किंवा कुटुंबातील व्यक्तीची कुंडली बनवा.',
        'अभी कोई कुंडली नहीं है। अपनी या परिवार के किसी सदस्य की कुंडली बनाएँ।',
        'No Kundalis yet. Create one for yourself or a family member.',
      );
  String get delete => _t('हटवा', 'हटाएँ', 'Delete');
  String get edit => _t('बदला', 'बदलें', 'Edit');
  String deleteConfirm(String name) => _t(
        '"$name" यांची कुंडली हटवायची?',
        '"$name" की कुंडली हटाएँ?',
        'Delete the Kundali of "$name"?',
      );
  String get cancel => _t('रद्द करा', 'रद्द करें', 'Cancel');

  // Form
  String get birthDetails => _t('जन्म तपशील', 'जन्म विवरण', 'Birth details');
  String get name => _t('नाव', 'नाम', 'Name');
  String get nameHint => _t('उदा. आदित्य', 'उदा. आदित्य', 'e.g. Aditya');
  String get birthDate => _t('जन्मतारीख', 'जन्म तिथि', 'Date of birth');
  String get birthTime => _t('जन्मवेळ', 'जन्म समय', 'Time of birth');
  String get birthPlace => _t('जन्मस्थान', 'जन्म स्थान', 'Place of birth');
  String get select => _t('निवडा', 'चुनें', 'Select');
  String get searchPlace =>
      _t('गाव / शहराचे नाव शोधा', 'गाँव / शहर का नाम खोजें', 'Search town or city');
  String get popularPlaces => _t('प्रमुख शहरे', 'प्रमुख शहर', 'Popular cities');
  String get searchResults => _t('शोध परिणाम', 'खोज परिणाम', 'Search results');
  String get noPlaceFound => _t(
        'ठिकाण सापडले नाही. इंटरनेट तपासा किंवा दुसरे नाव वापरून पाहा.',
        'स्थान नहीं मिला। इंटरनेट जाँचें या दूसरा नाम आज़माएँ।',
        'No place found. Check your internet or try another spelling.',
      );
  String get showKundali => _t('कुंडली पाहा', 'कुंडली देखें', 'Show Kundali');
  String get fillAll => _t(
        'कृपया नाव, तारीख, वेळ व जन्मस्थान भरा.',
        'कृपया नाम, तिथि, समय और जन्म स्थान भरें।',
        'Please fill in name, date, time and place of birth.',
      );
  String get timeTip => _t(
        'अचूक लग्नासाठी जन्मवेळ शक्य तितकी अचूक द्या.',
        'सटीक लग्न के लिए जन्म समय यथासंभव सही दें।',
        'Enter the birth time as precisely as possible for an accurate Lagna.',
      );

  // Result
  String get lagnaChart => _t('लग्न कुंडली', 'लग्न कुंडली', 'Lagna (D1)');
  String get chandraChart => _t('चंद्र कुंडली', 'चंद्र कुंडली', 'Chandra');
  String get navamsaChart => _t('नवमांश', 'नवांश', 'Navamsa (D9)');
  String get lagna => _t('लग्न', 'लग्न', 'Lagna');
  String get rashi => _t('राशी', 'राशि', 'Moon sign');
  String get sign => _t('राशी', 'राशि', 'Sign');
  String get nakshatra => _t('नक्षत्र', 'नक्षत्र', 'Nakshatra');
  String get suryaRashi => _t('सूर्य राशी', 'सूर्य राशि', 'Sun sign');
  String get pada => _t('चरण', 'चरण', 'Pada');
  String get nakshatraLord => _t('नक्षत्र स्वामी', 'नक्षत्र स्वामी', 'Nakshatra lord');
  String get grahaPositions => _t('ग्रह स्थिती', 'ग्रह स्थिति', 'Planetary positions');
  String get graha => _t('ग्रह', 'ग्रह', 'Graha');
  String get degree => _t('अंश', 'अंश', 'Degree');
  String get house => _t('भाव', 'भाव', 'House');
  String get retrograde => _t('वक्री', 'वक्री', 'Retrograde');
  String get retroMark => _t('व', 'व', 'R');
  String get vimshottari => _t('विंशोत्तरी महादशा', 'विंशोत्तरी महादशा', 'Vimshottari Mahadasha');
  String get current => _t('चालू', 'वर्तमान', 'Current');
  String get antardasha => _t('अंतर्दशा', 'अंतर्दशा', 'Antardasha');
  String get chartNote => _t(
        'उत्तर भारतीय शैली • लाहिरी अयनांश • भाव क्रमांक स्थिर, आकडे राशी दर्शवतात',
        'उत्तर भारतीय शैली • लाहिरी अयनांश • भाव स्थिर, अंक राशि दर्शाते हैं',
        'North Indian style • Lahiri ayanamsa • numbers show the rashi in each house',
      );
  String get ayanamsa => _t('अयनांश', 'अयनांश', 'Ayanamsa');
  String get utcOffset => _t('वेळ क्षेत्र', 'समय क्षेत्र', 'Time zone');

  // ── Astrological names ───────────────────────────────────────────────────
  static const _rashiMr = [
    'मेष', 'वृषभ', 'मिथुन', 'कर्क', 'सिंह', 'कन्या',
    'तूळ', 'वृश्चिक', 'धनु', 'मकर', 'कुंभ', 'मीन',
  ];
  static const _rashiHi = [
    'मेष', 'वृषभ', 'मिथुन', 'कर्क', 'सिंह', 'कन्या',
    'तुला', 'वृश्चिक', 'धनु', 'मकर', 'कुंभ', 'मीन',
  ];
  static const _rashiEn = [
    'Aries', 'Taurus', 'Gemini', 'Cancer', 'Leo', 'Virgo',
    'Libra', 'Scorpio', 'Sagittarius', 'Capricorn', 'Aquarius', 'Pisces',
  ];

  String rashiName(int index) =>
      (isEn ? _rashiEn : (lang == 'hi' ? _rashiHi : _rashiMr))[index % 12];

  static const _grahaMr = [
    'सूर्य', 'चंद्र', 'मंगळ', 'बुध', 'गुरु', 'शुक्र', 'शनि', 'राहू', 'केतू',
  ];
  static const _grahaHi = [
    'सूर्य', 'चंद्र', 'मंगल', 'बुध', 'गुरु', 'शुक्र', 'शनि', 'राहु', 'केतु',
  ];
  static const _grahaEn = [
    'Sun', 'Moon', 'Mars', 'Mercury', 'Jupiter', 'Venus', 'Saturn', 'Rahu', 'Ketu',
  ];
  static const _grahaShortDev = ['सू', 'चं', 'मं', 'बु', 'गु', 'शु', 'श', 'रा', 'के'];
  static const _grahaShortEn = ['Su', 'Mo', 'Ma', 'Me', 'Ju', 'Ve', 'Sa', 'Ra', 'Ke'];

  String grahaName(Graha g) =>
      (isEn ? _grahaEn : (lang == 'hi' ? _grahaHi : _grahaMr))[g.index];
  String grahaShort(Graha g) => (isEn ? _grahaShortEn : _grahaShortDev)[g.index];
  String get lagnaShort => _t('ल', 'ल', 'As');

  static const _nakMr = [
    'अश्विनी', 'भरणी', 'कृत्तिका', 'रोहिणी', 'मृग', 'आर्द्रा', 'पुनर्वसू',
    'पुष्य', 'आश्लेषा', 'मघा', 'पूर्वा फाल्गुनी', 'उत्तरा फाल्गुनी', 'हस्त',
    'चित्रा', 'स्वाती', 'विशाखा', 'अनुराधा', 'ज्येष्ठा', 'मूळ', 'पूर्वाषाढा',
    'उत्तराषाढा', 'श्रवण', 'धनिष्ठा', 'शततारका', 'पूर्वा भाद्रपदा',
    'उत्तरा भाद्रपदा', 'रेवती',
  ];
  static const _nakHi = [
    'अश्विनी', 'भरणी', 'कृत्तिका', 'रोहिणी', 'मृगशिरा', 'आर्द्रा', 'पुनर्वसु',
    'पुष्य', 'आश्लेषा', 'मघा', 'पूर्वा फाल्गुनी', 'उत्तरा फाल्गुनी', 'हस्त',
    'चित्रा', 'स्वाति', 'विशाखा', 'अनुराधा', 'ज्येष्ठा', 'मूल', 'पूर्वाषाढ़ा',
    'उत्तराषाढ़ा', 'श्रवण', 'धनिष्ठा', 'शतभिषा', 'पूर्वा भाद्रपद',
    'उत्तरा भाद्रपद', 'रेवती',
  ];
  static const _nakEn = [
    'Ashwini', 'Bharani', 'Krittika', 'Rohini', 'Mrigashira', 'Ardra', 'Punarvasu',
    'Pushya', 'Ashlesha', 'Magha', 'Purva Phalguni', 'Uttara Phalguni', 'Hasta',
    'Chitra', 'Swati', 'Vishakha', 'Anuradha', 'Jyeshtha', 'Mula', 'Purva Ashadha',
    'Uttara Ashadha', 'Shravana', 'Dhanishta', 'Shatabhisha', 'Purva Bhadrapada',
    'Uttara Bhadrapada', 'Revati',
  ];

  String nakshatraName(int index) =>
      (isEn ? _nakEn : (lang == 'hi' ? _nakHi : _nakMr))[index % 27];

  // ── Numbers & dates ──────────────────────────────────────────────────────
  static const _dev = ['०', '१', '२', '३', '४', '५', '६', '७', '८', '९'];

  /// Converts ASCII digits to Devanagari for Marathi and Hindi.
  String num(Object value) {
    final s = value.toString();
    if (isEn) return s;
    return s.replaceAllMapped(RegExp(r'\d'), (m) => _dev[int.parse(m[0]!)]);
  }

  /// `12° 34'` style degree within a rashi.
  String degrees(double deg) {
    final d = deg.floor();
    final m = ((deg - d) * 60).floor();
    return num("$d° ${m.toString().padLeft(2, '0')}'");
  }

  static const _monthMr = [
    'जानेवारी', 'फेब्रुवारी', 'मार्च', 'एप्रिल', 'मे', 'जून',
    'जुलै', 'ऑगस्ट', 'सप्टेंबर', 'ऑक्टोबर', 'नोव्हेंबर', 'डिसेंबर',
  ];
  static const _monthHi = [
    'जनवरी', 'फ़रवरी', 'मार्च', 'अप्रैल', 'मई', 'जून',
    'जुलाई', 'अगस्त', 'सितंबर', 'अक्टूबर', 'नवंबर', 'दिसंबर',
  ];
  static const _monthEn = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  String date(DateTime d) {
    final month = (isEn ? _monthEn : (lang == 'hi' ? _monthHi : _monthMr))[d.month - 1];
    return num('${d.day} $month ${d.year}');
  }

  String monthYear(DateTime d) {
    final month = (isEn ? _monthEn : (lang == 'hi' ? _monthHi : _monthMr))[d.month - 1];
    return num('$month ${d.year}');
  }

  String time(DateTime d) {
    final h12 = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final mm = d.minute.toString().padLeft(2, '0');
    if (isEn) return '$h12:$mm ${d.hour < 12 ? 'AM' : 'PM'}';
    final h = d.hour;
    final period = h < 4 || h >= 20
        ? _t('रात्री', 'रात', '')
        : h < 12
            ? _t('सकाळी', 'सुबह', '')
            : h < 17
                ? _t('दुपारी', 'दोपहर', '')
                : _t('संध्याकाळी', 'शाम', '');
    return '$period ${num('$h12:$mm')}';
  }

  String offset(Duration o) {
    final sign = o.isNegative ? '−' : '+';
    final mins = o.inMinutes.abs();
    return num('UTC $sign${mins ~/ 60}:${(mins % 60).toString().padLeft(2, '0')}');
  }
}
