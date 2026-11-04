import '../../services/kundali/guna_milan.dart';
import '../../services/kundali/vedic_astro_engine.dart';
import 'kundali_strings.dart';

/// Kundali Milan copy in Marathi, Hindi and English.
class MilanStrings {
  MilanStrings(this.lang) : fmt = KundaliStrings(lang);

  final String lang;
  final KundaliStrings fmt;

  bool get isEn => lang == 'en';

  String _t(String mr, String hi, String en) =>
      lang == 'en' ? en : (lang == 'hi' ? hi : mr);

  List<String> _pick(List<String> mr, List<String> hi, List<String> en) =>
      lang == 'en' ? en : (lang == 'hi' ? hi : mr);

  String get title => _t('कुंडली मिलन', 'कुंडली मिलान', 'Kundali Milan');
  String get subtitle => _t(
        'अष्टकूट गुणमिलन व मंगळ दोष तपासणी',
        'अष्टकूट गुण मिलान और मांगलिक दोष जाँच',
        'Ashtakoota guna matching & Manglik check',
      );
  String get groom => _t('वर', 'वर', 'Groom');
  String get bride => _t('वधू', 'वधू', 'Bride');
  String get choose => _t('कुंडली निवडा', 'कुंडली चुनें', 'Choose a Kundali');
  String get noSaved => _t(
        'अजून जतन केलेली कुंडली नाही. खालील बटणाने नवीन कुंडली बनवा.',
        'अभी कोई सहेजी गई कुंडली नहीं है। नीचे के बटन से नई कुंडली बनाएँ।',
        'No saved Kundalis yet. Create one with the button below.',
      );
  String get pickBoth => _t(
        'गुणमिलन पाहण्यासाठी वर व वधू दोघांची कुंडली निवडा.',
        'गुण मिलान देखने के लिए वर और वधू दोनों की कुंडली चुनें।',
        'Choose the groom’s and the bride’s Kundali to see the match.',
      );
  String get samePerson => _t(
        'वर व वधूसाठी वेगवेगळ्या कुंडल्या निवडा.',
        'वर और वधू के लिए अलग-अलग कुंडली चुनें।',
        'Choose two different Kundalis for the groom and the bride.',
      );
  String get swap => _t('अदलाबदल', 'अदला-बदली', 'Swap');

  // ── Score ────────────────────────────────────────────────────────────────
  String score(double v) =>
      fmt.num(v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(1));
  String outOf36(double total) =>
      _t('३६ पैकी ${score(total)} गुण', '३६ में से ${score(total)} गुण', '${score(total)} of 36 gunas');
  String get gunas => _t('गुण', 'गुण', 'Gunas');
  String get kootaDetails => _t('अष्टकूट तपशील', 'अष्टकूट विवरण', 'Ashtakoota details');

  String verdict(MilanVerdict v) => switch (v) {
        MilanVerdict.notRecommended =>
          _t('अनुकूल नाही', 'अनुकूल नहीं', 'Not recommended'),
        MilanVerdict.average => _t('साधारण जुळणी', 'सामान्य मिलान', 'Average match'),
        MilanVerdict.good => _t('उत्तम जुळणी', 'उत्तम मिलान', 'Good match'),
        MilanVerdict.excellent => _t('अतिउत्तम जुळणी', 'अति उत्तम मिलान', 'Excellent match'),
      };

  String verdictNote(MilanVerdict v) => switch (v) {
        MilanVerdict.notRecommended => _t(
            '१८ पेक्षा कमी गुण — परंपरेनुसार विवाहासाठी अनुकूल मानले जात नाही.',
            '१८ से कम गुण — परंपरा के अनुसार विवाह के लिए अनुकूल नहीं माना जाता।',
            'Below 18 gunas — traditionally not considered favourable for marriage.',
          ),
        MilanVerdict.average => _t(
            '१८ ते २४ गुण — विवाहासाठी स्वीकार्य मध्यम जुळणी.',
            '१८ से २४ गुण — विवाह के लिए स्वीकार्य मध्यम मिलान।',
            '18–24 gunas — an acceptable, moderate match.',
          ),
        MilanVerdict.good => _t(
            '२५ ते ३२ गुण — चांगली जुळणी मानली जाते.',
            '२५ से ३२ गुण — अच्छा मिलान माना जाता है।',
            '25–32 gunas — considered a good match.',
          ),
        MilanVerdict.excellent => _t(
            '३२ पेक्षा अधिक गुण — अतिशय उत्तम जुळणी.',
            '३२ से अधिक गुण — अत्यंत उत्तम मिलान।',
            'Above 32 gunas — an excellent match.',
          ),
      };

