import '../../domain/entities/aarti_item.dart';
import '../../domain/entities/lyric_stanza.dart';
import 'marathi_aarti_catalog.dart';

/// Static devotional catalog.
///
/// Timestamps are millisecond offsets from the start of the primary YouTube
/// video. Hanuman Chalisa timings are from a Gulshan Kumar/Hariharan LRC.
/// Other aartis use full lyrics distributed across the video duration.
final List<AartiItem> kDevotionalCatalog = [
  AartiItem(
    id: 'hanuman_chalisa',
    title: 'Hanuman Chalisa',
    titleHi: 'हनुमान चालीसा',
    titleMr: 'हनुमान चालीसा',
    deity: 'Lord Hanuman',
    deityHi: 'हनुमान जी',
    deityMr: 'हनुमान',
    singer: 'Hariharan',
    tags: const ['Chalisa', 'Stotra'],
    youtubeVideoId: 'AETFvQonfV8',
    backupVideoIds: const ['LUx8wlA_dk8', 'PlgIlN5gmQw'],
    durationText: '9:48',
    accentColorHex: '#FF6F00',
    deityEmoji: '🙏',
    aboutMr:
        'श्री हनुमान चालीसा ही गोस्वामी तुलसीदास यांनी रचलेली भगवान हनुमानाची स्तुती आहे. याचे पठण केल्याने भय, संकटे आणि नकारात्मकता दूर होते.',
    aboutHi:
        'श्री हनुमान चालीसा गोस्वामी तुलसीदास जी द्वारा रचित भगवान हनुमान की दिव्य स्तुति है। इसके पाठ से सभी भय, संकट और नकारात्मकता दूर होती है।',
    about:
        'Shree Hanuman Chalisa is a sacred 40-verse hymn composed by Goswami Tulsidas praising Lord Hanuman, bringing immense courage and protection.',
    lyrics: const [
LyricStanza(
        startTimeMs: 2090,
        devanagari: 'श्रीगुरु चरन सरोज रज निज मनु मुकुरु सुधारि\nबरनऊं रघुबर बिमल जसु जो दायकु फल चारि',
        transliteration:
            'Shri Guru Charan Saroj Raj, Nij Manu Mukuru Sudhari.\nBaranau Raghuvar Bimal Jasu, Jo Dayaku Phal Chari.',
      ),
      LyricStanza(
        startTimeMs: 24230,
        devanagari: 'बुद्धिहीन तनु जानिके सुमिरौं पवन कुमार\nबल बुद्धि बिद्या देहु मोहिं हरहु कलेस बिकार',
        transliteration:
            'Buddhiheen Tanu Janike, Sumirau Pavan Kumar.\nBal Buddhi Vidya Dehu Mohin, Harahu Kalesh Bikaar.',
      ),
      LyricStanza(
        startTimeMs: 55610,
        devanagari: 'जय हनुमान ज्ञान गुन सागर\nजय कपीस तिहुं लोक उजागर',
        transliteration:
            'Jai Hanuman Gyan Gun Sagar.\nJai Kapis Tihun Lok Ujagar.',
      ),
      LyricStanza(
        startTimeMs: 66490,
        devanagari: 'रामदूत अतुलित बल धामा\nअंजनि पुत्र पवनसुत नामा',
        transliteration:
            'Ram Doot Atulit Bal Dhama.\nAnjani Putra Pavan Sut Nama.',
      ),
      LyricStanza(
        startTimeMs: 82690,
        devanagari: 'महाबीर बिक्रम बजरंगी\nकुमति निवार सुमति के संगी',
        transliteration:
            'Mahabir Bikram Bajrangi.\nKumati Nivar Sumati Ke Sangi.',
      ),
      LyricStanza(
        startTimeMs: 93320,
        devanagari: 'कंचन बरन बिराज सुबेसा\nकानन कुंडल कुंचित केसा',
        transliteration:
            'Kanchan Baran Biraj Subesa.\nKanan Kundal Kunchit Kesa.',
      ),
      LyricStanza(
        startTimeMs: 103680,
        devanagari: 'हाथ बज्र औ ध्वजा बिराजै\nकांधे मूंज जनेऊ साजै',
        transliteration:
            'Hath Bajra Au Dhwaja Birajai.\nKandhe Moonj Janeu Sajai.',
      ),
      LyricStanza(
        startTimeMs: 114340,
        devanagari: 'संकर सुवन केसरीनंदन\nतेज प्रताप महा जग बन्दन',
        transliteration:
            'Shankar Suvan Kesari Nandan.\nTej Pratap Maha Jag Bandan.',
      ),
      LyricStanza(
        startTimeMs: 130280,
        devanagari: 'विद्यावान गुनी अति चातुर\nराम काज करिबे को आतुर',
        transliteration:
            'Vidyavan Guni Ati Chatur.\nRam Kaj Karibe Ko Aatur.',
      ),
      LyricStanza(
        startTimeMs: 140900,
        devanagari: 'प्रभु चरित्र सुनिबे को रसिया\nराम लखन सीता मन बसिया',
        transliteration:
            'Prabhu Charitra Sunibe Ko Rasiya.\nRam Lakhan Sita Man Basiya.',
      ),
      LyricStanza(
        startTimeMs: 150990,
        devanagari: 'सूक्ष्म रूप धरि सियहिं दिखावा\nबिकट रूप धरि लंक जरावा',
        transliteration:
            'Sukshma Roop Dhari Siyahi Dikhava.\nVikat Roop Dhari Lank Jarava.',
      ),
      LyricStanza(
        startTimeMs: 162160,
        devanagari: 'भीम रूप धरि असुर संहारे\nरामचंद्र के काज संवारे',
        transliteration:
            'Bhim Roop Dhari Asur Sanhare.\nRamchandra Ke Kaj Sanvare.',
      ),
      LyricStanza(
        startTimeMs: 177820,
        devanagari: 'लाय सजीवन लखन जियाये\nश्रीरघुबीर हरषि उर लाये',
        transliteration:
            'Laye Sanjivan Lakhan Jiyaye.\nShri Raghubeer Harashi Ur Laye.',
      ),
      LyricStanza(
        startTimeMs: 188450,
        devanagari: 'रघुपति कीन्ही बहुत बड़ाई\nतुम मम प्रिय भरतहि सम भाई',
        transliteration:
            'Raghupati Kinhi Bahut Badai.\nTum Mam Priya Bharatahi Sam Bhai.',
      ),
      LyricStanza(
        startTimeMs: 198800,
        devanagari: 'सहस बदन तुम्हरो जस गावैं\nअस कहि श्रीपति कंठ लगावैं',
        transliteration:
            'Sahas Badan Tumharo Jas Gaven.\nAs Kahi Shripati Kanth Lagaven.',
      ),
      LyricStanza(
        startTimeMs: 209170,
        devanagari: 'सनकादिक ब्रह्मादि मुनीसा\nनारद सारद सहित अहीसा',
        transliteration:
            'Sanakadik Brahmadi Munisa.\nNarad Sarad Sahit Ahisa.',
      ),
      LyricStanza(
        startTimeMs: 225400,
        devanagari: 'जम कुबेर दिगपाल जहां ते\nकबि कोबिद कहि सके कहां ते',
        transliteration:
            'Yam Kuber Digpal Jahan Te.\nKabi Kobid Kahi Sake Kahan Te.',
      ),
      LyricStanza(
        startTimeMs: 236030,
        devanagari: 'तुम उपकार सुग्रीवहिं कीन्हा\nराम मिलाय राज पद दीन्हा',
        transliteration:
            'Tum Upkar Sugrivahi Kinha.\nRam Milaye Raj Pad Deenha.',
      ),
      LyricStanza(
        startTimeMs: 246650,
        devanagari: 'तुम्हरो मंत्र बिभीषन माना\nलंकेस्वर भए सब जग जाना',
        transliteration:
            'Tumharo Mantra Vibhishan Mana.\nLankeshwar Bhaye Sab Jag Jana.',
      ),
      LyricStanza(
        startTimeMs: 257010,
        devanagari: 'जुग सहस्र जोजन पर भानू\nलील्यो ताहि मधुर फल जानू',
        transliteration:
            'Yug Sahasra Yojan Par Bhanu.\nLeelyo Tahi Madhur Phal Janu.',
      ),
      LyricStanza(
        startTimeMs: 272980,
        devanagari: 'प्रभु मुद्रिका मेलि मुख माहीं\nजलधि लांघि गये अचरज नाहीं',
        transliteration:
            'Prabhu Mudrika Meli Mukh Mahin.\nJaladhi Langhi Gaye Acharaj Nahin.',
      ),
      LyricStanza(
        startTimeMs: 283870,
        devanagari: 'दुर्गम काज जगत के जेते\nसुगम अनुग्रह तुम्हरे तेते',
        transliteration:
            'Durgam Kaj Jagat Ke Jete.\nSugam Anugrah Tumhare Tete.',
      ),
      LyricStanza(
        startTimeMs: 293960,
        devanagari: 'राम दुआरे तुम रखवारे\nहोत न आज्ञा बिनु पैसारे',
        transliteration:
            'Ram Duware Tum Rakhware.\nHot Na Aagya Binu Paisare.',
      ),
      LyricStanza(
        startTimeMs: 305120,
        devanagari: 'सब सुख लहै तुम्हारी सरना\nतुम रक्षक काहू को डर ना',
        transliteration:
            'Sab Sukh Lahai Tumhari Sarana.\nTum Rakshak Kahu Ko Dar Na.',
      ),
      LyricStanza(
        startTimeMs: 320790,
        devanagari: 'आपन तेज सम्हारो आपै\nतीनों लोक हांक तें कांपै',
        transliteration:
            'Aapan Tej Samharo Aapai.\nTeenon Lok Hank Te Kampai.',
      ),
      LyricStanza(
        startTimeMs: 331680,
        devanagari: 'भूत पिसाच निकट नहिं आवै\nमहाबीर जब नाम सुनावै',
        transliteration:
            'Bhoot Pisach Nikat Nahin Avai.\nMahabir Jab Naam Sunavai.',
      ),
      LyricStanza(
        startTimeMs: 342050,
        devanagari: 'नासै रोग हरै सब पीरा\nजपत निरंतर हनुमत बीरा',
        transliteration:
            'Nasai Rog Harai Sab Peera.\nJapat Nirantar Hanumat Beera.',
      ),
      LyricStanza(
        startTimeMs: 352930,
        devanagari: 'संकट तें हनुमान छुड़ावै\nमन क्रम बचन ध्यान जो लावै',
        transliteration:
            'Sankat Te Hanuman Chhudavai.\nMan Kram Bachan Dhyan Jo Lavai.',
      ),
      LyricStanza(
        startTimeMs: 368340,
        devanagari: 'सब पर राम तपस्वी राजा\nतिन के काज सकल तुम साजा',
        transliteration:
            'Sab Par Ram Tapasvi Raja.\nTin Ke Kaj Sakal Tum Saja.',
      ),
      LyricStanza(
        startTimeMs: 379240,
        devanagari: 'और मनोरथ जो कोई लावै\nसोइ अमित जीवन फल पावै',
        transliteration:
            'Aur Manorath Jo Koi Lavai.\nSoi Amit Jivan Phal Pavai.',
      ),
      LyricStanza(
        startTimeMs: 389600,
        devanagari: 'चारों जुग परताप तुम्हारा\nहै परसिद्ध जगत उजियारा',
        transliteration:
            'Charon Yug Partap Tumhara.\nHai Parsiddha Jagat Ujiyara.',
      ),
      LyricStanza(
        startTimeMs: 400480,
        devanagari: 'साधु संत के तुम रखवारे\nअसुर निकंदन राम दुलारे',
        transliteration:
            'Sadhu Sant Ke Tum Rakhware.\nAsur Nikandan Ram Dulare.',
      ),
      LyricStanza(
        startTimeMs: 415880,
        devanagari: 'अष्ट सिद्धि नौ निधि के दाता\nअस बर दीन जानकी माता',
        transliteration:
            'Ashta Siddhi Nau Nidhi Ke Data.\nAs Bar Deen Janaki Mata.',
      ),
      LyricStanza(
        startTimeMs: 426540,
        devanagari: 'राम रसायन तुम्हरे पासा\nसदा रहो रघुपति के दासा',
        transliteration:
            'Ram Rasayan Tumhare Pasa.\nSada Raho Raghupati Ke Dasa.',
      ),
      LyricStanza(
        startTimeMs: 436910,
        devanagari: 'तुम्हरे भजन राम को पावै\nजनम-जनम के दुख बिसरावै',
        transliteration:
            'Tumhare Bhajan Ram Ko Pavai.\nJanam Janam Ke Dukh Bisravai.',
      ),
      LyricStanza(
        startTimeMs: 447820,
        devanagari: 'अन्तकाल रघुबर पुर जाई\nजहां जन्म हरि भक्त कहाई',
        transliteration:
            'Antkaal Raghuvar Pur Jai.\nJahan Janam Hari Bhakt Kahai.',
      ),
      LyricStanza(
        startTimeMs: 463230,
        devanagari: 'और देवता चित्त न धरई\nहनुमत सेइ सर्ब सुख करई',
        transliteration:
            'Aur Devata Chitt Na Dharai.\nHanumat Sei Sarva Sukh Karai.',
      ),
      LyricStanza(
        startTimeMs: 473890,
        devanagari: 'संकट कटै मिटै सब पीरा\nजो सुमिरै हनुमत बलबीरा',
        transliteration:
            'Sankat Kate Mitai Sab Peera.\nJo Sumirai Hanumat Balbeera.',
      ),
      LyricStanza(
        startTimeMs: 484510,
        devanagari: 'जै जै जै हनुमान गोसाईं\nकृपा करहु गुरुदेव की नाईं',
        transliteration:
            'Jai Jai Jai Hanuman Gosain.\nKripa Karahu Gurudev Ki Nain.',
      ),
      LyricStanza(
        startTimeMs: 495140,
        devanagari: 'जो सत बार पाठ कर कोई\nछूटहि बंदि महा सुख होई',
        transliteration:
            'Jo Sat Baar Path Kar Koi.\nChhutahi Bandi Maha Sukh Hoi.',
      ),
      LyricStanza(
        startTimeMs: 510830,
        devanagari: 'जो यह पढ़ै हनुमान चालीसा\nहोय सिद्धि साखी गौरीसा',
        transliteration:
            'Jo Yah Padhai Hanuman Chalisa.\nHoye Siddhi Sakhi Gaurisa.',
      ),
      LyricStanza(
        startTimeMs: 521190,
        devanagari: 'तुलसीदास सदा हरि चेरा\nकीजै नाथ हृदय मंह डेरा',
        transliteration:
            'Tulsidas Sada Hari Chera.\nKeejai Nath Hridaya Mah Dera.',
      ),
      LyricStanza(
        startTimeMs: 539770,
        devanagari: 'पवन तनय संकट हरन मंगल मूरति रूप',
        transliteration:
            'Pavan Tanay Sankat Haran, Mangal Murti Roop.',
      ),
      LyricStanza(
        startTimeMs: 555980,
        devanagari: 'राम लखन सीता सहित हृदय बसहु सुर भूप',
        transliteration:
            'Ram Lakhan Sita Sahit, Hridaya Basahu Sur Bhoop.',
      ),
    ],
  ),
  AartiItem(
    id: 'ganesh_aarti',
    title: 'Shree Ganesh Aarti',
    titleHi: 'श्री गणेश आरती',
    titleMr: 'श्री गणेश आरती',
    deity: 'Lord Ganesha',
    deityHi: 'गणेश जी',
    deityMr: 'गणेश',
    singer: 'Lata Mangeshkar',
    tags: const ['Aarti', 'Chalisa'],
    youtubeVideoId: 'qux5HuSgaI4',
    backupVideoIds: const ['q72FRIUFcvM', 'UlLAxTVT1Qk'],
    durationText: '4:20',
    accentColorHex: '#F57C00',
    deityEmoji: '🐘',
    aboutMr: 'सुखकर्ता दुःखहर्ता ही श्री गणेशाची सर्वात प्रसिद्ध आरती आहे.',
    aboutHi: 'सुखकर्ता दुःखहर्ता भगवान श्री गणेश की अत्यंत पावन आरती है।',
    about: 'Sukhkarta Dukhharta is the most beloved Aarti of Lord Ganesha.',
    lyrics: const [
      LyricStanza(
        startTimeMs: 8000,
        devanagari: 'सुखकर्ता दुखहर्ता वार्ता विघ्नाची।\nनुरवी पुरवी प्रेम कृपा जयाची॥',
        transliteration: 'Sukhkarta Dukhharta Varta Vighnachi,\nNurvi Purvi Prem Krupa Jayachi.',
      ),
      LyricStanza(
        startTimeMs: 34888,
        devanagari: 'रत्नखचित फरा तुज गौरीकुमरा।\nचंदनाची उटी कुमकुम केशरा॥',
        transliteration: 'Ratna Khachit Fara Tuj Gauri Kumara,\nChandanachi Uti Kumkum Keshara.',
      ),
      LyricStanza(
        startTimeMs: 61777,
        devanagari: 'जय देव जय देव जय मंगलमूर्ती।\nदर्शनमात्रे मनकामना पुरती॥',
        transliteration: 'Jai Dev Jai Dev Jai Mangal Murti,\nDarshanmatre Man Kamna Purti.',
      ),
      LyricStanza(
        startTimeMs: 88666,
        devanagari: 'हिरेजडित मुकुट शोभतो बरा।\nरुणझुणती नूपुरे चरणी घागरा॥',
        transliteration: 'Hire Jadit Mukut Shobhato Bara,\nRunJhunati Nupure Charani Ghagara.',
      ),
      LyricStanza(
        startTimeMs: 115555,
        devanagari: 'जय देव जय देव जय मंगलमूर्ती।\nदर्शनमात्रे मनकामना पुरती॥',
        transliteration: 'Jai Dev Jai Dev Jai Mangal Murti,\nDarshanmatre Man Kamna Purti.',
      ),
      LyricStanza(
        startTimeMs: 142444,
        devanagari: 'लंबोदर पीतांबर फणिवर बंधना।\nसरळ सोंड वक्रतुंड त्रिनयना॥',
        transliteration: 'Lambodar Pitambar Phanivar Bandhana,\nSaral Sond Vakratunda Trinayana.',
      ),
      LyricStanza(
        startTimeMs: 169333,
        devanagari: 'दास रामाचा वाट पाहे सदना।\nसंकटी पावावे निर्वाणी रक्षावे सुरवर वंदना॥',
        transliteration: 'Das Ramacha Vat Pahe Sadana,\nSankati Pavave Nirvani Rakshave Suravar Vandana.',
      ),
      LyricStanza(
        startTimeMs: 196222,
        devanagari: 'जय देव जय देव जय मंगलमूर्ती।\nदर्शनमात्रे मनकामना पुरती॥',
        transliteration: 'Jai Dev Jai Dev Jai Mangal Murti,\nDarshanmatre Man Kamna Purti.',
      ),
      LyricStanza(
        startTimeMs: 223111,
        devanagari: 'सुखकर्ता दुखहर्ता वार्ता विघ्नाची।\nनुरवी पुरवी प्रेम कृपा जयाची॥',
        transliteration: 'Sukhkarta Dukhharta Varta Vighnachi,\nNurvi Purvi Prem Krupa Jayachi.',
      ),
      LyricStanza(
        startTimeMs: 250000,
        devanagari: 'जय देव जय देव जय मंगलमूर्ती।\nदर्शनमात्रे मनकामना पुरती॥',
        transliteration: 'Jai Dev Jai Dev Jai Mangal Murti,\nDarshanmatre Man Kamna Purti.',
      ),
    ],
  ),
  AartiItem(
    id: 'ganesh_shendur_lal',
    title: 'Shendur Lal Chadhayo Aarti',
    titleHi: 'शेंदूर लाल चढायो आरती',
    titleMr: 'शेंदूर लाल चढायो आरती',
    deity: 'Lord Ganesha',
    deityHi: 'गणेश जी',
    deityMr: 'गणेश',
    singer: 'Ravindra Sathe',
    tags: const ['Aarti'],
    youtubeVideoId: 'vVgz3Pg-EMs',
    backupVideoIds: const ['bo62sjQ0CmE', 'q72FRIUFcvM'],
    durationText: '3:45',
    accentColorHex: '#F57C00',
    deityEmoji: '🐘',
    aboutMr: 'शेंदूर लाल चढायो ही उत्तर भारतात प्रसिद्ध असलेली गणेश आरती आहे.',
    aboutHi: 'शेंदूर लाल चढायो भगवान श्री गणेश की अत्यंत लोकप्रिय आरती है।',
    about: 'Shendur Lal Chadhayo is a celebrated prayer honoring Lord Ganesha.',
    lyrics: const [
      LyricStanza(
        startTimeMs: 0,
        devanagari:
            'शेंदुर लाल चढ़ायो अच्छा गजमुख को ।\nदोंदिल लाल बिराजे सुत गौरिहर को ॥',
        transliteration:
            'Shendur Lal Chadhayo Achha Gajmukh Ko,\nDondil Lal Biraje Sut Gaurihar Ko.',
      ),
      LyricStanza(
        startTimeMs: 0,
        devanagari:
            'हाथ लिए गुड़लड्डू सांई सुरवर को ।\nमहिमा कहे न जाय लागत हूँ पद को ॥',
        transliteration:
            'Hath Liye Gudladdu Sain Survar Ko,\nMahima Kahe Na Jaay Lagat Hoon Pad Ko.',
      ),
      LyricStanza(
        startTimeMs: 0,
        devanagari:
            'जय देव जय देव, जय जय श्री गणराज ।\nविद्या सुखदाता धन्य तुम्हारा दर्शन मेरा मन रमता ॥',
        transliteration:
            'Jai Dev Jai Dev, Jai Jai Shri Ganraj,\nVidya Sukhdata Dhanya Tumhara Darshan Mera Man Ramata.',
      ),
      LyricStanza(
        startTimeMs: 0,
        devanagari:
            'अष्टौ सिद्धि दासी संकट को बैरी ।\nविघ्नविनाशन मंगल मूरत अधिकारी ॥',
        transliteration:
            'Ashtau Siddhi Dasi Sankat Ko Bairi,\nVighna Vinashan Mangal Murat Adhikari.',
      ),
      LyricStanza(
        startTimeMs: 0,
        devanagari:
            'कोटी सूरज प्रकाश ऐबी छबि तेरी ।\nगंडस्थल मद मस्तक झूले शशिबिहारी ॥',
        transliteration:
            'Koti Suraj Prakash Aibi Chhabi Teri,\nGandasthal Mad Mastak Jhoole Shashibihari.',
      ),
      LyricStanza(
        startTimeMs: 0,
        devanagari:
            'जय देव जय देव, जय जय श्री गणराज ।\nविद्या सुखदाता धन्य तुम्हारा दर्शन मेरा मन रमता ॥',
        transliteration:
            'Jai Dev Jai Dev, Jai Jai Shri Ganraj,\nVidya Sukhdata Dhanya Tumhara Darshan Mera Man Ramata.',
      ),
      LyricStanza(
        startTimeMs: 0,
        devanagari:
            'भव भगत से कोई शरणगत आवे ।\nसंतति संपत्ति सबही भरपूर पावे ॥',
        transliteration:
            'Bhav Bhagat Se Koi Sharanagat Aave,\nSantati Sampatti Sabahi Bharpur Paave.',
      ),
      LyricStanza(
        startTimeMs: 0,
        devanagari:
            'ऐसे तुम महाराज मोको अति भावे ।\nगोसावीनंदन निशिदिन गुण गावे ॥',
        transliteration:
            'Aise Tum Maharaj Moko Ati Bhave,\nGosavinandan Nishidin Gun Gave.',
      ),
      LyricStanza(
        startTimeMs: 0,
        devanagari:
            'जय देव जय देव, जय जय श्री गणराज ।\nविद्या सुखदाता धन्य तुम्हारा दर्शन मेरा मन रमता ॥',
        transliteration:
            'Jai Dev Jai Dev, Jai Jai Shri Ganraj,\nVidya Sukhdata Dhanya Tumhara Darshan Mera Man Ramata.',
      ),
    ],
  ),
  AartiItem(
    id: 'ganesh_jai_ganesh_deva',
    title: 'Jai Ganesh Jai Ganesh Deva',
    titleHi: 'जय गणेश जय गणेश देवा',
    titleMr: 'जय गणेश जय गणेश देवा',
    deity: 'Lord Ganesha',
    deityHi: 'गणेश जी',
    deityMr: 'गणेश',
    singer: 'Anuradha Paudwal',
    tags: const ['Aarti'],
    youtubeVideoId: 'Yuex2EnsGiY',
    backupVideoIds: const ['L-uG5-xf3Pk', '-I14Ze8cVfk'],
    durationText: '4:15',
    accentColorHex: '#F57C00',
    deityEmoji: '🐘',
    aboutMr: 'जय गणेश जय गणेश देवा ही अत्यंत लोकप्रिय आरती आहे.',
    aboutHi: 'जय गणेश जय गणेश देवा भगवान गणेश की सर्वाधिक लोकप्रिय आरती है।',
    about: 'Jai Ganesh Jai Ganesh Deva is the beloved universal prayer to Lord Ganesha.',
    lyrics: const [
      LyricStanza(
        startTimeMs: 0,
        devanagari: 'जय गणेश जय गणेश जय गणेश देवा ।\nमाता जाकी पार्वती पिता महादेवा ॥',
        transliteration: 'Jai Ganesh Jai Ganesh Jai Ganesh Deva,\nMata Jaaki Parvati Pita Mahadeva.',
      ),
      LyricStanza(
        startTimeMs: 0,
        devanagari: 'एकदंत दयावंत चार भुजाधारी ।\nमस्तक सिंदूर सोहे मूषक की सवारी ॥',
        transliteration: 'Ekadant Dayawant Char Bhujadhari,\nMastak Sindoor Sohe Mooshak Ki Sawari.',
      ),
      LyricStanza(
        startTimeMs: 0,
        devanagari: 'पान चढ़े फूल चढ़े और चढ़े मेवा ।\nलड्डू का भोग लगे संत करें सेवा ॥',
        transliteration: 'Paan Chadhe Phool Chadhe Aur Chadhe Mewa,\nLaddu Ka Bhog Lage Sant Karein Sewa.',
      ),
      LyricStanza(
        startTimeMs: 0,
        devanagari: 'जय गणेश जय गणेश जय गणेश देवा ।\nमाता जाकी पार्वती पिता महादेवा ॥',
        transliteration: 'Jai Ganesh Jai Ganesh Jai Ganesh Deva,\nMata Jaaki Parvati Pita Mahadeva.',
      ),
      LyricStanza(
        startTimeMs: 0,
        devanagari: 'अंधन को आँख देत कोढ़िन को काया ।\nबाँझन को पुत्र देत निर्धन को माया ॥',
        transliteration: 'Andhan Ko Aankh Det Kodhin Ko Kaaya,\nBanjhan Ko Putra Det Nirdhan Ko Maaya.',
      ),
      LyricStanza(
        startTimeMs: 0,
        devanagari: 'सूर श्याम शरण आये सफल कीजे सेवा ।\nमाता जाकी पार्वती पिता महादेवा ॥',
        transliteration: 'Sur Shyam Sharan Aaye Safal Keeje Sewa,\nMata Jaaki Parvati Pita Mahadeva.',
      ),
      LyricStanza(
        startTimeMs: 0,
        devanagari: 'जय गणेश जय गणेश जय गणेश देवा ।\nमाता जाकी पार्वती पिता महादेवा ॥',
        transliteration: 'Jai Ganesh Jai Ganesh Jai Ganesh Deva,\nMata Jaaki Parvati Pita Mahadeva.',
      ),
    ],
  ),
  AartiItem(
    id: 'ganesh_ghalin_lotangan',
    title: 'Ganpati Bappa Morya Aarti',
    titleHi: 'गणपती बाप्पा मोरया आरती',
    titleMr: 'गणपती बाप्पा मोरया आरती',
    deity: 'Lord Ganesha',
    deityHi: 'गणेश जी',
    deityMr: 'गणेश',
    singer: 'Traditional',
    tags: const ['Aarti', 'Prarthana'],
    youtubeVideoId: 'p25bal4mm9E',
    backupVideoIds: const ['2vSdS624Fvk', 'vv6zkM_O6N8'],
    durationText: '3:30',
    accentColorHex: '#F57C00',
    deityEmoji: '🐘',
    aboutMr: 'घालीन लोटांगण व मंत्र पुष्पांजली ही भावपूर्ण गणेश वंदना आहे.',
    aboutHi: 'घालीन लोटांगण एवं मंत्र पुष्पाञ्जलि भावपूर्ण गणेश वंदना है।',
    about: 'Ghalin Lotangan and Mantra Pushpanjali — soulful surrender to Lord Ganesha.',
    lyrics: const [
      LyricStanza(
        startTimeMs: 0,
        devanagari: 'घालीन लोटांगण वंदीन चरण ।\nडोळ्यांनी पाहीन रूप तुझें ॥',
        transliteration: 'Ghalin Lotangan Vandin Charan,\nDolyani Pahin Roop Tujhe.',
      ),
      LyricStanza(
        startTimeMs: 0,
        devanagari: 'प्रेमें आलिंगन आनंदे पूजिन ।\nभावें ओवाळीन म्हणे नामा ॥',
        transliteration: 'Preme Alingan Anande Pujin,\nBhave Ovalin Mhane Nama.',
      ),
      LyricStanza(
        startTimeMs: 0,
        devanagari: 'त्वमेव माता च पिता त्वमेव ।\nत्वमेव बन्धुश्च सखा त्वमेव ॥',
        transliteration: 'Tvameva Mata Cha Pita Tvameva,\nTvameva Bandhushcha Sakha Tvameva.',
      ),
      LyricStanza(
        startTimeMs: 0,
        devanagari: 'त्वमेव विद्या द्रविणं त्वमेव ।\nत्वमेव सर्वं मम देव देव ॥',
        transliteration: 'Tvameva Vidya Dravinam Tvameva,\nTvameva Sarvam Mama Deva Deva.',
      ),
      LyricStanza(
        startTimeMs: 0,
        devanagari:
            'कायेन वाचा मनसेन्द्रियैर्वा बुद्ध्यात्मना वा प्रकृतिस्वभावात् ।\nकरोमि यद्यत् सकलं परस्मै नारायणायेति समर्पयामि ॥',
        transliteration:
            'Kayena Vacha Manasendriyairva Buddhyatmana Va Prakritiswabhavat,\nKaromi Yadyat Sakalam Parasmai Narayanayeti Samarpayami.',
      ),
      LyricStanza(
        startTimeMs: 0,
        devanagari:
            'अच्युतं केशवं राम नारायणं कृष्ण दामोदरं वासुदेवं भजे ।\nश्रीधरं माधवं गोपिकावल्लभं जानकी नायकं रामचन्द्रं भजे ॥',
        transliteration:
            'Achyutam Keshavam Rama Narayanam Krishna Damodaram Vasudevam Bhaje,\nShridharam Madhavam Gopikavallabham Janaki Nayakam Ramachandram Bhaje.',
      ),
      LyricStanza(
        startTimeMs: 0,
        devanagari:
            'हरे राम हरे राम राम राम हरे हरे ।\nहरे कृष्ण हरे कृष्ण कृष्ण कृष्ण हरे हरे ॥',
        transliteration:
            'Hare Rama Hare Rama Rama Rama Hare Hare,\nHare Krishna Hare Krishna Krishna Krishna Hare Hare.',
      ),
    ],
  ),
  AartiItem(
    id: 'ganesh_siddhivinayak',
    title: 'Siddhivinayak Aarti',
    titleHi: 'सिद्धिविनायक आरती',
    titleMr: 'सिद्धिविनायक आरती',
    deity: 'Lord Ganesha',
    deityHi: 'गणेश जी',
    deityMr: 'गणेश',
    singer: 'Temple Recording',
    tags: const ['Aarti'],
    youtubeVideoId: '_oOQ5UYKAKo',
    backupVideoIds: const ['H9tWRGxuKTw', 'JuTcqGQwMdI'],
    durationText: '4:50',
    accentColorHex: '#F57C00',
    deityEmoji: '🐘',
    aboutMr: 'सिद्धिविनायकाच्या रूपातील गणेशाची विशेष आरती.',
    aboutHi: 'सिद्धिविनायक स्वरूप में भगवान गणेश की विशेष फलदायी आरती।',
    about: 'Siddhivinayak Aarti invokes Lord Ganesha in his wish-fulfilling form.',
    lyrics: const [
      LyricStanza(
        startTimeMs: 0,
        devanagari:
            'शेंदुर लाल चढ़ायो अच्छा गजमुख को ।\nदोंदिल लाल बिराजे सुत गौरिहर को ॥',
        transliteration:
            'Shendur Lal Chadhayo Achha Gajmukh Ko,\nDondil Lal Biraje Sut Gaurihar Ko.',
      ),
      LyricStanza(
        startTimeMs: 0,
        devanagari:
            'हाथ लिए गुड़लड्डू सांई सुरवर को ।\nमहिमा कहे न जाय लागत हूँ पद को ॥',
        transliteration:
            'Hath Liye Gudladdu Sain Survar Ko,\nMahima Kahe Na Jaay Lagat Hoon Pad Ko.',
      ),
      LyricStanza(
        startTimeMs: 0,
        devanagari:
            'जय देव जय देव, जय जय श्री गणराज ।\nविद्या सुखदाता धन्य तुम्हारा दर्शन मेरा मन रमता ॥',
        transliteration:
            'Jai Dev Jai Dev, Jai Jai Shri Ganraj,\nVidya Sukhdata Dhanya Tumhara Darshan Mera Man Ramata.',
      ),
      LyricStanza(
        startTimeMs: 0,
        devanagari:
            'अष्टौ सिद्धि दासी संकट को बैरी ।\nविघ्नविनाशन मंगल मूरत अधिकारी ॥',
        transliteration:
            'Ashtau Siddhi Dasi Sankat Ko Bairi,\nVighna Vinashan Mangal Murat Adhikari.',
      ),
      LyricStanza(
        startTimeMs: 0,
        devanagari:
            'भव भगत से कोई शरणगत आवे ।\nसंतति संपत्ति सबही भरपूर पावे ॥',
        transliteration:
            'Bhav Bhagat Se Koi Sharanagat Aave,\nSantati Sampatti Sabahi Bharpur Paave.',
      ),
      LyricStanza(
        startTimeMs: 0,
        devanagari: 'देवा श्री गणेशा, विघ्नहर्ता श्री सिद्धिविनायक ।\nजय देव जय देव ॥',
        transliteration:
            'Deva Shri Ganesha, Vighnaharta Shri Siddhivinayak,\nJai Dev Jai Dev.',
      ),
    ],
  ),
  AartiItem(
    id: 'ganesh_mangalmurti',
    title: 'Mangalmurti Morya Aarti',
    titleHi: 'मंगलमूर्ती मोरया आरती',
    titleMr: 'मंगलमूर्ती मोरया आरती',
    deity: 'Lord Ganesha',
    deityHi: 'गणेश जी',
    deityMr: 'गणेश',
    singer: 'Adarsh Shinde',
    tags: const ['Aarti', 'Stotra'],
    youtubeVideoId: 'K9SzRhWpUb4',
    backupVideoIds: const ['VvKjso_NjK8', 'utWF4jksixo'],
    durationText: '5:10',
    accentColorHex: '#F57C00',
    deityEmoji: '🐘',
    aboutMr: 'मंगलमूर्ती मोरया ही गणेश भक्तांमध्ये अतिशय लोकप्रिय रचना आहे.',
    aboutHi: 'मंगलमूर्ती मोरया गणेश भक्तों के मध्य अत्यंत प्रिय भजन है।',
    about: 'Mangalmurti Morya brings auspiciousness and festive Ganesha devotion.',
    lyrics: const [
      LyricStanza(
        startTimeMs: 0,
        devanagari:
            'लंबोदराय विघ्नेश्वराय गौरीसुताय ।\nकरुणाकाराय धूम्रवर्ण एकदंत गणनायकाय ॥',
        transliteration:
            'Lambodaraya Vighneshwaraya Gaurisutaya,\nKarunakaraya Dhumravarna Ekadanta Gananayakaya.',
      ),
      LyricStanza(
        startTimeMs: 0,
        devanagari: 'जीव जडला चरणी तुझ्या रे ।\nशरण आलो बाप्पा तुला रे ॥',
        transliteration: 'Jeev Jadala Charani Tujhya Re,\nSharan Aalo Bappa Tula Re.',
      ),
      LyricStanza(
        startTimeMs: 0,
        devanagari: 'तूच कर्ता सऱ्या सुखाचा ।\nदुःखहर्ता त्राता जगाचा ॥',
        transliteration: 'Tuch Karta Sarya Sukhacha,\nDukhharta Trata Jagacha.',
      ),
      LyricStanza(
        startTimeMs: 0,
        devanagari: 'तूच आदि आणि अनंत ।\nमंगलमूर्ती मोरया ॥',
        transliteration: 'Tuch Aadi Ani Ananta,\nMangalmurti Morya.',
      ),
      LyricStanza(
        startTimeMs: 0,
        devanagari: 'नाद घुमतो दही दिशा रे ।\nमंगलमूर्ती मोरया ॥',
        transliteration: 'Naad Ghumato Dahi Disha Re,\nMangalmurti Morya.',
      ),
      LyricStanza(
        startTimeMs: 0,
        devanagari: 'ढोल ताशा तशाणलेला ।\nनाम घोषात रंगलेला ॥',
        transliteration: 'Dhol Tasa Tashanlela,\nNaam Ghoshayat Ranglela.',
      ),
      LyricStanza(
        startTimeMs: 0,
        devanagari: 'बाप्पा तुझा मोरया ।\nमोरया हे मोरया ॥',
        transliteration: 'Bappa Tuja Morya,\nMorya He Morya.',
      ),
      LyricStanza(
        startTimeMs: 0,
        devanagari:
            'चंदन उटी शेंदूर टिळा ।\nमंगळाची मूर्ती तुझी ॥',
        transliteration: 'Chandan Uti Shendur Tila,\nMangalachi Murti Tuji.',
      ),
      LyricStanza(
        startTimeMs: 0,
        devanagari: 'मोरया हे मोरया ।\nमंगलमूर्ती मोरया ॥',
        transliteration: 'Morya He Morya,\nMangalmurti Morya.',
      ),
    ],
  ),
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
    youtubeVideoId: 'BhwOproElxU',
    backupVideoIds: const ['dsilAV0uKEM', '1z7Ozpxp7fE'],
    durationText: '5:12',
    accentColorHex: '#1565C0',
    deityEmoji: '🔱',
    aboutMr: 'ॐ जय शिव ओंकारा ही भगवान शिवाची अत्यंत पावन आरती आहे.',
    aboutHi: 'ॐ जय शिव ओंकारा भगवान शिव की परम पावन आरती है।',
    about: 'Om Jai Shiv Omkara is the sacred evening Aarti dedicated to Lord Shiva.',
    lyrics: const [
      LyricStanza(
        startTimeMs: 8000,
        devanagari: 'ॐ जय शिव ओंकारा, स्वामी जय शिव ओंकारा।\nब्रह्मा विष्णु सदाशिव, अर्धांगी धारा॥',
        transliteration: 'Om Jai Shiv Omkara, Swami Jai Shiv Omkara,\nBrahma Vishnu Sadashiv, Ardhangi Dhara.',
      ),
      LyricStanza(
        startTimeMs: 34545,
        devanagari: 'एकानन चतुरानन पंचानन राजे।\nहंसासन गरुड़ासन वृषवाहन साजे॥',
        transliteration: 'Ekanan Chaturanan Panchanana Raje,\nHansasan Garudasan Vrishvahan Saje.',
      ),
      LyricStanza(
        startTimeMs: 61090,
        devanagari: 'ॐ जय शिव ओंकारा, स्वामी जय शिव ओंकारा॥',
        transliteration: 'Om Jai Shiv Omkara, Swami Jai Shiv Omkara.',
      ),
      LyricStanza(
        startTimeMs: 87636,
        devanagari: 'दो भुज चार चतुर्भुज दशभुज अति सोहे।\nत्रिगुण रूप निरखते त्रिभुवन जन मोहे॥',
        transliteration: 'Do Bhuj Char Chaturbhuj Dashbhuj Ati Sohe,\nTrigun Rup Nirakhate Tribhuvan Jan Mohe.',
      ),
      LyricStanza(
        startTimeMs: 114181,
        devanagari: 'अक्षमाला वनमाला मुंडमाला धारी।\nचंदन मृगमद सोहे भाले शशि धारी॥',
        transliteration: 'Akshamala Vanmala Mundmala Dhari,\nChandan Mrigmad Sohe Bhale Shashi Dhari.',
      ),
      LyricStanza(
        startTimeMs: 140727,
        devanagari: 'ॐ जय शिव ओंकारा, स्वामी जय शिव ओंकारा॥',
        transliteration: 'Om Jai Shiv Omkara, Swami Jai Shiv Omkara.',
      ),
      LyricStanza(
        startTimeMs: 167272,
        devanagari: 'श्वेताम्बर पीताम्बर बाघाम्बर अंगे।\nसनकादिक गरुड़ादिक भूतादिक संगे॥',
        transliteration: 'Shvetambar Pitambar Baghambar Ange,\nSanakadik Garudadik Bhutadik Sange.',
      ),
      LyricStanza(
        startTimeMs: 193818,
        devanagari: 'कर मध्ये कमंडलु चक्र त्रिशूलधारी।\nसुखकर्ता दुखहर्ता जग पालन कर्ता॥',
        transliteration: 'Kar Madhye Kamandalu Chakra Trishul Dhari,\nSukhkarta Dukhharta Jag Palan Karta.',
      ),
      LyricStanza(
        startTimeMs: 220363,
        devanagari: 'ॐ जय शिव ओंकारा, स्वामी जय शिव ओंकारा॥',
        transliteration: 'Om Jai Shiv Omkara, Swami Jai Shiv Omkara.',
      ),
      LyricStanza(
        startTimeMs: 246909,
        devanagari: 'ब्रह्मा विष्णु सदाशिव जानत अविवेका।\nप्रणवाक्षर मध्ये ये तीनो एका॥',
        transliteration: 'Brahma Vishnu Sadashiv Janat Aviveka,\nPranavakshar Madhye Ye Teeno Eka.',
      ),
      LyricStanza(
        startTimeMs: 273454,
        devanagari: 'त्रिगुण स्वामी जी की आरती जो कोई नर गावे।\nकहत शिवानंद स्वामी मनवांछित फल पावे॥',
        transliteration: 'Trigun Swamiji Ki Aarti Jo Koi Nar Gave,\nKahat Shivanand Swami Manvanchhit Phal Pave.',
      ),
      LyricStanza(
        startTimeMs: 300000,
        devanagari: 'ॐ जय शिव ओंकारा, स्वामी जय शिव ओंकारा।\nब्रह्मा विष्णु सदाशिव, अर्धांगी धारा॥',
        transliteration: 'Om Jai Shiv Omkara, Swami Jai Shiv Omkara,\nBrahma Vishnu Sadashiv, Ardhangi Dhara.',
      ),
    ],
  ),
  AartiItem(
    id: 'durga_aarti',
    title: 'Durga Aarti',
    titleHi: 'दुर्गा आरती',
    titleMr: 'दुर्गा आरती',
    deity: 'Goddess Durga',
    deityHi: 'दुर्गा माँ',
    deityMr: 'दुर्गा',
    singer: 'Anuradha Paudwal',
    tags: const ['Aarti', 'Chalisa'],
    youtubeVideoId: '-rKAOaS7Q3I',
    backupVideoIds: const ['RY1jmTTjvhI', 'Iyki_pDrOUM'],
    durationText: '6:05',
    accentColorHex: '#AD1457',
    deityEmoji: '🌸',
    aboutMr: 'जय अम्बे गौरी ही माँ दुर्गेची लोकप्रिय आरती आहे.',
    aboutHi: 'जय अम्बे गौरी माँ दुर्गा की परम कल्याणकारी आरती है।',
    about: 'Jai Ambe Gauri is a divine hymn honoring Goddess Durga.',
    lyrics: const [
      LyricStanza(
        startTimeMs: 8000,
        devanagari: 'जय अम्बे गौरी, मैया जय श्यामा गौरी।\nतुमको निशदिन ध्यावत, हरि ब्रह्मा शिवरी॥',
        transliteration: 'Jai Ambe Gauri, Maiya Jai Shyama Gauri,\nTumko Nishdin Dhyavat, Hari Brahma Shivari.',
      ),
      LyricStanza(
        startTimeMs: 39090,
        devanagari: 'माँग सिंदूर बिराजत, टीको मृगमद को।\nउज्ज्वल से दोऊ नैना, चंद्रवदन नीको॥',
        transliteration: 'Mang Sindur Birajat, Tiko Mrigmad Ko,\nUjjwal Se Dou Naina, Chandravadan Niko.',
      ),
      LyricStanza(
        startTimeMs: 70181,
        devanagari: 'जय अम्बे गौरी, मैया जय श्यामा गौरी॥',
        transliteration: 'Jai Ambe Gauri, Maiya Jai Shyama Gauri.',
      ),
      LyricStanza(
        startTimeMs: 101272,
        devanagari: 'कनक समान कलेवर, रक्ताम्बर राजे।\nरक्त-पुष्प गल माला, कण्ठन पर साजे॥',
        transliteration: 'Kanak Saman Kalevar, Raktambar Raje,\nRakt Pushp Gal Mala, Kanthan Par Saje.',
      ),
      LyricStanza(
        startTimeMs: 132363,
        devanagari: 'केहरि वाहन राजत, खड्ग खप्परधारी।\nसुर-नर मुनि-जन सेवत, तिनके दुखहारी॥',
        transliteration: 'Kehari Vahan Rajat, Khadga Khappar Dhari,\nSur Nar Mun Jan Sevat, Tin Ke Dukh Hari.',
      ),
      LyricStanza(
        startTimeMs: 163454,
        devanagari: 'जय अम्बे गौरी, मैया जय श्यामा गौरी॥',
        transliteration: 'Jai Ambe Gauri, Maiya Jai Shyama Gauri.',
      ),
      LyricStanza(
        startTimeMs: 194545,
        devanagari: 'कानन कुंडल शोभित, नासाग्रे मोती।\nकोटिक चंद्र दिवाकर, राजत सम ज्योती॥',
        transliteration: 'Kanan Kundal Shobhit, Nasagre Moti,\nKotik Chandra Divakar, Rajat Sam Jyoti.',
      ),
      LyricStanza(
        startTimeMs: 225636,
        devanagari: 'शुम्भ निशुम्भ विदारे, महिषासुर घाती।\nधूम्र विलोचन नैना, निशदिन मदमाती॥',
        transliteration: 'Shumbhu Nishumbhu Vidare, Mahishasur Ghati,\nDhumra Vilochan Naina, Nishdin Madmati.',
      ),
      LyricStanza(
        startTimeMs: 256727,
        devanagari: 'जय अम्बे गौरी, मैया जय श्यामा गौरी॥',
        transliteration: 'Jai Ambe Gauri, Maiya Jai Shyama Gauri.',
      ),
      LyricStanza(
        startTimeMs: 287818,
        devanagari: 'चंद्रसूर्य धृत शीश, मुकुट पर राजैं।\nत्रिभुवन से नर नारी, तेरी दुति छाजें॥',
        transliteration: 'Chandra Surya Dhrit Sheesh, Mukut Par Rajain,\nTribhuvan Se Nar Nari, Teri Duti Chhajain.',
      ),
      LyricStanza(
        startTimeMs: 318909,
        devanagari: 'जो जन तुमको ध्यावत, निशिदिन मन लाई।\nताके दुख दरिद्र, निकट नहिं आई॥',
        transliteration: 'Jo Jan Tumko Dhyavat, Nishidin Man Lai,\nTake Dukh Daridr, Nikat Nahin Aai.',
      ),
      LyricStanza(
        startTimeMs: 350000,
        devanagari: 'जय अम्बे गौरी, मैया जय श्यामा गौरी।\nतुमको निशदिन ध्यावत, हरि ब्रह्मा शिवरी॥',
        transliteration: 'Jai Ambe Gauri, Maiya Jai Shyama Gauri,\nTumko Nishdin Dhyavat, Hari Brahma Shivari.',
      ),
    ],
  ),
  ...kMarathiAartiCatalog,
];
