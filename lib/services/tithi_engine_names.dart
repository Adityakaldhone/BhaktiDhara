import 'package:tithi_engine/tithi_engine.dart';

/// Marathi / Hindi / English labels for `tithi_engine` value types.
class TithiEngineNames {
  const TithiEngineNames(this.lang);

  final String lang;

  String _t(String mr, String hi, String en) =>
      lang == 'en' ? en : (lang == 'hi' ? hi : mr);

  static const _tithiMr = [
    'प्रतिपदा', 'द्वितीया', 'तृतीया', 'चतुर्थी', 'पंचमी',
    'षष्ठी', 'सप्तमी', 'अष्टमी', 'नवमी', 'दशमी',
    'एकादशी', 'द्वादशी', 'त्रयोदशी', 'चतुर्दशी',
  ];
  static const _tithiEn = [
    'Pratipada', 'Dwitiya', 'Tritiya', 'Chaturthi', 'Panchami',
    'Shashti', 'Saptami', 'Ashtami', 'Navami', 'Dashami',
    'Ekadashi', 'Dwadashi', 'Trayodashi', 'Chaturdashi',
  ];

  /// Name of tithi [number] (1–30); the 15th is Purnima / Amavasya.
  String tithi(int number) {
    if (number == 15) return _t('पौर्णिमा', 'पूर्णिमा', 'Purnima');
    if (number == 30) return _t('अमावास्या', 'अमावस्या', 'Amavasya');
    final i = (number - 1) % 15;
    return lang == 'en' ? _tithiEn[i] : _tithiMr[i];
  }

  String paksha(Paksha p) => p == Paksha.shukla
      ? _t('शुक्ल पक्ष', 'शुक्ल पक्ष', 'Shukla Paksha')
      : _t('कृष्ण (वद्य) पक्ष', 'कृष्ण पक्ष', 'Krishna Paksha');

  String pakshaShort(Paksha p) => p == Paksha.shukla
      ? _t('शुक्ल', 'शुक्ल', 'Shukla')
      : _t('वद्य', 'कृष्ण', 'Krishna');

  static const _monthMr = [
    'चैत्र', 'वैशाख', 'ज्येष्ठ', 'आषाढ', 'श्रावण', 'भाद्रपद',
    'अश्विन', 'कार्तिक', 'मार्गशीर्ष', 'पौष', 'माघ', 'फाल्गुन',
  ];
  static const _monthHi = [
    'चैत्र', 'वैशाख', 'ज्येष्ठ', 'आषाढ़', 'श्रावण', 'भाद्रपद',
    'आश्विन', 'कार्तिक', 'मार्गशीर्ष', 'पौष', 'माघ', 'फाल्गुन',
  ];

  String month(LunarMonth m, {bool isAdhika = false}) {
    final base = lang == 'en'
        ? m.displayName
        : (lang == 'hi' ? _monthHi[m.index] : _monthMr[m.index]);
    return isAdhika ? '${_t('अधिक', 'अधिक', 'Adhika')} $base' : base;
  }

  String tithiLabel(TithiInfo info) =>
      '${month(info.month, isAdhika: info.isAdhika)} '
      '${pakshaShort(info.paksha)} ${tithi(info.tithiNumber)}';

  String monthSystem(MonthSystem s) => s == MonthSystem.amant
      ? _t('अमांत', 'अमांत', 'Amant')
      : _t('पौर्णिमांत', 'पूर्णिमांत', 'Purnimant');

  String muhurtaRule(MuhurtaRule r) => switch (r) {
        MuhurtaRule.sunrise => _t('सूर्योदय तिथी', 'उदया तिथि', 'Sunrise tithi'),
        MuhurtaRule.nishita => _t('निशीथ काळ', 'निशीथ काल', 'Nishita kaal'),
        MuhurtaRule.madhyahna => _t('मध्याह्न काळ', 'मध्याह्न काल', 'Madhyahna'),
        MuhurtaRule.pradosh => _t('प्रदोष काळ', 'प्रदोष काल', 'Pradosh kaal'),
      };

