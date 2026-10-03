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
    id: 'stotra_gananayak_ashtakam',
    title: 'Shree Gananayakashtakam',
    titleHi: 'श्री गणनायकाष्टकम्',
    titleMr: 'श्री गणनायकाष्टकम्',
    deity: 'Lord Ganesha',
    deityHi: 'श्री गणेश',
    deityMr: 'श्री गणेश',
    singer: 'Traditional',
    tags: const ['Stotra', 'Ganesha', 'Ashtakam'],
    youtubeVideoId: 'xdiCqgp-Llw',
    durationText: '4:15',
    accentColorHex: '#E65100',
    deityEmoji: '🙏',
    aboutMr: 'श्री गणनायकाष्टकम् हे भगवान गणेशांचे अत्यंत पावन अष्टक स्तोत्र असून सर्व कार्य सिद्धीस नेणारे मानले जाते.',
    aboutHi: 'श्री गणनायकाष्टकम् भगवान श्री गणेश का पावन अष्टक स्तोत्र है जो समस्त विघ्नों का नाश कर सर्वसिद्धि प्रदान करता है।',
    about: 'Shree Gananayakashtakam is an auspicious 8-verse hymn praising Lord Ganesha, removing obstacles and granting wisdom and prosperity.',
    lyrics: const [
      LyricStanza(
        startTimeMs: 0,
        devanagari: 'एकदन्तं महाकायं तप्तकाञ्चनसन्निभम् ।\nलम्बोदरं विशालाक्षं वन्देऽहं गणनायकम् ॥ १ ॥',
        transliteration: "Ekadantam Mahakayam Tapta-Kanchana-Sannibham |\nLambodaram Vishalaksham Vande'ham Gananayakam || 1 ||",
      ),
      LyricStanza(
        startTimeMs: 25000,
        devanagari: 'मौञ्जीकृष्णाजिनधरं नागयज्ञोपवीतिनम् ।\nबालेन्दुसुकलामौलिं वन्देऽहं गणनायकम् ॥ २ ॥',
        transliteration: "Maunji-Krishna-Ajina-Dharam Naga-Yajnopavitinam |\nBalendu-Sukala-Maulim Vande'ham Gananayakam || 2 ||",
      ),
      LyricStanza(
        startTimeMs: 50000,
        devanagari: 'अम्बिकाहृदयानन्दं मातृभिःपरिवेष्टितम् ।\nभक्तप्रियं मदोन्मत्तं वन्देऽहं गणनायकम् ॥ ३ ॥',
        transliteration: "Ambika-Hridaya-Anandam Matribhih-Pariveshtitam |\nBhakta-Priyam Madonmattam Vande'ham Gananayakam || 3 ||",
      ),
      LyricStanza(
        startTimeMs: 75000,
        devanagari: 'चित्ररत्नविचित्राङ्गं चित्रमालाविभूषितम् ।\nचित्ररूपधरं देवं वन्देऽहं गणनायकम् ॥ ४ ॥',
        transliteration: "Chitra-Ratna-Vichitr-Angam Chitra-Mala-Vibhushitam |\nChitra-Rupa-Dharam Devam Vande'ham Gananayakam || 4 ||",
      ),
      LyricStanza(
        startTimeMs: 100000,
        devanagari: 'गजवक्त्रं सुरश्रेष्ठं कर्णचामरभूषितम् ।\nपाशाङ्कुशधरं देवं वन्देऽहं गणनायकम् ॥ ५ ॥',
        transliteration: "Gaja-Vaktram Sura-Shreshtham Karna-Chamara-Bhushitam |\nPashankusha-Dharam Devam Vande'ham Gananayakam || 5 ||",
      ),
      LyricStanza(
        startTimeMs: 125000,
        devanagari: 'मूषकोत्तममारुह्य देवासुरमहाहवे ।\nयोद्धुकामं महावीर्यं वन्देऽहं गणनायकम् ॥ ६ ॥',
        transliteration: "Mushakottamam-Aruhya Devasura-Maha-Have |\nYoddhu-Kamam Maha-Viryam Vande'ham Gananayakam || 6 ||",
      ),
      LyricStanza(
        startTimeMs: 150000,
        devanagari: 'यक्षकिन्नरगन्धर्वसिद्धविद्याधरैः सदा ।\nस्तूयमानं महाबाहुं वन्देऽहं गणनायकम् ॥ ७ ॥',
        transliteration: "Yaksha-Kinnara-Gandharva-Siddha-Vidyadharaih Sada |\nStuyamanam Maha-Bahum Vande'ham Gananayakam || 7 ||",
      ),
      LyricStanza(
        startTimeMs: 175000,
        devanagari: 'सर्वविघ्नहरं देवं सर्वविघ्नविवर्जितम् ।\nसर्वसिद्धिप्रदातारं वन्देऽहं गणनायकम् ॥ ८ ॥',
        transliteration: "Sarva-Vighna-Haram Devam Sarva-Vighna-Vivarjitam |\nSarva-Siddhi-Pradataram Vande'ham Gananayakam || 8 ||",
      ),
      LyricStanza(
        startTimeMs: 200000,
        devanagari: 'गणाष्टकमिदं पुण्यं यः पठेत्सततं नरः ।\nसिद्ध्यन्ति सर्वकार्याणि विद्यावान् धनवान् भवेत् ॥ ९ ॥\n\nइति श्री गणानायकाष्टकं सम्पूर्णम् ।',
        transliteration: 'Ganashtakam-Idam Punyam Yah Pathet-Satatam Narah |\nSiddhyanti Sarva-Karyani Vidyavan Dhanavan Bhavet || 9 ||\n\nIti Shri Gananayakashtakam Sampoornam |',
      ),
    ],
  ),

  AartiItem(
    id: 'stotra_ganapati_stavah',
    title: 'Shree Ganapati Stavah',
    titleHi: 'श्री गणपति स्तवः',
    titleMr: 'श्री गणपति स्तवः',
    deity: 'Lord Ganesha',
    deityHi: 'श्री गणेश',
    deityMr: 'श्री गणेश',
    singer: 'Traditional',
    tags: const ['Stotra', 'Ganesha', 'Stava', 'GaneshPurana'],
    youtubeVideoId: 'ryIk3Rc2Qso',
    durationText: '5:45',
    accentColorHex: '#E65100',
    deityEmoji: '🙏',
    aboutMr: 'श्रीगणेश पुराणातील उपासना खंडातील त्रयोदश अध्यायात ब्रह्मा, विष्णू व महेश यांनी गायलेला परम पवित्र श्री गणपति स्तव.',
    aboutHi: 'श्रीगणेश पुराण के उपासना खण्ड से उद्धृत श्रीगणपति स्तव ब्रह्मा, विष्णु और महेश द्वारा रचित दिव्य स्तुति है।',
    about: 'Shree Ganapati Stavah from the Ganesha Purana, sung by Brahma, Vishnu, and Mahesh in praise of the Supreme Param-Brahma Ganesha.',
    lyrics: const [
      LyricStanza(
        startTimeMs: 0,
        devanagari: 'ब्रह्मविष्णुमहेशा ऊचुः ।\n\nअजं निर्विकल्पं निराकारमेकं\nनिरानन्दमद्वैतमानन्दपूर्णम् ।\nपरं निर्गुणं निर्विशेषं निरीहं\nपरब्रह्मरूपं गणेशं भजेम ॥ १ ॥',
        transliteration: 'Brahma-Vishnu-Mahesha Uchuk |\n\nAjam Nirvikalpam Nirakaram-Ekam\nNiranandam-Advaitam-Ananda-Poornam |\nParam Nirgunam Nirvishesham Nireeham\nParabrahma-Rupam Ganesham Bhajema || 1 ||',
      ),
      LyricStanza(
        startTimeMs: 25000,
        devanagari: 'गुणातीतमाद्यं चिदानन्दरूपं\nचिदाभासकं सर्वगं ज्ञानगम्यम् ।\nमुनिध्येयमाकाशरूपं परेशं\nपरब्रह्मरूपं गणेशं भजेम ॥ २ ॥',
        transliteration: 'Gunatitam-Aadyam Chidananda-Rupam\nChidabhasakam Sarvagam Jnana-Gamyam |\nMunidhyeyam-Akasha-Rupam Paresham\nParabrahma-Rupam Ganesham Bhajema || 2 ||',
      ),
      LyricStanza(
        startTimeMs: 50000,
        devanagari: 'जगत्कारणं कारणज्ञानरूपं\nसुरादिं सुखादिं युगादिं गणेशम् ।\nजगद्व्यापिनं विश्ववन्द्यं सुरेशं\nपरब्रह्मरूपं गणेशं भजेम ॥ ३ ॥',
        transliteration: 'Jagat-Karanam Karana-Jnana-Rupam\nSuradim Sukhadim Yugadim Ganesham |\nJagad-Vyapinam Vishva-Vandyam Suresham\nParabrahma-Rupam Ganesham Bhajema || 3 ||',
      ),
      LyricStanza(
        startTimeMs: 75000,
        devanagari: 'रजोयोगतो ब्रह्मरूपं श्रुतिज्ञं\nसदा कार्यसक्तं हृदाचिन्त्यरूपम् ।\nजगत्कारकं सर्वविद्यानिधानं\nपरब्रह्मरूपं गणेशं नतास्मः ॥ ४ ॥',
        transliteration: 'Rajo-Yogato Brahma-Rupam Shrutijnam\nSada Karyasaktam Hridachintya-Rupam |\nJagat-Karakam Sarva-Vidya-Nidhanam\nParabrahma-Rupam Ganesham Natasmah || 4 ||',
      ),
      LyricStanza(
        startTimeMs: 100000,
        devanagari: 'सदा सत्त्वयोगं मुदा क्रीडमानं\nसुरारीन्हरन्तं जगत्पालयन्तम् ।\nअनेकावतारं निजज्ञानहारं\nसदा विष्णुरूपं गणेशं नमामः ॥ ५ ॥',
        transliteration: 'Sada Sattva-Yogam Muda Kridamanam\nSurarin-Harantam Jagat-Palayantam |\nAnekavataram Nija-Jnana-Haram\nSada Vishnu-Rupam Ganesham Namamah || 5 ||',
      ),
      LyricStanza(
        startTimeMs: 125000,
        devanagari: 'तमोयोगिनं रुद्ररूपं त्रिनेत्रं\nजगद्धारकं तारकं ज्ञानहेतुम् ।\nअनेकागमैः स्वं जनं बोधयन्तं\nसदा शर्वरूपं गणेशं नमामः ॥ ६ ॥',
        transliteration: 'Tamo-Yoginam Rudra-Rupam Trinetram\nJagad-Dharakam Tarakam Jnana-Hetum |\nAnekagamaih Svam Janam Bodhayantam\nSada Sharva-Rupam Ganesham Namamah || 6 ||',
      ),
      LyricStanza(
        startTimeMs: 150000,
        devanagari: 'तमस्तोमहारं जनाज्ञानहारं\nत्रयीवेदसारं परब्रह्मपारम् ।\nमुनिज्ञानकारं विदूरेविकारं\nसदा ब्रह्मरूपं गणेशं नमामः ॥ ७ ॥',
        transliteration: 'Tamas-Toma-Haram Janajnana-Haram\nTrayi-Veda-Saram Parabrahma-Param |\nMuni-Jnana-Karam Vidure-Vikaram\nSada Brahma-Rupam Ganesham Namamah || 7 ||',
      ),
      LyricStanza(
        startTimeMs: 175000,
        devanagari: 'निजैरोषधीस्तर्पयन्तं करोद्यैः\nसरौघान्कलाभिः सुधास्राविणीभिः ।\nदिनेशांशु सन्तापहारं द्विजेशं\nशशाङ्कस्वरूपं गणेशं नमामः ॥ ८ ॥',
        transliteration: 'Nijair-Oshadhir-Tarpayantam Karodyaih\nSaraughankalabhih Sudhasravinibhih |\nDineshamshu Santapaharam Dwijesham\nShashanka-Swarupam Ganesham Namamah || 8 ||',
      ),
      LyricStanza(
        startTimeMs: 200000,
        devanagari: 'प्रकाशस्वरूपं नभोवायुरूपं\nविकारादिहेतुं कलाकालभूतम् ।\nअनेकक्रियानेकशक्तिस्वरूपं\nसदा शक्तिरूपं गणेशं नमामः ॥ ९ ॥',
        transliteration: 'Prakasha-Swarupam Nabho-Vayu-Rupam\nVikaradi-Hetum Kala-Kala-Bhutam |\nAneka-Kriya-Aneka-Shakti-Swarupam\nSada Shakti-Rupam Ganesham Namamah || 9 ||',
      ),
      LyricStanza(
        startTimeMs: 225000,
        devanagari: 'प्रधानस्वरूपं महत्तत्त्वरूपं\nधरावारिरूपं दिगीशादिरूपम् ।\nअसत्सत्स्वरूपं जगद्धेतुभूतं\nसदा विश्वरूपं गणेशं नतास्मः ॥ १० ॥',
        transliteration: 'Pradhana-Swarupam Mahat-Tattva-Rupam\nDhara-Vari-Rupam Digishadi-Rupam |\nAsat-Sat-Swarupam Jagad-Hetu-Bhutam\nSada Vishva-Rupam Ganesham Natasmah || 10 ||',
      ),
      LyricStanza(
        startTimeMs: 250000,
        devanagari: 'त्वदीये मनः स्थापयेदङ्घ्रियुग्मे\nजनो विघ्नसङ्घान्न पीडां लभेत ।\nलसत्सूर्यबिम्बे विशाले स्थितोऽयं\nजनोध्वान्त पीडां कथं वा लभेत ॥ ११ ॥',
        transliteration: 'Tvadiye Manah Sthapayed-Anghri-Yugme\nJano Vighna-Sanghan-Na Peedam Labheta |\nLasat-Surya-Bimbe Vishale Sthito-Ayam\nJano-Dhvanta Peedam Katham Va Labheta || 11 ||',
      ),
      LyricStanza(
        startTimeMs: 275000,
        devanagari: 'वयं भ्रामिताः सर्वथाऽज्ञानयोगा-\n-दलब्धा तवाङ्घ्रिं बहून्वर्षपूगान् ।\nइदानीमवाप्तास्तवैव प्रसादा-\n-त्प्रपन्नान्सदा पाहि विश्वम्भराद्य ॥ १२ ॥',
        transliteration: 'Vayam Bhramitah Sarvatha-Ajnana-Yoga-\nDalabdha Tavanghrim Bahun-Varsha-Pugan |\nIdanim-Avaptas-Tavaiva Prasada-\nTprapannan-Sada Pahi Vishvambharadya || 12 ||',
      ),
      LyricStanza(
        startTimeMs: 300000,
        devanagari: 'गणेश उवाच ।\n\nइदं यः पठेत्प्रातरुत्थाय धीमान्\nत्रिसन्ध्यं सदा भक्तियुक्तो विशुद्धः ।\nसपुत्रान् श्रियं सर्वकामान् लभेत\nपरब्रह्मरूपो भवेदन्तकाले ॥ १३ ॥\n\nइति गणेशपुराणे उपासनाखण्डे त्रयोदशोऽध्याये श्रीगणपतिस्तवः ।',
        transliteration: 'Ganesha Uvacha |\n\nIdam Yah Pathet-Pratar-Utthaya Dhiman\nTri-Sandhyam Sada Bhakti-Yukto Vishuddhah |\nSa-Putran Shriyam Sarva-Kaman Labheta\nParabrahma-Rupo Bhaved-Anta-Kale || 13 ||\n\nIti Ganesha-Purane Upasana-Khande Trayodashodhyaye Shri Ganapati-Stavah |',
      ),
    ],
  ),

  AartiItem(
    id: 'stotra_ganesh_divyadurg',
    title: 'Shree Ganesh Divyadurg Stotram',
    titleHi: 'श्री गणेश दिव्यदुर्ग स्तोत्रम्',
    titleMr: 'श्री गणेश दिव्यदुर्ग स्तोत्रम्',
    deity: 'Lord Ganesha',
    deityHi: 'श्री गणेश',
    deityMr: 'श्री गणेश',
    singer: 'Traditional',
    tags: const ['Stotra', 'Ganesha', 'Divyadurg', 'PadmaPurana'],
    youtubeVideoId: 'cuSeY0LRD8Q',
    durationText: '6:20',
    accentColorHex: '#E65100',
    deityEmoji: '🙏',
    aboutMr: 'पद्मपुराणातील श्री गणेश दिव्यदुर्ग स्तोत्र हे सर्व संकट, भय आणि नकारात्मक शक्तींपासून अभेद्य संरक्षण देणारे महाकवच मानले जाते.',
    aboutHi: 'पद्मपुराण से उद्धृत श्री गणेश दिव्यदुर्ग स्तोत्र समस्त संकटों, भयों और व्याधियों से रक्षा करने वाला अमोघ दिव्य कवच है।',
    about: 'Shree Ganesh Divyadurg Stotram from the Padma Purana, a divine protective shield securing the devotee from all ten directions.',
    lyrics: const [
      LyricStanza(
        startTimeMs: 0,
        devanagari: 'श्रीकृष्ण उवाच ।\n\nवद शिव महानाथ पार्वतीरमणेश्वर ।\nदैत्यसङ्ग्रामवेलायां स्मरणीयं किमीश्वर ॥ १ ॥',
        transliteration: 'Shri Krishna Uvacha |\n\nVada Shiva Mahanaatha Parvati-Ramaneshwara |\nDaitya-Sangrama-Velayam Smaraniyam Kim-Ishwara || 1 ||',
      ),
      LyricStanza(
        startTimeMs: 20000,
        devanagari: 'ईश्वर उवाच ।\n\nशृणु कृष्ण प्रवक्ष्यामि गुह्याद्गुह्यतरं महत् ।\nगणेशदुर्गदिव्यं च शृणु वक्ष्यामि भक्तितः ॥ २ ॥',
        transliteration: 'Ishwara Uvacha |\n\nShrinu Krishna Pravakshyami Guhyad-Guhyataram Mahat |\nGanesha-Durga-Divyam Cha Shrinu Vakshyami Bhaktitah || 2 ||',
      ),
      LyricStanza(
        startTimeMs: 40000,
        devanagari: 'त्रिपुरवधवेलायां स्मरणीयं किमीश्वर ।\nदिव्यदुर्गप्रसादेन त्रिपुराणां वधः कृतः ॥ ३ ॥',
        transliteration: 'Tripura-Vadha-Velayam Smaraniyam Kim-Ishwara |\nDivya-Durga-Prasadena Tripuranam Vadhah Kritah || 3 ||',
      ),
      LyricStanza(
        startTimeMs: 60000,
        devanagari: 'श्रीकृष्ण उवाच ।\nहेरम्बस्य दुर्गमिदं वद त्वं भक्तवत्सल ।\n\nईश्वर उवाच ।\nशृणु वत्स प्रवक्ष्यामि दुर्गे वैनायकं शुभम् ॥ ४ ॥',
        transliteration: 'Shri Krishna Uvacha |\nHerambasya Durgam-Idam Vada Tvam Bhakta-Vatsala |\n\nIshwara Uvacha |\nShrinu Vatsa Pravakshyami Durge Vainayakam Shubham || 4 ||',
      ),
      LyricStanza(
        startTimeMs: 80000,
        devanagari: 'सङ्ग्रामे च श्मशाने च अरण्ये चोरसङ्कटे ।\nनृपद्वारे ज्वरे घोरे येनैव मुच्यते भयात् ॥ ५ ॥',
        transliteration: 'Sangrame Cha Shmashane Cha Aranye Chora-Sankate |\nNripa-Dvare Jvare Ghore Yenaiva Muchyate Bhayat || 5 ||',
      ),
      LyricStanza(
        startTimeMs: 100000,
        devanagari: 'प्राच्यां रक्षतु हेरम्बः आग्नेय्यामग्नितेजसा ।\nयाम्यां लम्बोदरो रक्षेत् नैरृत्यां पार्वतीसुतः ॥ ६ ॥',
        transliteration: 'Prachyam Rakshatu Herambah Agneyyam-Agni-Tejasa |\nYamyam Lambodaro Rakshet Nairrityam Parvati-Sutah || 6 ||',
      ),
      LyricStanza(
        startTimeMs: 120000,
        devanagari: 'प्रतीच्यां वक्रतुण्डश्च वायव्यां वरदप्रभुः ।\nगणेशः पातु औदीच्यां ईशान्यामीश्वरस्तथा ॥ ७ ॥',
        transliteration: 'Pratichyam Vakratundashcha Vayavyam Varada-Prabhuh |\nGaneshah Patu Audichyam Ishanyam-Ishwaras-Tatha || 7 ||',
      ),
      LyricStanza(
        startTimeMs: 140000,
        devanagari: 'ऊर्ध्वं रक्षेद्धूम्रवर्णो ह्यधस्तात्पापनाशनः ।\nएवं दशदिशो रक्षेत् हेरम्बो विघ्ननाशनः ॥ ८ ॥',
        transliteration: 'Urdhvam Rakshed-Dhoomravarno Hy-Adhastat-Papa-Nashanah |\nEvam Dasha-Disho Rakshet Herambo Vighna-Nashanah || 8 ||',
      ),
      LyricStanza(
        startTimeMs: 160000,
        devanagari: 'हेरम्बस्य दुर्गमिदं त्रिकालं यः पठेन्नरः ।\nकोटिजन्मकृतं पापं एकावृत्तेन नश्यति ॥ ९ ॥',
        transliteration: 'Herambasya Durgam-Idam Trikalam Yah Pathen-Narah |\nKoti-Janma-Kritam Papam Ekavrittena Nashyati || 9 ||',
      ),
      LyricStanza(
        startTimeMs: 180000,
        devanagari: 'गणेशाङ्गारशेषेण दिव्यदुर्गेण मन्त्रितम् ।\nललाटं चर्चितं येन त्रैलोक्यवशमानयेत् ॥ १० ॥',
        transliteration: 'Ganesh-Angara-Sheshena Divya-Durgena Mantritam |\nLalatam Charchitam Yena Trailokya-Vasham-Anayet || 10 ||',
      ),
      LyricStanza(
        startTimeMs: 200000,
        devanagari: 'मात्रागमसहस्राणि सुरापानशतानि च ।\nतत् क्षणात्तानि नश्यन्ति गणेशतीर्थवन्दनात् ॥ ११ ॥',
        transliteration: 'Matragama-Sahasrani Surapana-Shatani Cha |\nTat Kshanat-Tani Nashyanti Ganesha-Tirtha-Vandanat || 11 ||',
      ),
      LyricStanza(
        startTimeMs: 220000,
        devanagari: 'नैवेद्यं वक्ततुण्डस्य नरो भुङ्क्ते तु भक्तितः ।\nराज्यदानसहस्राणि तेषां फलमवाप्नुयात् ॥ १२ ॥',
        transliteration: 'Naivedyam Vakratundasya Naro Bhunkte Tu Bhaktitah |\nRajya-Dana-Sahasrani Tesham Phalam-Avapnuyat || 12 ||',
      ),
      LyricStanza(
        startTimeMs: 240000,
        devanagari: 'कदाचित्पठ्यते भक्त्या हेरम्बस्य प्रसादतः ।\nशाकिनी डाकिनी भूतप्रेत वेताल राक्षसाः ॥ १३ ॥\n\nब्रह्मराक्षसकूष्माण्डाः प्रणश्यन्ति च दूरतः ।\nभूर्जे वा ताडपत्रे वा दुर्गहेरम्बमालिखेत् ॥ १४ ॥',
        transliteration: 'Kadachit-Pathyate Bhaktya Herambasya Prasadatah |\nShakini Dakini Bhuta-Preta Vetala Rakshasah || 13 ||\n\nBrahmarakshasa-Kushmandah Pranashyanti Cha Dooratah |\nBhurje Va Tada-Patre Va Durga-Herambam-Alikhet || 14 ||',
      ),
      LyricStanza(
        startTimeMs: 270000,
        devanagari: 'करमूले धृतं येन करस्थाः सर्वसिद्धयः ।\nएकमावर्तनं भक्त्या पठेन्नित्यं तु यो नरः ॥ १५ ॥',
        transliteration: 'Karamule Dhritam Yena Karasthah Sarva-Siddhayah |\nEkam-Avartanam Bhaktya Pathen-Nityam Tu Yo Narah || 15 ||',
      ),
      LyricStanza(
        startTimeMs: 290000,
        devanagari: 'कल्पकोटिसहस्राणि शिवलोके महीयते ।\nलिङ्गदानसहस्राणि पृथ्वीदानशतानि च ॥ १६ ॥\n\nगजदानसहस्रं च गणेशस्तवनात् फलम् ॥ १७ ॥\n\nइति श्रीपद्मपुराणे गणेशदिव्यदुर्गस्तोत्रं सम्पूर्णम् ।',
        transliteration: 'Kalpa-Koti-Sahasrani Shivaloke Mahiyate |\nLinga-Dana-Sahasrani Prithvi-Dana-Shatani Cha || 16 ||\n\nGaja-Dana-Sahasram Cha Ganesha-Stavanat Phalam || 17 ||\n\nIti Shri Padma-Purane Ganesha-Divyadurg-Stotram Sampoornam |',
      ),
    ],
  ),

  AartiItem(
    id: 'stotra_ganesh_pancharatnam',
    title: 'Shree Ganesh Pancharatnam',
    titleHi: 'श्री गणेश पञ्चरत्नम्',
    titleMr: 'श्री गणेश पंचरत्न स्तोत्र',
    deity: 'Lord Ganesha',
    deityHi: 'श्री गणेश',
    deityMr: 'श्री गणेश',
    singer: 'Traditional / M. S. Subbulakshmi',
    tags: const ['Stotra', 'Ganesha', 'Pancharatnam', 'AdiShankaracharya'],
    youtubeVideoId: 'kJVdjMaObtA',
    durationText: '4:45',
    accentColorHex: '#E65100',
    deityEmoji: '🙏',
    aboutMr: 'आद्य शंकराचार्य विरचित श्री गणेश पञ्चरत्नम् हे गणेशांचे अत्यंत सुमधुर आणि प्रभावी स्तुती स्तोत्र आहे.',
    aboutHi: 'आदि शंकराचार्य द्वारा रचित श्री गणेश पञ्चरत्नम् विघ्नहर्ता भगवान गणेश का परम पावन एवं मधुर स्तोत्र है।',
    about: 'Shree Ganesh Pancharatnam composed by Adi Shankaracharya praises the joyful, auspicious forms of Lord Vinayaka.',
    lyrics: const [
      LyricStanza(
        startTimeMs: 0,
        devanagari: 'मुदा करात्तमोदकं सदा विमुक्तिसाधकं\nकलाधरावतंसकं विलासिलोकरक्षकम् ।\nअनायकैकनायकं विनाशितेभदैत्यकं\nनताशुभाशुनाशकं नमामि तं विनायकम् ॥ १ ॥',
        transliteration: 'Muda Karatta-Modakam Sada Vimukti-Sadhakam\nKaladharavatamsakam Vilasi-Loka-Rakshakam |\nAnayakaika-Nayakam Vinashitebha-Daityakam\nNata-Shubhashu-Nashakam Namami Tam Vinayakam || 1 ||',
      ),
      LyricStanza(
        startTimeMs: 40000,
        devanagari: 'नतेतरातिभीकरं नवोदितार्कभास्वरं\nनमत्सुरारिनिर्जरं नताधिकापदुद्धरम् ।\nसुरेश्वरं निधीश्वरं गजेश्वरं गणेश्वरं\nमहेश्वरं तमाश्रये परात्परं निरन्तरम् ॥ २ ॥',
        transliteration: 'Natetarati-Bhikaram Navoditarka-Bhasvaram\nNamatsurar-Inirjaram Natadhikapad-Uddharam |\nSureshwaram Nidhishwaram Gajeshwaram Ganeshwaram\nMaheshwaram Tam-Ashraye Paratparam Nirantaram || 2 ||',
      ),
      LyricStanza(
        startTimeMs: 80000,
        devanagari: 'समस्तलोकशङ्करं निरस्तदैत्यकुञ्जरं\nदरेतरोदरं वरं वरेभवक्त्रमक्षरम् ।\nकृपाकरं क्षमाकरं मुदाकरं यशस्करं\nमनस्करं नमस्कृतां नमस्करोमि भास्वरम् ॥ ३ ॥',
        transliteration: 'Samasta-Loka-Shankaram Nirasta-Daitya-Kunjaram\nDaretarodaram Varam Varebha-Vaktram-Aksharam |\nKripakaram Kshamkaram Mudakaram Yashaskaram\nManaskaram Namaskritam Namaskaromi Bhasvaram || 3 ||',
      ),
      LyricStanza(
        startTimeMs: 120000,
        devanagari: 'अकिञ्चनार्तिमार्जनं चिरन्तनोक्तिभाजनं\nपुरारिपूर्वनन्दनं सुरारिगर्वचर्वणम् ।\nप्रपञ्चनाशभीषणं धनञ्जयादिभूषणं\nकपोलदानवारणं भजे पुराणवारणम् ॥ ४ ॥',
        transliteration: 'Akinchanarti-Marjanam Chirantanokti-Bhajanam\nPurari-Poorva-Nandanam Surari-Garva-Charvanam |\nPrapancha-Nasha-Bhishanam Dhananjayadi-Bhushanam\nKapola-Dana-Varanam Bhaje Purana-Varanam || 4 ||',
      ),
      LyricStanza(
        startTimeMs: 160000,
        devanagari: 'नितान्तकान्तदन्तकान्तिमन्तकान्तकात्मजं\nअचिन्त्यरूपमन्तहीनमन्तरायकृन्तनम् ।\nहृदन्तरे निरन्तरं वसन्तमेव योगिनां\nतमेकदन्तमेव तं विचिन्तयामि सन्ततम् ॥ ५ ॥',
        transliteration: 'Nitanta-Kanta-Danta-Kantim-Antakantakatmajam\nAchintya-Rupam-Antahinam-Antaraya-Krintanam |\nHridantare Nirantaram Vasantam-Eva Yoginam\nTam-Ekadantam-Eva Tam Vichintayami Santatam || 5 ||',
      ),
      LyricStanza(
        startTimeMs: 200000,
        devanagari: 'महागणेशपञ्चरत्नमादरेण योऽन्वहं\nप्रजल्पति प्रभातके हृदि स्मरन्गणेश्वरम् ।\nअरोगतामदोषतां सुसाहितीं सुपुत्रतां\nसमाहितायुरष्टभूतिमभ्युपैति सोऽचिरात् ॥ ६ ॥',
        transliteration: "Maha-Ganesha-Pancharatnam-Adarena Yo'nvaham\nPrajalpati Prabhatake Hridi Smaran-Ganeshwaram |\nArogatam-Adoshatam Susahitim Suputratam\nSamahitayur-Ashtabhutim-Abhyupaiti So'chirat || 6 ||",
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

  AartiItem(
    id: 'mantra_ganapati_mantraksharavali',
    title: 'Shri Ganapati Mantraksharavali Stotram',
    titleHi: 'श्री गणपति मन्त्राक्षरावलि स्तोत्रम्',
    titleMr: 'श्री गणपति मन्त्राक्षरावलि स्तोत्रम्',
    deity: 'Lord Ganesha',
    deityHi: 'श्री गणेश',
    deityMr: 'श्री गणेश',
    singer: 'Traditional',
    tags: const ['Mantra', 'Ganesha', 'Stotra'],
    youtubeVideoId: 'S8UclCJsTjo',
    durationText: '11:20',
    accentColorHex: '#E65100',
    deityEmoji: '🙏',
    aboutMr: 'श्री गणपति मन्त्राक्षरावलि स्तोत्र हे महागणपतींच्या सिद्ध मंत्राक्षरांनी गुंफलेले अत्यंत दुर्मिळ व सर्वमनोकामना पूर्ण करणारे पावन स्तोत्र आहे.',
    aboutHi: 'श्री गणपति मन्त्राक्षरावलि स्तोत्र महागणपति के सिद्ध मंत्राक्षरों से समन्वित अत्यंत पावन व सर्वसिद्धि प्रदायक स्तोत्र है।',
    about: 'Shri Ganapati Mantraksharavali Stotram is a sacred hymn woven from the potent syllables of the Maha Ganapati mantra for supreme grace and obstacle removal.',
    lyrics: const [
      LyricStanza(
        startTimeMs: 0,
        devanagari: 'श्रीदेव्युवाच ।\nविना तपो विना ध्यानम् विना होमं विना जपम् ।\nअनायासेन विघ्नेशप्रीणनं वद मे प्रभो ॥ १ ॥',
        transliteration: 'Shri Devyuvacha |\nVina Tapo Vina Dhyanam Vina Homam Vina Japam |\nAnayasena Vighnesha-Prinandam Vada Me Prabho || 1 ||',
      ),
      LyricStanza(
        startTimeMs: 20000,
        devanagari: 'महेश्वर उवाच ।\nमन्त्राक्षरावलिस्तोत्रं महासौभाग्यवर्धनम् ।\nदुर्लभं दुष्टमनसां सुलभं शुद्धचेतसाम् ॥ २ ॥',
        transliteration: 'Maheshwara Uvacha |\nMantraksharavali-Stotram Maha-Saubhagya-Vardhanam |\nDurlabham Dushta-Manasam Sulabham Shuddha-Chetasam || 2 ||',
      ),
      LyricStanza(
        startTimeMs: 40000,
        devanagari: 'महागणपतिप्रीतिप्रतिपादकमञ्जसा ।\nकथयामि घनश्रोणि कर्णाभ्यामवतंसय ॥ ३ ॥',
        transliteration: 'Maha-Ganapati-Priti-Pratipadakam-Anjasa |\nKathayami Ghana-Shroni Karnabhyam-Avatamsaya || 3 ||',
      ),
      LyricStanza(
        startTimeMs: 60000,
        devanagari: 'ओङ्कारवलयाकारं अच्छकल्लोलमालिकम् ।\nऐक्षवं चेतसा वन्दे सिन्धुं सन्धुक्षितस्वनम् ॥ ४ ॥',
        transliteration: 'Omkara-Valayakaram Achha-Kallola-Malikam |\nAikshavam Chetasa Vande Sindhum Sandhukshita-Svanam || 4 ||',
      ),
      LyricStanza(
        startTimeMs: 80000,
        devanagari: 'श्रीमन्तमिक्षुजलधेः अन्तरभ्युदितं नुमः ।\nमणिद्वीपं महाकारं महाकल्पं महोदयम् ॥ ५ ॥',
        transliteration: 'Shrimantam-Ikshu-Jaladheh Antarabhyuditam Numah |\nMani-Dvipam Mahakaram Maha-Kalpam Mahodayam || 5 ||',
      ),
      LyricStanza(
        startTimeMs: 100000,
        devanagari: 'ह्रीप्रदेन महाधाम्ना धाम्नामीशे विभारके ।\nकल्पोद्यानस्थितं वन्दे भास्वन्तं मणिमण्डपम् ॥ ६ ॥',
        transliteration: 'Hri-Pradena Maha-Dhamna Dhamnam-Ishe Vibharake |\nKalpodyana-Sthitam Vande Bhasvantam Mani-Mandapam || 6 ||',
      ),
      LyricStanza(
        startTimeMs: 120000,
        devanagari: 'क्लीबस्यापि स्मरोन्मादकारिशृङ्गारशालिनि ।\nतन्मध्ये गणनाथस्य मणिसिंहासनं भजे ॥ ७ ॥',
        transliteration: 'Klibasyapi Smaronmada-Kari-Shringara-Shalini |\nTanmadhye Gananathasya Mani-Simhasanam Bhaje || 7 ||',
      ),
      LyricStanza(
        startTimeMs: 140000,
        devanagari: 'ग्लौकलाभिरिवाच्छाभिस्तीव्रादिनवशक्तिभिः ।\nजुष्टं लिपिमयं पद्मं धर्माद्याश्रयमाश्रये ॥ ८ ॥',
        transliteration: 'Glau-Kalabhirivachhabhis-Tivradinava-Shaktibhih |\nJushtam Lipimayam Padmam Dharmadyashrayam-Ashraye || 8 ||',
      ),
      LyricStanza(
        startTimeMs: 160000,
        devanagari: 'गम्भीरमिव तत्राब्धिं वसन्तं त्र्यश्रमण्डले ।\nउत्सङ्गगतलक्ष्मीकं उद्यत्तिग्मांशुपाटलम् ॥ ९ ॥',
        transliteration: 'Gambhiramiva Tatrabdhim Vasantam Tryashra-Mandale |\nUtsanga-Gata-Lakshmikam Udyat-Tigmamshu-Patalam || 9 ||',
      ),
      LyricStanza(
        startTimeMs: 180000,
        devanagari: 'गदेक्षुकार्मुकरुजाचक्राम्बुजगुणोत्पलैः ।\nव्रीह्यग्रनिजदन्ताग्रकलशीमातुलुङ्गकैः ॥ १० ॥',
        transliteration: 'Gadekshu-Karmuka-Ruja-Chakrambuja-Gunotpalaih |\nVrihyagra-Nija-Dantagra-Kalashi-Matulungakaih || 10 ||',
      ),
      LyricStanza(
        startTimeMs: 200000,
        devanagari: 'णषष्ठवर्णवाच्यस्य दारिद्र्यस्य विभञ्जकैः ।\nएतैरेकादशकरान् अलङ्कुर्वाणमुन्मदम् ॥ ११ ॥',
        transliteration: 'Na-Shashta-Varna-Vachyasya Daridryasya Vibhanjakaih |\nEtair-Ekadasha-Karan Alankurvanam-Unmadam || 11 ||',
      ),
      LyricStanza(
        startTimeMs: 220000,
        devanagari: 'परानन्दमयं भक्तप्रत्यूहव्यूहनाशनम् ।\nपरमार्थप्रबोधाब्धिं पश्यामि गणनायकम् ॥ १२ ॥',
        transliteration: 'Paranandamayam Bhakta-Pratyuha-Vyuha-Nashanam |\nParamartha-Prabodhabdhim Pashyami Gananayakam || 12 ||',
      ),
      LyricStanza(
        startTimeMs: 240000,
        devanagari: 'तत्पुरः प्रस्फुरद्बिल्वमूलपीठसमाश्रयौ ।\nरमारमेशौ विमृशाम्यशेषशुभदायकौ ॥ १३ ॥',
        transliteration: 'Tatpurah Prasphurad-Bilva-Mula-Pitha-Samashrayau |\nRama-Rameshau Vimrishamya-Shesha-Shubhadayakau || 13 ||',
      ),
      LyricStanza(
        startTimeMs: 260000,
        devanagari: 'येन दक्षिणभागस्थन्यग्रोधतलमाश्रितम् ।\nसाकल्पं सायुधं वन्दे तं साम्बं परमेश्वरम् ॥ १४ ॥',
        transliteration: 'Yena Dakshina-Bhagastha-Nyagrodha-Talam-Ashritam |\nSakalpam Sayudham Vande Tam Sambam Parameshwaram || 14 ||',
      ),
      LyricStanza(
        startTimeMs: 280000,
        devanagari: 'वरसम्भोगरुचिरौ पश्चिमे पिप्पलाश्रयौ ।\nरमणीयतरौ वन्दे रतिपुष्पशिलीमुखौ ॥ १५ ॥',
        transliteration: 'Vara-Sambhogaruchirau Pashchime Pippalashrayau |\nRamaniyatarau Vande Rati-Pushpa-Shilimukhau || 15 ||',
      ),
      LyricStanza(
        startTimeMs: 300000,
        devanagari: 'रममाणौ गणेशानोत्तरदिक्फलिनीतले ।\nभूभूधरावुदाराभौ भजे भुवनपालकौ ॥ १६ ॥',
        transliteration: 'Ramamanau Ganeshanottara-Dik-Phalini-Tale |\nBhu-Bhudharav-Udarabhau Bhaje Bhuvana-Palakau || 16 ||',
      ),
      LyricStanza(
        startTimeMs: 320000,
        devanagari: 'वलमानवपुर्ज्योतिः कडारितककुप्तटीः ।\nहृदयाद्यङ्गषड्देवीरङ्गरक्षाकृते भजे ॥ १७ ॥',
        transliteration: 'Valamana-Vapurjyotih Kadarita-Kakuptatih |\nHridayadyanga-Shaddeviranga-Raksha-Krite Bhaje || 17 ||',
      ),
      LyricStanza(
        startTimeMs: 340000,
        devanagari: 'रदकाण्डरुचिज्योत्स्नाकाशगण्डस्रवन्मदम् ।\nऋद्ध्याश्लेषकृतामोदमामोदं देवमाश्रये ॥ १८ ॥',
        transliteration: 'Rada-Kanda-Ruchijyotsnakasha-Ganda-Sravanmadam |\nRiddhyashlesha-Kritamodam-Amodam Devam-Ashraye || 18 ||',
      ),
      LyricStanza(
        startTimeMs: 360000,
        devanagari: 'दलत्कपोलविगलन्मदधारावलाहकम् ।\nसमृद्धितटिदाश्लिष्टं प्रमोदं हृदि भावये ॥ १९ ॥',
        transliteration: 'Dalat-Kapola-Vigalan-Madadhara-Valahakam |\nSamriddhi-Tatid-Ashlishtam Pramodam Hridi Bhavaye || 19 ||',
      ),
      LyricStanza(
        startTimeMs: 380000,
        devanagari: 'सकान्तिं कान्तिलतिकापरिरब्धतनुं भजे ।\nभुजप्रकाण्डसच्छायं सुमुखं कल्पपादपम् ॥ २० ॥',
        transliteration: 'Sakantim Kanti-Latika-Parirabdha-Tanum Bhaje |\nBhuja-Prakanda-Sachhayam Sumukham Kalpa-Padapam || 20 ||',
      ),
      LyricStanza(
        startTimeMs: 400000,
        devanagari: 'वन्दे तुन्दिलमिन्धानं चन्द्रकन्दलशीतलम् ।\nदुर्मुखं मदनावत्या निर्मितालिङ्गनामृतम् ॥ २१ ॥',
        transliteration: 'Vande Tundilam-Indhanam Chandra-Kandala-Shitalam |\nDurmukham Madanavatyah Nirmitalinganamritam || 21 ||',
      ),
      LyricStanza(
        startTimeMs: 420000,
        devanagari: 'जम्भवैरिकृताभ्यर्च्यौ जगदभ्युदयप्रदौ ।\nअहं मदद्रवाविघ्नौ हतये त्वेनसां श्रये ॥ २२ ॥',
        transliteration: 'Jambhavairi-Kritabhyarchyau Jagad-Abhyudaya-Pradau |\nAham Madadrava-Vighnau Hataye Tvenasam Shraye || 22 ||',
      ),
      LyricStanza(
        startTimeMs: 440000,
        devanagari: 'नवशृङ्गाररुचिरौ नमत्सर्वसुरासुरौ ।\nद्राविणीविघ्नकर्तारौ द्रावयेतां दरिद्रताम् ॥ २३ ॥',
        transliteration: 'Nava-Shringara-Ruchirau Namat-Sarva-Surasurau |\nDravini-Vighna-Kartarau Dravayetam Daridratam || 23 ||',
      ),
      LyricStanza(
        startTimeMs: 460000,
        devanagari: 'मेदुरं मौक्तिकासारं वर्षन्तौ भक्तिशालिनाम् ।\nवसुधाराशङ्खनिधी वाक्पुष्पाञ्जलिभिः स्तुमः ॥ २४ ॥',
        transliteration: 'Meduram Mauktikasaram Varshantau Bhaktishalinam |\nVasudhara-Shankha-Nidhi Vak-Pushpanjalibhih Stumah || 24 ||',
      ),
      LyricStanza(
        startTimeMs: 480000,
        devanagari: 'वर्षन्तौ रत्नवर्षेण वलद्बालातपत्विषौ ।\nवरदौ नमतां वन्दे वसुधापद्मशेवधी ॥ २५ ॥',
        transliteration: 'Varshantau Ratna-Varshena Valad-Balatapa-Tvishau |\nVaradau Namatam Vande Vasudha-Padma-Shevadhi || 25 ||',
      ),
      LyricStanza(
        startTimeMs: 500000,
        devanagari: 'शमिताधिमहाव्याधीः सान्द्रानन्दकरम्बिताः ।\nब्राह्म्यादीः कलये शक्तीः शक्तीनामभिवृद्धये ॥ २६ ॥',
        transliteration: 'Shamitadhi-Maha-Vyadhih Sandrananda-Karambitah |\nBrahmyadih Kalaye Shaktih Shaktinam-Abhivridhaye || 26 ||',
      ),
      LyricStanza(
        startTimeMs: 520000,
        devanagari: 'मामवन्तु महेन्द्राद्या दिक्पाला दर्पशालिनः ।\nसंनताः श्रीगणाधीशं सवाहायुधशक्तयः ॥ २७ ॥',
        transliteration: 'Mamavantu Mahendradya Dikpala Darpashalinah |\nSannatah Shri-Ganadhisham Savahayudha-Shaktayah || 27 ||',
      ),
      LyricStanza(
        startTimeMs: 540000,
        devanagari: 'नवीनपल्लवच्छायादायादवपुरुज्ज्वलम् ।\nमेदस्वि मदनिष्यन्दस्रोतस्वि कटकोटरम् ॥ २८ ॥',
        transliteration: 'Navina-Pallavachhaya-Dayadavapur-Ujjvalam |\nMedasvi Madanishyanda-Srotasvi Katakotaram || 28 ||',
      ),
      LyricStanza(
        startTimeMs: 560000,
        devanagari: 'यजमानतनुं यागरूपिणं यज्ञपूरुषम् ।\nयमं यमवतामर्च्यं यत्नभाजामदुर्लभम् ॥ २९ ॥',
        transliteration: 'Yajamana-Tanum Yaga-Rupinam Yajna-Purusham |\nYamam Yamavatam-Archyam Yatnabhajam-Adurlabham || 29 ||',
      ),
      LyricStanza(
        startTimeMs: 580000,
        devanagari: 'स्वारस्यपरमानन्दस्वरूपं स्वयमुद्गतम् ।\nस्वयं वेद्यं स्वयं शक्तं स्वयं कृत्यत्रयाकरम् ॥ ३० ॥',
        transliteration: 'Svarasya-Paramananda-Svarupam Svayam-Udgatam |\nSvayam Vedyam Svayam Shaktam Svayam Krityatrayakaram || 30 ||',
      ),
      LyricStanza(
        startTimeMs: 600000,
        devanagari: 'हारकेयूर मुकुटकनकाङ्गद कुण्डलैः ।\nअलङ्कृतं च विघ्नानां हर्तारं देवमाश्रये ॥ ३१ ॥',
        transliteration: 'Hara-Keyura Mukuta-Kanakangada Kundalaih |\nAlankritam Cha Vighnanam Hartaram Devam-Ashraye || 31 ||',
      ),
      LyricStanza(
        startTimeMs: 620000,
        devanagari: 'मन्त्राक्षरावलिस्तोत्रं कथितं तव सुन्दरि ।\nसमस्तमीप्सितं तेन सम्पादय शिवे शिवम् ॥ ३२ ॥\n\nइति श्री गणपति मन्त्राक्षरावलि स्तोत्रम् ।',
        transliteration: 'Mantraksharavali-Stotram Kathitam Tava Sundari |\nSamastam-Ipsitam Tena Sampadaya Shive Shivam || 32 ||\n\nIti Shri Ganapati Mantraksharavali Stotram |',
      ),
    ],
  ),

  AartiItem(
    id: 'mantra_ganesh_moolamantra_padamala',
    title: 'Shri Ganesh Moolamantra Padamala Stotram',
    titleHi: 'श्री गणेश मूलमन्त्रपदमाला स्तोत्रम्',
    titleMr: 'श्री गणेश मूलमन्त्रपदमाला स्तोत्रम्',
    deity: 'Lord Ganesha',
    deityHi: 'श्री गणेश',
    deityMr: 'श्री गणेश',
    singer: 'Traditional',
    tags: const ['Mantra', 'Ganesha', 'Moolamantra'],
    youtubeVideoId: 'd1ArOnqN1xU',
    durationText: '6:45',
    accentColorHex: '#E65100',
    deityEmoji: '🙏',
    aboutMr: 'श्री गणेश मूलमन्त्रपदमाला स्तोत्रम् हे श्री अनन्तानन्दनाथ विरचित भगवान गणेशांच्या मूलमंत्रातील प्रत्येक पदाचे रहस्य उलगडणारे दिव्य स्तोत्र आहे.',
    aboutHi: 'श्री गणेश मूलमन्त्रपदमाला स्तोत्रम् श्री अनंतानंदनाथ द्वारा रचित भगवान गणेश के मूलमंत्र के प्रत्येक पद की महिमा का गुणगान करने वाला अनुपम स्तोत्र है।',
    about: 'Shri Ganesh Moolamantra Padamala Stotram composed by Shri Anantanandanatha is an esoteric hymn glorifying each syllable of Lord Ganesha’s sacred Moola Mantra.',
    lyrics: const [
      LyricStanza(
        startTimeMs: 0,
        devanagari: 'ओमित्येतदजस्य कण्ठविवरं भित्वा बहिर्निर्गतं\nचोमित्येव समस्तकर्म ऋषिभिः प्रारभ्यते मानुषैः ।\nओमित्येव सदा जपन्ति यतयः स्वात्मैकनिष्ठाः परं\nचोंकाराकृतिवक्त्रमिन्दुनिटिलं विघ्नेश्वरं भवाये ॥ १ ॥',
        transliteration: 'Omityetad-Ajasya Kantha-Vivaram Bhitva Bahir-Nirgatam\nChomityeva Samasta-Karma Rishibhih Prarabhyate Manushaih |\nOmityeva Sada Japanti Yatayah Svatmaika-Nishthah Param\nChonkarakriti-Vaktram-Indu-Nitilam Vighneshwaram Bhavaye || 1 ||',
      ),
      LyricStanza(
        startTimeMs: 26000,
        devanagari: 'श्रीं बीजं श्रमदुःखजन्ममरणव्याध्याधिभीनाशकं\nमृत्युक्रोधनशान्तिबिन्दुविलसद्वर्णाकृति श्रीप्रदम् ।\nस्वान्तस्थात्मशरस्य लक्ष्यमजरस्वात्मावबोधप्रदं\nश्रीश्रीनायकसेवितेभवदनप्रेमास्पदं भावये ॥ २ ॥',
        transliteration: 'Shrim Bijam Shrama-Duhkha-Janma-Marana-Vyadhyadhi-Bhi-Nashakam\nMrityu-Krodhana-Shanti-Bindu-Vilasadvarnakriti Shripradam |\nSvantasthatma-Sharasya Lakshyam-Ajara-Svatmavabodha-Pradam\nShri-Shri-Nayaka-Sevitebha-Vadana-Premaspadam Bhavaye || 2 ||',
      ),
      LyricStanza(
        startTimeMs: 52000,
        devanagari: 'ह्रीं बीजं हृदयत्रिकोणविलसन्मध्यासनस्थं सदा\nचाकाशानलवामलोचननिशानाथार्धवर्णात्मकम् ।\nमायाकार्यजगत्प्रकाशकमुमारूपं स्वशक्तिप्रदं\nमायातीतपदप्रदं हृदि भजे लोकेश्वराराधितम् ॥ ३ ॥',
        transliteration: 'Hrim Bijam Hridaya-Trikona-Vilasan-Madhyasanastham Sada\nChakashanala-Vama-Lochana-Nishanathardha-Varnatmakam |\nMaya-Karya-Jagat-Prakashakam-Uma-Rupam Svashakti-Pradam\nMayatita-Pada-Pradam Hridi Bhaje Lokeshwararadhitam || 3 ||',
      ),
      LyricStanza(
        startTimeMs: 78000,
        devanagari: 'क्लीं बीजं कलिधातुवत्कलयतां सर्वेष्टदं देहिनां\nधातृक्ष्मायुतशान्तिबिन्दुविलसद्वर्णात्मकं कामदम् ।\nश्रीकृष्णप्रियमिन्दिरासुतमनःप्रीत्येकहेतुं परं\nहृत्पद्मे कलये सदा कलिहरं कालारिपुत्रप्रियम् ॥ ४ ॥',
        transliteration: 'Klim Bijam Kali-Dhatu-Vatkalyatam Sarveshtadam Dehinam\nDhatrikshmayuta-Shanti-Bindu-Vilasadvarnatmakam Kamadam |\nShri-Krishna-Priyam-Indirasuta-Manah-Prityeka-Hetum Param\nHritpadme Kalaye Sada Kali-Haram Kalari-Putra-Priyam || 4 ||',
      ),
      LyricStanza(
        startTimeMs: 104000,
        devanagari: 'ग्लौं बीजं गुणरूपनिर्गुणपरब्रह्मादिशक्तेर्महा-\n-हङ्काराकृतिदण्डिनीप्रियमजश्रीनाथरुद्रेष्टदम् ।\nसर्वाकर्षिणिदेवराजभुवनार्णेन्द्वात्मकं श्रीकरं\nचित्ते विघ्ननिवारणाय गिरिजाजातप्रियं भावये ॥ ५ ॥',
        transliteration: 'Glaum Bijam Guna-Rupa-Nirguna-Parabrahmadishakter-Maha-\n-Hankarakriti-Dandini-Priyam-Aja-Shrinatha-Rudreshtadam |\nSarvakarshini-Devaraja-Bhuvanarnendvatmakam Shrikaram\nChitte Vighna-Nivaranaya Girijajata-Priyam Bhavaye || 5 ||',
      ),
      LyricStanza(
        startTimeMs: 130000,
        devanagari: 'गङ्गासुतं गन्धमुखोपचार-\n-प्रियं खगारोहणभागिनेयम् ।\nगङ्गासुताद्यं वरगन्धतत्त्व-\n-मूलाम्बुजस्थं हृदि भावयेऽहम् ॥ ६ ॥',
        transliteration: 'Ganga-Sutam Gandha-Mukhopachara-\n-Priyam Khagarohana-Bhagineyam |\nGanga-Sutadyam Vara-Gandha-Tattva-\n-Mulambujastham Hridi Bhavaye\'ham || 6 ||',
      ),
      LyricStanza(
        startTimeMs: 156000,
        devanagari: 'गणपतये वरगुणनिधये\nसुरगणपतये नतजनततये ।\nमणिगणभूषितचरणयुगा-\n-श्रितमलहरणे चण ते नमः ॥ ७ ॥',
        transliteration: 'Ganapataye Vara-Guna-Nidhaye\nSura-Ganapataye Nata-Jana-Tataye |\nMani-Gana-Bhushita-Charana-Yuga-\n-Shrita-Mala-Harane Chana Te Namah || 7 ||',
      ),
      LyricStanza(
        startTimeMs: 182000,
        devanagari: 'वराभये मोदकमेकदन्तं\nकराम्बुजातैः सततं धरन्तम् ।\nवराङ्गचन्द्रं परभक्तिसान्द्रै-\n-र्जनैर्भजन्तं कलये सदाऽन्तः ॥ ८ ॥',
        transliteration: 'Varabhaye Modakam-Ekadantam\nKarambujataih Satatam Dharantam |\nVaranga-Chandram Para-Bhakti-Sandrair-\n-Janair-Bhajantam Kalaye Sadantah || 8 ||',
      ),
      LyricStanza(
        startTimeMs: 208000,
        devanagari: 'वरद नतजनानां सन्ततं वक्रतुण्ड\nस्वरमयनिजगात्र स्वात्मबोधैकहेतो ।\nकरलसदमृताम्भः पूर्णपत्राद्य मह्यं\nगरगलसुत शीघ्रं देहि मद्बोधमीड्यम् ॥ ९ ॥',
        transliteration: 'Varada Nata-Jananam Santatam Vakratunda\nSvaramaya-Nija-Gatra Svatmabodhaika-Heto |\nKaralasad-Amritambhah Purna-Patradya Mahyam\nGaragalasuta Shighram Dehi Madbodham-Idyam || 9 ||',
      ),
      LyricStanza(
        startTimeMs: 234000,
        devanagari: 'सर्वजनं परिपालय शर्वज\nपर्वसुधाकरगर्वहर ।\nपर्वतनाथसुतासुत पालय\nखर्वं मा कुरु दीनमिमम् ॥ १० ॥',
        transliteration: 'Sarvajanam Paripalaya Sharvaja\nParvasudhakara-Garvahara |\nParvatanatha-Sutasuta Palaya\nKharvam Ma Kuru Dinam-Imam || 10 ||',
      ),
      LyricStanza(
        startTimeMs: 260000,
        devanagari: 'मेदोऽस्थिमांसरुधिरान्त्रमये शरीरे\nमेदिन्यबग्निमरुदम्बरलास्यमाने ।\nमे दारुणं मदमुखाघमुमाज हृत्वा\nमेधाह्वयासनवरे वस दन्तिवक्त्र ॥ ११ ॥',
        transliteration: 'Medo\'sthi-Mamsa-Rudhiran-Tramaye Sharire\nMedinyabagni-Marud-Ambaralasyamane |\nMe Darunam Madamukhagham-Umaja Hritva\nMedhahvayasana-Vare Vasa Dantivaktra || 11 ||',
      ),
      LyricStanza(
        startTimeMs: 286000,
        devanagari: 'वशं कुरु त्वं शिवजात मां ते\nवशीकृताशेषसमस्तलोक ।\nवसार्णसंशोभितमूलपद्म-\n-लसच्छ्रियाऽलिङ्गित वारणास्य ॥ १२ ॥',
        transliteration: 'Vasham Kuru Tvam Shivajata Mam Te\nVashikritashesa-Samastaloka |\nVasarna-Samshobhita-Mulapadma-\n-Lasachhriyalingita Varanasya || 12 ||',
      ),
      LyricStanza(
        startTimeMs: 312000,
        devanagari: 'आनयाशु पदवारिजान्तिकं\nमां नयादिगुणवर्जितं तव ।\nहानिहीनपदजामृतस्य ते\nपानयोग्यमिभवक्त्र मां कुरु ॥ १३ ॥',
        transliteration: 'Anayashu Padavarijantikam\nMam Nayadiguna-Varjitam Tava |\nHani-Hina-Padajamritasya Te\nPana-Yogyam-Ibhavaktra Mam Kuru || 13 ||',
      ),
      LyricStanza(
        startTimeMs: 338000,
        devanagari: 'स्वाहास्वरूपेण विराजसे त्वं\nसुधाशनानां प्रियकर्मणीड्य ।\nस्वधास्वरूपेण तु पित्र्यकर्म-\n-ण्युमासुतेज्यामय विश्वमूर्ते ॥ १४ ॥',
        transliteration: 'Svaha-Svarupena Virajase Tvam\nSudhashananam Priyakarmanidya |\nSvadha-Svarupena Tu Pitryakarma-\n-Nyumasutejyamaya Vishvamurte || 14 ||',
      ),
      LyricStanza(
        startTimeMs: 364000,
        devanagari: 'अष्टाविंशतिवर्णपत्रलसितं हारं गणेशप्रियं\nकष्टाऽनिष्टहरं चतुर्दशपदैः पुष्पैर्मनोहारकम् ।\nतुष्ट्यादिप्रदसद्गुरूत्तमपदाम्भोजे चिदानन्ददं\nशिष्टेष्टोऽहमनन्तसूत्रहृदयाबद्धं सुभक्त्यार्पये ॥ १५ ॥\n\nइति श्रीअनन्तानन्दनाथकृत श्री गणेश मूलमन्त्रपदमाला स्तोत्रम् ।',
        transliteration: 'Ashtavimshati-Varna-Patra-Lasitam Haram Ganesha-Priyam\nKashtanishta-Haram Chaturdasha-Padaih Pushpair-Manoharakam |\nTushtyadi-Prada-Sadgurottama-Padambhoje Chidanandadam\nShishteshto\'ham-Ananta-Sutra-Hridayabaddham Subhaktyarpaye || 15 ||\n\nIti Shri Anantanandanatha-Krita Shri Ganesh Moolamantra Padamala Stotram |',
      ),
    ],
  ),

  AartiItem(
    id: 'mantra_ganesh_vakratunda',
    title: 'Vakratunda Maha-Kaya Mantra',
    titleHi: 'वक्रतुण्ड महाकाय मंत्र',
    titleMr: 'वक्रतुंड महाकाय मंत्र',
    deity: 'Lord Ganesha',
    deityHi: 'श्री गणेश',
    deityMr: 'श्री गणेश',
    singer: 'Traditional',
    tags: const ['Mantra', 'Ganesha', 'Vakratunda'],
    youtubeVideoId: '_lli0S6i_Fw',
    durationText: '3:45',
    accentColorHex: '#E65100',
    deityEmoji: '🙏',
    aboutMr: 'सर्व शुभ कार्यांच्या सुरुवातीला विघ्न दूर करण्यासाठी उच्चारला जाणारा भगवान श्री गणेशांचा परम पावन वक्रतुंड मंत्र.',
    aboutHi: 'समस्त शुभ कार्यों के आरंभ में विघ्नों के निवारण हेतु उच्चारित श्री गणेश का अत्यंत मंगलकारी मंत्र।',
    about: 'The supreme obstacle-removing invocation to Lord Ganesha chanted before beginning any auspicious undertaking.',
    lyrics: const [
      LyricStanza(
        startTimeMs: 0,
        devanagari: 'श्री वक्रतुण्ड महाकाय सूर्य कोटी समप्रभा ।\nनिर्विघ्नं कुरु मे देव सर्व-कार्येशु सर्वदा ॥',
        transliteration: 'Shree Vakratunda Mahakaya Suryakoti Samaprabha |\nNirvighnam Kuru Me Deva Sarva-Kaaryeshu Sarvada ||',
      ),
    ],
  ),

  AartiItem(
    id: 'mantra_ganesh_shubh_labh',
    title: 'Shubh Labh Ganapati Mantra',
    titleHi: 'शुभ लाभ गणपति मंत्र',
    titleMr: 'शुभ लाभ गणपती मंत्र',
    deity: 'Lord Ganesha',
    deityHi: 'श्री गणेश',
    deityMr: 'श्री गणेश',
    singer: 'Traditional',
    tags: const ['Mantra', 'Ganesha', 'Shubh Labh'],
    youtubeVideoId: 'axfnRoqsHgg',
    durationText: '4:10',
    accentColorHex: '#E65100',
    deityEmoji: '🙏',
    aboutMr: 'सौभाग्य, ऋद्धी-सिद्धी आणि व्यापार-व्यवसायात शुभ-लाभ प्रदान करणारा महागणपती मंत्र.',
    aboutHi: 'सौभाग्य, समृद्धि और व्यापार में शुभ-लाभ प्रदान करने वाला श्री गणेश का सिद्ध मंत्र।',
    about: 'A potent mantra invoking Lord Ganesha for good fortune, prosperity, and continuous auspicious blessings.',
    lyrics: const [
      LyricStanza(
        startTimeMs: 0,
        devanagari: 'ॐ श्रीम गम सौभाग्य गणपतये ।\nवर्वर्द सर्वजन्म में वषमान्य नमः ॥',
        transliteration: 'Om Shreem Gam Saubhagya Ganpataye |\nVarvarda Sarvajanma Mein Vashamanya Namah ||',
      ),
    ],
  ),

  AartiItem(
    id: 'mantra_ganesh_gayatri',
    title: 'Ganesha Gayatri Mantra',
    titleHi: 'श्री गणेश गायत्री मंत्र',
    titleMr: 'श्री गणेश गायत्री मंत्र',
    deity: 'Lord Ganesha',
    deityHi: 'श्री गणेश',
    deityMr: 'श्री गणेश',
    singer: 'Traditional',
    tags: const ['Mantra', 'Ganesha', 'Gayatri'],
    youtubeVideoId: 'dkVlpm1mKFI',
    durationText: '5:20',
    accentColorHex: '#E65100',
    deityEmoji: '🙏',
    aboutMr: 'बुद्धीची एकाग्रता, आत्मज्ञान आणि सर्व विघ्नांच्या समापनासाठी भगवान गणेशांचा गायत्री मंत्र.',
    aboutHi: 'सद्बुद्धि, मेधा शक्ति और आत्म-विकास प्रदान करने वाला श्री गणेश का दिव्य गायत्री मंत्र।',
    about: 'The sacred Gayatri mantra dedicated to the elephant-headed deity for higher intellect and spiritual clarity.',
    lyrics: const [
      LyricStanza(
        startTimeMs: 0,
        devanagari: 'ॐ एकदन्ताय विद्महे, वक्रतुण्डाय धीमहि ।\nतन्नो दन्ति प्रचोदयात् ॥',
        transliteration: 'Om Ekadantaya Viddhamahe, Vakratundaya Dhimahi |\nTanno Danti Prachodayat ||',
      ),
    ],
  ),

  AartiItem(
    id: 'mantra_ganesh_maha_moola',
    title: 'Maha Ganapati Moola Mantra',
    titleHi: 'महागणपति मूल मंत्र',
    titleMr: 'महागणपती मूळ मंत्र',
    deity: 'Lord Ganesha',
    deityHi: 'श्री गणेश',
    deityMr: 'श्री गणेश',
    singer: 'Traditional',
    tags: const ['Mantra', 'Ganesha', 'Moola Mantra'],
    youtubeVideoId: '3uYZWsgo8bY',
    durationText: '6:15',
    accentColorHex: '#E65100',
    deityEmoji: '🙏',
    aboutMr: 'महागणपतींचा अष्टाविंशत्यक्षर सिद्ध मूलमंत्र जो सर्व सिद्धि आणि मनोकामना पूर्ण करतो.',
    aboutHi: 'समस्त कामनाओं और सिद्धियों को प्रदान करने वाला भगवान महागणपति का सिद्ध मूल मंत्र।',
    about: 'The potent 28-syllable root mantra of Maha Ganapati granting supreme fulfillment and protection.',
    lyrics: const [
      LyricStanza(
        startTimeMs: 0,
        devanagari: 'ॐ श्रीं ह्रीं क्लीं ग्लौं गं गणपतये\nवर वरद सर्वजनं मे वशमानय स्वाहा ॥',
        transliteration: 'Om Shrim Hrim Klim Glaum Gam Ganapataye\nVara Varada Sarvajanam Me Vashamanaya Svaha ||',
      ),
    ],
  ),

  AartiItem(
    id: 'mantra_ganesh_rinharta',
    title: 'Rinharta Ganapati Mantra',
    titleHi: 'ऋणहर्ता गणपति मंत्र',
    titleMr: 'ऋणहर्ता गणपती मंत्र',
    deity: 'Lord Ganesha',
    deityHi: 'श्री गणेश',
    deityMr: 'श्री गणेश',
    singer: 'Traditional',
    tags: const ['Mantra', 'Ganesha', 'Rinharta'],
    youtubeVideoId: 'boSeruDq6WQ',
    durationText: '4:40',
    accentColorHex: '#E65100',
    deityEmoji: '🙏',
    aboutMr: 'आर्थिक अडथळे, दारिद्र्य आणि सर्व प्रकारच्या ऋणांतून मुक्ती देणारा ऋणहर्ता गणेश मंत्र.',
    aboutHi: 'आर्थिक संकटों, ऋण और दरिद्रता से मुक्ति दिलाने वाला चमत्कारी ऋणहर्ता गणेश मंत्र।',
    about: 'The powerful debt-clearing and obstacle-severing mantra dedicated to Rinharta Ganapati.',
    lyrics: const [
      LyricStanza(
        startTimeMs: 0,
        devanagari: 'ॐ गणेश ऋणं छिन्धि वरेण्यं हुं नमः फट् ॥',
        transliteration: 'Om Ganesha Rinam Chhindhi Varenyam Hum Namah Phat ||',
      ),
    ],
  ),

  AartiItem(
    id: 'mantra_ganesh_haridra',
    title: 'Haridra Ganapati Mantra',
    titleHi: 'हरिद्रा गणपति मंत्र',
    titleMr: 'हरिद्रा गणपती मंत्र',
    deity: 'Lord Ganesha',
    deityHi: 'श्री गणेश',
    deityMr: 'श्री गणेश',
    singer: 'Traditional',
    tags: const ['Mantra', 'Ganesha', 'Haridra'],
    youtubeVideoId: 'qIMVoWHcFXc',
    durationText: '5:00',
    accentColorHex: '#E65100',
    deityEmoji: '🙏',
    aboutMr: 'पीतवर्णी हरिद्रा गणपतींचा हा मंत्र रोग, शत्रू आणि सर्व प्रकारच्या संकटांवर विजय मिळवून देतो.',
    aboutHi: 'हरिद्रा (हल्दी) गणपति का यह पावन मंत्र आकर्षण, विजय और संकट-निवारण प्रदान करता है।',
    about: 'The sacred golden-hued Haridra Ganapati mantra for protection, pacification of negativity, and wish fulfillment.',
    lyrics: const [
      LyricStanza(
        startTimeMs: 0,
        devanagari: 'ॐ हुं गं ग्लौं हरिद्रा गणपतये वर वरद\nसर्व जन हृदयं स्तम्भय-स्तम्भय स्वाहा ॥',
        transliteration: 'Om Hum Gam Glaum Haridra Ganapataye Vara Varada\nSarva Jana Hridayam Stambhaya-Stambhaya Svaha ||',
      ),
    ],
  ),

  AartiItem(
    id: 'mantra_ganesh_heramba',
    title: 'Heramba Ganapati Mantra',
    titleHi: 'हेरम्ब गणपति मंत्र',
    titleMr: 'हेरंब गणपती मंत्र',
    deity: 'Lord Ganesha',
    deityHi: 'श्री गणेश',
    deityMr: 'श्री गणेश',
    singer: 'Traditional',
    tags: const ['Mantra', 'Ganesha', 'Heramba'],
    youtubeVideoId: 'wKKIhwERzBE',
    durationText: '4:50',
    accentColorHex: '#E65100',
    deityEmoji: '🙏',
    aboutMr: 'पंचमुखी हेरंब गणपतींचा हा मंत्र महासंकटांचे त्वरित निवारण करून अभय प्रदान करतो.',
    aboutHi: 'पंचमुखी हेरम्ब गणपति का यह सिद्ध मंत्र समस्त घोर संकटों का निवारण कर सुरक्षा प्रदान करता है।',
    about: 'Invoking the five-faced protector form of Ganesha to dissipate acute distress and grant fearlessness.',
    lyrics: const [
      LyricStanza(
        startTimeMs: 0,
        devanagari: 'ॐ नमो हेरम्ब मदमोहितमम सङ्कटान् निवारय निवारय स्वाहा ॥',
        transliteration: 'Om Namo Heramba MadamohitaMama Sankatan Nivaraya Nivaraya Svaha ||',
      ),
    ],
  ),

  AartiItem(
    id: 'mantra_ganesh_ekakshari',
    title: 'Ganesha Ekakshari Mantra',
    titleHi: 'गणेश एकाक्षरी मंत्र',
    titleMr: 'गणेश एकाक्षरी मंत्र',
    deity: 'Lord Ganesha',
    deityHi: 'श्री गणेश',
    deityMr: 'श्री गणेश',
    singer: 'Traditional',
    tags: const ['Mantra', 'Ganesha', 'Beej Mantra'],
    youtubeVideoId: 'Qm5m6nMOB0Y',
    durationText: '3:30',
    accentColorHex: '#E65100',
    deityEmoji: '🙏',
    aboutMr: '\'गं\' हे गणेशांचे एकाक्षरी परम बीजमंत्र असून अथांग शक्ती व त्वरित फल देणारे मानले जाते.',
    aboutHi: '\'गं\' भगवान गणेश का एकाक्षर बीज मंत्र है जो अत्यंत सूक्ष्म, तेजस्वी एवं शीघ्र फलदायक है।',
    about: 'The single-syllable primordial seed sound \'Gam\' embodying the full conscious power of Lord Ganesha.',
    lyrics: const [
      LyricStanza(
        startTimeMs: 0,
        devanagari: 'गं ॥',
        transliteration: 'Gam ||',
      ),
    ],
  ),

  AartiItem(
    id: 'mantra_ganesh_shadakshara',
    title: 'Ganesha Shadakshara Mantra',
    titleHi: 'गणेश षडाक्षरा मंत्र',
    titleMr: 'गणेश षडाक्षरी मंत्र',
    deity: 'Lord Ganesha',
    deityHi: 'श्री गणेश',
    deityMr: 'श्री गणेश',
    singer: 'Traditional',
    tags: const ['Mantra', 'Ganesha', 'Shadakshara'],
    youtubeVideoId: 'cidhzMLBUPQ',
    durationText: '4:15',
    accentColorHex: '#E65100',
    deityEmoji: '🙏',
    aboutMr: 'सहा अक्षरांचा हा प्रभावशाली मंत्र सर्व दुष्ट शक्तींचा नाश करून कार्यसिद्धी घडवून आणतो.',
    aboutHi: 'छह अक्षरों का यह तेजस्वी मंत्र नकारात्मक शक्तियों का शमन कर अभीष्ट सिद्धि देता है।',
    about: 'The six-syllable protective mantra invoking the curved-trunk aspect of Ganesha with the powerful Hum beeja.',
    lyrics: const [
      LyricStanza(
        startTimeMs: 0,
        devanagari: 'ॐ वक्रतुण्डाय हुम् ॥',
        transliteration: 'Om Vakratundaya Hum ||',
      ),
    ],
  ),

  AartiItem(
    id: 'mantra_ganesh_ashtakshara',
    title: 'Ganesha Ashtakshara Mantra',
    titleHi: 'गणेश अष्टाक्षरा मंत्र',
    titleMr: 'गणेश अष्टाक्षरी मंत्र',
    deity: 'Lord Ganesha',
    deityHi: 'श्री गणेश',
    deityMr: 'श्री गणेश',
    singer: 'Traditional',
    tags: const ['Mantra', 'Ganesha', 'Ashtakshara'],
    youtubeVideoId: 'CdJVxS1FJ8w',
    durationText: '4:30',
    accentColorHex: '#E65100',
    deityEmoji: '🙏',
    aboutMr: 'अष्टाक्षरी महामंत्र जो कोट्यवधी भक्तांचे नित्य कल्याण करतो आणि सर्व सिद्धी देतो.',
    aboutHi: 'सर्वाधिक लोकप्रिय एवं सिद्ध अष्टाक्षर मंत्र जो समस्त बाधाओं को दूर कर अनंत सुख-शांति देता है।',
    about: 'The timeless, revered eight-syllable salutation to Lord Ganapati universally chanted for all auspicious beginnings.',
    lyrics: const [
      LyricStanza(
        startTimeMs: 0,
        devanagari: 'ॐ गं गणपतये नमः ॥',
        transliteration: 'Om Gam Ganapataye Namah ||',
      ),
    ],
  ),

  AartiItem(
    id: 'mantra_ganesh_kshipra_prasada',
    title: 'Kshipra Prasada Ganapati Mantra',
    titleHi: 'क्षिप्रप्रसाद गणपति मंत्र',
    titleMr: 'क्षिप्रप्रसाद गणपती मंत्र',
    deity: 'Lord Ganesha',
    deityHi: 'श्री गणेश',
    deityMr: 'श्री गणेश',
    singer: 'Traditional',
    tags: const ['Mantra', 'Ganesha', 'Kshipra Prasada'],
    youtubeVideoId: 'DnUlrEsUeN0',
    durationText: '3:50',
    accentColorHex: '#E65100',
    deityEmoji: '🙏',
    aboutMr: 'अत्यंत तत्परतेने आणि शीघ्रतेने प्रसन्न होऊन संकटे दूर करणारा क्षिप्रप्रसाद मंत्र.',
    aboutHi: 'अतिशीघ्र प्रसन्न होकर मनोवांछित फल देने वाले क्षिप्रप्रसाद गणपति का सिद्ध मंत्र।',
    about: 'A sacred invocation to Kshipra Prasada Ganapati, celebrated for swift blessings and instantaneous grace.',
    lyrics: const [
      LyricStanza(
        startTimeMs: 0,
        devanagari: 'गं क्षिप्रप्रसादनाय नमः ॥',
        transliteration: 'Gam Kshipraprasadanaya Namah ||',
      ),
    ],
  ),

  AartiItem(
    id: 'chalisa_ganesh',
    title: 'Shri Ganesha Chalisa',
    titleHi: 'श्री गणेश चालीसा',
    titleMr: 'श्री गणेश चालीसा',
    deity: 'Lord Ganesha',
    deityHi: 'श्री गणेश',
    deityMr: 'श्री गणेश',
    singer: 'Traditional',
    tags: const ['Chalisa', 'Ganesha', 'Popular'],
    youtubeVideoId: 'WyHFSjN0miU',
    durationText: '9:30',
    accentColorHex: '#E65100',
    deityEmoji: '🙏',
    aboutMr: 'श्री गणेश चालीसा हे भगवान श्री गणेशांचे नित्य पठणासाठी अत्यंत लोकप्रिय व सर्व विघ्न हरणारे ४० चौपायांचे स्तोत्र आहे.',
    aboutHi: 'श्री गणेश चालीसा भगवान श्री गणेश का परम मंगलकारी एवं समस्त विघ्नों का नाश करने वाला ४० चौपाइयों का पावन स्तुति पाठ है।',
    about: 'Shri Ganesha Chalisa is a sacred 40-verse hymn in praise of Lord Ganesha, dispelling obstacles and bestowing wisdom, prosperity, and peace.',
    lyrics: const [
      LyricStanza(
        startTimeMs: 0,
        devanagari: '॥ दोहा ॥\nजय गणपति सदगुण सदन, कविवर बदन कृपाल ।\nविघ्न हरण मंगल करण, जय जय गिरिजालाल ॥',
        transliteration: '|| Doha ||\nJaya Ganapati Sadguna Sadana, Kavivara Badana Kripala |\nVighna Harana Mangala Karana, Jaya Jaya Girijalala ||',
      ),
      LyricStanza(
        startTimeMs: 25000,
        devanagari: '॥ चौपाई ॥\nजय जय जय गणपति गणराजू । मंगल भरण करण शुभः काजू ॥\nजै गजबदन सदन सुखदाता । विश्व विनायका बुद्धि विधाता ॥',
        transliteration: '|| Chaupai ||\nJaya Jaya Jaya Ganapati Ganaraju | Mangala Bharana Karana Shubha Kaju ||\nJai Gajabadana Sadana Sukhadata | Vishva Vinayaka Buddhi Vidhata ||',
      ),
      LyricStanza(
        startTimeMs: 50000,
        devanagari: 'वक्र तुण्ड शुची शुण्ड सुहावना । तिलक त्रिपुण्ड भाल मन भावन ॥\nराजत मणि मुक्तन उर माला । स्वर्ण मुकुट शिर नयन विशाला ॥',
        transliteration: 'Vakra Tunda Shuchi Shunda Suhavana | Tilaka Tripunda Bhala Mana Bhavana ||\nRajata Mani Muktana Ura Mala | Svarna Mukuta Shira Nayana Vishala ||',
      ),
      LyricStanza(
        startTimeMs: 75000,
        devanagari: 'पुस्तक पाणि कुठार त्रिशूलं । मोदक भोग सुगन्धित फूलं ॥\nसुन्दर पीताम्बर तन साजित । चरण पादुका मुनि मन राजित ॥',
        transliteration: 'Pustaka Pani Kuthara Trishulam | Modaka Bhoga Sugandhita Phulam ||\nSundara Pitambara Tana Sajita | Charana Paduka Muni Mana Rajita ||',
      ),
      LyricStanza(
        startTimeMs: 100000,
        devanagari: 'धनि शिव सुवन षडानन भ्राता । गौरी लालन विश्व-विख्याता ॥\nऋद्धि-सिद्धि तव चंवर सुधारे । मुषक वाहन सोहत द्वारे ॥',
        transliteration: 'Dhani Shiva Suvana Shadanana Bhrata | Gauri Lalana Vishva-Vikhyata ||\nRiddhi-Siddhi Tava Chamvara Sudhare | Mushaka Vahana Sohata Dvare ||',
      ),
      LyricStanza(
        startTimeMs: 125000,
        devanagari: 'कहौ जन्म शुभ कथा तुम्हारी । अति शुची पावन मंगलकारी ॥\nएक समय गिरिराज कुमारी । पुत्र हेतु तप कीन्हा भारी ॥',
        transliteration: 'Kahau Janma Shubha Katha Tumhari | Ati Shuchi Pavana Mangalakari ||\nEka Samaya Giriraja Kumari | Putra Hetu Tapa Kinha Bhari ||',
      ),
      LyricStanza(
        startTimeMs: 150000,
        devanagari: 'भयो यज्ञ जब पूर्ण अनूपा । तब पहुंच्यो तुम धरी द्विज रूपा ॥\nअतिथि जानी के गौरी सुखारी । बहुविधि सेवा करी तुम्हारी ॥',
        transliteration: 'Bhayo Yajna Jaba Purna Anupa | Taba Pahunchyo Tuma Dhari Dvija Rupa ||\nAtithi Jani Ke Gauri Sukhari | Bahuvidhi Seva Kari Tumhari ||',
      ),
      LyricStanza(
        startTimeMs: 175000,
        devanagari: 'अति प्रसन्न हवै तुम वर दीन्हा । मातु पुत्र हित जो तप कीन्हा ॥\nमिलहि पुत्र तुहि, बुद्धि विशाला । बिना गर्भ धारण यहि काला ॥',
        transliteration: 'Ati Prasanna Havai Tuma Vara Dinha | Matu Putra Hita Jo Tapa Kinha ||\nMilahi Putra Tuhi, Buddhi Vishala | Bina Garbha Dharana Yahi Kala ||',
      ),
      LyricStanza(
        startTimeMs: 200000,
        devanagari: 'गणनायक गुण ज्ञान निधाना । पूजित प्रथम रूप भगवाना ॥\nअस कही अन्तर्धान रूप हवै । पालना पर बालक स्वरूप हवै ॥',
        transliteration: 'Gananayaka Guna Gyana Nidhana | Pujita Prathama Rupa Bhagavana ||\nAsa Kahi Antardhana Rupa Havai | Palana Para Balaka Svarupa Havai ||',
      ),
      LyricStanza(
        startTimeMs: 225000,
        devanagari: 'बनि शिशु रुदन जबहिं तुम ठाना । लखि मुख सुख नहिं गौरी समाना ॥\nसकल मगन, सुखमंगल गावहिं । नाभ ते सुरन, सुमन वर्षावहिं ॥',
        transliteration: 'Bani Shishu Rudana Jabahin Tuma Thana | Lakhi Mukha Sukha Nahin Gauri Samana ||\nSakala Magana, Sukhamangala Gavahin | Nabha Te Surana, Sumana Varshavahin ||',
      ),
      LyricStanza(
        startTimeMs: 250000,
        devanagari: 'शम्भु, उमा, बहुदान लुटावहिं । सुर मुनिजन, सुत देखन आवहिं ॥\nलखि अति आनन्द मंगल साजा । देखन भी आये शनि राजा ॥',
        transliteration: 'Shambhu, Uma, Bahudana Lutavahin | Sura Munijana, Suta Dekhana Aavahin ||\nLakhi Ati Aananda Mangala Saja | Dekhana Bhi Aaye Shani Raja ||',
      ),
      LyricStanza(
        startTimeMs: 275000,
        devanagari: 'निज अवगुण गुनि शनि मन माहीं । बालक, देखन चाहत नाहीं ॥\nगिरिजा कछु मन भेद बढायो । उत्सव मोर, न शनि तुही भायो ॥',
        transliteration: 'Nija Avaguna Guni Shani Mana Mahin | Balaka, Dekhana Chahata Nahin ||\nGirija Kachhu Mana Bheda Badhayo | Utsava Mora, Na Shani Tuhi Bhayo ||',
      ),
      LyricStanza(
        startTimeMs: 300000,
        devanagari: 'कहत लगे शनि, मन सकुचाई । का करिहौ, शिशु मोहि दिखाई ॥\nनहिं विश्वास, उमा उर भयऊ । शनि सों बालक देखन कहयऊ ॥',
        transliteration: 'Kahata Lage Shani, Mana Sakuchai | Ka Karihau, Shishu Mohi Dikhai ||\nNahin Vishvasa, Uma Ura Bhayau | Shani Son Balaka Dekhana Kahayau ||',
      ),
      LyricStanza(
        startTimeMs: 325000,
        devanagari: 'पदतहिं शनि दृग कोण प्रकाशा । बालक सिर उड़ि गयो अकाशा ॥\nगिरिजा गिरी विकल हवै धरणी । सो दुःख दशा गयो नहीं वरणी ॥',
        transliteration: 'Padatahin Shani Driga Kona Prakasha | Balaka Sira Uri Gayo Akasha ||\nGirija Giri Vikala Havai Dharani | So Duhkha Dasha Gayo Nahin Varani ||',
      ),
      LyricStanza(
        startTimeMs: 350000,
        devanagari: 'हाहाकार मच्यौ कैलाशा । शनि कीन्हों लखि सुत को नाशा ॥\nतुरत गरुड़ चढ़ि विष्णु सिधायो । काटी चक्र सो गज सिर लाये ॥',
        transliteration: 'Hahakara Machyau Kailasha | Shani Kinho Lakhi Suta Ko Nasha ||\nTurata Garuda Chadhi Vishnu Sidhayo | Kati Chakra So Gaja Sira Laye ||',
      ),
      LyricStanza(
        startTimeMs: 375000,
        devanagari: 'बालक के धड़ ऊपर धारयो । प्राण मन्त्र पढ़ि शंकर डारयो ॥\nनाम गणेश शम्भु तब कीन्हे । प्रथम पूज्य बुद्धि निधि, वर दीन्हे ॥',
        transliteration: 'Balaka Ke Dhada Upara Dharayo | Prana Mantra Padhi Shankara Darayo ||\nNama Ganesha Shambhu Taba Kinhe | Prathama Pujya Buddhi Nidhi, Vara Dinhe ||',
      ),
      LyricStanza(
        startTimeMs: 400000,
        devanagari: 'बुद्धि परीक्षा जब शिव कीन्हा । पृथ्वी कर प्रदक्षिणा लीन्हा ॥\nचले षडानन, भरमि भुलाई । रचे बैठ तुम बुद्धि उपाई ॥',
        transliteration: 'Buddhi Pariksha Jaba Shiva Kinha | Prithvi Kara Pradakshina Linha ||\nChale Shadanana, Bharami Bhulai | Rache Baitha Tuma Buddhi Upai ||',
      ),
      LyricStanza(
        startTimeMs: 425000,
        devanagari: 'चरण मातु-पितु के धर लीन्हें । तिनके सात प्रदक्षिण कीन्हें ॥\nधनि गणेश कही शिव हिये हरषे । नभ ते सुरन सुमन बहु बरसे ॥',
        transliteration: 'Charana Matu-Pitu Ke Dhara Linhen | Tinake Sata Pradakshina Kinhen ||\nDhani Ganesha Kahi Shiva Hiye Harashe | Nabha Te Surana Sumana Bahu Barase ||',
      ),
      LyricStanza(
        startTimeMs: 450000,
        devanagari: 'तुम्हरी महिमा बुद्धि बड़ाई । शेष सहसमुख सके न गाई ॥\nमैं मतिहीन मलीन दुखारी । करहूं कौन विधि विनय तुम्हारी ॥',
        transliteration: 'Tumhari Mahima Buddhi Badai | Shesha Sahasamukha Sake Na Gai ||\nMain Matihin Malina Dukhari | Karahun Kauna Vidhi Vinaya Tumhari ||',
      ),
      LyricStanza(
        startTimeMs: 475000,
        devanagari: 'भजत रामसुन्दर प्रभुदासा । जग प्रयाग, ककरा, दुर्वासा ॥\nअब प्रभु दया दीना पर कीजै । अपनी शक्ति भक्ति कुछ दीजै ॥',
        transliteration: 'Bhajata Ramasundara Prabhudasa | Jaga Prayaga, Kakara, Durvasa ||\nAba Prabhu Daya Dina Para Kijai | Apani Shakti Bhakti Kuchha Dijai ||',
      ),
      LyricStanza(
        startTimeMs: 500000,
        devanagari: '॥ दोहा ॥\nश्री गणेश यह चालीसा, पाठ करै कर ध्यान ।\nनित नव मंगल गृह बसै, लहे जगत सन्मान ॥\n\nसम्बन्ध अपने सहस्र दश, ऋषि पंचमी दिनेश ।\nपूरण चालीसा भयो, मंगल मूर्ती गणेश ॥',
        transliteration: '|| Doha ||\nShri Ganesha Yaha Chalisa, Patha Karai Kara Dhyana |\nNita Nava Mangala Griha Basai, Lahe Jagata Sanmana ||\n\nSambandha Apane Sahasra Dasha, Rishi Panchami Dinesha |\nPurana Chalisa Bhayo, Mangala Murti Ganesha ||',
      ),
    ],
  ),
];
