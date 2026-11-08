import '../../domain/entities/aarti_item.dart';
import '../../domain/entities/lyric_stanza.dart';
import 'bhajan_catalog.dart';
import 'catalog.dart';

/// Aartis, chalisas, mantras and stotras for the Gujarat temple deities
/// (Somnath, Dwarkadhish, Ambaji, Khodiyar, ...) shown in the Bhakti darshan.
final List<AartiItem> kGujaratiDeitiesCatalog = [
  for (final entry in _deityVideos.entries)
    for (final videoKey in entry.value)
      _buildItem(entry.key, _deities[entry.key]!, videoKey, _videos[videoKey]!),
];

AartiItem _buildItem(String deityKey, _GujDeity deity, String videoKey, _GujVideo video) {
  final slug = deityKey.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');
  return AartiItem(
    id: 'guj_${slug}_$videoKey',
    title: video.title,
    titleHi: video.titleHi,
    titleMr: video.titleHi,
    deity: deityKey,
    deityHi: deity.nameHi,
    deityMr: deity.nameMr,
    singer: video.singer,
    tags: video.tags,
    youtubeVideoId: video.videoId,
    durationText: '5:00',
    accentColorHex: deity.accentColorHex,
    deityEmoji: deity.emoji,
    about: '${video.title} — devotion to $deityKey.',
    aboutHi: '${video.titleHi} — ${deity.nameHi} की भक्ति।',
    aboutMr: '${video.titleHi} — ${deity.nameMr} यांची भक्ती.',
    lyrics: video.lyricsFromId != null
        ? _lyricsOf(video.lyricsFromId!)
        : [
            LyricStanza(
              startTimeMs: 0,
              devanagari: video.devanagari,
              transliteration: video.transliteration,
            ),
          ],
  );
}

List<LyricStanza> _lyricsOf(String id) =>
    kDevotionalCatalog.followedBy(kBhajanCatalog).firstWhere((i) => i.id == id).lyrics;

class _GujDeity {
  final String nameHi;
  final String nameMr;
  final String accentColorHex;
  final String emoji;

  const _GujDeity(this.nameHi, this.nameMr, this.accentColorHex, this.emoji);
}

class _GujVideo {
  final String videoId;
  final String title;
  final String titleHi;
  final String singer;
  final List<String> tags;

  /// Reuse the lyrics of an existing catalog item with this id.
  final String? lyricsFromId;
  final String devanagari;
  final String transliteration;

  const _GujVideo(
    this.videoId,
    this.title,
    this.titleHi,
    this.singer,
    this.tags, {
    this.lyricsFromId,
    this.devanagari = '',
    this.transliteration = '',
  });
}

const _shiv = '#1565C0';
const _krishna = '#0D47A1';
const _mata = '#C62828';

const Map<String, _GujDeity> _deities = {
  'Somnath Mahadev': _GujDeity('सोमनाथ महादेव', 'सोमनाथ महादेव', _shiv, '🔱'),
  'Nageshwar Mahadev': _GujDeity('नागेश्वर महादेव', 'नागेश्वर महादेव', _shiv, '🔱'),
  'Bhadreshwar Mahadev': _GujDeity('भद्रेश्वर महादेव', 'भद्रेश्वर महादेव', _shiv, '🔱'),
  'Dwarkadhish': _GujDeity('श्री द्वारकाधीश', 'श्री द्वारकाधीश', _krishna, '🦚'),
  'Ranchhodrai': _GujDeity('श्री रणछोड़राय', 'श्री रणछोडराय', _krishna, '🦚'),
  'Ranchhodji': _GujDeity('श्री रणछोड़जी', 'श्री रणछोडजी', _krishna, '🦚'),
  'Bhalka Tirth Krishna': _GujDeity('भालका तीर्थ श्रीकृष्ण', 'भालका तीर्थ श्रीकृष्ण', _krishna, '🦚'),
  'Shamlaji': _GujDeity('श्री शामलाजी', 'श्री शामळाजी', _krishna, '🦚'),
  'Ambaji': _GujDeity('अंबाजी माता', 'अंबाजी माता', _mata, '🌺'),
  'Pavagadh Mahakali': _GujDeity('पावागढ़ महाकाली', 'पावागड महाकाली', _mata, '🌺'),
  'Chamunda Mata': _GujDeity('चामुंडा माता', 'चामुंडा माता', _mata, '🌺'),
  'Bahuchar Mata': _GujDeity('बहुचर माता', 'बहुचर माता', _mata, '🌺'),
  'Khodiyar Mata': _GujDeity('खोडियार माता', 'खोडियार माता', _mata, '🌺'),
  'Ashapura Mata': _GujDeity('आशापुरा माता', 'आशापुरा माता', _mata, '🌺'),
  'Meldi Mata': _GujDeity('मेलडी माता', 'मेलडी माता', _mata, '🌺'),
  'Momai Mata': _GujDeity('मोमाई माता', 'मोमाई माता', _mata, '🌺'),
  'Harsiddhi Mata': _GujDeity('हरसिद्धि माता', 'हरसिद्धी माता', _mata, '🌺'),
  'Umiya Mata': _GujDeity('उमिया माता', 'उमिया माता', _mata, '🌺'),
  'Swaminarayan': _GujDeity('भगवान स्वामिनारायण', 'भगवान स्वामिनारायण', '#AD1457', '🙏'),
  'Mahudi Ghantakarna Mahavir': _GujDeity('महुडी घंटाकर्ण महावीर', 'महुडी घंटाकर्ण महावीर', '#E65100', '🔔'),
};