  static const _karanaMr = [
    'बव', 'बालव', 'कौलव', 'तैतिल', 'गरज', 'वणिज', 'विष्टी (भद्रा)',
    'शकुनी', 'चतुष्पाद', 'नाग', 'किंस्तुघ्न',
  ];
  static const _karanaHi = [
    'बव', 'बालव', 'कौलव', 'तैतिल', 'गर', 'वणिज', 'विष्टि (भद्रा)',
    'शकुनि', 'चतुष्पद', 'नाग', 'किंस्तुघ्न',
  ];
  static const _karanaEn = [
    'Bava', 'Balava', 'Kaulava', 'Taitila', 'Garaja', 'Vanija',
    'Vishti (Bhadra)', 'Shakuni', 'Chatushpada', 'Naga', 'Kimstughna',
  ];

  /// Karana for half-tithi index (0–59, see [karanaIndexOf]).
  String karana(int halfIndex) {
    final i = karanaIndexOf(halfIndex);
    return lang == 'en'
        ? _karanaEn[i]
        : (lang == 'hi' ? _karanaHi[i] : _karanaMr[i]);
  }

  /// Maps a half-tithi (0–59) to an index into the karana name tables:
  /// 0–6 movable karanas, 7 Shakuni, 8 Chatushpada, 9 Naga, 10 Kimstughna.
  static int karanaIndexOf(int halfIndex) {
    if (halfIndex == 0) return 10;
    if (halfIndex >= 57) return 7 + (halfIndex - 57);
    return (halfIndex - 1) % 7;
  }

  static bool isVishti(int halfIndex) => karanaIndexOf(halfIndex) == 6;

  String locationSource(LocationSource s) => s == LocationSource.cityCorrected
      ? _t('स्विस इफेमेरिस प्रमाणित', 'स्विस इफेमेरिस प्रमाणित',
          'Swiss Ephemeris verified')
      : _t('खगोलीय गणना', 'खगोलीय गणना', 'Astronomical calculation');

  /// Localized observance name; falls back to the engine's English name.
  String observance(String id, String fallback) {
    final names = _observanceNames[id];
    if (names == null) return fallback;
    return _t(names.$1, names.$2, names.$3);
  }

