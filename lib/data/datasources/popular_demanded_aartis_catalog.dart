import '../../domain/entities/aarti_item.dart';
import '../../domain/entities/lyric_stanza.dart';

/// Top high-demand regional and devotional aartis requested by devotees:
/// 1. आई तुळजाभवानी (Goddess Tuljabhavani - Maharashtra Kuldevi)
/// 2. श्री राधा रानी (Radha Rani - Barsana)
/// 3. श्री बांके बिहारी (Banke Bihari - Vrindavan)
/// 4. श्री जोतिबा (Lord Jyotiba - Kolhapur / Kedarnath)
/// 5. श्री कालभैरव (Lord Kalbhairav - Kashi / Ujjain)
final List<AartiItem> kPopularDemandedAartisCatalog = [
  // ── 1. आई तुळजाभवानी ──────────────────────────────────────────────
  AartiItem(
    id: 'tuljabhavani_durge_durgat_bhari',
    title: 'Durge Durgat Bhari (Tuljabhavani Aarti)',
    titleHi: 'माँ तुलजा भवानी आरती (दुर्गे दुर्घट भारी)',
    titleMr: 'आई तुळजाभवानी आरती (दुर्गे दुर्घट भारी)',
    deity: 'Goddess Tuljabhavani',
    deityHi: 'माँ तुलजा भवानी',
    deityMr: 'आई तुळजाभवानी',
    singer: 'Lata Mangeshkar',
    tags: const ['Aarti', 'Devi', 'Kuldevi'],
    youtubeVideoId: 'qux5HuSgaI4',
    backupVideoIds: const ['G_QzYcQyIqA', 'jH88F4gB3p0'],
    durationText: '4:15',
    accentColorHex: '#B71C1C',
    deityEmoji: '🌺',
    aboutMr: 'महाराष्ट्राची कुलस्वामिनी श्री आई तुळजाभवानी मातेची अत्यंत पवित्र आरती.',
    aboutHi: 'महाराष्ट्र की कुलस्वामिनी माँ तुलजा भवानी की परम पावन आरती।',
    about: 'Sacred Aarti of Goddess Tuljabhavani, Kulswamini of Maharashtra.',
    lyrics: const [
      LyricStanza(
        startTimeMs: 0,
        devanagari: 'दुर्गे दुर्घट भारी तुजविण संसारी ।\nअनाथनाथे अंबे करुणा विस्तारी ॥\nवारीं वारीं जन्ममरणातें वारीं ।\nहारीं पडलों आतां संकट नीवारीं ॥ १ ॥\n\nजय देवी जय देवी जय महिषासुरमथनी ।\nसुरवरईश्वरवरदे तारक संजीवनी ॥ ध्रु० ॥',
        transliteration: 'Durge durgat bhari tujvin sansari,\nAnathnathe ambe karuna vistari.\nVarin varin janmamarnate varin,\nHarin padlon ata sankat nivari. (1)\n\nJai Devi Jai Devi Jai Mahishasuramathani,\nSuravara-ishvara-varade taraka sanjeevani. (Refrain)',
      ),
      LyricStanza(
        startTimeMs: 70000,
        devanagari: 'प्रसन्नवदने प्रसन्न होसी निजदासां ।\nक्लेशांपासोनि सोडीं तोडीं भवपाशां ॥\nअंबे तुजवांचून कोण पुरवील आशा ।\nनरहरिनुरसी झाला ठाव द्यावा पायांपाशीं ॥ २ ॥\n\nजय देवी जय देवी जय महिषासुरमथनी ।\nसुरवरईश्वरवरदे तारक संजीवनी ॥ ध्रु० ॥',
        transliteration: 'Prasannavadane prasanna hosi nijadasan,\nKleshanpasoni sodin todin bhavpashan.\nAmbe tujvanchun kon purveel asha,\nNaraharinurasi jhala thav dyava payanpashin. (2)\n\nJai Devi Jai Devi Jai Mahishasuramathani,\nSuravara-ishvara-varade taraka sanjeevani. (Refrain)',
      ),
    ],
  ),
  AartiItem(
    id: 'tuljabhavani_aai_raja_udo_udo',
    title: 'Aai Raja Udo Udo (Gondhal & Aarti)',
    titleHi: 'आई राजा उदो उदो (गोंधळ व आरती)',
    titleMr: 'आई राजा उदो उदो (गोंधळ व स्तुती)',
    deity: 'Goddess Tuljabhavani',
    deityHi: 'माँ तुलजा भवानी',
    deityMr: 'आई तुळजाभवानी',
    singer: 'Ajay-Atul',
    tags: const ['Aarti', 'Gondhal', 'Devi'],
    youtubeVideoId: 'kP0q1p01h6c',
    durationText: '5:30',
    accentColorHex: '#B71C1C',
    deityEmoji: '🌺',
    aboutMr: 'आई तुळजाभवानीचा जागर व मंगल गोंधळ.',
    aboutHi: 'माँ तुलजा भवानी का पावन गोंधल व स्तुति।',
    about: 'Traditional sacred Gondhal invoking Goddess Tuljabhavani.',
    lyrics: const [
      LyricStanza(
        startTimeMs: 0,
        devanagari: 'आई राजा उदो उदो बोला उदो उदो बोला उदो ।\nआई भवानी तुळजापूरची कुलस्वामिनी जगदंबा ॥\nसिंहासनारूढ माता तुळजापूर निवासिनी ।\nभक्तांच्या हाकेला धावून येई जननी ॥',
        transliteration: 'Aai Raja Udo Udo Bola Udo Udo Bola Udo,\nAai Bhavani Tuljapur-chi Kulswamini Jagadamba.\nSimhasanarudha Mata Tuljapur Nivasini,\nBhaktanchya hakela dhavun yei Janani.',
      ),
    ],
  ),

  // ── 2. श्री राधा रानी ──────────────────────────────────────────────
  AartiItem(
    id: 'radha_aarti_vrishbhanu_dulari',
    title: 'Aarti Shri Vrishbhanu Dulari Ki',
    titleHi: 'श्री राधा रानी आरती (आरती श्री वृषभानु दुलारी की)',
    titleMr: 'श्री राधा राणी आरती',
    deity: 'Radha',
    deityHi: 'राधा रानी',
    deityMr: 'राधा राणी',
    singer: 'Pujya Gaurav Krishna Goswami',
    tags: const ['Aarti', 'Radha', 'Barsana'],
    youtubeVideoId: '_f7GqJ28x6o',
    backupVideoIds: const ['Qk3LpGq0vHw'],
    durationText: '6:10',
    accentColorHex: '#E91E63',
    deityEmoji: '🌸',
    aboutMr: 'बरसानेची लाडली श्री राधा राणीची अत्यंत सुंदर व कृपाळू आरती.',
    aboutHi: 'बरसाना की लाडली श्री राधा रानी की परम पावन आरती।',
    about: 'Divine Aarti of Shri Radha Rani praising the Princess of Barsana.',
    lyrics: const [
      LyricStanza(
        startTimeMs: 0,
        devanagari: 'आरती श्री वृषभानु-दुलारी की ।\nकीर्ति-प्रिया, रूप-उजियारी की ॥\nकोटि-रूप-मदन-मोहन-मोहिनी ।\nनित नव रूप अनुपम सोहिनी ॥\n\nआरती श्री वृषभानु-दुलारी की ।\nश्री राधे राधे बरसाने वारी की ॥',
        transliteration: 'Aarti Shri Vrishabhanu-Dulari Ki,\nKirti-Priya, Roop-Ujiyari Ki.\nKoti-Roop-Madan-Mohan-Mohini,\nNit Nav Roop Anupam Sohini.\n\nAarti Shri Vrishabhanu-Dulari Ki,\nShri Radhe Radhe Barsane Vari Ki.',
      ),
      LyricStanza(
        startTimeMs: 75000,
        devanagari: 'नवल-किशोर-नित प्रेम-विहारिणी ।\nभक्त-जनों के सकल दुःख हारिणी ॥\nशरणागत-वत्सल सुख-दायिनी ।\nश्री युगल-छवि मन-हरषायिनी ॥\n\nआरती श्री वृषभानु-दुलारी की ।\nश्री राधे राधे बरसाने वारी की ॥',
        transliteration: 'Naval-Kishor-Nit Prem-Viharini,\nBhakt-Janon Ke Sakal Dukh Harini.\nSharanagat-Vatsal Sukh-Dayini,\nShri Yugal-Chhavi Man-Harshayini.\n\nAarti Shri Vrishabhanu-Dulari Ki,\nShri Radhe Radhe Barsane Vari Ki.',
      ),
    ],
  ),
  AartiItem(
    id: 'radha_kripa_kataksha',
    title: 'Shri Radha Kripa Kataksha Stotram',
    titleHi: 'श्री राधा कृपा कटाक्ष स्तोत्रम्',
    titleMr: 'श्री राधा कृपा कटाक्ष स्तोत्र',
    deity: 'Radha',
    deityHi: 'राधा रानी',
    deityMr: 'राधा राणी',
    singer: 'Traditional',
    tags: const ['Stotra', 'Radha', 'Barsana'],
    youtubeVideoId: 'v8P5M0F33G4',
    durationText: '8:45',
    accentColorHex: '#E91E63',
    deityEmoji: '🌸',
    aboutMr: 'भगवान शंकरांनी रचलेले श्री राधा कृपा कटाक्ष स्तोत्र.',
    aboutHi: 'भगवान शिव द्वारा रचित अत्यंत चमत्कारी श्री राधा कृपा कटाक्ष स्तोत्र।',
    about: 'The sacred Shri Radha Kripa Kataksha Stotram for divine grace.',
    lyrics: const [
      LyricStanza(
        startTimeMs: 0,
        devanagari: 'मुनीन्द्रवृन्दवन्दिते त्रिलोकशोकहारिणि\nप्रसन्नवक्त्रपङ्कजे निकुञ्जभूविलासिनी ।\nव्रजेन्द्रभानुन्दिनि प्रपुण्यपुण्यचन्द्रिके\nकदा करिष्यसीह मां कृपाकटाक्षभाजनम् ॥ १ ॥',
        transliteration: 'Munindra-vrinda-vandite triloka-shoka-harini,\nPrasanna-vaktra-pankaje nikunja-bhu-vilasini.\nVrajendra-bhanu-nandini prapunya-punya-chandrike,\nKada karishyasiha mam kripa-kataksha-bhajanam. (1)',
      ),
    ],
  ),

  // ── 3. श्री बांके बिहारी ──────────────────────────────────────────
  AartiItem(
    id: 'banke_bihari_teri_aarti_gaun',
    title: 'Shri Banke Bihari Teri Aarti Gaun',
    titleHi: 'श्री बांके बिहारी तेरी आरती गाऊं',
    titleMr: 'श्री बांके बिहारी तेरी आरती गाऊं',
    deity: 'Banke Bihari',
    deityHi: 'श्री बांके बिहारी',
    deityMr: 'श्री बांके बिहारी',
    singer: 'Pujya Chitra Vichitra Ji',
    tags: const ['Aarti', 'Krishna', 'Vrindavan'],
    youtubeVideoId: '1w3DkW_JtV0',
    backupVideoIds: const ['9Tz8_5V0j7o'],
    durationText: '5:40',
    accentColorHex: '#1A237E',
    deityEmoji: '🦚',
    aboutMr: 'वृंदावनातील ठाकूर श्री बांके बिहारीजींची जगप्रसिद्ध परम पावन आरती.',
    aboutHi: 'वृंदावन के ठाकुर श्री बांके बिहारी जी की जगप्रसिद्ध एवं अति प्रिय आरती।',
    about: 'Beloved Aarti of Thakur Shri Banke Bihari Ji of Vrindavan.',
    lyrics: const [
      LyricStanza(
        startTimeMs: 0,
        devanagari: 'श्री बांके बिहारी तेरी आरती गाऊं ।\nकुंज बिहारी तेरी आरती गाऊं ॥\nश्री श्याम सुंदर तेरी आरती गाऊं ।\nश्री बांके बिहारी तेरी आरती गाऊं ॥ ध्रु० ॥\n\nमोर मुकुट प्यारे शीश पे सोहे ।\nप्यारी बंसी मेरो मन मोहे ॥\nदेखि छवि बलिहारी जाऊं ।\nश्री बांके बिहारी तेरी आरती गाऊं ॥ १ ॥',
        transliteration: 'Shri Banke Bihari teri aarti gaun,\nKunj Bihari teri aarti gaun.\nShri Shyam Sundar teri aarti gaun,\nShri Banke Bihari teri aarti gaun. (Refrain)\n\nMor mukut pyare sheesh pe sohe,\nPyari bansi mero man mohe.\nDekhi chhavi balihari jaun,\nShri Banke Bihari teri aarti gaun. (1)',
      ),
      LyricStanza(
        startTimeMs: 70000,
        devanagari: 'चरणों से निकली गंगा प्यारी ।\nजिसने सारी दुनिया तारी ॥\nउन चरणों में शीश नवाऊं ।\nश्री बांके बिहारी तेरी आरती गाऊं ॥ २ ॥\n\nश्री हरिदास के प्यारे तुम हो ।\nमेरे मोहन जीवन धन हो ॥\nदेखि युगल छवि बलिहारी जाऊं ।\nश्री बांके बिहारी तेरी आरती गाऊं ॥ ३ ॥',
        transliteration: 'Charnon se nikli Ganga pyari,\nJisne saari duniya taari.\nUn charnon mein sheesh navaun,\nShri Banke Bihari teri aarti gaun. (2)\n\nShri Haridas ke pyare tum ho,\nMere Mohan jeevan dhan ho.\nDekhi yugal chhavi balihari jaun,\nShri Banke Bihari teri aarti gaun. (3)',
      ),
    ],
  ),

  // ── 4. श्री जोतिबा (केदारलिंग) ──────────────────────────────────
  AartiItem(
    id: 'jyotiba_aarti_changbhala',
    title: 'Shri Jyotibachi Aarti (Changbhala)',
    titleHi: 'श्री जोतिबा आरती (चांगभलं जोतिबाच्या नावानं)',
    titleMr: 'श्री जोतिबा आरती (चांगभलं)',
    deity: 'Lord Jyotiba',
    deityHi: 'श्री जोतिबा',
    deityMr: 'श्री जोतिबा',
    singer: 'Traditional',
    tags: const ['Aarti', 'Jyotiba', 'Kuldevta'],
    youtubeVideoId: 'gP1eOQcEkmU',
    durationText: '4:30',
    accentColorHex: '#E65100',
    deityEmoji: '🔱',
    aboutMr: 'कोल्हापूर वाडी रत्नागिरीचे आराध्य दैवत श्री केदारलिंग जोतिबाची मंगल आरती.',
    aboutHi: 'कोल्हापुर वाडी रत्नागिरि के आराध्य देव श्री जोतिबा (केदारलिंग) की आरती।',
    about: 'Sacred Aarti of Lord Jyotiba (Kedareshwar) of Wadi Ratnagiri, Kolhapur.',
    lyrics: const [
      LyricStanza(
        startTimeMs: 0,
        devanagari: 'जय देव जय देव जय श्री जोतिबा ।\nचांगभलं चांगभलं नावानं जोतिबा ॥ ध्रु० ॥\n\nरत्नागिरी शिखरीं सुंदर मंदिर ।\nगुलाल खोबऱ्याची उधळण साचार ॥\nघोड्यावर स्वार हातीं त्रिशूळ डमरू ।\nदर्शन घेतांचि भवभय वारू ॥ १ ॥\n\nजय देव जय देव जय श्री जोतिबा ।\nचांगभलं चांगभलं नावानं जोतिबा ॥ ध्रु० ॥',
        transliteration: 'Jai Dev Jai Dev Jai Shri Jyotiba,\nChangbhala Changbhala navan Jyotiba. (Refrain)\n\nRatnagiri shikhari sundar mandir,\nGulal khobryachi udhalan sachar.\nGhodyavar swar haati trishul damaru,\nDarshan ghetanchi bhavbhay vaaru. (1)\n\nJai Dev Jai Dev Jai Shri Jyotiba,\nChangbhala Changbhala navan Jyotiba. (Refrain)',
      ),
      LyricStanza(
        startTimeMs: 65000,
        devanagari: 'काळभैरव यमाई संगती शोभती ।\nभक्तजन आवडीं तव गुण गाती ॥\nसंकटीं रक्षीसी भक्तां निर्धार ।\nदास म्हणे जोतिबा कृपेचा सागर ॥ २ ॥\n\nजय देव जय देव जय श्री जोतिबा ।\nचांगभलं चांगभलं नावानं जोतिबा ॥ ध्रु० ॥',
        transliteration: 'Kalbhairav Yamai sangati shobhati,\nBhaktajan aavadin tav gun gaati.\nSankatin rakshisi bhaktan nirdhar,\nDaas mhane Jyotiba krupecha saagar. (2)\n\nJai Dev Jai Dev Jai Shri Jyotiba,\nChangbhala Changbhala navan Jyotiba. (Refrain)',
      ),
    ],
  ),

  // ── 5. श्री कालभैरव ──────────────────────────────────────────────
  AartiItem(
    id: 'kalbhairav_aarti_jai_bhairav_deva',
    title: 'Shri Kalbhairav Aarti (Jai Bhairav Deva)',
    titleHi: 'श्री कालभैरव आरती (जय भैरव देवा)',
    titleMr: 'श्री काळभैरव आरती',
    deity: 'Lord Bhairavnath',
    deityHi: 'कालभैरव',
    deityMr: 'काळभैरवनाथ',
    singer: 'Traditional',
    tags: const ['Aarti', 'Bhairav', 'Shiva'],
    youtubeVideoId: 'w_n_Q-rC96M',
    durationText: '4:50',
    accentColorHex: '#212121',
    deityEmoji: '🔱',
    aboutMr: 'काशीचे कोतवाल भगवान श्री कालभैरव यांची संकटहारी महा आरती.',
    aboutHi: 'काशी के कोतवाल भगवान श्री कालभैरव जी की परम कल्याणकारी आरती।',
    about: 'Sacred Aarti of Lord Kalbhairav, protector and ruler of Kashi.',
    lyrics: const [
      LyricStanza(
        startTimeMs: 0,
        devanagari: 'जय भैरव देवा, प्रभु जय भैरव देवा ।\nजय काली और गौरा, तुमको नित ध्यावत ॥ ध्रु० ॥\n\nशीश जटा हाथ त्रिशूल, कर खप्पर साजे ।\nबटुक भैरव महा-भैरव, डमरू घन बाजे ॥ १ ॥\n\nजय भैरव देवा, प्रभु जय भैरव देवा ।\nजय काली और गौरा, तुमको नित ध्यावत ॥ ध्रु० ॥',
        transliteration: 'Jai Bhairav Deva, Prabhu Jai Bhairav Deva,\nJai Kali aur Gaura, tumko nit dhyavat. (Refrain)\n\nSheesh jata haath trishul, kar khappar saje,\nBatuk Bhairav Maha-Bhairav, damaru ghan baje. (1)\n\nJai Bhairav Deva, Prabhu Jai Bhairav Deva,\nJai Kali aur Gaura, tumko nit dhyavat. (Refrain)',
      ),
      LyricStanza(
        startTimeMs: 65000,
        devanagari: 'कष्ट कलेश हरो सब, भक्तां सुखकारी ।\nभूत प्रेत बाधा नाशक, दुष्टन संहारी ॥ २ ॥\n\nजो जन भक्ति से ध्यावे, मनवांछित फल पावे ।\nश्री भैरव नाथ कृपा से, भवसागर तर जावे ॥ ३ ॥\n\nजय भैरव देवा, प्रभु जय भैरव देवा ।\nजय काली और गौरा, तुमको नित ध्यावत ॥ ध्रु० ॥',
        transliteration: 'Kasht kalesh haro sab, bhaktan sukhkari,\nBhoot pret badha nashak, dushtan sanhari. (2)\n\nJo jan bhakti se dhyave, man-vanchhit phal paave,\nShri Bhairav Nath kripa se, bhavsagar tar jaave. (3)\n\nJai Bhairav Deva, Prabhu Jai Bhairav Deva,\nJai Kali aur Gaura, tumko nit dhyavat. (Refrain)',
      ),
    ],
  ),
  AartiItem(
    id: 'kalbhairav_ashtakam',
    title: 'Shri Kalabhairava Ashtakam',
    titleHi: 'श्री कालभैरवाष्टकम्',
    titleMr: 'श्री कालभैरवाष्टकम्',
    deity: 'Lord Bhairavnath',
    deityHi: 'कालभैरव',
    deityMr: 'काळभैरवनाथ',
    singer: 'Traditional',
    tags: const ['Stotra', 'Bhairav', 'Shiva'],
    youtubeVideoId: 'U_kR4WpC9Yw',
    durationText: '7:20',
    accentColorHex: '#212121',
    deityEmoji: '🔱',
    aboutMr: 'आद्य शंकराचार्य विरचित संकटहारी श्री कालभैरवाष्टकम्.',
    aboutHi: 'आदि शंकराचार्य जी द्वारा रचित अत्यंत प्रभावशाली कालभैरवाष्टकम्।',
    about: 'Powerful Kalabhairava Ashtakam composed by Adi Shankaracharya.',
    lyrics: const [
      LyricStanza(
        startTimeMs: 0,
        devanagari: 'देवराजसेव्यमानपावनाङ्घ्रिपङ्कजं\nव्यालयज्ञसूत्रमिन्दुशेखरं कृपाकरम् ।\nनारदादियोगिवृन्दवन्दितं दिगम्बरं\nकाशिकापुराधिनाथकालभैरवं भजे ॥ १ ॥',
        transliteration: 'Devaraja-sevyamana-pavananghri-pankajam,\nVyala-yajna-sutram-indu-shekharam kripakaram.\nNaradadi-yogi-vrinda-vanditam digambaram,\nKashika-puradhinatha-kalabhairavam bhaje. (1)',
      ),
    ],
  ),
];
