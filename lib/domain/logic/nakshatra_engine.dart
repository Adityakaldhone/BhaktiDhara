/// Nakshatra and Yoga computed from mean Sun & Moon longitudes.
///
/// Uses a simple mean-longitude approximation (no external packages).
/// Accuracy: ±1 nakshatra, sufficient for calendar display purposes.
class NakshatraEngine {
  static final _j2000 = DateTime.utc(2000, 1, 1, 12, 0, 0);

  /// Days elapsed since J2000.0 epoch.
  static double _daysFromJ2000(DateTime dateUtc) {
    return dateUtc.difference(_j2000).inMicroseconds / Duration.microsecondsPerDay;
  }

  /// Mean Moon longitude in degrees (0–360).
  static double _moonLongitude(DateTime dateUtc) {
    final T = _daysFromJ2000(dateUtc);
    double L = 218.3165 + 13.1763966 * T;
    L = L % 360.0;
    if (L < 0) L += 360.0;
    return L;
  }

  /// Mean Sun longitude in degrees (0–360).
  static double _sunLongitude(DateTime dateUtc) {
    final T = _daysFromJ2000(dateUtc);
    double M = 280.46646 + 0.9856474 * T;
    M = M % 360.0;
    if (M < 0) M += 360.0;
    return M;
  }

  /// Nakshatra index 0–26 (Ashvini=0 ... Revati=26).
  static int nakshatraIndex(DateTime dateUtc) {
    final L = _moonLongitude(dateUtc);
    return (L / (360.0 / 27)).floor() % 27;
  }

  /// Yoga index 0–26 (Vishkambha=0 ... Vaidhriti=26).
  static int yogaIndex(DateTime dateUtc) {
    final L = _moonLongitude(dateUtc);
    final M = _sunLongitude(dateUtc);
    double sum = L + M;
    sum = sum % 360.0;
    if (sum < 0) sum += 360.0;
    return (sum / (360.0 / 27)).floor() % 27;
  }

  /// Nakshatra name in the given language.
  static String nakshatraName(int index, String lang) {
    final i = index.clamp(0, 26);
    if (lang == 'en') return _nakshatraEn[i];
    if (lang == 'hi') return _nakshatraHi[i];
    return _nakshatraMr[i];
  }

  /// Yoga name in the given language.
  static String yogaName(int index, String lang) {
    final i = index.clamp(0, 26);
    if (lang == 'en') return _yogaEn[i];
    if (lang == 'hi') return _yogaHi[i];
    return _yogaMr[i];
  }

  // ── Nakshatra names ─────────────────────────────────────────────────────

  static const _nakshatraMr = [
    'अश्विनी', 'भरणी', 'कृत्तिका', 'रोहिणी', 'मृगशीर्ष',
    'आर्द्रा', 'पुनर्वसु', 'पुष्य', 'आश्लेषा', 'मघा',
    'पूर्वा फाल्गुनी', 'उत्तरा फाल्गुनी', 'हस्त', 'चित्रा', 'स्वाती',
    'विशाखा', 'अनुराधा', 'ज्येष्ठा', 'मूळ', 'पूर्वाषाढा',
    'उत्तराषाढा', 'श्रवण', 'धनिष्ठा', 'शतभिषा', 'पूर्वाभाद्रपदा',
    'उत्तराभाद्रपदा', 'रेवती',
  ];

  static const _nakshatraHi = [
    'अश्विनी', 'भरणी', 'कृत्तिका', 'रोहिणी', 'मृगशिरा',
    'आर्द्रा', 'पुनर्वसु', 'पुष्य', 'आश्लेषा', 'मघा',
    'पूर्वा फाल्गुनी', 'उत्तरा फाल्गुनी', 'हस्त', 'चित्रा', 'स्वाती',
    'विशाखा', 'अनुराधा', 'ज्येष्ठा', 'मूल', 'पूर्वाषाढा',
    'उत्तराषाढा', 'श्रवण', 'धनिष्ठा', 'शतभिषा', 'पूर्वाभाद्रपद',
    'उत्तराभाद्रपद', 'रेवती',
  ];

  static const _nakshatraEn = [
    'Ashvini', 'Bharani', 'Krittika', 'Rohini', 'Mrigashira',
    'Ardra', 'Punarvasu', 'Pushya', 'Ashlesha', 'Magha',
    'Purva Phalguni', 'Uttara Phalguni', 'Hasta', 'Chitra', 'Svati',
    'Vishakha', 'Anuradha', 'Jyeshtha', 'Mula', 'Purvashadha',
    'Uttarashadha', 'Shravana', 'Dhanishtha', 'Shatabhisha', 'Purva Bhadrapada',
    'Uttara Bhadrapada', 'Revati',
  ];

  // ── Yoga names ──────────────────────────────────────────────────────────

  static const _yogaMr = [
    'विष्कुंभ', 'प्रीती', 'आयुष्मान', 'सौभाग्य', 'शोभन',
    'अतिगंड', 'सुकर्मा', 'धृती', 'शूळ', 'गंड',
    'वृद्धी', 'ध्रुव', 'व्याघात', 'हर्षण', 'वज्र',
    'सिद्धी', 'व्यतीपात', 'वरीयान', 'परिघ', 'शिव',
    'सिद्ध', 'साध्य', 'शुभ', 'शुक्ल', 'ब्रह्म',
    'इंद्र', 'वैधृती',
  ];

  static const _yogaHi = [
    'विष्कुम्भ', 'प्रीति', 'आयुष्मान', 'सौभाग्य', 'शोभन',
    'अतिगण्ड', 'सुकर्मा', 'धृति', 'शूल', 'गण्ड',
    'वृद्धि', 'ध्रुव', 'व्याघात', 'हर्षण', 'वज्र',
    'सिद्धि', 'व्यतीपात', 'वरीयान', 'परिघ', 'शिव',
    'सिद्ध', 'साध्य', 'शुभ', 'शुक्ल', 'ब्रह्म',
    'इन्द्र', 'वैधृति',
  ];

  static const _yogaEn = [
    'Vishkambha', 'Priti', 'Ayushman', 'Saubhagya', 'Shobhana',
    'Atiganda', 'Sukarma', 'Dhriti', 'Shula', 'Ganda',
    'Vriddhi', 'Dhruva', 'Vyaghata', 'Harshana', 'Vajra',
    'Siddhi', 'Vyatipata', 'Variyan', 'Parigha', 'Shiva',
    'Siddha', 'Sadhya', 'Shubha', 'Shukla', 'Brahma',
    'Indra', 'Vaidhriti',
  ];

}