  // ── Kootas ───────────────────────────────────────────────────────────────
  String kootaName(Koota k) => _pick(
        ['वर्ण', 'वश्य', 'तारा', 'योनी', 'ग्रहमैत्री', 'गण', 'भकूट', 'नाडी'],
        ['वर्ण', 'वश्य', 'तारा', 'योनि', 'ग्रह मैत्री', 'गण', 'भकूट', 'नाड़ी'],
        ['Varna', 'Vashya', 'Tara', 'Yoni', 'Graha Maitri', 'Gana', 'Bhakoot', 'Nadi'],
      )[k.index];

  String kootaMeaning(Koota k) => _pick(
        [
          'कार्य व स्वभाव', 'परस्पर आकर्षण', 'आरोग्य व भाग्य', 'शारीरिक अनुरूपता',
          'मानसिक मैत्री', 'स्वभाव', 'प्रेम व कौटुंबिक सुख', 'आरोग्य व संतती',
        ],
        [
          'कर्म और स्वभाव', 'परस्पर आकर्षण', 'स्वास्थ्य और भाग्य', 'शारीरिक अनुकूलता',
          'मानसिक मैत्री', 'स्वभाव', 'प्रेम और पारिवारिक सुख', 'स्वास्थ्य और संतान',
        ],
        [
          'Work & nature', 'Mutual attraction', 'Health & fortune', 'Physical compatibility',
          'Mental friendship', 'Temperament', 'Love & family welfare', 'Health & progeny',
        ],
      )[k.index];

  /// Name of a partner's category for [k] (see [KootaResult.boy]).
  String kootaValue(Koota k, int v) => switch (k) {
        Koota.varna => _pick(
            ['ब्राह्मण', 'क्षत्रिय', 'वैश्य', 'शूद्र'],
            ['ब्राह्मण', 'क्षत्रिय', 'वैश्य', 'शूद्र'],
            ['Brahmin', 'Kshatriya', 'Vaishya', 'Shudra'],
          )[v],
        Koota.vashya => _pick(
            ['चतुष्पद', 'मानव', 'जलचर', 'वनचर', 'कीटक'],
            ['चतुष्पद', 'मानव', 'जलचर', 'वनचर', 'कीट'],
            ['Quadruped', 'Human', 'Water', 'Wild', 'Insect'],
          )[v],
        Koota.tara => _pick(
            ['जन्म', 'संपत', 'विपत', 'क्षेम', 'प्रत्यरी', 'साधक', 'वध', 'मित्र', 'अतिमित्र'],
            ['जन्म', 'सम्पत', 'विपत', 'क्षेम', 'प्रत्यरि', 'साधक', 'वध', 'मित्र', 'अति मित्र'],
            ['Janma', 'Sampat', 'Vipat', 'Kshema', 'Pratyari', 'Sadhaka', 'Vadha', 'Mitra',
              'Ati-mitra'],
          )[v - 1],
        Koota.yoni => _pick(
            ['अश्व', 'गज', 'मेंढा', 'सर्प', 'श्वान', 'मार्जार', 'मूषक', 'गाय', 'महिष',
              'व्याघ्र', 'हरिण', 'वानर', 'मुंगूस', 'सिंह'],
            ['अश्व', 'गज', 'मेढ़ा', 'सर्प', 'श्वान', 'मार्जार', 'मूषक', 'गौ', 'महिष',
              'व्याघ्र', 'मृग', 'वानर', 'नकुल', 'सिंह'],
            ['Horse', 'Elephant', 'Sheep', 'Serpent', 'Dog', 'Cat', 'Rat', 'Cow', 'Buffalo',
              'Tiger', 'Deer', 'Monkey', 'Mongoose', 'Lion'],
          )[v],
        Koota.maitri => fmt.grahaName(Graha.values[v]),
        Koota.gana => _pick(
            ['देव', 'मनुष्य', 'राक्षस'],
            ['देव', 'मनुष्य', 'राक्षस'],
            ['Deva', 'Manushya', 'Rakshasa'],
          )[v],
        Koota.bhakoot => fmt.rashiName(v),
        Koota.nadi => _pick(
            ['आद्य', 'मध्य', 'अंत्य'],
            ['आदि', 'मध्य', 'अंत्य'],
            ['Aadi', 'Madhya', 'Antya'],
          )[v],
      };

