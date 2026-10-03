class CardDeity {
  final String id;
  final Map<String, String> name;
  final Map<String, String> jaykar;

  const CardDeity({
    required this.id,
    required this.name,
    required this.jaykar,
  });

  /// Deities still drawn as full-scene paintings because they have no cut-out in assets/bhakti/.
  static const _fullSceneIds = {'santoshi_mata', 'gayatri'};

  /// Card ids whose cut-out file in assets/bhakti/ has a different name.
  static const _bhaktiFileNames = {
    'mahadev': 'shiva',
    'datta': 'dutt',
    'lakshmi': 'laxmi',
    'venkatesh': 'Venkateswara',
    'shani': 'shanidev',
  };

  /// Cut-outs sit inside the arch on a halo; full scenes fill the arch.
  bool get isCutout => !_fullSceneIds.contains(id);

  String get asset => isCutout
      ? 'assets/bhakti/${_bhaktiFileNames[id] ?? id}.png'
      : 'assets/decorations/$id.png';

  String localizedName(String lang) => name[lang] ?? name['mr']!;

  String localizedJaykar(String lang) => jaykar[lang] ?? jaykar['mr']!;
}

/// Content for status cards. Everything ships inside the app, so cards work
/// offline and cannot be altered remotely.
class GreetingContent {
  static const deities = <CardDeity>[
    CardDeity(
      id: 'ganesh',
      name: {'mr': 'गणपती', 'hi': 'गणेश', 'en': 'Ganesh'},
      jaykar: {'mr': 'गणपती बाप्पा मोरया', 'hi': 'जय श्री गणेश', 'en': 'Jai Shri Ganesh'},    ),
    CardDeity(
      id: 'mahadev',
      name: {'mr': 'महादेव', 'hi': 'महादेव', 'en': 'Mahadev'},
      jaykar: {'mr': 'हर हर महादेव', 'hi': 'हर हर महादेव', 'en': 'Har Har Mahadev'},    ),
    CardDeity(
      id: 'vitthal',
      name: {'mr': 'विठ्ठल', 'hi': 'विट्ठल', 'en': 'Vitthal'},
      jaykar: {'mr': 'जय हरी विठ्ठल', 'hi': 'जय हरि विट्ठल', 'en': 'Jai Hari Vitthal'},    ),
    CardDeity(
      id: 'datta',
      name: {'mr': 'दत्तगुरू', 'hi': 'दत्तात्रेय', 'en': 'Datta'},
      jaykar: {'mr': 'श्री गुरुदेव दत्त', 'hi': 'श्री गुरुदेव दत्त', 'en': 'Shri Gurudev Datta'},    ),
    CardDeity(
      id: 'lakshmi',
      name: {'mr': 'महालक्ष्मी', 'hi': 'लक्ष्मी', 'en': 'Lakshmi'},
      jaykar: {'mr': 'जय महालक्ष्मी माता', 'hi': 'जय माँ लक्ष्मी', 'en': 'Jai Maa Lakshmi'},    ),
    CardDeity(
      id: 'hanuman',
      name: {'mr': 'हनुमान', 'hi': 'हनुमान', 'en': 'Hanuman'},
      jaykar: {'mr': 'जय बजरंगबली', 'hi': 'जय बजरंगबली', 'en': 'Jai Bajrangbali'},    ),
    CardDeity(
      id: 'khandoba',
      name: {'mr': 'खंडोबा', 'hi': 'खंडोबा', 'en': 'Khandoba'},
      jaykar: {'mr': 'येळकोट येळकोट जय मल्हार', 'hi': 'जय मल्हार', 'en': 'Jai Malhar'},    ),
    CardDeity(
      id: 'vishnu',
      name: {'mr': 'श्री विष्णू', 'hi': 'श्री विष्णु', 'en': 'Vishnu'},
      jaykar: {'mr': 'ॐ नमो नारायणाय', 'hi': 'ॐ नमो नारायणाय', 'en': 'Om Namo Narayanaya'},    ),
    CardDeity(
      id: 'saibaba',
      name: {'mr': 'साईबाबा', 'hi': 'साईं बाबा', 'en': 'Sai Baba'},
      jaykar: {'mr': 'ॐ साई राम', 'hi': 'ॐ साईं राम', 'en': 'Om Sai Ram'},    ),
    CardDeity(
      id: 'durga',
      name: {'mr': 'दुर्गा माता', 'hi': 'दुर्गा माँ', 'en': 'Durga'},
      jaykar: {'mr': 'जय अंबे जगदंबे', 'hi': 'जय माता दी', 'en': 'Jai Mata Di'},    ),
    CardDeity(
      id: 'rama',
      name: {'mr': 'श्रीराम', 'hi': 'श्रीराम', 'en': 'Shri Ram'},
      jaykar: {'mr': 'जय श्री राम', 'hi': 'जय श्री राम', 'en': 'Jai Shri Ram'},    ),
    CardDeity(
      id: 'krishna',
      name: {'mr': 'श्रीकृष्ण', 'hi': 'श्रीकृष्ण', 'en': 'Krishna'},
      jaykar: {'mr': 'जय श्री कृष्ण', 'hi': 'राधे राधे', 'en': 'Jai Shri Krishna'},    ),
    CardDeity(
      id: 'gajanan_maharaj',
      name: {'mr': 'गजानन महाराज', 'hi': 'गजानन महाराज', 'en': 'Gajanan Maharaj'},
      jaykar: {'mr': 'गण गण गणात बोते', 'hi': 'गण गण गणात बोते', 'en': 'Gan Gan Ganat Bote'},    ),
    CardDeity(
      id: 'venkatesh',
      name: {'mr': 'व्यंकटेश', 'hi': 'वेंकटेश्वर', 'en': 'Venkatesh'},
      jaykar: {'mr': 'गोविंदा गोविंदा', 'hi': 'गोविंदा गोविंदा', 'en': 'Govinda Govinda'},    ),
    CardDeity(
      id: 'santoshi_mata',
      name: {'mr': 'संतोषी माता', 'hi': 'संतोषी माता', 'en': 'Santoshi Mata'},
      jaykar: {'mr': 'जय संतोषी माता', 'hi': 'जय संतोषी माता', 'en': 'Jai Santoshi Maa'},    ),
    CardDeity(
      id: 'shani',
      name: {'mr': 'शनिदेव', 'hi': 'शनिदेव', 'en': 'Shani Dev'},
      jaykar: {'mr': 'ॐ शं शनैश्चराय नमः', 'hi': 'ॐ शं शनैश्चराय नमः', 'en': 'Om Shani Devaya Namah'},    ),
    CardDeity(
      id: 'bhairavnath',
      name: {'mr': 'भैरवनाथ', 'hi': 'काल भैरव', 'en': 'Bhairavnath'},
      jaykar: {'mr': 'भैरवनाथाच्या नावानं चांगभलं', 'hi': 'जय काल भैरव', 'en': 'Jai Kaal Bhairav'},    ),
    CardDeity(
      id: 'surya',
      name: {'mr': 'सूर्यदेव', 'hi': 'सूर्यदेव', 'en': 'Surya Dev'},
      jaykar: {'mr': 'ॐ सूर्याय नमः', 'hi': 'ॐ सूर्याय नमः', 'en': 'Om Suryaya Namah'},    ),
    CardDeity(
      id: 'chandra',
      name: {'mr': 'चंद्रदेव', 'hi': 'चंद्रदेव', 'en': 'Chandra Dev'},
      jaykar: {'mr': 'ॐ सोमाय नमः', 'hi': 'ॐ सोमाय नमः', 'en': 'Om Somaya Namah'},    ),
    CardDeity(
      id: 'narmada',
      name: {'mr': 'नर्मदा माता', 'hi': 'नर्मदा मैया', 'en': 'Narmada Mata'},
      jaykar: {'mr': 'नर्मदे हर', 'hi': 'नर्मदे हर', 'en': 'Narmade Har'},    ),
    CardDeity(
      id: 'gayatri',
      name: {'mr': 'गायत्री माता', 'hi': 'गायत्री माँ', 'en': 'Gayatri Mata'},
      jaykar: {'mr': 'जय गायत्री माता', 'hi': 'जय माँ गायत्री', 'en': 'Jai Gayatri Maa'},    ),
  ];

  static CardDeity deity(String id) =>
      deities.firstWhere((d) => d.id == id, orElse: () => deities.first);

  static const morningGreeting = {'mr': 'शुभ सकाळ', 'hi': 'सुप्रभात', 'en': 'Good Morning'};

  static const altGreeting = {'mr': 'राम कृष्ण हरी', 'hi': 'राधे राधे', 'en': 'Jai Shri Ram'};

  static const brand = {'mr': 'BhaktiDhara ॲप', 'hi': 'BhaktiDhara ऐप', 'en': 'BhaktiDhara app'};
}