const _shivVideos = [
  'shiv_aarti',
  'shiv_chalisa',
  'om_namah_shivaya',
  'mahamrityunjaya',
  'lingashtakam',
  'shiv_tandav',
  'rudrashtakam',
  'panchakshara',
];

const _krishnaVideos = [
  'kunj_bihari',
  'krishna_chalisa',
  'vasudevaya',
  'madhurashtakam',
  'achyutashtakam',
  'krishnashtakam',
];

const _mataVideos = [
  'durga_chalisa',
  'chamunda_mantra',
  'vishwambhari_stuti',
  'argala_stotram',
];

const Map<String, List<String>> _deityVideos = {
  'Somnath Mahadev': [..._shivVideos, 'somnath_bholiya'],
  'Nageshwar Mahadev': _shivVideos,
  'Bhadreshwar Mahadev': _shivVideos,
  'Dwarkadhish': _krishnaVideos,
  'Ranchhodrai': [..._krishnaVideos, 'ranchhod_bavani'],
  'Ranchhodji': [..._krishnaVideos, 'ranchhod_bavani'],
  'Bhalka Tirth Krishna': _krishnaVideos,
  'Shamlaji': ['jagdish_hare', 'vishnu_chalisa', 'om_namo_narayanaya', 'vishnu_sahasranamam'],
  'Ambaji': ['jai_adhyashakti', ..._mataVideos],
  'Pavagadh Mahakali': [..._mataVideos, 'mahakali_chalisa'],
  'Chamunda Mata': [..._mataVideos, 'chamunda_aarti'],
  'Bahuchar Mata': ['bahuchar_aarti', 'bahuchar_stuti'],
  'Khodiyar Mata': ['khodiyar_aarti', 'khodiyar_stuti'],
  'Ashapura Mata': ['ashapura_aarti'],
  'Meldi Mata': ['meldi_aarti', 'meldi_stuti'],
  'Momai Mata': ['momai_aarti', 'momai_stuti', 'momai_dhun'],
  'Harsiddhi Mata': ['harsiddhi_aarti', 'harsiddhi_stuti', 'harsiddhi_dhun'],
  'Umiya Mata': ['umiya_aarti', 'umiya_chalisa'],
  'Swaminarayan': ['swaminarayan_aarti', 'swaminarayan_dhun'],
  'Mahudi Ghantakarna Mahavir': ['ghantakarna_aarti', 'ghantakarna_stotra', 'ghantakarna_chalisa'],
};

const _aarti = ['Aarti'];
const _chalisa = ['Chalisa'];
const _mantra = ['Mantra'];
const _stotra = ['Stotra'];
const _stuti = ['Stuti', 'Stotra'];