  // ── Doshas ───────────────────────────────────────────────────────────────
  String get doshas => _t('दोष', 'दोष', 'Doshas');
  String get nadiDosha => _t('नाडी दोष', 'नाड़ी दोष', 'Nadi dosha');
  String get nadiDoshaNote => _t(
        'दोघांची नाडी एकच आहे; परंपरेने आरोग्य व संततीसाठी हा मोठा दोष मानला जातो.',
        'दोनों की नाड़ी एक ही है; परंपरा में इसे स्वास्थ्य और संतान के लिए बड़ा दोष माना जाता है।',
        'Both share the same Nadi — traditionally a major dosha for health and progeny.',
      );
  String get nadiCancelledNote => _t(
        'परिहार: राशी एक व नक्षत्र वेगळे, किंवा नक्षत्र एक व चरण वेगळे असल्याने दोष रद्द मानला जातो.',
        'परिहार: राशि एक और नक्षत्र अलग, या नक्षत्र एक और चरण अलग होने से दोष निरस्त माना जाता है।',
        'Cancelled: same rashi with different nakshatras, or same nakshatra with different padas.',
      );
  String get bhakootDosha => _t('भकूट दोष', 'भकूट दोष', 'Bhakoot dosha');
  String get bhakootDoshaNote => _t(
        'राशींचे परस्पर स्थान (२-१२, ५-९ किंवा ६-८) प्रतिकूल आहे.',
        'राशियों की परस्पर स्थिति (२-१२, ५-९ या ६-८) प्रतिकूल है।',
        'The Moon signs sit 2-12, 5-9 or 6-8 from each other, which is unfavourable.',
      );
  String get bhakootCancelledNote => _t(
        'परिहार: दोन्ही राशींचे स्वामी एकच किंवा परस्पर मित्र असल्याने दोष रद्द मानला जातो.',
        'परिहार: दोनों राशियों के स्वामी एक ही या परस्पर मित्र होने से दोष निरस्त माना जाता है।',
        'Cancelled: both Moon signs are ruled by the same or mutually friendly grahas.',
      );
  String get cancelled => _t('परिहार', 'परिहार', 'Cancelled');
  String get present => _t('आहे', 'है', 'Present');
  String get noMajorDosha => _t(
        'नाडी किंवा भकूट दोष नाही.',
        'नाड़ी या भकूट दोष नहीं है।',
        'No Nadi or Bhakoot dosha.',
      );

  // ── Manglik ──────────────────────────────────────────────────────────────
  String get manglik => _t('मंगळ दोष', 'मांगलिक दोष', 'Manglik (Mangal dosha)');
  String manglikStatus(ManglikStatus m) {
    if (m.fromLagna) return _t('मंगळ आहे', 'मांगलिक', 'Manglik');
    if (m.fromMoon) {
      return _t('सौम्य मंगळ (चंद्रापासून)', 'आंशिक मांगलिक (चंद्र से)', 'Mild (from Moon only)');
    }
    return _t('मंगळ नाही', 'मांगलिक नहीं', 'Not Manglik');
  }

  String marsHouses(ManglikStatus m) => _t(
        'मंगळ: लग्नापासून ${fmt.num(m.houseFromLagna)}, चंद्रापासून ${fmt.num(m.houseFromMoon)} वे स्थान',
        'मंगल: लग्न से ${fmt.num(m.houseFromLagna)}, चंद्र से ${fmt.num(m.houseFromMoon)} वाँ भाव',
        'Mars in house ${m.houseFromLagna} from Lagna, ${m.houseFromMoon} from Moon',
      );
  String manglikVerdict(MilanResult r) {
    if (!r.manglikMatch) {
      return _t(
        'एकाच व्यक्तीला मंगळ आहे — परंपरेनुसार जाणकारांचा सल्ला घ्यावा.',
        'केवल एक व्यक्ति मांगलिक है — परंपरा के अनुसार विद्वान की सलाह लें।',
        'Only one partner is Manglik — traditionally a learned astrologer is consulted.',
      );
    }
    if (r.boyManglik.isManglik) {
      return _t(
        'दोघांनाही मंगळ आहे, त्यामुळे दोष परस्पर रद्द होतो.',
        'दोनों मांगलिक हैं, इसलिए दोष परस्पर निरस्त होता है।',
        'Both are Manglik, so the dosha cancels out.',
      );
    }
    return _t(
      'दोघांनाही मंगळ नाही — या बाबतीत जुळणी योग्य आहे.',
      'दोनों मांगलिक नहीं हैं — इस दृष्टि से मिलान ठीक है।',
      'Neither is Manglik — no concern here.',
    );
  }

  String get disclaimer => _t(
        'गुणमिलन हे पारंपरिक मार्गदर्शन आहे. अंतिम निर्णयासाठी जाणकार ज्योतिषींचा सल्ला घ्या.',
        'गुण मिलान पारंपरिक मार्गदर्शन है। अंतिम निर्णय के लिए विद्वान ज्योतिषी से परामर्श करें।',
        'Guna milan is traditional guidance. Consult a learned astrologer before deciding.',
      );
}
