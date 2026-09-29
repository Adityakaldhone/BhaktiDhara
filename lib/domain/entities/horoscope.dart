/// Model representing a Zodiac sign (Rashi) in Vedic astrology.
class Rashi {
  final String id;
  final String nameMr;
  final String nameHi;
  final String nameEn;
  final String symbol;
  final String rulingPlanet;
  final String element;
  final String dateRange;

  const Rashi({
    required this.id,
    required this.nameMr,
    required this.nameHi,
    required this.nameEn,
    required this.symbol,
    required this.rulingPlanet,
    required this.element,
    required this.dateRange,
  });

  String localizedName(String langCode) {
    switch (langCode) {
      case 'hi':
        return nameHi;
      case 'en':
        return nameEn;
      case 'mr':
      default:
        return nameMr;
    }
  }
}

/// The 12 sacred Vedic Rashis (Zodiac signs).
const List<Rashi> kAllRashis = [
  Rashi(
    id: 'aries',
    nameMr: 'मेष',
    nameHi: 'मेष',
    nameEn: 'Aries',
    symbol: '♈',
    rulingPlanet: 'मंगळ (Mars)',
    element: 'अग्नी (Fire)',
    dateRange: '२१ मार्च - १९ एप्रिल',
  ),
  Rashi(
    id: 'taurus',
    nameMr: 'वृषभ',
    nameHi: 'वृषभ',
    nameEn: 'Taurus',
    symbol: '♉',
    rulingPlanet: 'शुक्र (Venus)',
    element: 'पृथ्वी (Earth)',
    dateRange: '२० एप्रिल - २० मे',
  ),
  Rashi(
    id: 'gemini',
    nameMr: 'मिथुन',
    nameHi: 'मिथुन',
    nameEn: 'Gemini',
    symbol: '♊',
    rulingPlanet: 'बुध (Mercury)',
    element: 'वायू (Air)',
    dateRange: '२१ मे - २० जून',
  ),
  Rashi(
    id: 'cancer',
    nameMr: 'कर्क',
    nameHi: 'कर्क',
    nameEn: 'Cancer',
    symbol: '♋',
    rulingPlanet: 'चंद्र (Moon)',
    element: 'जल (Water)',
    dateRange: '२१ जून - २२ जुलै',
  ),
  Rashi(
    id: 'leo',
    nameMr: 'सिंह',
    nameHi: 'सिंह',
    nameEn: 'Leo',
    symbol: '♌',
    rulingPlanet: 'सूर्य (Sun)',
    element: 'अग्नी (Fire)',
    dateRange: '२३ जुलै - २२ ऑगस्ट',
  ),
  Rashi(
    id: 'virgo',
    nameMr: 'कन्या',
    nameHi: 'कन्या',
    nameEn: 'Virgo',
    symbol: '♍',
    rulingPlanet: 'बुध (Mercury)',
    element: 'पृथ्वी (Earth)',
    dateRange: '२३ ऑगस्ट - २२ सप्टेंबर',
  ),
  Rashi(
    id: 'libra',
    nameMr: 'तुला',
    nameHi: 'तुला',
    nameEn: 'Libra',
    symbol: '♎',
    rulingPlanet: 'शुक्र (Venus)',
    element: 'वायू (Air)',
    dateRange: '२३ सप्टेंबर - २२ ऑक्टोबर',
  ),
  Rashi(
    id: 'scorpio',
    nameMr: 'वृश्चिक',
    nameHi: 'वृश्चिक',
    nameEn: 'Scorpio',
    symbol: '♏',
    rulingPlanet: 'मंगळ (Mars)',
    element: 'जल (Water)',
    dateRange: '२३ ऑक्टोबर - २१ नोव्हेंबर',
  ),
  Rashi(
    id: 'sagittarius',
    nameMr: 'धनु',
    nameHi: 'धनु',
    nameEn: 'Sagittarius',
    symbol: '♐',
    rulingPlanet: 'गुरु (Jupiter)',
    element: 'अग्नी (Fire)',
    dateRange: '२२ नोव्हेंबर - २१ डिसेंबर',
  ),
  Rashi(
    id: 'capricorn',
    nameMr: 'मकर',
    nameHi: 'मकर',
    nameEn: 'Capricorn',
    symbol: '♑',
    rulingPlanet: 'शनि (Saturn)',
    element: 'पृथ्वी (Earth)',
    dateRange: '२२ डिसेंबर - १९ जानेवारी',
  ),
  Rashi(
    id: 'aquarius',
    nameMr: 'कुंभ',
    nameHi: 'कुंभ',
    nameEn: 'Aquarius',
    symbol: '♒',
    rulingPlanet: 'शनि (Saturn)',
    element: 'वायू (Air)',
    dateRange: '२० जानेवारी - १८ फेब्रुवारी',
  ),
  Rashi(
    id: 'pisces',
    nameMr: 'मीन',
    nameHi: 'मीन',
    nameEn: 'Pisces',
    symbol: '♓',
    rulingPlanet: 'गुरु (Jupiter)',
    element: 'जल (Water)',
    dateRange: '१९ फेब्रुवारी - २० मार्च',
  ),
];

/// Structured astrological horoscope reading returned from Gemini / Vedic source.
class HoroscopeReading {
  final String rashiId;
  final String period; // 'today', 'tomorrow', 'weekly'
  final String dateText;
  final String summary;
  final String career;
  final String health;
  final String love;
  final String luckyNumber;
  final String luckyColor;
  final String remedy;
  final int auspiciousPercentage;
  final bool isAiGenerated;

  const HoroscopeReading({
    required this.rashiId,
    required this.period,
    required this.dateText,
    required this.summary,
    required this.career,
    required this.health,
    required this.love,
    required this.luckyNumber,
    required this.luckyColor,
    required this.remedy,
    this.auspiciousPercentage = 85,
    this.isAiGenerated = true,
  });

  factory HoroscopeReading.fromJson(
    Map<String, dynamic> json, {
    required String rashiId,
    required String period,
    required String dateText,
    bool isAiGenerated = true,
  }) {
    return HoroscopeReading(
      rashiId: rashiId,
      period: period,
      dateText: dateText,
      summary: json['summary']?.toString() ?? '',
      career: json['career']?.toString() ?? '',
      health: json['health']?.toString() ?? '',
      love: json['love']?.toString() ?? '',
      luckyNumber: json['luckyNumber']?.toString() ?? '७',
      luckyColor: json['luckyColor']?.toString() ?? 'केशरी (Saffron)',
      remedy: json['remedy']?.toString() ?? 'श्री गणेशाय नमः जप करा.',
      auspiciousPercentage:
          (json['auspiciousPercentage'] is num)
              ? (json['auspiciousPercentage'] as num).toInt()
              : 85,
      isAiGenerated: isAiGenerated,
    );
  }
}