  static const Map<String, (String, String, String)> _observanceNames = {
    'maha_shivaratri': ('महाशिवरात्री', 'महाशिवरात्रि', 'Maha Shivaratri'),
    'ram_navami': ('श्रीराम नवमी', 'श्रीराम नवमी', 'Ram Navami'),
    'akshaya_tritiya': ('अक्षय्य तृतीया', 'अक्षय तृतीया', 'Akshaya Tritiya'),
    'guru_purnima': ('गुरुपौर्णिमा', 'गुरु पूर्णिमा', 'Guru Purnima'),
    'raksha_bandhan': (
      'रक्षाबंधन / नारळी पौर्णिमा',
      'रक्षाबंधन',
      'Raksha Bandhan / Narali Purnima'
    ),
    'janmashtami_smarta': (
      'श्रीकृष्ण जन्माष्टमी',
      'श्रीकृष्ण जन्माष्टमी',
      'Krishna Janmashtami'
    ),
    'ganesh_chaturthi': ('श्री गणेश चतुर्थी', 'गणेश चतुर्थी', 'Ganesh Chaturthi'),
    'vijayadashami': ('विजयादशमी (दसरा)', 'विजयादशमी (दशहरा)', 'Vijayadashami (Dussehra)'),
    'diwali': ('दिवाळी - लक्ष्मीपूजन', 'दीपावली - लक्ष्मी पूजन', 'Diwali - Lakshmi Puja'),
    'durga_ashtami': ('दुर्गाष्टमी', 'दुर्गाष्टमी', 'Durga Ashtami'),
    'nirjala_ekadashi': ('निर्जला एकादशी', 'निर्जला एकादशी', 'Nirjala Ekadashi'),
    'sharad_navratri': ('घटस्थापना (नवरात्रारंभ)', 'घटस्थापना (नवरात्रि आरंभ)', 'Ghatasthapana (Navratri begins)'),
    'maha_navami': ('महानवमी', 'महानवमी', 'Maha Navami'),
    'karva_chauth': ('करवा चौथ', 'करवा चौथ', 'Karva Chauth'),
    'bhai_dooj': ('भाऊबीज', 'भाई दूज', 'Bhai Dooj'),
    'khichdi_amavasya': ('पौष अमावास्या', 'पौष अमावस्या', 'Pausha Amavasya'),
    'gauri_tritiya': ('गौरी तृतीया', 'गौरी तृतीया', 'Gauri Tritiya'),
    'holi': ('होळी पौर्णिमा', 'होली', 'Holi'),
    'gudi_padwa': ('गुढीपाडवा', 'गुड़ी पड़वा / नववर्ष', 'Gudi Padwa'),
    'hanuman_jayanti': ('हनुमान जयंती', 'हनुमान जयंती', 'Hanuman Jayanti'),
    'vat_purnima': ('वटपौर्णिमा', 'वट पूर्णिमा', 'Vat Purnima'),
    'ashadhi_ekadashi': ('आषाढी एकादशी', 'देवशयनी एकादशी', 'Ashadhi Ekadashi'),
    'nag_panchami': ('नागपंचमी', 'नाग पंचमी', 'Nag Panchami'),
    'hartalika': ('हरतालिका', 'हरतालिका तीज', 'Hartalika'),
    'rishi_panchami': ('ऋषिपंचमी', 'ऋषि पंचमी', 'Rishi Panchami'),
    'anant_chaturdashi': ('अनंत चतुर्दशी', 'अनंत चतुर्दशी', 'Anant Chaturdashi'),
    'kojagiri_purnima': ('कोजागिरी पौर्णिमा', 'शरद पूर्णिमा', 'Kojagiri Purnima'),
    'dhanteras': ('धनत्रयोदशी', 'धनतेरस', 'Dhanteras'),
    'naraka_chaturdashi': ('नरक चतुर्दशी', 'नरक चतुर्दशी', 'Naraka Chaturdashi'),
    'bali_pratipada': ('दिवाळी पाडवा (बलिप्रतिपदा)', 'गोवर्धन पूजा', 'Diwali Padwa'),
    'kartiki_ekadashi': ('कार्तिकी एकादशी', 'देवउठनी एकादशी', 'Kartiki Ekadashi'),
    'tulsi_vivah': ('तुळशी विवाह', 'तुलसी विवाह', 'Tulsi Vivah'),
    'tripuri_purnima': ('त्रिपुरारी पौर्णिमा', 'कार्तिक पूर्णिमा', 'Tripuri Purnima'),
    'datta_jayanti': ('श्री दत्त जयंती', 'दत्तात्रेय जयंती', 'Datta Jayanti'),
    'vasant_panchami': ('वसंत पंचमी', 'वसंत पंचमी', 'Vasant Panchami'),
    'maghi_ganesh_jayanti': ('माघी गणेश जयंती', 'गणेश जयंती', 'Maghi Ganesh Jayanti'),
    'ratha_saptami': ('रथसप्तमी', 'रथ सप्तमी', 'Ratha Saptami'),
    'masik_krishna_ekadashi': ('एकादशी (वद्य)', 'एकादशी (कृष्ण)', 'Ekadashi (Krishna)'),
    'masik_shukla_ekadashi': ('एकादशी (शुक्ल)', 'एकादशी (शुक्ल)', 'Ekadashi (Shukla)'),
    'masik_purnima': ('पौर्णिमा', 'पूर्णिमा', 'Purnima'),
    'masik_amavasya': ('अमावास्या', 'अमावस्या', 'Amavasya'),
    'masik_krishna_ashtami': ('कालाष्टमी', 'कालाष्टमी', 'Kalashtami'),
    'masik_shukla_ashtami': ('दुर्गाष्टमी (मासिक)', 'मासिक दुर्गाष्टमी', 'Masik Durgashtami'),
    'sankashti_chaturthi': ('संकष्टी चतुर्थी', 'संकष्टी चतुर्थी', 'Sankashti Chaturthi'),
    'vinayaki_chaturthi': ('विनायकी चतुर्थी', 'विनायक चतुर्थी', 'Vinayaki Chaturthi'),
    'pradosh_shukla': ('प्रदोष (शुक्ल)', 'प्रदोष व्रत (शुक्ल)', 'Pradosh (Shukla)'),
    'pradosh_krishna': ('प्रदोष (वद्य)', 'प्रदोष व्रत (कृष्ण)', 'Pradosh (Krishna)'),
    'masik_shivaratri': ('मासिक शिवरात्री', 'मासिक शिवरात्रि', 'Masik Shivaratri'),
  };
}
