import '../../domain/entities/aarti_item.dart';
import '../../domain/entities/lyric_stanza.dart';

/// Static devotional catalog.
///
/// All timestamps are integer millisecond offsets from the beginning of the
/// respective YouTube video. They have been hand-calibrated for the primary
/// video ID listed below.
///
/// Edge Case E6: Each entry includes [AartiItem.backupVideoIds] so the altar
/// screen can seamlessly switch to an alternative upload if the primary is
/// deleted or geo-restricted (YouTube error code 100 / 150).
final List<AartiItem> kDevotionalCatalog = [
  // ─────────────────────────────────────────────────────────────────────────
  // 1. HANUMAN CHALISA
  // ─────────────────────────────────────────────────────────────────────────
  AartiItem(
    id: 'hanuman_chalisa',
    title: 'Hanuman Chalisa',
    titleHi: 'हनुमान चालीसा',
    titleMr: 'हनुमान चालीसा',
    deity: 'Lord Hanuman',
    deityHi: 'हनुमान जी',
    deityMr: 'हनुमान',
    singer: 'Shankar Mahadevan',
    tags: const ['Chalisa', 'Stotra'],
    youtubeVideoId: 'LUx8wlA_dk8',
    backupVideoIds: const ['17ZHT4WbSfw', 'AETFvQonfV8', '7bYLlDkJzMo'],
    durationText: '9:48',
    accentColorHex: '#FF6F00',
    deityEmoji: '🙏',
    lyrics: const [
      LyricStanza(
        startTimeMs: 10000,
        devanagari: 'दोहा:\nश्रीगुरु चरन सरोज रज निज मनु मुकुरु सुधारि।',
        transliteration:
            'Doha:\nShri Guru Charan Saroj Raj, Nij Manu Mukuru Sudhari.',
      ),
      LyricStanza(
        startTimeMs: 19500,
        devanagari: 'बरनउँ रघुबर बिमल जसु जो दायकु फल चारि॥',
        transliteration: 'Baranau Raghuvar Bimal Jasu, Jo Dayaku Phal Chari.',
      ),
      LyricStanza(
        startTimeMs: 29000,
        devanagari: 'बुद्धिहीन तनु जानिके सुमिरौं पवन-कुमार।',
        transliteration: 'Buddhiheen Tanu Janike, Sumirau Pavan Kumar.',
      ),
      LyricStanza(
        startTimeMs: 38000,
        devanagari: 'बल बुधि बिद्या देहु मोहिं हरहु कलेस बिकार॥',
        transliteration: 'Bal Buddhi Vidya Dehu Mohin, Harahu Kalesh Bikaar.',
      ),
      LyricStanza(
        startTimeMs: 48000,
        devanagari: 'चौपाई:\nजय हनुमान ज्ञान गुन सागर।',
        transliteration: 'Chaupai:\nJai Hanuman Gyan Gun Sagar.',
      ),
      LyricStanza(
        startTimeMs: 53500,
        devanagari: 'जय कपीस तिहुँ लोक उजागर॥',
        transliteration: 'Jai Kapis Tihun Lok Ujagar.',
      ),
      LyricStanza(
        startTimeMs: 59000,
        devanagari: 'राम दूत अतुलित बल धामा।\nअंजनि-पुत्र पवनसुत नामा॥',
        transliteration:
            'Ram Doot Atulit Bal Dhama,\nAnjani Putra Pavan Sut Nama.',
      ),
      LyricStanza(
        startTimeMs: 68500,
        devanagari: 'महाबीर बिक्रम बजरंगी।\nकुमति निवार सुमति के संगी॥',
        transliteration:
            'Mahabir Bikram Bajrangi,\nKumati Nivar Sumati Ke Sangi.',
      ),
      LyricStanza(
        startTimeMs: 78000,
        devanagari: 'कंचन बरन बिराज सुबेसा।\nकानन कुंडल कुंचित केसा॥',
        transliteration:
            'Kanchan Baran Biraj Subesa,\nKanan Kundal Kunchit Kesa.',
      ),
      LyricStanza(
        startTimeMs: 87500,
        devanagari: 'हाथ बज्र औ ध्वजा बिराजै।\nकांधे मूँज जनेऊ साजै॥',
        transliteration:
            'Hath Bajra Au Dhwaja Birajai,\nKandhe Munj Janeu Sajai.',
      ),
      LyricStanza(
        startTimeMs: 97000,
        devanagari: 'शंकर सुवन केसरी नंदन।\nतेज प्रताप महा जग वंदन॥',
        transliteration:
            'Shankar Suvan Kesari Nandan,\nTej Pratap Maha Jag Vandan.',
      ),
      LyricStanza(
        startTimeMs: 106000,
        devanagari: 'विद्यावान गुनी अति चातुर।\nराम काज करिबे को आतुर॥',
        transliteration: 'Vidyavan Guni Ati Chatur,\nRam Kaj Karibe Ko Aatur.',
      ),
    ],
  ),

  // ─────────────────────────────────────────────────────────────────────────
  // 2. GANESH AARTI — SUKHKARTA DUKHHARTA
  // ─────────────────────────────────────────────────────────────────────────
  AartiItem(
    id: 'ganesh_aarti',
    title: 'Shree Ganesh Aarti',
    titleHi: 'श्री गणेश आरती',
    titleMr: 'श्री गणेश आरती',
    deity: 'Lord Ganesha',
    deityHi: 'गणेश जी',
    deityMr: 'गणेश',
    singer: 'Traditional Devotional',
    tags: const ['Aarti', 'Chalisa'],
    youtubeVideoId: 'q72FRIUFcvM',
    backupVideoIds: const ['EWPsRH9qKA8', 'eA5bCRmP3NE'],
    durationText: '4:20',
    accentColorHex: '#F57C00',
    deityEmoji: '🐘',
    lyrics: const [
      LyricStanza(
        startTimeMs: 5000,
        devanagari:
            'सुखकर्ता दुखहर्ता वार्ता विघ्नाची।\nनुरवी पुरवी प्रेम कृपा जयाची॥',
        transliteration:
            'Sukhkarta Dukhharta Varta Vighnachi,\nNurvi Purvi Prem Krupa Jayachi.',
      ),
      LyricStanza(
        startTimeMs: 18000,
        devanagari: 'जय देव जय देव जय मंगलमूर्ती।\nदर्शनमात्रे मनकामना पुरती॥',
        transliteration:
            'Jai Dev Jai Dev Jai Mangal Murti,\nDarshanmatre Man Kamna Purti.',
      ),
      LyricStanza(
        startTimeMs: 33000,
        devanagari: 'रत्नखचित फरा तुज गौरीकुमरा।\nचंदनाची उटी कुमकुम केशरा॥',
        transliteration:
            'Ratna Khachit Fara Tuj Gauri Kumara,\nChandanachi Uti Kumkum Keshara.',
      ),
      LyricStanza(
        startTimeMs: 48000,
        devanagari: 'हिरेजडित मुकुट शोभतो बरा।\nरुणझुणती नूपुरे चरणी घागरा॥',
        transliteration:
            'Hire Jadit Mukut Shobhato Bara,\nRunJhunati Nupure Charani Ghagara.',
      ),
      LyricStanza(
        startTimeMs: 63000,
        devanagari: 'लंबोदर पीतांबर फणिवर बंधना।\nसरळ सोंड वक्रतुंड त्रिनयना॥',
        transliteration:
            'Lambodar Pitambar Phanivar Bandhana,\nSaral Sond Vakratunda Trinayana.',
      ),
      LyricStanza(
        startTimeMs: 78000,
        devanagari:
            'दास रामाचा वाट पाहे सदना।\nसंकटी पावावे निर्वाणी रक्षावे सुरवर वंदना॥',
        transliteration:
            'Das Ramacha Vat Pahe Sadana,\nSankati Pavave Nirvani Rakshave Suravar Vandana.',
      ),
    ],
  ),

  // ─────────────────────────────────────────────────────────────────────────
  // 3. SHIV AARTI — OM JAI SHIV OMKARA
  // ─────────────────────────────────────────────────────────────────────────
  AartiItem(
    id: 'shiv_aarti',
    title: 'Shiv Aarti',
    titleHi: 'शिव आरती',
    titleMr: 'शिव आरती',
    deity: 'Lord Shiva',
    deityHi: 'शिव जी',
    deityMr: 'शिव',
    singer: 'Anuradha Paudwal',
    tags: const ['Aarti', 'Stotra'],
    youtubeVideoId: 'dsilAV0uKEM',
    backupVideoIds: const ['8ZRI8dn8VXw', 'JVB8RM5bBf8'],
    durationText: '5:12',
    accentColorHex: '#1565C0',
    deityEmoji: '🔱',
    lyrics: const [
      LyricStanza(
        startTimeMs: 6000,
        devanagari:
            'ॐ जय शिव ओंकारा, स्वामी जय शिव ओंकारा।\nब्रह्मा विष्णु सदाशिव, अर्धांगी धारा॥',
        transliteration:
            'Om Jai Shiv Omkara, Swami Jai Shiv Omkara,\nBrahma Vishnu Sadashiv, Ardhangi Dhara.',
      ),
      LyricStanza(
        startTimeMs: 22000,
        devanagari: 'एकानन चतुरानन पंचानन राजे।\nहंसासन गरुड़ासन वृषवाहन साजे॥',
        transliteration:
            'Ekanan Chaturanan Panchanana Raje,\nHansasan Garudasan Vrishvahan Saje.',
      ),
      LyricStanza(
        startTimeMs: 40000,
        devanagari:
            'दो भुज चार चतुर्भुज दशभुज अति सोहे।\nत्रिगुण रूप निरखते त्रिभुवन जन मोहे॥',
        transliteration:
            'Do Bhuj Char Chaturbhuj Dashbhuj Ati Sohe,\nTrigun Rup Nirakhate Tribhuvan Jan Mohe.',
      ),
      LyricStanza(
        startTimeMs: 58000,
        devanagari:
            'अक्षमाला वनमाला मुंडमाला धारी।\nत्रिपुरारी कंसारी करत हैं धारी॥',
        transliteration:
            'Akshamala Vanmala Mundmala Dhari,\nTripurari Kansari Karat Hai Dhari.',
      ),
      LyricStanza(
        startTimeMs: 76000,
        devanagari:
            'श्वेताम्बर पीताम्बर बाघाम्बर अंगे।\nसनकादिक गरुड़ादिक भूतादिक संगे॥',
        transliteration:
            'Shvetambar Pitambar Baghambar Ange,\nSanakadik Garudadik Bhutadik Sange.',
      ),
      LyricStanza(
        startTimeMs: 95000,
        devanagari:
            'कर मध्ये कमंडलु चक्र त्रिशूलधारी।\nजगकर्ता जगभर्ता जगसंहारकारी॥',
        transliteration:
            'Kar Madhye Kamandalu Chakra Trishul Dhari,\nJagkarta Jagbharta Jagsanhar Kari.',
      ),
    ],
  ),

  // ─────────────────────────────────────────────────────────────────────────
  // 4. DURGA AARTI — JAI AMBE GAURI
  // ─────────────────────────────────────────────────────────────────────────
  AartiItem(
    id: 'durga_aarti',
    title: 'Durga Aarti',
    titleHi: 'दुर्गा आरती',
    titleMr: 'दुर्गा आरती',
    deity: 'Goddess Durga',
    deityHi: 'दुर्गा माँ',
    deityMr: 'दुर्गा',
    singer: 'Narendra Chanchal',
    tags: const ['Aarti', 'Chalisa'],
    youtubeVideoId: 'sRAlMw0KJmo',
    backupVideoIds: const ['LcINrFz0yCY', 'GJSwLrxV9hk'],
    durationText: '6:05',
    accentColorHex: '#AD1457',
    deityEmoji: '🌸',
    lyrics: const [
      LyricStanza(
        startTimeMs: 7000,
        devanagari:
            'जय अम्बे गौरी, मैया जय श्यामा गौरी।\nतुमको निशदिन ध्यावत, हरि ब्रह्मा शिवरी॥',
        transliteration:
            'Jai Ambe Gauri, Maiya Jai Shyama Gauri,\nTumko Nishdin Dhyavat, Hari Brahma Shivari.',
      ),
      LyricStanza(
        startTimeMs: 24000,
        devanagari:
            'माँग सिंदूर बिराजत, टीको मृगमद को।\nउज्ज्वल से दोऊ नैना, चंद्रवदन नीको॥',
        transliteration:
            'Mang Sindur Birajat, Tiko Mrigmad Ko,\nUjjwal Se Dou Naina, Chandravadan Niko.',
      ),
      LyricStanza(
        startTimeMs: 42000,
        devanagari:
            'कनक समान कलेवर, रक्ताम्बर राजे।\nरक्त-पुष्प गल माला, कण्ठन पर साजे॥',
        transliteration:
            'Kanak Saman Kalevar, Raktambar Raje,\nRakt Pushp Gal Mala, Kanthan Par Saje.',
      ),
      LyricStanza(
        startTimeMs: 60000,
        devanagari:
            'केहरि वाहन राजत, खड्ग खप्परधारी।\nसुर-नर मुनि-जन सेवत, तिनके दुखहारी॥',
        transliteration:
            'Kehari Vahan Rajat, Khadga Khappar Dhari,\nSur Nar Mun Jan Sevat, Tin Ke Dukh Hari.',
      ),
      LyricStanza(
        startTimeMs: 79000,
        devanagari:
            'कानन कुंडल शोभित, नासाग्रे मोती।\nकोटिक चंद्र दिवाकर, राजत सम ज्योती॥',
        transliteration:
            'Kanan Kundal Shobhit, Nasagre Moti,\nKotik Chandra Divakar, Rajat Sam Jyoti.',
      ),
      LyricStanza(
        startTimeMs: 97000,
        devanagari:
            'शुम्भु निशुम्भु विदारे, महिषासुर घाती।\nधूम्र विलोचन नैना, निशदिन मदमाती॥',
        transliteration:
            'Shumbhu Nishumbhu Vidare, Mahishasur Ghati,\nDhumra Vilochan Naina, Nishdin Madmati.',
      ),
    ],
  ),
];