const Map<String, _GujVideo> _videos = {
  // ── Mahadev (Somnath / Nageshwar / Bhadreshwar) ─────────────────────────
  'shiv_aarti': _GujVideo('KM4r40jDaac', 'Om Jai Shiv Omkara (Shiv Aarti)', 'ॐ जय शिव ओंकारा (शिव आरती)', 'Tripti Shakya', _aarti,
      lyricsFromId: 'shiv_aarti'),
  'shiv_chalisa': _GujVideo('EOOm_mBLKLY', 'Shiv Chalisa', 'शिव चालीसा', 'Anuradha Paudwal', _chalisa),
  'om_namah_shivaya': _GujVideo('XEKmS2iZcRk', 'Om Namah Shivaya Dhun', 'ॐ नमः शिवाय धुन', 'Anuradha Paudwal', _mantra,
      devanagari: 'ॐ नमः शिवाय।', transliteration: 'Om Namah Shivaya.'),
  'mahamrityunjaya': _GujVideo('adyjwFgXRNY', 'Mahamrityunjaya Mantra (108 Times)', 'महामृत्युंजय मंत्र (108 बार)', 'Shankar Sahney', _mantra,
      devanagari: 'ॐ त्र्यम्बकं यजामहे सुगन्धिं पुष्टिवर्धनम्।\nउर्वारुकमिव बन्धनान्मृत्योर्मुक्षीय मामृतात्॥',
      transliteration: 'Om Tryambakam Yajamahe Sugandhim Pushtivardhanam,\nUrvarukamiva Bandhanan Mrityor Mukshiya Mamritat.'),
  'lingashtakam': _GujVideo('KyM9A258UwY', 'Lingashtakam', 'लिंगाष्टकम्', 'Pujya Rameshbhai Oza', _stotra),
  'shiv_tandav': _GujVideo('1I23gABHrnM', 'Shiva Tandava Stotram', 'शिव तांडव स्तोत्रम्', 'Uma Mohan', _stotra,
      lyricsFromId: 'stotra_shiv_tandav'),
  'rudrashtakam': _GujVideo('3eJTp3P1ZMQ', 'Shri Rudrashtakam (Namami Shamishan)', 'श्री रुद्राष्टकम् (नमामीशमीशान)', 'Meditation & Gyaan Manthann', _stotra),
  'panchakshara': _GujVideo('NHBJn0KxWbU', 'Shiva Panchakshara Stotram', 'शिव पंचाक्षर स्तोत्रम्', 'Anandmurti Gurumaa', _stotra),
  'somnath_bholiya': _GujVideo('2oUJGRxbCfc', 'Somnath Mahadev Bholiya (Shiv Aarti)', 'सोमनाथ महादेव भोळिया (शिव आरती)', 'Studio Sangeeta', _aarti),

  // ── Krishna (Dwarkadhish / Ranchhodrai / Ranchhodji / Bhalka Tirth) ─────
  'kunj_bihari': _GujVideo('EMO1AT1UQf0', 'Aarti Kunj Bihari Ki', 'आरती कुंज बिहारी की', 'Hariharan', _aarti,
      lyricsFromId: 'krishna_kunj_bihari'),
  'krishna_chalisa': _GujVideo('Q2ag5XCZVyc', 'Shri Krishna Chalisa', 'श्री कृष्ण चालीसा', 'Bhajan Shrinkhla', _chalisa),
  'vasudevaya': _GujVideo('wLTy-h4ArFE', 'Om Namo Bhagavate Vasudevaya (108 Times)', 'ॐ नमो भगवते वासुदेवाय (108 बार)', 'USP Devotional', _mantra,
      devanagari: 'ॐ नमो भगवते वासुदेवाय नमः।', transliteration: 'Om Namo Bhagavate Vasudevaya Namah.'),
  'madhurashtakam': _GujVideo('t_KcX_TTYcM', 'Madhurashtakam', 'मधुराष्टकम्', 'Sooryagayathri & Raghuram Manikandan', _stotra),
  'achyutashtakam': _GujVideo('W90FHJygVQw', 'Achyutashtakam', 'अच्युताष्टकम्', 'Vasundhara', _stotra),
  'krishnashtakam': _GujVideo('2ZWZ2DIZ4u4', 'Krishnashtakam (Vasudeva Sutam Devam)', 'कृष्णाष्टकम् (वसुदेव सुतं देवं)', 'Om Voices Junior', _stotra),
  'ranchhod_bavani': _GujVideo('nELD-UAZptI', 'Ranchhod Bavani', 'रणछोड़ बावनी', 'Ruchita Prajapati', _stuti),

  // ── Shamlaji (Vishnu) ───────────────────────────────────────────────────
  'jagdish_hare': _GujVideo('NE3SWh9_vR4', 'Om Jai Jagdish Hare', 'ॐ जय जगदीश हरे', 'Anuradha Paudwal', _aarti,
      lyricsFromId: 'vishnu_om_jai_jagdish_hare'),
  'vishnu_chalisa': _GujVideo('LdFA31_4izU', 'Shri Vishnu Chalisa', 'श्री विष्णु चालीसा', 'Anuradha Paudwal', _chalisa),
  'om_namo_narayanaya': _GujVideo('lW-niMLpAuw', 'Om Namo Narayanaya (108 Times)', 'ॐ नमो नारायणाय (108 बार)', 'Jothishi', _mantra,
      devanagari: 'ॐ नमो नारायणाय।', transliteration: 'Om Namo Narayanaya.'),
  'vishnu_sahasranamam': _GujVideo('HWneIeWd-Rg', 'Vishnu Sahasranamam', 'विष्णु सहस्रनाम', 'M. S. Subbulakshmi', _stotra),

  // ── Mataji (Ambaji / Pavagadh Mahakali / Chamunda) ──────────────────────
  'jai_adhyashakti': _GujVideo('JiTpnD20Elk', 'Jai Adhyashakti (Ambe Maa Aarti)', 'जय आद्यशक्ति (अंबे माँ आरती)', 'Rajshri Soul', _aarti),
  'durga_chalisa': _GujVideo('AXvmt88JLWg', 'Shri Durga Chalisa', 'श्री दुर्गा चालीसा', 'Anuradha Paudwal', _chalisa),
  'chamunda_mantra': _GujVideo('cdlS1XC3Gus', 'Om Aim Hrim Klim Chamundaye Vichche (108 Times)', 'ॐ ऐं ह्रीं क्लीं चामुण्डायै विच्चे (108 बार)', 'Anuradha Paudwal', _mantra,
      devanagari: 'ॐ ऐं ह्रीं क्लीं चामुण्डायै विच्चे।', transliteration: 'Om Aim Hrim Klim Chamundaye Vichche.'),
  'vishwambhari_stuti': _GujVideo('IU6k5cA9X94', 'Vishwambhari Stuti', 'विश्वंभरी स्तुति', 'Nova Spiritual India', _stuti),
  'argala_stotram': _GujVideo('nK4mQqTZ7P4', 'Argala Stotram', 'अर्गला स्तोत्रम्', 'Rajshri Soul', _stotra),
  'mahakali_chalisa': _GujVideo('2ndsi1hI4EE', 'Shree Mahakali Chalisa', 'श्री महाकाली चालीसा', 'Ruchita Prajapati', _chalisa),
  'chamunda_aarti': _GujVideo('pvUI3s91y_I', 'Chamunda Maa Ni Aarti', 'चामुंडा माँ नी आरती', 'Nova Gujarati', _aarti),

  // ── Gujarati Mataji ─────────────────────────────────────────────────────
  'bahuchar_aarti': _GujVideo('Tn1XZTZIafI', 'Bahuchar Maa Aarti (Khamma Khamma Re Bahuchar Maat)', 'बहुचर माँ आरती (खम्मा खम्मा रे बहुचर मात)', 'Studio Sangeeta', _aarti),
  'bahuchar_stuti': _GujVideo('U4iWbcWqFQ0', 'Bahuchar Maa Ni Stuti', 'बहुचर माँ नी स्तुति', 'Ruchita Prajapati', _stuti),
  'khodiyar_aarti': _GujVideo('qtTFR0OIE8Y', 'Jay Khodiyar Maa (Khodiyar Maa Ni Aarti)', 'जय खोडियार माँ (खोडियार माँ नी आरती)', 'Nova Gujarati', _aarti),
  'khodiyar_stuti': _GujVideo('ELNedIogu-Q', 'Khodiyar Maa Ni Stuti', 'खोडियार माँ नी स्तुति', 'Ruchita Prajapati', _stuti),
  'ashapura_aarti': _GujVideo('FlF9MJ-IG4U', 'Ashapura Mataji Aarti (Lakh Lakh Divla Ri)', 'आशापुरा माताजी आरती (लख लख दिवला री)', 'Shyam Paliwal', _aarti),
  'meldi_aarti': _GujVideo('WrNZlAhqpNE', 'Meldi Mata Ni Aarti', 'मेलडी माता नी आरती', 'Jyoti Vanjara', _aarti),
  'meldi_stuti': _GujVideo('pZ_Qp2e8QK8', 'Meldi Maa Ni Stuti', 'मेलडी माँ नी स्तुति', 'Ruchita Prajapati', _stuti),
  'momai_aarti': _GujVideo('vzHdO0Jcsk8', 'Momai Maa Ni Aarti', 'मोमाई माँ नी आरती', 'Jyoti Vanjara', _aarti),
  'momai_stuti': _GujVideo('Df9pA_R5SH8', 'Momai Maa Ni Stuti', 'मोमाई माँ नी स्तुति', 'Ruchita Prajapati', _stuti),
  'momai_dhun': _GujVideo('Kqcwt7jtLpc', 'Momai Maa Sharnam Mamah (Dhun)', 'मोमाई माँ शरणं मम (धुन)', 'Ruchita Prajapati', _mantra,
      devanagari: 'मोमाई माँ शरणं मम।', transliteration: 'Momai Maa Sharanam Mama.'),
  'harsiddhi_aarti': _GujVideo('RFYwdmaxE4U', 'Harsiddhi Mata Ni Aarti', 'हरसिद्धि माता नी आरती', 'Jyoti Vanjara', _aarti),
  'harsiddhi_stuti': _GujVideo('9-ErXqupZKs', 'Harsiddhi Maa Ni Stuti', 'हरसिद्धि माँ नी स्तुति', 'Ruchita Prajapati', _stuti),
  'harsiddhi_dhun': _GujVideo('JQqDVOvkRv0', 'Harsiddhi Maa Sharnam Mamah (Dhun)', 'हरसिद्धि माँ शरणं मम (धुन)', 'Ruchita Prajapati', _mantra,
      devanagari: 'हरसिद्धि माँ शरणं मम।', transliteration: 'Harsiddhi Maa Sharanam Mama.'),
  'umiya_aarti': _GujVideo('IMT9q2YYxnY', 'Umiya Maa Ni Aarti', 'उमिया माँ नी आरती', 'Jyoti Vanjara', _aarti),
  'umiya_chalisa': _GujVideo('bxamgoLWfJo', 'Maa Umiya Chalisa', 'माँ उमिया चालीसा', 'Radhe Krishna', _chalisa),

  // ── Swaminarayan ────────────────────────────────────────────────────────
  'swaminarayan_aarti': _GujVideo('z06iS-mh-R4', 'Swaminarayan Aarti', 'स्वामिनारायण आरती', 'Suprabha KV', _aarti),
  'swaminarayan_dhun': _GujVideo('HcXl_jGkGiM', 'Swaminarayan Dhun', 'स्वामिनारायण धुन', 'BAPS', _mantra,
      devanagari: 'स्वामिनारायण, स्वामिनारायण।', transliteration: 'Swaminarayan, Swaminarayan.'),

  // ── Mahudi Ghantakarna Mahavir ──────────────────────────────────────────
  'ghantakarna_aarti': _GujVideo('MA8h9zgNPcE', 'Ghantakarna Mahavir Gaaje (Aarti)', 'घंटाकर्ण महावीर गाजे (आरती)', 'Vishal', _aarti),
  'ghantakarna_stotra': _GujVideo('oR1C11vxzcI', 'Shri Ghantakarna Mahavir Stotra', 'श्री घंटाकर्ण महावीर स्तोत्र', 'Spread Jainism', _stotra),
  'ghantakarna_chalisa': _GujVideo('rcqh5H1tmMA', 'Shri Ghantakarna Chalisa', 'श्री घंटाकर्ण चालीसा', 'Shrenik Nahar', _chalisa),
};
