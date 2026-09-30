import '../../domain/entities/aarti_item.dart';
import '../../domain/entities/lyric_stanza.dart';

/// Sacred Hindu Bhajans & Kirtans — lyrics and [LyricStanza.startTimeMs]
/// are matched to the primary [AartiItem.youtubeVideoId] for each entry.
final List<AartiItem> kBhajanCatalog = [
  // ─────────────────────────────────────────────────────────────────────────
  // 1. ACHYUTAM KESHAVAM — Vikram Hazra (Art of Living)
  // Video: QyMZxGlXulY (~5:45)
  // ─────────────────────────────────────────────────────────────────────────
  AartiItem(
    id: 'bhajan_achyutam_keshavam',
    title: 'Achyutam Keshavam',
    titleHi: 'अच्युतम केशवम',
    titleMr: 'अच्युतम केशवम',
    deity: 'Lord Krishna',
    deityHi: 'श्री कृष्ण',
    deityMr: 'श्री कृष्ण',
    singer: 'Vikram Hazra',
    tags: const ['Popular', 'Bhajan', 'Krishna', 'Kirtan'],
    youtubeVideoId: 'QyMZxGlXulY',
    backupVideoIds: const ['Nil8W8XlJaE', 'fnZf62u0j5Q'],
    durationText: '5:45',
    accentColorHex: '#1E88E5',
    deityEmoji: '🦚',
    aboutMr:
        'अच्युतम केशवम हे भगवान श्रीकृष्णाचे अतिशय लोकप्रिय व मधुर भजन आहे. निष्काम भक्ती आणि श्रद्धेने देवाला हाक मारल्यास देव कसा धावून येतो याचे सुरेख वर्णन यात आहे.',
    aboutHi:
        'अच्युतम केशवम भगवान श्री कृष्ण का अत्यंत मधुर एवं प्रिय भजन है। इसमें बताया गया है कि सच्चे प्रेम और निष्ठा से पुकारने पर प्रभु सदैव अपने भक्त के पास आते हैं।',
    about:
        'Achyutam Keshavam is a beloved Art of Living bhajan by Vikram Hazra, praising Lord Krishna with the famous "Kaun kehte hain" verses.',
    lyrics: const [
      LyricStanza(
        startTimeMs: 14000,
        devanagari: 'अच्युतं केशवं कृष्ण दामोदरं\nराम नारायणं जानकी वल्लभम् ॥',
        transliteration:
            'Achyutam Keshavam Krishna Damodaram,\nRama Narayanam Janaki Vallabham.',
      ),
      LyricStanza(
        startTimeMs: 42000,
        devanagari: 'कौन कहते हैं भगवान आते नहीं\nतुम मीरा के जैसे बुलाते नहीं ॥',
        transliteration:
            'Kaun Kehte Hain Bhagwan Aate Nahin,\nTum Meera Ke Jaise Bulate Nahin.',
      ),
      LyricStanza(
        startTimeMs: 70000,
        devanagari: 'अच्युतं केशवं कृष्ण दामोदरं\nराम नारायणं जानकी वल्लभम् ॥',
        transliteration:
            'Achyutam Keshavam Krishna Damodaram,\nRama Narayanam Janaki Vallabham.',
      ),
      LyricStanza(
        startTimeMs: 98000,
        devanagari: 'कौन कहते हैं भगवान खाते नहीं\nबेर शबरी के जैसे खिलाते नहीं ॥',
        transliteration:
            'Kaun Kehte Hain Bhagwan Khaate Nahin,\nBer Shabari Ke Jaise Khilate Nahin.',
      ),
      LyricStanza(
        startTimeMs: 126000,
        devanagari: 'अच्युतं केशवं कृष्ण दामोदरं\nराम नारायणं जानकी वल्लभम् ॥',
        transliteration:
            'Achyutam Keshavam Krishna Damodaram,\nRama Narayanam Janaki Vallabham.',
      ),
      LyricStanza(
        startTimeMs: 154000,
        devanagari: 'कौन कहते हैं भगवान सोते नहीं\nमाँ यशोदा के जैसे सुलाते नहीं ॥',
        transliteration:
            'Kaun Kehte Hain Bhagwan Sote Nahin,\nMaa Yashoda Ke Jaise Sulate Nahin.',
      ),
      LyricStanza(
        startTimeMs: 182000,
        devanagari: 'अच्युतं केशवं कृष्ण दामोदरं\nराम नारायणं जानकी वल्लभम् ॥',
        transliteration:
            'Achyutam Keshavam Krishna Damodaram,\nRama Narayanam Janaki Vallabham.',
      ),
      LyricStanza(
        startTimeMs: 210000,
        devanagari: 'कौन कहते हैं भगवान नाचते नहीं\nगोपियों की तरह तुम नचाते नहीं ॥',
        transliteration:
            'Kaun Kehte Hain Bhagwan Naachte Nahin,\nGopiyon Ki Tarah Tum Nachate Nahin.',
      ),
      LyricStanza(
        startTimeMs: 238000,
        devanagari: 'अच्युतं केशवं कृष्ण दामोदरं\nराम नारायणं जानकी वल्लभम् ॥',
        transliteration:
            'Achyutam Keshavam Krishna Damodaram,\nRama Narayanam Janaki Vallabham.',
      ),
      LyricStanza(
        startTimeMs: 266000,
        devanagari: 'नाम जपते चलो काम करते चलो\nहर समय कृष्ण का नाम धरते चलो ॥',
        transliteration:
            'Naam Japte Chalo Kaam Karte Chalo,\nHar Samay Krishna Ka Naam Dharte Chalo.',
      ),
      LyricStanza(
        startTimeMs: 294000,
        devanagari: 'अच्युतं केशवं कृष्ण दामोदरं\nराम नारायणं जानकी वल्लभम् ॥',
        transliteration:
            'Achyutam Keshavam Krishna Damodaram,\nRama Narayanam Janaki Vallabham.',
      ),
    ],
  ),

  // ─────────────────────────────────────────────────────────────────────────
  // 2. SHRI RAM CHANDRA KRIPALU — Lata Mangeshkar
  // Video: YBt0zQ1eZf8 (~5:18)
  // ─────────────────────────────────────────────────────────────────────────
  AartiItem(
    id: 'bhajan_shri_ram_chandra_kripalu',
    title: 'Shri Ram Chandra Kripalu',
    titleHi: 'श्री रामचंद्र कृपालु',
    titleMr: 'श्री रामचंद्र कृपालु',
    deity: 'Lord Rama',
    deityHi: 'श्री राम',
    deityMr: 'प्रभू श्रीराम',
    singer: 'Lata Mangeshkar',
    tags: const ['Popular', 'Bhajan', 'Ram', 'Stuti'],
    youtubeVideoId: 'YBt0zQ1eZf8',
    backupVideoIds: const ['IE3r92gJrFM'],
    durationText: '5:18',
    accentColorHex: '#E65100',
    deityEmoji: '🏹',
    aboutMr:
        'गोस्वामी तुलसीदास रचित ही श्रीराम स्तुती संस्कृत व अवधी भाषेतील अद्भुत रचना आहे. प्रभू श्रीरामांच्या दिव्य रूपाचे आणि करुणेचे यामध्ये अलौकिक दर्शन घडते.',
    aboutHi:
        'गोस्वामी तुलसीदास जी द्वारा रचित यह पावन स्तुति मर्यादा पुरुषोत्तम श्री राम के परम कल्याणकारी और सुंदर स्वरूप का गुणगान करती है।',
    about:
        'Composed by Saint Goswami Tulsidas, Shri Ram Chandra Kripalu Bhajman praises the merciful form, grace, and valor of Lord Rama.',
    lyrics: const [
      LyricStanza(
        startTimeMs: 6000,
        devanagari:
            'श्रीरामचन्द्र कृपालु भजु मन हरण भवभय दारुणम् ।\nनवकंज लोचन कंज मुख कर कंज पद कंजारुणम् ॥',
        transliteration:
            'Shri Ramchandra Kripalu Bhaju Man Haran Bhavbhaya Darunam,\nNavkanj Lochan Kanj Mukh Kar Kanj Pad Kanjarunam.',
      ),
      LyricStanza(
        startTimeMs: 50000,
        devanagari:
            'कन्दर्प अगणित अमित छवि नवनील नीरद सुन्दरम् ।\nपट पीत मानहु तडित रुचि शुचि नौमि जनक सुतावरम् ॥',
        transliteration:
            'Kandarp Aganit Amit Chhavi Navneel Neerad Sundaram,\nPat Peet Maanhu Tadit Ruchi Shuchi Naumi Janak Sutavaram.',
      ),
      LyricStanza(
        startTimeMs: 96000,
        devanagari:
            'भजु दीनबन्धु दिनेश दानव दैत्यवंश निकन्दनम् ।\nरघुनन्द आनन्दकन्द कोशलचन्द दशरथ नन्दनम् ॥',
        transliteration:
            'Bhaju Deenbandhu Dinesh Daanav Daityavansh Nikandanam,\nRaghunand Anandkand Kaushalchand Dashrath Nandanam.',
      ),
      LyricStanza(
        startTimeMs: 142000,
        devanagari:
            'सिर मुकुट कुण्डल तिलक चारु उदार अंग विभूषणम् ।\nआजानुभुज शर चाप धर संग्राम जित खर दूषणम् ॥',
        transliteration:
            'Sir Mukut Kundal Tilak Chaaru Udaar Ang Vibhooshanam,\nAajanubhuj Shar Chaap Dhar Sangram Jit Khar Dooshanam.',
      ),
      LyricStanza(
        startTimeMs: 188000,
        devanagari:
            'इति वदति तुलसीदास शंकर शेष मुनि मन रंजनम् ।\nमम हृदय कंज निवास कुरु कामादि खल दल गंजनम् ॥',
        transliteration:
            'Iti Vadati Tulsidas Shankar Shesh Muni Man Ranjanam,\nMam Hridaya Kanj Nivaas Kuru Kaamadi Khal Dal Ganjanam.',
      ),
    ],
  ),

  // ─────────────────────────────────────────────────────────────────────────
  // 3. RAGHUPATI RAGHAV RAJA RAM — Hariharan
  // Video: rZ8jDjSwCY0 (~4:30)
  // ─────────────────────────────────────────────────────────────────────────
  AartiItem(
    id: 'bhajan_raghupati_raghav',
    title: 'Raghupati Raghav Raja Ram',
    titleHi: 'रघुपति राघव राजा राम',
    titleMr: 'रघुपति राघव राजा राम',
    deity: 'Lord Rama',
    deityHi: 'श्री राम',
    deityMr: 'प्रभू श्रीराम',
    singer: 'Hariharan',
    tags: const ['Bhajan', 'Ram', 'Kirtan'],
    youtubeVideoId: 'rZ8jDjSwCY0',
    backupVideoIds: const ['NlofTdtjRy8', 'xBBY32frKqI'],
    durationText: '4:30',
    accentColorHex: '#FB8C00',
    deityEmoji: '🏹',
    aboutMr:
        'रघुपति राघव राजा राम हे संपूर्ण विश्वात प्रसिद्ध असलेले सनातन राम भजन आहे. मनःशांती आणि एकाग्रतेसाठी हे नामस्मरण अत्यंत प्रभावी मानले जाते.',
    aboutHi:
        'रघुपति राघव राजा राम संपूर्ण भारतवर्ष में गाया जाने वाला सर्वप्रिय राम भजन और कीर्तन है जो मन को परम शांति प्रदान करता है।',
    about:
        'The immortal Ram dhun celebrating Lord Rama and Mother Sita, with Gandhi\'s famous unity couplet Ishwar Allah Tero Naam.',
    lyrics: const [
      LyricStanza(
        startTimeMs: 5000,
        devanagari: 'रघुपति राघव राजा राम ।\nपतित पावन सीताराम ॥',
        transliteration: 'Raghupati Raghav Raja Ram,\nPatit Pavan Sita Ram.',
      ),
      LyricStanza(
        startTimeMs: 35000,
        devanagari: 'सीताराम सीताराम ।\nभज प्यारे तू सीताराम ॥',
        transliteration: 'Sita Ram Sita Ram,\nBhaj Pyare Tu Sita Ram.',
      ),
      LyricStanza(
        startTimeMs: 65000,
        devanagari: 'ईश्वर अल्लाह तेरो नाम ।\nसबको सन्मति दे भगवान ॥',
        transliteration:
            'Ishwar Allah Tero Naam,\nSabko Sanmati De Bhagwan.',
      ),
      LyricStanza(
        startTimeMs: 100000,
        devanagari: 'रघुपति राघव राजा राम ।\nपतित पावन सीताराम ॥',
        transliteration: 'Raghupati Raghav Raja Ram,\nPatit Pavan Sita Ram.',
      ),
      LyricStanza(
        startTimeMs: 140000,
        devanagari: 'राम राम जय राजा राम ।\nराम राम जय सीताराम ॥',
        transliteration: 'Ram Ram Jai Raja Ram,\nRam Ram Jai Sita Ram.',
      ),
      LyricStanza(
        startTimeMs: 180000,
        devanagari: 'रघुपति राघव राजा राम ।\nपतित पावन सीताराम ॥',
        transliteration: 'Raghupati Raghav Raja Ram,\nPatit Pavan Sita Ram.',
      ),
    ],
  ),

  // ─────────────────────────────────────────────────────────────────────────
  // 4. HARE KRISHNA MAHAMANTRA — Jagjit Singh
  // Video: dDi901rag90 (~7:10) — mantra only, no extra verses
  // ─────────────────────────────────────────────────────────────────────────
  AartiItem(
    id: 'bhajan_hare_krishna_mahamantra',
    title: 'Hare Krishna Mahamantra',
    titleHi: 'हरे कृष्ण महामंत्र',
    titleMr: 'हरे कृष्ण महामंत्र',
    deity: 'Lord Krishna',
    deityHi: 'महामंत्र',
    deityMr: 'महामंत्र',
    singer: 'Jagjit Singh',
    tags: const ['Kirtan', 'MahaMantra', 'Krishna'],
    youtubeVideoId: 'dDi901rag90',
    backupVideoIds: const ['DpiqtZSLB3w', '2Jd8-qgA8Gw'],
    durationText: '7:10',
    accentColorHex: '#00897B',
    deityEmoji: '🦚',
    aboutMr:
        'कलियुगातील उद्धारासाठी कलिसंतरण उपनिषदामध्ये सांगितलेला हा सर्वश्रेष्ठ तारक मंत्र आहे. याचे गायन केल्याने अंतःकरण शुद्ध होते.',
    aboutHi:
        'कलियुग में मुक्ति और आध्यात्मिक आनंद के लिए यह महामंत्र वेदों द्वारा प्रमाणित है। इसके श्रवण और कीर्तन से परम शांति मिलती है।',
    about:
        'Jagjit Singh\'s soulful rendering of the Hare Krishna Mahamantra from the Kali-Santarana Upanishad.',
    lyrics: const [
      LyricStanza(
        startTimeMs: 8000,
        devanagari:
            'हरे कृष्ण हरे कृष्ण\nकृष्ण कृष्ण हरे हरे ॥',
        transliteration:
            'Hare Krishna Hare Krishna,\nKrishna Krishna Hare Hare.',
      ),
      LyricStanza(
        startTimeMs: 40000,
        devanagari: 'हरे राम हरे राम\nराम राम हरे हरे ॥',
        transliteration: 'Hare Rama Hare Rama,\nRama Rama Hare Hare.',
      ),
      LyricStanza(
        startTimeMs: 75000,
        devanagari:
            'हरे कृष्ण हरे कृष्ण कृष्ण कृष्ण हरे हरे ।\nहरे राम हरे राम राम राम हरे हरे ॥',
        transliteration:
            'Hare Krishna Hare Krishna Krishna Krishna Hare Hare,\nHare Rama Hare Rama Rama Rama Hare Hare.',
      ),
      LyricStanza(
        startTimeMs: 140000,
        devanagari:
            'हरे कृष्ण हरे कृष्ण कृष्ण कृष्ण हरे हरे ।\nहरे राम हरे राम राम राम हरे हरे ॥',
        transliteration:
            'Hare Krishna Hare Krishna Krishna Krishna Hare Hare,\nHare Rama Hare Rama Rama Rama Hare Hare.',
      ),
      LyricStanza(
        startTimeMs: 220000,
        devanagari:
            'हरे कृष्ण हरे कृष्ण कृष्ण कृष्ण हरे हरे ।\nहरे राम हरे राम राम राम हरे हरे ॥',
        transliteration:
            'Hare Krishna Hare Krishna Krishna Krishna Hare Hare,\nHare Rama Hare Rama Rama Rama Hare Hare.',
      ),
      LyricStanza(
        startTimeMs: 300000,
        devanagari:
            'हरे कृष्ण हरे कृष्ण कृष्ण कृष्ण हरे हरे ।\nहरे राम हरे राम राम राम हरे हरे ॥',
        transliteration:
            'Hare Krishna Hare Krishna Krishna Krishna Hare Hare,\nHare Rama Hare Rama Rama Rama Hare Hare.',
      ),
    ],
  ),

  // ─────────────────────────────────────────────────────────────────────────
  // 5. HAR HAR SHAMBHU — Abhilipsa Panda & Jeetu Sharma
  // Video: RZK30grtV-0
  // ─────────────────────────────────────────────────────────────────────────
  AartiItem(
    id: 'bhajan_har_har_shambhu',
    title: 'Har Har Shambhu',
    titleHi: 'हर हर शंभू शिव महादेवा',
    titleMr: 'हर हर शंभू शिव महादेवा',
    deity: 'Lord Shiva',
    deityHi: 'भगवान शिव',
    deityMr: 'महादेव',
    singer: 'Abhilipsa Panda',
    tags: const ['Bhajan', 'Shiva', 'Kirtan'],
    youtubeVideoId: 'RZK30grtV-0',
    backupVideoIds: const ['eeG5Ydy2eEw'],
    durationText: '5:40',
    accentColorHex: '#3949AB',
    deityEmoji: '🔱',
    aboutMr:
        'भगवान शिवाची दिव्य कीर्ती आणि तांडव रूपाची ऊर्जा देणारे हे अत्यंत शक्तिशाली व ऊर्जावान शिव भजन आहे.',
    aboutHi:
        'भगवान शिव शंकर की असीम महिमा और कर्पूरगौरं स्तुति से सुसज्जित यह अत्यंत ऊर्जावान और दिव्य शिव भजन है।',
    about:
        'The viral Abhilipsa Panda & Jeetu Sharma Shiva anthem with traditional shlokas and the Har Har Shambhu chorus.',
    lyrics: const [
      LyricStanza(
        startTimeMs: 0,
        devanagari:
            'हर हर शंभू शंभू शंभू शिव महादेवा ।\nशंभू शंभू शंभू शंभू शिव महादेवा ॥',
        transliteration:
            'Har Har Shambhu Shambhu Shambhu Shiva Mahadeva,\nShambhu Shambhu Shambhu Shambhu Shiva Mahadeva.',
      ),
      LyricStanza(
        startTimeMs: 28000,
        devanagari:
            'कर्पूरगौरं करुणावतारं संसारसारं भुजगेन्द्रहारम् ।\nसदावसन्तं हृदयारविन्दे भवं भवानीसहितं नमामि ॥',
        transliteration:
            'Karpura Gauram Karunavataram Sansarasaram Bhujagendraharam,\nSadavasantam Hridayaravinde Bhavam Bhavanisahitam Namami.',
      ),
      LyricStanza(
        startTimeMs: 68000,
        devanagari:
            'हर हर शंभू शंभू शंभू शिव महादेवा ।\nशंभू शंभू शंभू शंभू शिव महादेवा ॥',
        transliteration:
            'Har Har Shambhu Shambhu Shambhu Shiva Mahadeva,\nShambhu Shambhu Shambhu Shambhu Shiva Mahadeva.',
      ),
      LyricStanza(
        startTimeMs: 96000,
        devanagari:
            'सानन्दमानन्दवने वसन्तं आनन्दकन्दं हतपापवृन्दम् ।\nवाराणसीनाथमनाथनाथं श्रीविश्वनाथं शरणं प्रपद्ये ॥',
        transliteration:
            'Sanandamanandavane Vasantam Anandakandam Hatapapavrindaam,\nVaranasinatham Anathanatham Shri Vishwanatham Sharanam Prapadye.',
      ),
      LyricStanza(
        startTimeMs: 140000,
        devanagari:
            'हर हर शंभू शंभू शंभू शिव महादेवा ।\nशंभू शंभू शंभू शंभू शिव महादेवा ॥',
        transliteration:
            'Har Har Shambhu Shambhu Shambhu Shiva Mahadeva,\nShambhu Shambhu Shambhu Shambhu Shiva Mahadeva.',
      ),
      LyricStanza(
        startTimeMs: 168000,
        devanagari:
            'अवन्तिकायां विहितावतारं मुक्तिप्रदानाय च सज्जनानाम् ।\nअकालमृत्योः परिरक्षणार्थं वन्दे महाकालमहासुरेशम् ॥',
        transliteration:
            'Avantikaayam Vihitavataram Muktipradanaya Cha Sajjananam,\nAkalamrityoh Parirakshanartham Vande Mahakala Mahasuresham.',
      ),
      LyricStanza(
        startTimeMs: 212000,
        devanagari:
            'हर हर शंभू शंभू शंभू शिव महादेवा ।\nशंभू शंभू शंभू शंभू शिव महादेवा ॥',
        transliteration:
            'Har Har Shambhu Shambhu Shambhu Shiva Mahadeva,\nShambhu Shambhu Shambhu Shambhu Shiva Mahadeva.',
      ),
      LyricStanza(
        startTimeMs: 240000,
        devanagari:
            'नागेन्द्रहाराय त्रिलोचनाय भस्माङ्गरागाय महेश्वराय ।\nनित्याय शुद्धाय दिगम्बराय तस्मै नकाराय नमः शिवाय ॥',
        transliteration:
            'Nagendraharaya Trilochanaya Bhasmangaragaya Maheshwaraya,\nNityaya Shuddhaya Digambaraya Tasmai Nakaraya Namah Shivaya.',
      ),
      LyricStanza(
        startTimeMs: 285000,
        devanagari:
            'हर हर शंभू शंभू शंभू शिव महादेवा ।\nशंभू शंभू शंभू शंभू शिव महादेवा ॥',
        transliteration:
            'Har Har Shambhu Shambhu Shambhu Shiva Mahadeva,\nShambhu Shambhu Shambhu Shambhu Shiva Mahadeva.',
      ),
    ],
  ),

  // ─────────────────────────────────────────────────────────────────────────
  // 6. VITTHAL VITTHAL JAI HARI — Suresh Wadkar (Saanwla Vitthal)
  // Video: CXHHDS5yRKE (~7:58) — naam sankirtan only
  // ─────────────────────────────────────────────────────────────────────────
  AartiItem(
    id: 'bhajan_vitthal_vitthal',
    title: 'Vitthal Vitthal Jai Hari',
    titleHi: 'विट्ठल विट्ठल जय हरि',
    titleMr: 'विठ्ठल विठ्ठल जय हरी',
    deity: 'Lord Vitthal',
    deityHi: 'भगवान विट्ठल',
    deityMr: 'विठ्ठल माऊली',
    singer: 'Suresh Wadkar',
    tags: const ['Bhajan', 'Vitthal', 'Abhang', 'Kirtan'],
    youtubeVideoId: 'CXHHDS5yRKE',
    backupVideoIds: const ['Mz317YSIOiE'],
    durationText: '7:58',
    accentColorHex: '#8E24AA',
    deityEmoji: '🙏',
    aboutMr:
        'पंढरपूरच्या पांडुरंगाचे हे अमृततुल्य नामस्मरण महाराष्ट्रातील वारकरी परंपरेचे हृदय आहे. विठ्ठल नामाच्या गजराने चित्त प्रसन्न होते.',
    aboutHi:
        'पंढरपुर के भगवान विट्ठल (पांडुरंग) का यह मधुर कीर्तन और नामस्मरण संतों की पावन वाणी से मन को आनंदित करता है।',
    about:
        'Suresh Wadkar\'s Saanwla Vitthal naam sankirtan — Vitthal Vitthal Jai Hari — filling the heart with Pandharpur devotion.',
    lyrics: const [
      LyricStanza(
        startTimeMs: 0,
        devanagari: 'विठ्ठल विठ्ठल जय हरी विठ्ठल ।\nविठ्ठल विठ्ठल जय हरी विठ्ठल ॥',
        transliteration:
            'Vitthal Vitthal Jai Hari Vitthal,\nVitthal Vitthal Jai Hari Vitthal.',
      ),
      LyricStanza(
        startTimeMs: 0,
        devanagari: 'जय हरी विठ्ठल, जय हरी विठ्ठल ।\nविठ्ठल विठ्ठल जय हरी विठ्ठल ॥',
        transliteration:
            'Jai Hari Vitthal, Jai Hari Vitthal,\nVitthal Vitthal Jai Hari Vitthal.',
      ),
      LyricStanza(
        startTimeMs: 0,
        devanagari: 'विठ्ठल विठ्ठल विठ्ठल विठ्ठल ।\nजय हरी विठ्ठल, जय हरी विठ्ठल ॥',
        transliteration:
            'Vitthal Vitthal Vitthal Vitthal,\nJai Hari Vitthal, Jai Hari Vitthal.',
      ),
    ],
  ),

  // ─────────────────────────────────────────────────────────────────────────
  // 7. CHALO BULAWA AAYA HAI — Narendra Chanchal (Avtaar 1983)
  // Video: UIvpNrP4WQs (~7:25)
  // ─────────────────────────────────────────────────────────────────────────
  AartiItem(
    id: 'bhajan_chalo_bulawa_aaya_hai',
    title: 'Chalo Bulawa Aaya Hai',
    titleHi: 'चलो बुलावा आया है',
    titleMr: 'चलो बुलावा आया है',
    deity: 'Goddess Durga',
    deityHi: 'माँ दुर्गा / वैष्णो देवी',
    deityMr: 'दुर्गा माता',
    singer: 'Narendra Chanchal',
    tags: const ['Bhajan', 'Durga', 'Mata', 'Kirtan'],
    youtubeVideoId: 'UIvpNrP4WQs',
    backupVideoIds: const ['To-0P_cgvII', 'RWsFGsmbaeY'],
    durationText: '7:25',
    accentColorHex: '#C2185B',
    deityEmoji: '🌺',
    aboutMr:
        'माता वैष्णोदेवीचे अतिशय प्रसिद्ध व भावुक भजन. संकटात सापडलेल्या प्रत्येक भक्ताला आई जगदंबेचे प्रेम आणि आधार देणारे हे गीत आहे.',
    aboutHi:
        'माता वैष्णो देवी का यह अमर भजन हर भक्त के दिल में माँ के प्रति असीम श्रद्धा और विश्वास जगाता है। जय माता दी!',
    about:
        'The iconic Maa Vaishno Devi pilgrimage anthem by Narendra Chanchal from the film Avtaar (1983).',
    lyrics: const [
      LyricStanza(
        startTimeMs: 5000,
        devanagari:
            'माता जिनको याद करे, वो लोग निराले होते हैं ।\nमाता जिनका नाम पुकारे, किस्मत वाले होते हैं ॥',
        transliteration:
            'Mata Jinko Yaad Kare, Vo Log Nirale Hote Hain,\nMata Jinka Naam Pukare, Kismat Wale Hote Hain.',
      ),
      LyricStanza(
        startTimeMs: 35000,
        devanagari:
            'चलो बुलावा आया है, माता ने बुलाया है ।\nचलो बुलावा आया है, माता ने बुलाया है ॥',
        transliteration:
            'Chalo Bulawa Aaya Hai, Mata Ne Bulaya Hai,\nChalo Bulawa Aaya Hai, Mata Ne Bulaya Hai.',
      ),
      LyricStanza(
        startTimeMs: 70000,
        devanagari:
            'ऊँचे पर्वत पे रानी माँ ने दरबार लगाया है ।\nचलो बुलावा आया है, माता ने बुलाया है ॥',
        transliteration:
            'Unche Parvat Pe Rani Maa Ne Darbar Lagaya Hai,\nChalo Bulawa Aaya Hai, Mata Ne Bulaya Hai.',
      ),
      LyricStanza(
        startTimeMs: 110000,
        devanagari:
            'सारे जग में एक ठिकाना सारे ग़म के मारों का ।\nरास्ता देख रही है माता अपनी आँख के तारों का ॥',
        transliteration:
            'Saare Jag Mein Ek Thikana Saare Gham Ke Maaron Ka,\nRaasta Dekh Rahi Hai Mata Apni Aankh Ke Taaron Ka.',
      ),
      LyricStanza(
        startTimeMs: 160000,
        devanagari:
            'जय माता दी कहते जाओ, आने जाने वालों को ।\nचलते जाओ तुम मत देखो अपने पाँव के छालों को ॥',
        transliteration:
            'Jai Mata Di Kehte Jao, Aane Jaane Walon Ko,\nChalte Jao Tum Mat Dekho Apne Paon Ke Chhalon Ko.',
      ),
      LyricStanza(
        startTimeMs: 220000,
        devanagari:
            'वैष्णो देवी के मंदिर में लोग मुरादें पाते हैं ।\nरोते रोते आते हैं, हँसते हँसते जाते हैं ॥',
        transliteration:
            'Vaishno Devi Ke Mandir Mein Log Muraden Paate Hain,\nRote Rote Aate Hain, Hanste Hanste Jaate Hain.',
      ),
      LyricStanza(
        startTimeMs: 280000,
        devanagari:
            'प्रेम से बोलो जय माता दी, सारे बोलो जय माता दी ।\nवैष्णो रानी जय माता दी, अंबे कल्याणी जय माता दी ॥',
        transliteration:
            'Prem Se Bolo Jai Mata Di, Saare Bolo Jai Mata Di,\nVaishno Rani Jai Mata Di, Ambe Kalyani Jai Mata Di.',
      ),
      LyricStanza(
        startTimeMs: 340000,
        devanagari:
            'चलो बुलावा आया है, माता ने बुलाया है ।\nजय माता दी, जय माता दी ॥',
        transliteration:
            'Chalo Bulawa Aaya Hai, Mata Ne Bulaya Hai,\nJai Mata Di, Jai Mata Di.',
      ),
    ],
  ),

  // ─────────────────────────────────────────────────────────────────────────
  // 8. PRATHAM TULA VANDITO — Vasantrao Deshpande & Anuradha Paudwal
  // Video: NCIGW4ttJ5I (Ashtavinayak original)
  // ─────────────────────────────────────────────────────────────────────────
  AartiItem(
    id: 'bhajan_pratham_tula_vandito',
    title: 'Pratham Tula Vandito',
    titleHi: 'प्रथम तुला वंदितो',
    titleMr: 'प्रथम तुला वंदितो कृपाळा',
    deity: 'Lord Ganesha',
    deityHi: 'गणेश जी',
    deityMr: 'गणपती बाप्पा',
    singer: 'Vasantrao Deshpande',
    tags: const ['Bhajan', 'Ganesha', 'BhaktiGeet'],
    youtubeVideoId: 'NCIGW4ttJ5I',
    backupVideoIds: const ['SoYOiRBVRi8', 'uGPk5r4NC_Q'],
    durationText: '6:13',
    accentColorHex: '#E65100',
    deityEmoji: '🐘',
    aboutMr:
        'कोणत्याही शुभ कार्याच्या प्रारंभी विघ्नहर्त्या गजाननाची प्रथम पूजा केली जाते. हे भक्तिगीत गणेशाच्या चरणी लीन होण्याची प्रेरणा देते.',
    aboutHi:
        'भगवान श्री गणेश की स्तुति में गाया गया यह पारंपरिक व पावन भजन हर शुभ कार्य के आरंभ में विघ्नों के नाश हेतु गाया जाता है।',
    about:
        'The classic Ashtavinayak Marathi stavan — Pratham Tula Vandito — sung by Pandit Vasantrao Deshpande and Anuradha Paudwal.',
    lyrics: const [
      LyricStanza(
        startTimeMs: 8000,
        devanagari: 'प्रथम तुला वंदितो कृपाळा ।\nगजानना गणराया ॥',
        transliteration: 'Pratham Tula Vandito Kripala,\nGajanana Ganaraya.',
      ),
      LyricStanza(
        startTimeMs: 45000,
        devanagari:
            'विघ्नविनाशक, गुणीजन पालक, दुरित तिमिर हारका ।\nसुखकारक तू, दुःख विदारक, तूच तुझ्या सारखा ॥',
        transliteration:
            'Vighnavinashak, Gunijan Palak, Durit Timir Haraka,\nSukhakarak Tu, Dukh Vidarak, Tu-ch Tujhya Saarakha.',
      ),
      LyricStanza(
        startTimeMs: 90000,
        devanagari: 'वक्रतुंड ब्रह्मांडनायका ।\nविनायका प्रभुराया ॥',
        transliteration: 'Vakratunda Brahmandanayaka,\nVinayaka Prabhuraya.',
      ),
      LyricStanza(
        startTimeMs: 130000,
        devanagari:
            'सिद्धिविनायक तूच अनंता, शिवात्मजा मंगला ।\nसिंदूरवदना, विद्याधीशा, गणाधिपा वत्सला ॥',
        transliteration:
            'Siddhivinayak Tu-ch Ananta, Shivatmaja Mangala,\nSindoorvadana, Vidyadhisha, Ganadhipa Vatsala.',
      ),
      LyricStanza(
        startTimeMs: 180000,
        devanagari: 'तूच ईश्वरा सहाय्य करावे ।\nहा भवसिंधू तराया ॥',
        transliteration:
            'Tu-ch Ishwara Sahayya Karaave,\nHa Bhavasindhu Taraya.',
      ),
      LyricStanza(
        startTimeMs: 230000,
        devanagari:
            'गजवदना तव रूप मनोहर, शुक्लांबर शिवसुता ।\nचिंतामणी तू अष्टविनायक, सकळांची देवता ॥',
        transliteration:
            'Gajavadana Tav Roop Manohar, Shuklambar Shivasuta,\nChintamani Tu Ashtavinayak, Sakalanchi Devata.',
      ),
      LyricStanza(
        startTimeMs: 290000,
        devanagari: 'ऋद्धी-सिद्धीच्या वरा दयाळा ।\nदेई कृपेची छाया ॥',
        transliteration:
            'Riddhi-Siddhichya Vara Dayala,\nDei Kripechi Chhaya.',
      ),
    ],
  ),

  // ─────────────────────────────────────────────────────────────────────────
  // 9. MANGAL BHAVAN AMANGAL HARI — Ravindra Jain (Geet Gaata Chal)
  // Video: 917H0ZSIkUs
  // ─────────────────────────────────────────────────────────────────────────
  AartiItem(
    id: 'bhajan_mangal_bhavan',
    title: 'Mangal Bhavan Amangal Hari',
    titleHi: 'मंगल भवन अमंगल हारी',
    titleMr: 'मंगल भवन अमंगल हारी',
    deity: 'Lord Rama',
    deityHi: 'श्री राम',
    deityMr: 'प्रभू श्रीराम',
    singer: 'Ravindra Jain',
    tags: const ['Bhajan', 'Ram', 'Chaupai'],
    youtubeVideoId: '917H0ZSIkUs',
    backupVideoIds: const ['9RnE7iuoWXo', 'A7SDFx1Rw0g'],
    durationText: '5:50',
    accentColorHex: '#D84315',
    deityEmoji: '🏹',
    aboutMr:
        'श्रीरामचरितमानसातील अतिशय पवित्र चौपाया. घरात व जीवनात मंगल, समृद्धी आणि शांती आणण्यासाठी दररोज याचे श्रवण व पठण केले जाते.',
    aboutHi:
        'रामचरितमानस की यह दिव्य चौपाई हर अमंगल को दूर कर जीवन में शुभता और सुख-शांति का संचार करती है।',
    about:
        'Ravindra Jain\'s immortal Geet Gaata Chal chaupais invoking Lord Rama\'s blessings with the Ram Siya Ram refrain.',
    lyrics: const [
      LyricStanza(
        startTimeMs: 5000,
        devanagari:
            'मंगल भवन अमंगल हारी ।\nद्रवहु सुदसरथ अजर बिहारी ॥\nराम सिया राम सिया राम जय जय राम ॥',
        transliteration:
            'Mangal Bhavan Amangal Haari,\nDravahu Sudasrath Ajar Bihaari.\nRam Siya Ram Siya Ram Jai Jai Ram.',
      ),
      LyricStanza(
        startTimeMs: 45000,
        devanagari:
            'होइहि सोइ जो राम रचि राखा ।\nको करि तर्क बढ़ावै साखा ॥\nराम सिया राम सिया राम जय जय राम ॥',
        transliteration:
            'Hoihi Soi Jo Ram Rachi Rakha,\nKo Kari Tark Badhavai Saakha.\nRam Siya Ram Siya Ram Jai Jai Ram.',
      ),
      LyricStanza(
        startTimeMs: 90000,
        devanagari:
            'धीरज धरम मित्र अरु नारी ।\nआपद् काल परखिए चारी ॥\nराम सिया राम सिया राम जय जय राम ॥',
        transliteration:
            'Dheeraj Dharam Mitra Aru Naari,\nAapad Kaal Parakhiye Chaari.\nRam Siya Ram Siya Ram Jai Jai Ram.',
      ),
      LyricStanza(
        startTimeMs: 135000,
        devanagari:
            'जाकी रही भावना जैसी ।\nप्रभु मूरत देखी तिन तैसी ॥\nराम सिया राम सिया राम जय जय राम ॥',
        transliteration:
            'Jaaki Rahi Bhavna Jaisi,\nPrabhu Moorat Dekhi Tin Taisi.\nRam Siya Ram Siya Ram Jai Jai Ram.',
      ),
      LyricStanza(
        startTimeMs: 180000,
        devanagari:
            'रघुकुल रीत सदा चली आई ।\nप्राण जाई पर वचन न जाई ॥\nराम सिया राम सिया राम जय जय राम ॥',
        transliteration:
            'Raghukul Reet Sada Chali Aayi,\nPraan Jaaye Par Vachan Na Jaayi.\nRam Siya Ram Siya Ram Jai Jai Ram.',
      ),
      LyricStanza(
        startTimeMs: 225000,
        devanagari:
            'हरि अनंत हरि कथा अनंता ।\nकहहि सुनहि बहुविधि सब संता ॥\nराम सिया राम सिया राम जय जय राम ॥',
        transliteration:
            'Hari Anant Hari Katha Ananta,\nKahahi Sunahi Bahuvidhi Sab Santa.\nRam Siya Ram Siya Ram Jai Jai Ram.',
      ),
    ],
  ),

  // ─────────────────────────────────────────────────────────────────────────
  // 10. RADHE RADHE GAATE REHNA — Acharya Gaurav Krishna Goswami
  // Video: V89gZ4saKiU (live) — NOT "Govind Gopal"
  // ─────────────────────────────────────────────────────────────────────────
  AartiItem(
    id: 'bhajan_radhe_radhe_govind',
    title: 'Radhe Radhe Gaate Rehna',
    titleHi: 'राधे राधे गाते रहना',
    titleMr: 'राधे राधे गाते रहना',
    deity: 'Lord Krishna',
    deityHi: 'श्री कृष्ण',
    deityMr: 'श्री कृष्ण',
    singer: 'Gaurav Krishna Goswami',
    tags: const ['Bhajan', 'Krishna', 'Kirtan'],
    youtubeVideoId: 'V89gZ4saKiU',
    backupVideoIds: const ['uBaDenookxY', 'J3cf85W8jc8'],
    durationText: '6:10',
    accentColorHex: '#1976D2',
    deityEmoji: '🦚',
    aboutMr:
        'वृंदावन धाम आणि श्री राधा-कृष्णाच्या प्रेमरंगात रंगवून टाकणारे हे अत्यंत मधुर संकीर्तन आहे. याच्या श्रवणाने मन भक्तीत डुंबून जाते.',
    aboutHi:
        'श्री धाम वृंदावन की पावन रज और राधा रानी के अनन्य प्रेम का रस बरसाने वाला अत्यंत मधुर संकीर्तन।',
    about:
        'Acharya Gaurav Krishna Goswami\'s beloved Vrindavan kirtan — Radhe Radhe Gaate Rehna, Jaldi Jaldi Vrindavan Aate Rehna.',
    lyrics: const [
      LyricStanza(
        startTimeMs: 5000,
        devanagari:
            'राधे राधे गाते रहना ।\nजल्दी जल्दी वृन्दावन आते रहना ॥',
        transliteration:
            'Radhe Radhe Gaate Rehna,\nJaldi Jaldi Vrindavan Aate Rehna.',
      ),
      LyricStanza(
        startTimeMs: 45000,
        devanagari:
            'वृन्दावन आके तेरे भाग खुल जायेंगे ।\nयमुना नहा के सारे पाप धुल जायेंगे ॥\nबार बार यमुना नहाते रहना ॥',
        transliteration:
            'Vrindavan Aake Tere Bhaag Khul Jayenge,\nYamuna Naha Ke Saare Paap Dhul Jayenge.\nBaar Baar Yamuna Nahate Rehna.',
      ),
      LyricStanza(
        startTimeMs: 100000,
        devanagari:
            'चैन भी मिलेगा, आराम भी मिलेगा ।\nराधा की कृपा से तुम्हें श्याम भी मिलेंगे ॥\nदोनों को हृदय में बसाते रहना ॥',
        transliteration:
            'Chain Bhi Milega, Aaram Bhi Milega,\nRadha Ki Kripa Se Tumhe Shyam Bhi Milenge.\nDonon Ko Hridaya Mein Basate Rehna.',
      ),
      LyricStanza(
        startTimeMs: 160000,
        devanagari:
            'एक बार आके जरा दर्शन तो कर लो ।\nबिहारी जी की छवि को आँखों में भर लो ॥\nचरणों में शीश नवाते रहना ॥',
        transliteration:
            'Ek Baar Aake Zara Darshan To Kar Lo,\nBihari Ji Ki Chhavi Ko Aankhon Mein Bhar Lo.\nCharanon Mein Sheesh Navate Rehna.',
      ),
      LyricStanza(
        startTimeMs: 220000,
        devanagari:
            'कृष्ण का हृदय है राधा रानी ।\nऔर राधा का हृदय है ये ब्रज भूमि ॥\nब्रज रज शीश चढ़ाते रहना ॥',
        transliteration:
            'Krishna Ka Hridaya Hai Radha Rani,\nAur Radha Ka Hridaya Hai Ye Braj Bhoomi.\nBraj Raj Sheesh Chadhaate Rehna.',
      ),
      LyricStanza(
        startTimeMs: 280000,
        devanagari:
            'राधे राधे गाते रहना ।\nजल्दी जल्दी वृन्दावन आते रहना ॥',
        transliteration:
            'Radhe Radhe Gaate Rehna,\nJaldi Jaldi Vrindavan Aate Rehna.',
      ),
    ],
  ),

  // ─────────────────────────────────────────────────────────────────────────
  // 11. OM NAMAH SHIVAYA DHUN — Anuradha Paudwal (T-Series)
  // Video: C9dwTF1cTto — mantra dhun (no jyotirlinga verses)
  // ─────────────────────────────────────────────────────────────────────────
  AartiItem(
    id: 'bhajan_om_namah_shivaya_dhun',
    title: 'Om Namah Shivaya Dhun',
    titleHi: 'ॐ नमः शिवाय धुन',
    titleMr: 'ॐ नमः शिवाय धुन',
    deity: 'Lord Shiva',
    deityHi: 'भगवान शिव',
    deityMr: 'महादेव',
    singer: 'Anuradha Paudwal',
    tags: const ['Kirtan', 'Shiva', 'Dhun'],
    youtubeVideoId: 'C9dwTF1cTto',
    backupVideoIds: const ['ahyW7HFs7rc', '3FcBh45t9Vs'],
    durationText: '8:00',
    accentColorHex: '#283593',
    deityEmoji: '🔱',
    aboutMr:
        'पंचाक्षरी मंत्र "ॐ नमः शिवाय" ची शांत आणि ध्यान लावणारी धुन. मानसिक तणाव दूर करून अंतर्मुख होण्यासाठी ही धुन अत्यंत फलदायी ठरते.',
    aboutHi:
        'पंचाक्षर मंत्र "ॐ नमः शिवाय" की ध्यानमयी और मधुर धुन जो मन को शांत और एकाग्र कर शिवत्व का अनुभव कराती है।',
    about:
        'Anuradha Paudwal\'s peaceful Om Namah Shivaya dhun — a meditative loop of the sacred Panchakshari mantra.',
    lyrics: const [
      LyricStanza(
        startTimeMs: 10000,
        devanagari: 'ॐ नमः शिवाय, ॐ नमः शिवाय ।\nॐ नमः शिवाय, ॐ नमः शिवाय ॥',
        transliteration:
            'Om Namah Shivaya, Om Namah Shivaya,\nOm Namah Shivaya, Om Namah Shivaya.',
      ),
      LyricStanza(
        startTimeMs: 60000,
        devanagari: 'हर हर भोले नमः शिवाय ।\nॐ नमः शिवाय, ॐ नमः शिवाय ॥',
        transliteration:
            'Har Har Bhole Namah Shivaya,\nOm Namah Shivaya, Om Namah Shivaya.',
      ),
      LyricStanza(
        startTimeMs: 120000,
        devanagari: 'ॐ नमः शिवाय, ॐ नमः शिवाय ।\nहर हर महादेव नमः शिवाय ॥',
        transliteration:
            'Om Namah Shivaya, Om Namah Shivaya,\nHar Har Mahadev Namah Shivaya.',
      ),
      LyricStanza(
        startTimeMs: 200000,
        devanagari: 'ॐ नमः शिवाय, ॐ नमः शिवाय ।\nॐ नमः शिवाय, ॐ नमः शिवाय ॥',
        transliteration:
            'Om Namah Shivaya, Om Namah Shivaya,\nOm Namah Shivaya, Om Namah Shivaya.',
      ),
      LyricStanza(
        startTimeMs: 300000,
        devanagari: 'हर हर भोले नमः शिवाय ।\nॐ नमः शिवाय, ॐ नमः शिवाय ॥',
        transliteration:
            'Har Har Bhole Namah Shivaya,\nOm Namah Shivaya, Om Namah Shivaya.',
      ),
      LyricStanza(
        startTimeMs: 400000,
        devanagari: 'ॐ नमः शिवाय, ॐ नमः शिवाय ।\nहर हर महादेव नमः शिवाय ॥',
        transliteration:
            'Om Namah Shivaya, Om Namah Shivaya,\nHar Har Mahadev Namah Shivaya.',
      ),
    ],
  ),

  // ─────────────────────────────────────────────────────────────────────────
  // 12. SHREE KRISHNA GOVIND HARE MURARI — Ravindra Jain
  // Video: YutkSde3F3k
  // ─────────────────────────────────────────────────────────────────────────
  AartiItem(
    id: 'bhajan_shree_krishna_govind',
    title: 'Shree Krishna Govind Hare Murari',
    titleHi: 'श्री कृष्ण गोविंद हरे मुरारी',
    titleMr: 'श्री कृष्ण गोविंद हरे मुरारी',
    deity: 'Lord Krishna',
    deityHi: 'श्री कृष्ण',
    deityMr: 'श्री कृष्ण',
    singer: 'Ravindra Jain',
    tags: const ['Bhajan', 'Krishna', 'Kirtan'],
    youtubeVideoId: 'YutkSde3F3k',
    backupVideoIds: const ['IfNr3leJEeI', '4X9kXnjLXmY'],
    durationText: '6:40',
    accentColorHex: '#0288D1',
    deityEmoji: '🦚',
    aboutMr:
        'भगवान श्रीकृष्णाच्या नावांचा जप करणारे हे भजन भक्ताला संपूर्ण समर्पणाची आणि संरक्षणाची अनुभूती देते.',
    aboutHi:
        'श्री कृष्ण गोविंद हरे मुरारी, हे नाथ नारायण वासुदेवा! संकट के समय प्रभु की शरण में जाने वाला परम पावन भजन।',
    about:
        'Ravindra Jain\'s classic Shri Krishna serial anthem — taking absolute refuge in Lord Krishna and Narayana.',
    lyrics: const [
      LyricStanza(
        startTimeMs: 8000,
        devanagari:
            'श्री कृष्ण गोविंद हरे मुरारी ।\nहे नाथ नारायण वासुदेवा ॥',
        transliteration:
            'Shree Krishna Govind Hare Murari,\nHe Nath Narayan Vasudeva.',
      ),
      LyricStanza(
        startTimeMs: 40000,
        devanagari:
            'पितु मात स्वामी सखा हमारे ।\nहे नाथ नारायण वासुदेवा ॥',
        transliteration:
            'Pitu Maat Swami Sakha Hamare,\nHe Nath Narayan Vasudeva.',
      ),
      LyricStanza(
        startTimeMs: 80000,
        devanagari:
            'बंदी गृह के तुम अवतारी ।\nकहीं जन्मे कहीं पले मुरारी ॥\nगोकुल में चमके मथुरा के तारे ॥',
        transliteration:
            'Bandi Grih Ke Tum Avatari,\nKahin Janme Kahin Pale Murari.\nGokul Mein Chamke Mathura Ke Taare.',
      ),
      LyricStanza(
        startTimeMs: 140000,
        devanagari:
            'श्री कृष्ण गोविंद हरे मुरारी ।\nहे नाथ नारायण वासुदेवा ॥',
        transliteration:
            'Shree Krishna Govind Hare Murari,\nHe Nath Narayan Vasudeva.',
      ),
      LyricStanza(
        startTimeMs: 180000,
        devanagari:
            'अधर पे बंशी हृदय में राधे ।\nबँट गए दोनों में आधे आधे ॥\nवहीं गए जहाँ गए पुकारे ॥',
        transliteration:
            'Adhar Pe Banshi Hridaya Mein Radhe,\nBat Gaye Donon Mein Aadhe Aadhe.\nWahin Gaye Jahan Gaye Pukare.',
      ),
      LyricStanza(
        startTimeMs: 250000,
        devanagari:
            'गीता में उपदेश सुनाया ।\nधर्म युद्ध को धर्म बताया ॥\nहे नाथ नारायण वासुदेवा ॥',
        transliteration:
            'Geeta Mein Upadesh Sunaya,\nDharm Yuddh Ko Dharm Bataya.\nHe Nath Narayan Vasudeva.',
      ),
      LyricStanza(
        startTimeMs: 320000,
        devanagari:
            'श्री कृष्ण गोविंद हरे मुरारी ।\nहे नाथ नारायण वासुदेवा ॥',
        transliteration:
            'Shree Krishna Govind Hare Murari,\nHe Nath Narayan Vasudeva.',
      ),
    ],
  ),

  // ═══════════════════════════════════════════════════════════════════════════
  // STOTRAS (स्तोत्रे)
  // ═══════════════════════════════════════════════════════════════════════════
  AartiItem(
    id: 'stotra_hanuman_chalisa',
    title: 'Hanuman Chalisa',
    titleHi: 'हनुमान चालीसा',
    titleMr: 'श्री हनुमान चालीसा',
    deity: 'Lord Hanuman',
    deityHi: 'हनुमान जी',
    deityMr: 'हनुमान',
    singer: 'Hariharan',
    tags: const ['Popular', 'Stotra', 'Chalisa', 'Hanuman'],
    youtubeVideoId: 'AETFvQonfV8',
    backupVideoIds: const ['LUx8wlA_dk8'],
    durationText: '9:48',
    accentColorHex: '#FF6F00',
    deityEmoji: '🙏',
    aboutMr: 'श्री हनुमान चालीसा ही गोस्वामी तुलसीदास यांनी रचलेली भगवान हनुमानाची स्तुती आहे. याचे पठण केल्याने भय आणि संकटे दूर होतात.',
    aboutHi: 'श्री हनुमान चालीसा गोस्वामी तुलसीदास जी द्वारा रचित भगवान हनुमान की दिव्य स्तुति है। इसके पाठ से सभी भय और संकट दूर होते हैं।',
    about: 'Shree Hanuman Chalisa is a sacred 40-verse hymn praising Lord Hanuman composed by Goswami Tulsidas.',
    lyrics: const [
      LyricStanza(
        startTimeMs: 2090,
        devanagari: 'श्रीगुरु चरन सरोज रज निज मनु मुकुरु सुधारि ।\nबरनऊं रघुबर बिमल जसु जो दायकु फल चारि ॥',
        transliteration: 'Shri Guru Charan Saroj Raj Nij Manu Mukuru Sudhari,\nBaranau Raghuvar Bimal Jasu Jo Dayaku Phal Chari.',
      ),
      LyricStanza(
        startTimeMs: 24230,
        devanagari: 'बुद्धिहीन तनु जानिके सुमिरौं पवन कुमार ।\nबल बुद्धि बिद्या देहु मोहिं हरहु कलेस बिकार ॥',
        transliteration: 'Buddhiheen Tanu Janike Sumirau Pavan Kumar,\nBal Buddhi Vidya Dehu Mohin Harahu Kalesh Bikaar.',
      ),
      LyricStanza(
        startTimeMs: 55610,
        devanagari: 'जय हनुमान ज्ञान गुन सागर ।\nजय कपीस तिहुं लोक उजागर ॥',
        transliteration: 'Jai Hanuman Gyan Gun Sagar,\nJai Kapis Tihun Lok Ujagar.',
      ),
      LyricStanza(
        startTimeMs: 66490,
        devanagari: 'रामदूत अतुलित बल धामा ।\nअंजनि पुत्र पवनसुत नामा ॥',
        transliteration: 'Ram Doot Atulit Bal Dhama,\nAnjani Putra Pavan Sut Nama.',
      ),
      LyricStanza(
        startTimeMs: 82690,
        devanagari: 'महाबीर बिक्रम बजरंगी ।\nकुमति निवार सुमति के संगी ॥',
        transliteration: 'Mahabir Bikram Bajrangi,\nKumati Nivar Sumati Ke Sangi.',
      ),
      LyricStanza(
        startTimeMs: 110000,
        devanagari: 'संकट कटै मिटै सब पीरा ।\nजो सुमिरै हनुमत बलबीरा ॥',
        transliteration: 'Sankat Kate Mite Sab Peera,\nJo Sumirai Hanumat Balbira.',
      ),
      LyricStanza(
        startTimeMs: 140000,
        devanagari: 'पवनतनय संकट हरन मंगल मूरति रूप ।\nराम लखन सीता सहित हृदय बसहु सुर भूप ॥',
        transliteration: 'Pavan Tanay Sankat Haran Mangal Murati Roop,\nRam Lakhan Sita Sahit Hridaya Basahu Sur Bhoop.',
      ),
    ],
  ),

  AartiItem(
    id: 'stotra_ram_raksha',
    title: 'Shri Ram Raksha Stotra',
    titleHi: 'श्री रामरक्षा स्तोत्र',
    titleMr: 'श्री रामरक्षा स्तोत्र',
    deity: 'Lord Rama',
    deityHi: 'श्री राम',
    deityMr: 'श्री राम',
    singer: 'Sadhana Sargam',
    tags: const ['Popular', 'Stotra', 'Ram'],
    youtubeVideoId: 'F7Z7rC6sX1U',
    backupVideoIds: const ['7-nUvA7mK2k'],
    durationText: '8:45',
    accentColorHex: '#D84315',
    deityEmoji: '🏹',
    aboutMr: 'श्री रामरक्षा स्तोत्र हे बुधकौशिक ऋषींनी रचलेले भगवान श्रीरामाचे अत्यंत प्रभावी आणि संरक्षक स्तोत्र आहे.',
    aboutHi: 'श्री रामरक्षा स्तोत्र बुधकौशिक ऋषि द्वारा रचित भगवान श्री राम का परम रक्षाकारी स्तोत्र है।',
    about: 'Shri Ram Raksha Stotra is an auspicious Sanskrit hymn of divine protection dedicated to Lord Rama.',
    lyrics: const [
      LyricStanza(
        startTimeMs: 5000,
        devanagari: 'चरितं रघुनाथस्य शतकोटि प्रविस्तरम् ।\nएकैकमक्षरं पुंसां महापातकनाशनम् ॥',
        transliteration: 'Charitam Raghunathasya Shatakoti Pravistaram,\nEkaikam Aksharam Pumsam Mahapataka Nashanam.',
      ),
      LyricStanza(
        startTimeMs: 35000,
        devanagari: 'ध्यात्वा नीलोत्पलश्यामं रामं राजीवलोचनम् ।\nजानकीलक्ष्मणोपेतं जटामुकुटमण्डितम् ॥',
        transliteration: 'Dhyatva Nilotpala Shyamam Ramam Rajiva Lochanam,\nJanaki Lakshmanopetam Jata Mukuta Manditam.',
      ),
      LyricStanza(
        startTimeMs: 65000,
        devanagari: 'सासितूणधनुर्बाणपाणिं नक्तंचरान्तकम् ।\nस्वलीलया जगत्त्रातुमाविर्भूतमजं विभुम् ॥',
        transliteration: 'Sasituna Dhanurbana Panim Naktancharantakam,\nSvalilaya Jagat Tratum Avirbhootam Ajam Vibhum.',
      ),
      LyricStanza(
        startTimeMs: 95000,
        devanagari: 'रामरक्षां पठेत्प्राज्ञः पापघ्नीं सर्वकामदाम् ।\nशिरो मे राघवः पातु भालं दशरथात्मजः ॥',
        transliteration: 'Ramaraksham Pathet Prajnah Papaghneem Sarvakamadam,\nShiro Me Raghavah Paatu Bhaalam Dasharathatmajah.',
      ),
      LyricStanza(
        startTimeMs: 140000,
        devanagari: 'आपदामपहर्तारं दातारं सर्वसंपदाम् ।\nलोकाभिरामं श्रीरामं भूयो भूयो नमाम्यहम् ॥',
        transliteration: 'Aapadaam Apahartaaram Daataaram Sarvasampadaam,\nLokabhiraamam Shreeraamam Bhooyo Bhooyo Namaamyaham.',
      ),
    ],
  ),

  AartiItem(
    id: 'stotra_maruti',
    title: 'Shri Maruti Stotra',
    titleHi: 'श्री मारुति स्तोत्र',
    titleMr: 'श्री मारुती स्तोत्र',
    deity: 'Lord Hanuman',
    deityHi: 'हनुमान जी',
    deityMr: 'हनुमान',
    singer: 'Suresh Wadkar',
    tags: const ['Popular', 'Stotra', 'Hanuman'],
    youtubeVideoId: 'xP80n0s9iE0',
    backupVideoIds: const ['jO5K6l9_sB4'],
    durationText: '4:20',
    accentColorHex: '#E65100',
    deityEmoji: '🚩',
    aboutMr: 'समर्थ रामदास स्वामी विरचित भीमरूपी मारुती स्तोत्र. हे स्तोत्र शक्ती, तेज आणि आरोग्य प्रदान करते.',
    aboutHi: 'समर्थ रामदास स्वामी द्वारा रचित भीमरूपी मारुति स्तोत्र बल, बुद्धि और आरोग्य प्रदान करता है।',
    about: 'Maruti Stotra is a renowned hymn composed by Samarth Ramdas Swami for health, courage, and fearlessness.',
    lyrics: const [
      LyricStanza(
        startTimeMs: 5000,
        devanagari: 'भीमरूपी महारुद्रा वज्र हनुमान मारुती ।\nवनारी अंजनीसूता रामदूता प्रभंजना ॥',
        transliteration: 'Bheemaroopi Maharudra Vajra Hanuman Maruti,\nVanaari Anjanisuta Ramduta Prabhanjana.',
      ),
      LyricStanza(
        startTimeMs: 30000,
        devanagari: 'महाबळी प्राणदाता सकळां उठवी बळें ।\nसौख्यकारी दुःखहारी दूत वैष्णव गायका ॥',
        transliteration: 'Mahabali Pranadata Sakalan Uthavee Bale,\nSaukhyakari Dukhhari Doot Vaishnav Gayaka.',
      ),
      LyricStanza(
        startTimeMs: 58000,
        devanagari: 'दीननाथा दयावंता सर्व संकटनिवारणा ।\nरामचंद्रकृपापात्रा दास मारुति नम्र गा ॥',
        transliteration: 'Deenanatha Dayavanta Sarva Sankatanivarana,\nRamchandrakrupapatra Das Maruti Namra Ga.',
      ),
    ],
  ),

  AartiItem(
    id: 'stotra_shiv_tandav',
    title: 'Shiv Tandav Stotra',
    titleHi: 'शिव तांडव स्तोत्र',
    titleMr: 'शिव तांडव स्तोत्र',
    deity: 'Lord Shiva',
    deityHi: 'शिव जी',
    deityMr: 'महादेव',
    singer: 'Shankar Mahadevan',
    tags: const ['Popular', 'Stotra', 'Shiva'],
    youtubeVideoId: '8q0_vH8o7x4',
    backupVideoIds: const ['hMBKmQ3KVmo'],
    durationText: '9:15',
    accentColorHex: '#1565C0',
    deityEmoji: '🔱',
    aboutMr: 'लंकेचा राजा रावण याने रचलेले शिव तांडव स्तोत्र भगवान शिवाच्या शक्ती, सौंदर्य आणि तांडव नृत्याची अद्वितीय स्तुती करते.',
    aboutHi: 'रावण द्वारा रचित शिव तांडव स्तोत्र भगवान शिव की शक्ति और आनंद तांडव का अद्भुत वर्णन करता है।',
    about: 'Shiv Tandav Stotra is a powerful hymn praising Lord Shiva composed by Ravana.',
    lyrics: const [
      LyricStanza(
        startTimeMs: 8000,
        devanagari: 'जटाटवीगलज्जलप्रवाहपावितस्थले\nगलेऽवलम्ब्य लम्बितां भुजङ्गतुङ्गमालिकाम् ।\nडमड्डमड्डमड्डमन्निनादवड्डमर्वयं\nचकार चण्डताण्डवं तनोतु नः शिवः शिवम् ॥',
        transliteration: 'Jatatavigalajjala Pravahapavitasthale\nGaleavalambya Lambitam Bhujangatungamalikam,\nDamad Damad Damad Daman Ninadavaddamarvayam\nChakara Chandatandavam Tanotu Nah Shivah Shivam.',
      ),
      LyricStanza(
        startTimeMs: 40000,
        devanagari: 'जटाकटाहसम्भ्रमभ्रमन्निलिम्पनिर्झरी-\nविलोलवीचिवल्लरीविराजमानमूर्धनि ।\nधधद्धधद्धधज्ज्वलल्ललाटपट्टपावके\nकिशोरचन्द्रशेखरे रतिः प्रतिक्षणं मम ॥',
        transliteration: 'Jatakatahasambhrama Bhramannilimpanirjhari\nVilolavichivallari Virajamanamurdhani,\nDhagaddhagaddhagajjvalal Lalatapattapavake\nKishorachandrashekhare Ratih Pratikshenam Mama.',
      ),
    ],
  ),

  AartiItem(
    id: 'stotra_ganesh_atharvashirsha',
    title: 'Ganpati Atharvashirsha',
    titleHi: 'गणपति अथर्वशीर्ष',
    titleMr: 'श्री गणपती अथर्वशीर्ष',
    deity: 'Lord Ganesha',
    deityHi: 'गणेश जी',
    deityMr: 'श्री गणेश',
    singer: 'Anuradha Paudwal',
    tags: const ['Popular', 'Stotra', 'Ganesha'],
    youtubeVideoId: 'D-5e4iH6L6E',
    backupVideoIds: const ['WJ8uE2e0W1c'],
    durationText: '6:30',
    accentColorHex: '#F57C00',
    deityEmoji: '🐘',
    aboutMr: 'गणपती अथर्वशीर्ष हे अथर्ववेदातील अत्यंत पवित्र उपनिषद असून श्री गणेशाच्या परब्रह्म स्वरूपाचे वर्णन करते.',
    aboutHi: 'गणपति अथर्वशीर्ष अथर्ववेद का अत्यंत पावन उपनिषद है जो श्री गणेश के ब्रह्म स्वरूप का गान करता है।',
    about: 'Ganpati Atharvashirsha is a revered Vedic text invoking Lord Ganesha as the supreme reality.',
    lyrics: const [
      LyricStanza(
        startTimeMs: 6000,
        devanagari: 'ॐ नमस्ते गणपतये ।\nत्वमेव प्रत्यक्षं तत्त्वमसि ।\nत्वमेव केवलं कर्ताऽसि ।\nत्वमेव केवलं धर्ताऽसि ।\nत्वमेव केवलं हर्ताऽसि ॥',
        transliteration: 'Om Namaste Ganapataye,\nTvam Eva Pratyaksham Tattvam Asi,\nTvam Eva Kevalam Karta Asi,\nTvam Eva Kevalam Dharta Asi,\nTvam Eva Kevalam Harta Asi.',
      ),
      LyricStanza(
        startTimeMs: 45000,
        devanagari: 'त्वमेव सर्वं खल्विदं ब्रह्मासि ।\nत्वं साक्षादात्माऽसि नित्यम् ॥\nऋतं वच्मि । सत्यं वच्मि ॥',
        transliteration: 'Tvam Eva Sarvam Khalvidam Brahmasi,\nTvam Sakshad Atma Asi Nityam.\nRitam Vachmi, Satyam Vachmi.',
      ),
    ],
  ),

  AartiItem(
    id: 'stotra_mahalakshmi_ashtakam',
    title: 'Shri Mahalakshmi Ashtakam',
    titleHi: 'श्री महालक्ष्मी अष्टकम',
    titleMr: 'श्री महालक्ष्मी अष्टकम्',
    deity: 'Goddess Lakshmi',
    deityHi: 'लक्ष्मी जी',
    deityMr: 'महालक्ष्मी',
    singer: 'Devi Chitralekha',
    tags: const ['Stotra', 'Lakshmi'],
    youtubeVideoId: 'mC6_N9zQ45w',
    backupVideoIds: const ['YF_U_u6V9Vw'],
    durationText: '4:50',
    accentColorHex: '#C2185B',
    deityEmoji: '🌸',
    aboutMr: 'देवराज इंद्राने रचलेले महालक्ष्मी अष्टकम् सुख, समृद्धी आणि ऐश्वर्य देणारे आहे.',
    aboutHi: 'इंद्र देव द्वारा रचित महालक्ष्मी अष्टकम सुख और समृद्धि प्रदान करने वाला पावन स्तोत्र है।',
    about: 'Mahalakshmi Ashtakam is an auspicious hymn of eight verses praising Goddess Lakshmi composed by Lord Indra.',
    lyrics: const [
      LyricStanza(
        startTimeMs: 8000,
        devanagari: 'नमस्तेऽस्तु महामाये श्रीपीठे सुरपूजिते ।\nशङ्खचक्रगदाहस्ते महालक्ष्मि नमोऽस्तु ते ॥',
        transliteration: 'Namastestu Mahamaye Shri Peethe Sura Poojite,\nShankha Chakra Gada Haste Mahalakshmi Namostu Te.',
      ),
      LyricStanza(
        startTimeMs: 38000,
        devanagari: 'नमस्ते गरुडारूढे कोलासुरभयङ्करि ।\nसर्वपापहरे देवि महालक्ष्मि नमोऽस्तु ते ॥',
        transliteration: 'Namaste Garudarudhe Kolasura Bhayankari,\nSarva Papa Hare Devi Mahalakshmi Namostu Te.',
      ),
    ],
  ),

  AartiItem(
    id: 'stotra_sankat_nashan',
    title: 'Sankat Nashan Ganesh Stotra',
    titleHi: 'संकटनाशन गणेश स्तोत्र',
    titleMr: 'संकटनाशन गणेश स्तोत्र',
    deity: 'Lord Ganesha',
    deityHi: 'गणेश जी',
    deityMr: 'श्री गणेश',
    singer: 'Suresh Wadkar',
    tags: const ['Stotra', 'Ganesha'],
    youtubeVideoId: 'W34zT5N81vU',
    backupVideoIds: const ['3yO4B20zXyE'],
    durationText: '3:50',
    accentColorHex: '#E65100',
    deityEmoji: '🙏',
    aboutMr: 'नारद पुराणातील संकटनाशन गणेश स्तोत्र सर्व संकटांचे निवारण करणारे मानले जाते.',
    aboutHi: 'नारद पुराण से उद्धृत संकटनाशन गणेश स्तोत्र समस्त संकटों का नाश करता है।',
    about: 'Sankat Nashan Ganesh Stotra removes obstacles and brings peace and success.',
    lyrics: const [
      LyricStanza(
        startTimeMs: 5000,
        devanagari: 'प्रणम्य शिरसा देवं गौरीपुत्रं विनायकम् ।\nभक्तावासं स्मरेन्नित्यमायुःकामार्थसिद्धये ॥',
        transliteration: 'Pranamya Shirasa Devam Gauriputram Vinayakam,\nBhaktavasam Smaren Nityam Ayuh Kamartha Siddhaye.',
      ),
      LyricStanza(
        startTimeMs: 32000,
        devanagari: 'प्रथमं वक्रतुण्डं च एकदन्तं द्वितीयकम् ।\nतृतीयं कृष्णपिङ्गाक्षं गजवक्त्रं चतुर्थकम् ॥',
        transliteration: 'Prathamam Vakratundam Cha Ekadantam Dvitiyakam,\nTritiyam Krishna Pingaksham Gajavaktram Chaturthakam.',
      ),
    ],
  ),

  // ═══════════════════════════════════════════════════════════════════════════
  // MANTRAS (मंत्र)
  // ═══════════════════════════════════════════════════════════════════════════
  AartiItem(
    id: 'mantra_gayatri',
    title: 'Gayatri Mantra',
    titleHi: 'गायत्री मंत्र',
    titleMr: 'गायत्री मंत्र',
    deity: 'Gayatri',
    deityHi: 'गायत्री माँ',
    deityMr: 'गायत्री',
    singer: 'Anuradha Paudwal',
    tags: const ['Popular', 'Mantra', 'Gayatri'],
    youtubeVideoId: 'Z_r6i4rE4kE',
    backupVideoIds: const ['D27m35j62yA'],
    durationText: '21:00',
    accentColorHex: '#FBC02D',
    deityEmoji: '☀️',
    aboutMr: 'वेदांचे सार असलेला गायत्री मंत्र बुद्धीला प्रकाशमान करणारा आणि आत्मिक शांती देणारा महामंत्र आहे.',
    aboutHi: 'गायत्री मंत्र समस्त वेदों का सार है जो बुद्धि को सत्य के मार्ग पर अग्रसर करता है।',
    about: 'Gayatri Mantra is the sacred Vedic prayer for spiritual illumination and wisdom.',
    lyrics: const [
      LyricStanza(
        startTimeMs: 4000,
        devanagari: 'ॐ भूर्भुवः स्वः ।\nतत्सवितुर्वरेण्यं भर्गो देवस्य धीमहि ।\nधियो यो नः प्रचोदयात् ॥',
        transliteration: 'Om Bhur Bhuvah Svah,\nTat Savitur Varenyam Bhargo Devasya Dhimahi,\nDhiyo Yo Nah Prachodayat.',
      ),
    ],
  ),

  AartiItem(
    id: 'mantra_mahamrityunjaya',
    title: 'Mahamrityunjaya Mantra',
    titleHi: 'महामृत्युंजय मंत्र',
    titleMr: 'महामृत्युंजय मंत्र',
    deity: 'Lord Shiva',
    deityHi: 'शिव जी',
    deityMr: 'महादेव',
    singer: 'Shankar Sahney',
    tags: const ['Popular', 'Mantra', 'Shiva'],
    youtubeVideoId: 'Kz1Q2-x7Lw8',
    backupVideoIds: const ['s6w8R3ZfE0g'],
    durationText: '18:40',
    accentColorHex: '#1565C0',
    deityEmoji: '🔱',
    aboutMr: 'ऋग्वेदातील महामृत्युंजय मंत्र आरोग्य, दीर्घायुष्य आणि मोक्ष प्रदान करणारा शक्तिशाली मंत्र आहे.',
    aboutHi: 'महामृत्युंजय मंत्र अकाल मृत्यु के भय को मिटाने और आरोग्य प्रदान करने वाला महामंत्र है।',
    about: 'Mahamrityunjaya Mantra is the great death-conquering mantra from the Rigveda.',
    lyrics: const [
      LyricStanza(
        startTimeMs: 5000,
        devanagari: 'ॐ त्र्यम्बकं यजामहे सुगन्धिं पुष्टिवर्धनम् ।\nउर्वारुकमिव बन्धनान् मृत्योर्मुक्षीय माऽमृतात् ॥',
        transliteration: 'Om Tryambakam Yajamahe Sugandhim Pushtivardhanam,\nUrvarukamiva Bandhanan Mrityor Mukshiya Maamritat.',
      ),
    ],
  ),

  AartiItem(
    id: 'mantra_ganesh',
    title: 'Om Gam Ganapataye Namah',
    titleHi: 'ॐ गं गणपतये नमः',
    titleMr: 'ॐ गं गणपतये नमः',
    deity: 'Lord Ganesha',
    deityHi: 'गणेश जी',
    deityMr: 'श्री गणेश',
    singer: 'Suresh Wadkar',
    tags: const ['Popular', 'Mantra', 'Ganesha'],
    youtubeVideoId: 'V9P5m5n7R6s',
    backupVideoIds: const ['b215lY8e9wI'],
    durationText: '11:15',
    accentColorHex: '#EF6C00',
    deityEmoji: '🐘',
    aboutMr: 'श्री गणेशाचा बीजमंत्र नवीन कार्याची सुरुवात निर्विघ्नपणे करण्यासाठी जपला जातो.',
    aboutHi: 'श्री गणेश का मूल बीज मंत्र समस्त विघ्नों को हरने वाला है।',
    about: 'Om Gam Ganapataye Namah is the primary Ganesha seed mantra for removing obstacles.',
    lyrics: const [
      LyricStanza(
        startTimeMs: 4000,
        devanagari: 'ॐ गं गणपतये नमः ।\nॐ गं गणपतये नमः ।\nॐ गं गणपतये नमः ॥',
        transliteration: 'Om Gam Ganapataye Namah,\nOm Gam Ganapataye Namah,\nOm Gam Ganapataye Namah.',
      ),
    ],
  ),

  AartiItem(
    id: 'mantra_om_namah_shivaya',
    title: 'Om Namah Shivaya',
    titleHi: 'ॐ नमः शिवाय',
    titleMr: 'ॐ नमः शिवाय',
    deity: 'Lord Shiva',
    deityHi: 'शिव जी',
    deityMr: 'महादेव',
    singer: 'Anuradha Paudwal',
    tags: const ['Popular', 'Mantra', 'Shiva'],
    youtubeVideoId: 'M7d2Q3j0P6w',
    backupVideoIds: const ['3p2_uXf7YqQ'],
    durationText: '15:30',
    accentColorHex: '#0288D1',
    deityEmoji: '🔱',
    aboutMr: 'भगवान शिवाचा षडाक्षर महामंत्र जो मनाला ध्यानस्थ आणि शांत करतो.',
    aboutHi: 'शिव पंचाक्षर मंत्र आत्मा को शांति और मुक्ति प्रदान करता है।',
    about: 'Om Namah Shivaya is the supreme five-syllable mantra honoring Lord Shiva.',
    lyrics: const [
      LyricStanza(
        startTimeMs: 4000,
        devanagari: 'ॐ नमः शिवाय ।\nॐ नमः शिवाय ।\nहर हर भोले नमः शिवाय ॥',
        transliteration: 'Om Namah Shivaya,\nOm Namah Shivaya,\nHar Har Bhole Namah Shivaya.',
      ),
    ],
  ),

  AartiItem(
    id: 'mantra_swami_samarth',
    title: 'Swami Samarth Tarak Mantra',
    titleHi: 'स्वामी समर्थ तारक मंत्र',
    titleMr: 'श्री स्वामी समर्थ तारक मंत्र',
    deity: 'Swami Samarth',
    deityHi: 'स्वामी समर्थ',
    deityMr: 'स्वामी समर्थ',
    singer: 'Anuradha Paudwal',
    tags: const ['Popular', 'Mantra', 'Swami Samarth'],
    youtubeVideoId: 'V186U5o-q-I',
    backupVideoIds: const ['r9B7w3K1a2s'],
    durationText: '6:12',
    accentColorHex: '#E65100',
    deityEmoji: '🚩',
    aboutMr: 'निःशंक होई रे मना निर्भय होई रे मना... स्वामींचे हे अभयवचन भक्तांना संकटसमयी धैर्य देते.',
    aboutHi: 'श्री स्वामी समर्थ तारक मंत्र भक्तों को भयमुक्त और आत्मविश्वासी बनाता है।',
    about: 'Swami Samarth Tarak Mantra brings fearlessness, peace, and divine reassurance.',
    lyrics: const [
      LyricStanza(
        startTimeMs: 6000,
        devanagari: 'निःशंक होई रे मना निर्भय होई रे मना ।\nप्रचंड स्वामीबळ पाठीशी नित्य आहे रे मना ॥',
        transliteration: 'Nishank Hoi Re Mana Nirbhay Hoi Re Mana,\nPrachand Swamibal Pathishi Nitya Aahe Re Mana.',
      ),
      LyricStanza(
        startTimeMs: 38000,
        devanagari: 'अतर्क्य अवधूत हे स्मरणगामी ।\nअशक्य ही शक्य करतील स्वामी ॥',
        transliteration: 'Atarkya Avadhoot He Smaranagami,\nAshakya Hee Shakya Karateel Swami.',
      ),
    ],
  ),

  AartiItem(
    id: 'mantra_radha',
    title: 'Radha Radha Dhun',
    titleHi: 'राधा राधा धुन',
    titleMr: 'राधा राधा नाम जप',
    deity: 'Radha',
    deityHi: 'राधा रानी',
    deityMr: 'राधा',
    singer: 'Gaurav Krishna Goswami',
    tags: const ['Popular', 'Mantra', 'Radha', 'Krishna'],
    youtubeVideoId: 'jN9x9W1Y2gI',
    backupVideoIds: const ['r5d4F7v3nKs'],
    durationText: '12:05',
    accentColorHex: '#AD1457',
    deityEmoji: '🌸',
    aboutMr: 'श्री राधा राणीचे प्रेममय नामस्मरण भक्तीरसात लीन करते.',
    aboutHi: 'राधा रानी का पावन नाम जप हृदय को भक्ति और आनंद से भर देता है।',
    about: 'Chanting Radha Radha connects the devotee with purest divine love and joy.',
    lyrics: const [
      LyricStanza(
        startTimeMs: 4000,
        devanagari: 'राधा राधा राधा राधा राधा राधा राधा ।\nश्री राधा राधा राधा राधा ॥',
        transliteration: 'Radha Radha Radha Radha Radha Radha Radha,\nShri Radha Radha Radha Radha.',
      ),
    ],
  ),

  AartiItem(
    id: 'mantra_vasudevaya',
    title: 'Om Namo Bhagavate Vasudevaya',
    titleHi: 'ॐ नमो भगवते वासुदेवाय',
    titleMr: 'ॐ नमो भगवते वासुदेवाय',
    deity: 'Lord Vishnu',
    deityHi: 'विष्णु जी',
    deityMr: 'श्री विष्णू',
    singer: 'Jagjit Singh',
    tags: const ['Mantra', 'Vishnu'],
    youtubeVideoId: 'R7f8T9Y1x6o',
    backupVideoIds: const ['w-74t-J6i78'],
    durationText: '10:45',
    accentColorHex: '#3949AB',
    deityEmoji: '🪷',
    aboutMr: 'भगवान श्री विष्णूंचा द्वादशाक्षर महामंत्र जो मोक्ष आणि सुख-शांती देणारा आहे.',
    aboutHi: 'द्वादशाक्षर महामंत्र समस्त पापों का नाश कर परम शांति देता है।',
    about: 'The 12-syllable liberation mantra dedicated to Lord Vishnu and Krishna.',
    lyrics: const [
      LyricStanza(
        startTimeMs: 5000,
        devanagari: 'ॐ नमो भगवते वासुदेवाय ।\nॐ नमो भगवते वासुदेवाय ॥',
        transliteration: 'Om Namo Bhagavate Vasudevaya,\nOm Namo Bhagavate Vasudevaya.',
      ),
    ],
  ),

  AartiItem(
    id: 'mantra_shani',
    title: 'Shani Shloka & Mantra',
    titleHi: 'शनि देव मंत्र',
    titleMr: 'शनि मंत्र (नीलांजन समाभासं)',
    deity: 'Lord Shani',
    deityHi: 'शनि देव',
    deityMr: 'शनि देव',
    singer: 'Ravindra Sathe',
    tags: const ['Mantra', 'Shani'],
    youtubeVideoId: 'X9w1B2v7P8m',
    backupVideoIds: const ['YF8p2Q9n1xI'],
    durationText: '5:10',
    accentColorHex: '#263238',
    deityEmoji: '🪐',
    aboutMr: 'शनि महाराजांचे नीलांजन समाभासं ध्यान श्लोक व मंत्र ग्रहदोष शांतीसाठी पठण केले जाते.',
    aboutHi: 'शनि देव का यह पावन मंत्र सभी बाधाओं और ग्रह दोषों को शांत करता है।',
    about: 'Shani Mantra brings peace, protection, and relief from karmic difficulties.',
    lyrics: const [
      LyricStanza(
        startTimeMs: 4000,
        devanagari: 'ॐ नीलांजन समाभासं रविपुत्रं यमाग्रजम् ।\nछाया मार्तण्ड सम्भूतं तं नमामि शनैश्चरम् ॥',
        transliteration: 'Om Neelanjana Samabhasam Raviputram Yamagrajam,\nChhaya Martanda Sambhutam Tam Namami Shanaishcharam.',
      ),
    ],
  ),
];
