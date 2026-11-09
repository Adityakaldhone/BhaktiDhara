import '../../domain/entities/aarti_item.dart';
import '../../domain/entities/lyric_stanza.dart';
import 'regional_lyrics_catalog.dart';

/// Aartis, chalisas, mantras and stotras for the Rajasthan temple and folk
/// deities (Salasar Balaji, Shrinathji, Karni Mata, Ramdevji, ...) shown in
/// the Bhakti darshan.
final List<AartiItem> kRajasthaniDeitiesCatalog = [
  for (final row in _rows) _buildItem(row),
];

AartiItem _buildItem(_RjRow row) {
  final deity = _deities[row.deity]!;
  final slug = row.deity.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');
  final videoSlug = row.videoId.replaceAll(RegExp(r'[^A-Za-z0-9]'), '_');
  return AartiItem(
    id: 'rj_${slug}_$videoSlug',
    title: row.title,
    titleHi: row.titleHi,
    titleMr: row.titleHi,
    deity: row.deity,
    deityHi: deity.nameHi,
    deityMr: deity.nameMr,
    singer: row.singer,
    tags: row.tags,
    youtubeVideoId: row.videoId,
    durationText: '5:00',
    accentColorHex: deity.accentColorHex,
    deityEmoji: deity.emoji,
    about: '${row.title} — devotion to ${row.deity}.',
    aboutHi: '${row.titleHi} — ${deity.nameHi} की भक्ति।',
    aboutMr: '${row.titleHi} — ${deity.nameMr} यांची भक्ती.',
    lyrics: kRegionalLyricsByVideo[row.videoId] ??
        [
          LyricStanza(
            startTimeMs: 0,
            devanagari: row.devanagari,
            transliteration: row.transliteration,
          ),
        ],
  );
}

class _RjDeity {
  final String nameHi;
  final String nameMr;
  final String accentColorHex;
  final String emoji;

  const _RjDeity(this.nameHi, this.nameMr, this.accentColorHex, this.emoji);
}

class _RjRow {
  final String deity;
  final List<String> tags;
  final String title;
  final String titleHi;
  final String videoId;
  final String singer;
  final String devanagari;
  final String transliteration;

  const _RjRow(
    this.deity,
    this.tags,
    this.title,
    this.titleHi,
    this.videoId,
    this.singer, {
    this.devanagari = '',
    this.transliteration = '',
  });
}

const _balaji = '#E65100';
const _krishna = '#0D47A1';
const _shiv = '#1565C0';
const _mata = '#C62828';
const _lokdev = '#AD1457';

const Map<String, _RjDeity> _deities = {
  'Salasar Balaji': _RjDeity('सालासर बालाजी', 'सालासर बालाजी', _balaji, '🚩'),
  'Mehandipur Balaji': _RjDeity('मेहंदीपुर बालाजी', 'मेहंदीपूर बालाजी', _balaji, '🚩'),
  'Shrinathji': _RjDeity('श्रीनाथजी', 'श्रीनाथजी', _krishna, '🦚'),
  'Govind Dev Ji': _RjDeity('श्री गोविंद देव जी', 'श्री गोविंद देव जी', _krishna, '🦚'),
  'Charbhuja Nath': _RjDeity('चारभुजा नाथ', 'चारभुजा नाथ', _krishna, '🦚'),
  'Eklingji': _RjDeity('श्री एकलिंगजी', 'श्री एकलिंगजी', _shiv, '🔱'),
  'Brahma Ji': _RjDeity('ब्रह्मा जी', 'ब्रह्मदेव', '#F9A825', '🪷'),
  'Karni Mata': _RjDeity('करणी माता', 'करणी माता', _mata, '🌺'),
  'Jeen Mata': _RjDeity('जीण माता', 'जीण माता', _mata, '🌺'),
  'Kaila Devi': _RjDeity('कैला देवी', 'कैला देवी', _mata, '🌺'),
  'Ashapura Mata': _RjDeity('आशापुरा माता', 'आशापुरा माता', _mata, '🌺'),
  'Rani Sati Dadi': _RjDeity('राणी सती दादी', 'राणी सती दादी', _mata, '🌺'),
  'Tripura Sundari': _RjDeity('माँ त्रिपुर सुंदरी', 'त्रिपुरसुंदरी माता', _mata, '🌺'),
  'Gogaji': _RjDeity('गोगाजी (जाहरवीर)', 'गोगाजी (जाहरवीर)', _lokdev, '🐍'),
  'Tejaji': _RjDeity('वीर तेजाजी', 'वीर तेजाजी', _lokdev, '🐎'),
  'Pabuji': _RjDeity('पाबूजी राठौड़', 'पाबूजी राठोड', _lokdev, '🐎'),
  'Ramdevji': _RjDeity('बाबा रामदेवजी', 'बाबा रामदेवजी', _lokdev, '🐎'),
  'Devnarayan Ji': _RjDeity('देवनारायण जी', 'देवनारायण जी', _lokdev, '🐎'),
  'Mallinath Ji': _RjDeity('रावल मल्लीनाथ जी', 'रावल मल्लीनाथ जी', _lokdev, '🙏'),
};

const _aarti = ['Aarti'];
const _chalisa = ['Chalisa'];
const _mantra = ['Mantra'];
const _stotra = ['Stotra'];

const List<_RjRow> _rows = [
  // ── Salasar Balaji ──────────────────────────────────────────────────────
  _RjRow('Salasar Balaji', _aarti, 'Om Jai Hanumat Veera', 'ॐ जय हनुमत वीरा', 'TKPagwyhE1I', 'T-Series Bhakti Sagar'),
  _RjRow('Salasar Balaji', _aarti, 'Jag Mag Jag Mag Salasar Balaji Aarti', 'जग मग जग मग सालासर बालाजी आरती', '0FrdS21iQa8', 'RDC Rajasthani'),
  _RjRow('Salasar Balaji', _aarti, 'Jayati Jay Jai Bajrang Bala', 'जयति जय जय बजरंग बाला', 's6pSOZQWCY0', 'Sunil Sharma'),
  _RjRow('Salasar Balaji', _chalisa, 'Salasar Balaji Chalisa', 'सालासर बालाजी चालीसा', '_KahA1ZpSXw', 'Saral Puja'),
  _RjRow('Salasar Balaji', _stotra, 'Salasar Balaji Stuti', 'सालासर बालाजी स्तुति', 'BrrpALyAVKI', 'Shree Amarchand Dham, Sikar'),
  _RjRow('Salasar Balaji', _mantra, 'Om Shri Salasar Balaji Namah', 'ॐ श्री सालासर बालाजी नमः', 'sPUPL-Agh60', 'Bhakti Rang',
      devanagari: 'ॐ श्री सालासर बालाजी नमः।', transliteration: 'Om Shri Salasar Balaji Namah.'),

  // ── Shrinathji ──────────────────────────────────────────────────────────
  _RjRow('Shrinathji', _aarti, 'Aarti Shrinathji Ni Mangla Kari', 'आरती श्रीनाथजी नी मंगला करी', 'nL6guAGD-Mk', 'Soor Mandir'),
  _RjRow('Shrinathji', _aarti, 'Shrinathji Ni Sandhiya Aarti', 'श्रीनाथजी नी संध्या आरती', 'zXbEH-J-N-A', 'RDC Bhakti Sagar'),
  _RjRow('Shrinathji', _chalisa, 'Shrinathji Chalisa', 'श्रीनाथजी चालीसा', 'emYrDQ4PlWc', 'Nidhi Dhodakia & Bhaskar Shukla'),
  _RjRow('Shrinathji', _mantra, 'Shri Krishna Sharanam Mama', 'श्री कृष्ण शरणं मम', 'Pf6pPveoI9s', 'Sona Rupa',
      devanagari: 'श्रीकृष्णः शरणं मम।', transliteration: 'Shri Krishnah Sharanam Mama.'),
  _RjRow('Shrinathji', _mantra, 'Shreenathji Sharanam Mama', 'श्रीनाथजी शरणं मम', '6ZctKVSkjAQ', 'Music Centre',
      devanagari: 'श्रीनाथजी शरणं मम।', transliteration: 'Shrinathji Sharanam Mama.'),
  _RjRow('Shrinathji', _stotra, 'Krishnashraya Stotra', 'कृष्णाश्रय स्तोत्र', 'KY0PY-80tSA', 'Hiren Khakhi'),
  _RjRow('Shrinathji', _stotra, 'Pratah Smaranam', 'प्रातः स्मरणम्', 'mkZF5ur7-sc', 'Studio Shreenathji'),

  // ── Eklingji ────────────────────────────────────────────────────────────
  _RjRow('Eklingji', _aarti, 'Eklingji Aarti', 'एकलिंगजी आरती', 'Z5XdUPhTMAY', 'Arvind Pandya'),
  _RjRow('Eklingji', _stotra, 'Eklingji Stuti', 'एकलिंगजी स्तुति', 'b7labMcoXr4', 'Yogendra Pandya'),
  _RjRow('Eklingji', _stotra, 'Ekling Aravali Stavah', 'एकलिंग अरावली स्तवः', 'Boia7bAOCSo', 'Joshi Ashvinkumar'),
  _RjRow('Eklingji', _stotra, 'Devaih Krita Ekalinga Shiva Stuti', 'देवैः कृता एकलिङ्गशिवस्तुतिः', 'n18vLugnsFA', 'Sanatan Chetna'),
  _RjRow('Eklingji', _chalisa, 'Eklingji Mahadev Chalisa', 'एकलिंगजी महादेव चालीसा', 'HAHLGlsLsss', 'Amrit Bhakti Barsa'),
  _RjRow('Eklingji', _mantra, 'Eklingji Gayatri Mantra', 'एकलिंगजी गायत्री मंत्र', 'SJOxC8M9IKw', 'Dharmesh Joshi'),

  // ── Brahma Ji ───────────────────────────────────────────────────────────
  _RjRow('Brahma Ji', _aarti, 'Pitu Matu Sahayak Swami Sakha', 'पितु मातु सहायक स्वामी सखा', 'NIV3Zy16Ffw', 'Vrat Katha'),
  _RjRow('Brahma Ji', _chalisa, 'Brahma Chalisa', 'ब्रह्मा चालीसा', 'irvls6Fhczw', 'Kumar Vishu'),
  _RjRow('Brahma Ji', _mantra, 'Om Kham Brahma', 'ॐ खं ब्रह्म', 'ad9mNsOUUT8', 'OnlineBhajans',
      devanagari: 'ॐ खं ब्रह्म।', transliteration: 'Om Kham Brahma.'),
  _RjRow('Brahma Ji', _mantra, 'Om Brahmane Namah', 'ॐ ब्रह्मणे नमः', 'FWoRoBS5Y1Q', 'Chant Central',
      devanagari: 'ॐ ब्रह्मणे नमः।', transliteration: 'Om Brahmane Namah.'),
  _RjRow('Brahma Ji', _mantra, 'Brahma Gayatri Mantra', 'ब्रह्म गायत्री मंत्र', '26YcxRFtnME', 'Geethanjali'),
  _RjRow('Brahma Ji', _mantra, 'Om Brahma Devaya Namah', 'ॐ ब्रह्मदेवाय नमः', 'S_JzBXNTqpU', 'Pure Meditation',
      devanagari: 'ॐ ब्रह्मदेवाय नमः।', transliteration: 'Om Brahmadevaya Namah.'),
  _RjRow('Brahma Ji', _stotra, 'Brahma Stotram', 'ब्रह्म स्तोत्रम्', 'HQcSg42zkCA', 'Easy Treasure'),

  // ── Karni Mata ──────────────────────────────────────────────────────────
  _RjRow('Karni Mata', _aarti, 'Om Jai Ambe Karni', 'ॐ जय अंबे करणी', 'UrBBXSoACX0', 'Karni Music'),
  _RjRow('Karni Mata', _aarti, 'Shri Karunamay Kiniyan Ki Ye Aarti', 'श्री करुणामय किनियाँ की ये आरती', 'pD6r2p7LNp0', 'Karni Bhakti Sagar'),
  _RjRow('Karni Mata', _chalisa, 'Karni Chalisa', 'करणी चालीसा', 'Tfn4fOQDV5c', 'Jay Indresh'),
  _RjRow('Karni Mata', _mantra, 'Om Karni Namah', 'ॐ करणी नमः', 'VvJR1BNfJ1c', 'Nisha Bhura',
      devanagari: 'ॐ करणी नमः।', transliteration: 'Om Karni Namah.'),
  _RjRow('Karni Mata', _mantra, 'Namoh Namoh Jai Karni Maa', 'नमो नमो जय करणी माँ', 'Jv_UKtFdh3Y', 'Mohani Music',
      devanagari: 'नमो नमो जय करणी माँ।', transliteration: 'Namo Namo Jai Karni Maa.'),
  _RjRow('Karni Mata', _stotra, 'Karni Mahima Stotra', 'करणी महिमा स्तोत्र', 'zn5bpRdmpK8', 'clickbykf'),
  _RjRow('Karni Mata', _stotra, 'Karni Vandana Stotram', 'करणी वंदना स्तोत्रम्', 'nQZNYIyEa30', 'Dharmansh Foundation'),
  _RjRow('Karni Mata', _stotra, 'Karni Raksha Kavach', 'करणी रक्षा कवच', 'qUMC92hQT1A', 'Nisha Bhura'),

  // ── Jeen Mata ───────────────────────────────────────────────────────────
  _RjRow('Jeen Mata', _aarti, 'Om Jai Shri Jeen Maiya', 'ॐ जय श्री जीण मैया', 'vOJVCT5U3dg', 'Saurabh Madhukar'),
  _RjRow('Jeen Mata', _chalisa, 'Jeen Mata Chalisa', 'जीण माता चालीसा', 'QqMyPUas80A', 'Kumar Rakesha'),
  _RjRow('Jeen Mata', _mantra, 'Shri Jeen Bhagwati Namo Namah', 'श्री जीण भगवती नमो नमः', 'Buap0-XmbHs', 'Jeen Mata Bhajan',
      devanagari: 'श्री जीण भगवती नमो नमः।', transliteration: 'Shri Jeen Bhagwati Namo Namah.'),
  _RjRow('Jeen Mata', _stotra, 'Jeen Shat Stotra', 'श्री जीण शत-स्तोत्र', 'Tk63PoebKzA', 'Jeen Mata Ki Diwani'),

  // ── Kaila Devi ──────────────────────────────────────────────────────────
  _RjRow('Kaila Devi', _aarti, 'Om Jai Kaila Rani', 'ॐ जय कैला रानी', 'Sf4ZRZiIWOQ', 'Bhajan Teerth'),
  _RjRow('Kaila Devi', _chalisa, 'Kaila Devi Chalisa', 'कैला देवी चालीसा', '-tyeSYhYVzI', 'T-Series Bhakti Sagar'),
  _RjRow('Kaila Devi', _mantra, 'Maa Kaila Maiya Namo Namah', 'माँ कैला मैया नमो नमः', 'AURJUDNYhDA', 'Ambey Bhakti',
      devanagari: 'माँ कैला मैया नमो नमः।', transliteration: 'Maa Kaila Maiya Namo Namah.'),

  // ── Ashapura Mata (Lakh Lakh Divla Ri is already in the Gujarati catalog) ─
  _RjRow('Ashapura Mata', _aarti, 'Anand Mangal Aarti Aashapuri Maa', 'आनंद मंगल आरती आशापुरी माँ', 'ws3p1Jp7FoI', 'Ratansinh Vaghela'),
  _RjRow('Ashapura Mata', _aarti, 'Mein To Karu Ashapura Mataji Ri Aarti', 'में तो करूं आशापुरा माताजी री आरती', 'FFrayKzoayk', 'Sanskar Video'),
  _RjRow('Ashapura Mata', _aarti, 'Utaro Aarti Mata Madhwadi Ni', 'उतारो आरती माता मढवाडी नी', 'sOQejx9us8U', 'Hemant Chauhan'),
  _RjRow('Ashapura Mata', _aarti, 'Araj Karu He Mhari Anant Ashapura', 'अरज करूं हे म्हारी अनंत आशापुरा', 'AyOEC84fc_M', 'Marudhar Ri Rasdhar'),
  _RjRow('Ashapura Mata', _chalisa, 'Ashapura Maa Chalisa (Gujarati)', 'आशापुरा माँ चालीसा (गुजराती)', 'wnArTFsLRjY', 'Kiran Patel'),
  _RjRow('Ashapura Mata', _mantra, 'Ashapura Maa Mantra', 'आशापुरा माँ मंत्र', 'GA1TmDV5OXs', 'Mayur & Geeta Hemant Chauhan'),
  _RjRow('Ashapura Mata', _mantra, 'Shree Ashapura Namo Namah', 'श्री आशापुरा नमो नमः', 'qeJsqiG6_sY', 'Mohani Music',
      devanagari: 'श्री आशापुरा नमो नमः।', transliteration: 'Shree Ashapura Namo Namah.'),
  _RjRow('Ashapura Mata', _mantra, 'Maa Ashapura Beej Mantra', 'माँ आशापुरा बीज मंत्र', 'LbcMVFHXEo4', 'Sadhana Sargam'),
  _RjRow('Ashapura Mata', _stotra, 'Aashapura Maa Stuti (Bhav Dukh Bhanjani)', 'आशापुरा माँ स्तुति (भव दुःख भंजनी)', 'EaD1vNRZbD4', 'Ruchita Prajapati'),
  _RjRow('Ashapura Mata', _stotra, 'Ashapura Ashtottara Shatanama Stotram', 'आशापुरा अष्टोत्तर शतनाम स्तोत्रम्', 'i212quHc20Y', 'Rajendra Kumar Vyas'),

  // ── Gogaji ──────────────────────────────────────────────────────────────
  _RjRow('Gogaji', _aarti, 'Jai Jai Jaharveer Hare', 'जय जय जाहरवीर हरे', 'cKYi3i6-jPM', 'Bhajan Kirtan Sonotek'),
  _RjRow('Gogaji', _aarti, 'Guga Jahar Peer Sohla Aarti', 'गुगा जाहर पीर सोहला आरती', 'bmr0sE_Dg6E', 'Fan Gugga Peer Ke'),
  _RjRow('Gogaji', _chalisa, 'Jai Jai Jai Jahar Randheera (Jaharveer Chalisa)', 'जय जय जय जाहर रणधीरा (जाहरवीर चालीसा)', 'R_HytySSO7g', 'Kirtan Yug'),
  _RjRow('Gogaji', _mantra, 'Shri Jaharveer Ji Ka Mantra', 'श्री जाहरवीर जी का मंत्र', 'qpmU_Z2bNJg', 'Deepak Sain'),
  _RjRow('Gogaji', _mantra, 'Om Shri Gogaya Namah', 'ॐ श्री गोगाय नमः', 'gAaOzcuYICY', 'Chill Vibe Bhakti',
      devanagari: 'ॐ श्री गोगाय नमः।', transliteration: 'Om Shri Gogaya Namah.'),

  // ── Tejaji ──────────────────────────────────────────────────────────────
  _RjRow('Tejaji', _aarti, 'Dhore Dhore Aarti Utara Teja Thari', 'धोरे धोरे आरती उतारा तेजा थारी', 'j2zxoGoOHWw', 'Navin Rajkunvar'),
  _RjRow('Tejaji', _aarti, 'Lakh Lakh Divla Ri Aarti Tejaji Re Dham', 'लख लख दिवला री आरती तेजाजी रे धाम', '97zCAFZQbEY', 'Jogaram'),
  _RjRow('Tejaji', _aarti, 'Vir Shree Tejaji Aarti', 'वीर श्री तेजाजी आरती', 'Gq8O1g2WHbs', 'Release'),
  _RjRow('Tejaji', _chalisa, 'Tejaji Chalisa', 'तेजाजी चालीसा', 'NngWTpRY11g', 'Ramkumar Maluni'),

  // ── Pabuji ──────────────────────────────────────────────────────────────
  _RjRow('Pabuji', _aarti, 'Lakh Lakh Divla Ri Aarti Pabuji Re Dham', 'लख लख दिवला री आरती पाबूजी रे धाम', 'BvuqFmLmFBU', 'Neniram Dewasi'),
  _RjRow('Pabuji', _aarti, 'Pabuji Rathoda Ri Hove Aarti', 'पाबूजी राठौड़ा री होवे आरती', 'Q2om8Gfsks4', 'Prahlad Dewasi'),

  // ── Ramdevji ────────────────────────────────────────────────────────────
  _RjRow('Ramdevji', _aarti, 'Picham Dhara Su Mhara Pirji Padhariya', 'पिछम धरा सूं म्हारा पीरजी पधारिया', '94jb1e8DIXI', 'Nova Rajasthani'),
  _RjRow('Ramdevji', _aarti, 'Om Jai Ajmal Lala', 'ओम जय अजमल लाला', 'Xjf-_z-MeAI', 'Shri Krishna Cassettes'),
  _RjRow('Ramdevji', _aarti, 'Alakhdhani Ni Aarti', 'अलखधणी नी आरती', 'zJspgM2fWCc', 'Jigar Studio'),
  _RjRow('Ramdevji', _chalisa, 'Ramdev Chalisa (Hindi)', 'रामदेव चालीसा (हिंदी)', 'UbEopserUb0', 'Kumar Vishu'),
  _RjRow('Ramdevji', _chalisa, 'Vando Prabhu Shri Ramdev (Chalisa)', 'वंदो प्रभु श्री रामदेव (चालीसा)', 'v_iqaLhRkUM', 'Ruchita Prajapati'),
  _RjRow('Ramdevji', _mantra, 'Shri Ramdevaya Namo Namah', 'श्री रामदेवाय नमो नमः', 'nm3xEtb_GtM', 'Saurav Madhukar',
      devanagari: 'श्री रामदेवाय नमो नमः।', transliteration: 'Shri Ramdevaya Namo Namah.'),
  _RjRow('Ramdevji', _stotra, 'Namami Shri Ramdev (Ramdevpir Stuti)', 'नमामि श्री रामदेव (रामदेवपीर स्तुति)', 'PrUks4AXX1M', 'Studio Sangeeta'),

  // ── Devnarayan Ji ───────────────────────────────────────────────────────
  _RjRow('Devnarayan Ji', _aarti, 'Devnarayan Bhagwan Ri Aarti', 'देवनारायण भगवान री आरती', 'mApK_elUX_M', 'Prakash Gandhi'),
  _RjRow('Devnarayan Ji', _aarti, 'Narayan Sandhya Phooli Chhe Din Aathiyo', 'नारायण संध्या फूली छे दिन आथियो', 'YTjBdzmBmjQ', 'Gokul Sharma'),
  _RjRow('Devnarayan Ji', _aarti, 'Kamal Phool Avtari Mara Dev', 'कमल फूल अवतारी मारा देव', '4uZp5HNsSy8', 'Ishwar Bhagat'),
  _RjRow('Devnarayan Ji', _aarti, 'Devnarayan Ji Ki Aarti (Girraj Lalwari)', 'देवनारायण जी की आरती (गिर्राज लालवाड़ी)', 'uvt6hNeAj3A', 'Girraj Lalwari'),
  _RjRow('Devnarayan Ji', _aarti, 'Hove Narayan Thaki Aarti', 'होवे नारायण थाकी आरती', 'rrFo_EHQE5o', 'Lad Singh Bhagat'),
  _RjRow('Devnarayan Ji', _chalisa, 'Devnarayan Chalisa', 'देवनारायण चालीसा', 'DkoU-QcgKMg', 'Kailash Gurjar'),
  _RjRow('Devnarayan Ji', _stotra, 'Om Dev Mangalam', 'ओम् देव मंगलम', 'MxYZeI-VAzU', 'Dhabhai Music'),
  _RjRow('Devnarayan Ji', _mantra, 'Om Namo Shri Devnarayan', 'ॐ नमो श्री देवनारायण', 'fwMEf5tlZ_I', 'Sanwariya Gurjar',
      devanagari: 'ॐ नमो श्री देवनारायण।', transliteration: 'Om Namo Shri Devnarayan.'),

  // ── Mallinath Ji ────────────────────────────────────────────────────────
  _RjRow('Mallinath Ji', _aarti, 'Shree Rawal Mallinath Ji Ki Aarti', 'श्री रावल मल्लीनाथ जी की आरती', 'Glo1QmkGN2s', 'Marudhar Ri Rasdhar'),

  // ── Mehandipur Balaji ───────────────────────────────────────────────────
  _RjRow('Mehandipur Balaji', _aarti, 'Om Jai Hanumat Veera', 'ॐ जय हनुमत वीरा', 'TKPagwyhE1I', 'T-Series Bhakti Sagar'),
  _RjRow('Mehandipur Balaji', _chalisa, 'Mehandipur Balaji Chalisa', 'मेहंदीपुर बालाजी चालीसा', 'kvwKj3Q71PM', 'Pankaj Kataria'),

  // ── Rani Sati Dadi ──────────────────────────────────────────────────────
  _RjRow('Rani Sati Dadi', _aarti, 'Om Jai Shri Rani Sati Mata', 'ॐ जय श्री राणी सती माता', 'X_vvNRPms88', 'Bhakti Bhajan Kirtan'),
  _RjRow('Rani Sati Dadi', _aarti, 'Maat Shri Rani Sati Meri (Prachin Aarti)', 'मात श्री राणी सती मेरी (प्राचीन आरती)', 'O9foBoqyojI', 'Saurabh & Keshav Madhukar'),
  _RjRow('Rani Sati Dadi', _chalisa, 'Rani Sati Chalisa', 'राणी सती चालीसा', 'qadG0QWUc90', 'Tara Devi'),
  _RjRow('Rani Sati Dadi', _mantra, 'Om Shri Rani Satye Namo Namah', 'ॐ श्री राणी सत्यै नमो नमः', '6byEVD6VYhk', 'Saurabh & Keshav Madhukar',
      devanagari: 'ॐ श्री राणी सत्यै नमो नमः।', transliteration: 'Om Shri Rani Satyai Namo Namah.'),
  _RjRow('Rani Sati Dadi', _stotra, 'Rani Sati Dadi Mangal Ashtak', 'राणी सती दादी मंगल अष्टक', 'PfLiPvELfL0', 'Rani Sati Dadi Bhajan'),

  // ── Tripura Sundari ─────────────────────────────────────────────────────
  _RjRow('Tripura Sundari', _aarti, 'Aarti Maa Tripura Sundari Mataji', 'आरती माँ त्रिपुर सुंदरी माताजी', 'xFnkd92VifU', 'Dr. Rajeev Pandya'),
  _RjRow('Tripura Sundari', _aarti, 'Lalita Aarti', 'ललिता आरती', 'FcuvlhWlPw0', 'Devaki Pandit'),
  _RjRow('Tripura Sundari', _aarti, 'Aarti Tripura Sundarichi', 'आरती त्रिपुरसुंदरीची', 'am-kBPWjMA0', 'Suresh Bhalerao'),
  _RjRow('Tripura Sundari', _chalisa, 'Lalita Mata Chalisa (Tripura Sundari Chalisa)', 'ललिता माता चालीसा (त्रिपुर सुंदरी चालीसा)', 'JKpk-MH-1CE', 'Tara Devi'),
  _RjRow('Tripura Sundari', _stotra, 'Tripura Sundari Ashtakam', 'त्रिपुर सुंदरी अष्टकम्', 'rAWoHu96SNM', 'Mambalam Sisters'),
  _RjRow('Tripura Sundari', _stotra, 'Tripura Sundari Stuti', 'त्रिपुर सुंदरी स्तुति', 'TbWlx8HiGoE', 'Dinsu Spiritual'),
  _RjRow('Tripura Sundari', _mantra, 'Shodashi Tripura Sundari Mantra', 'षोडशी त्रिपुर सुंदरी मंत्र', 'UP4B2NqdN3A', 'Chant Central'),
  _RjRow('Tripura Sundari', _stotra, 'Lalita Sahasranama Stotram', 'ललिता सहस्रनाम स्तोत्रम्', 'DtSBLpQStT4', 'Rajshri Soul'),
  _RjRow('Tripura Sundari', _stotra, 'Lalita Trishati', 'ललिता त्रिशती', 'HHNV9sLs4ns', 'Challakere Brothers'),
  _RjRow('Tripura Sundari', _stotra, 'Lalita Pancharatnam', 'ललिता पंचरत्नम्', 'kG9rdaRI_pI', 'Devotional'),
  _RjRow('Tripura Sundari', _stotra, 'Tripura Sundari Kavacham', 'त्रिपुर सुंदरी कवचम्', 'Un-OEg0O0-I', 'Raksha Kavach Mantra'),
  _RjRow('Tripura Sundari', _stotra, 'Lalita Moola Mantra Kavacham', 'ललिता मूलमंत्र कवचम्', 'ZDqRe2yI1_o', 'Easy Treasure'),
  _RjRow('Tripura Sundari', _stotra, 'Lalita Tripura Sundari Saubhagya Kavach', 'ललिता त्रिपुर सुंदरी सौभाग्य कवच', 'bPaeFcB5sXo', 'Spiritual Waves Bhakti Dhaara'),

  // ── Govind Dev Ji ───────────────────────────────────────────────────────
  _RjRow('Govind Dev Ji', _aarti, 'Aarti Kije Shri Radha Govind Gopal Ki', 'आरती कीजे श्री राधा गोविंद गोपाल की', 'VV7MgrNAqqs', 'Gajendra Chhipa'),
  _RjRow('Govind Dev Ji', _aarti, 'Radha Govind Teri Aarti Gaun', 'राधा गोविंद तेरी आरती गाऊं', 'nvSLeJG6aNI', 'Jai Nandkishore'),
  _RjRow('Govind Dev Ji', _stotra, 'Main Araj Karu Shri Radha Govind (Stuti)', 'मैं अरज करूँ श्री राधा गोविंद (स्तुति)', 'bl7D9lkR21E', 'Lok Bhajan Kirtan'),
  _RjRow('Govind Dev Ji', _stotra, 'Govinda Sharanagati Stotram', 'श्री गोविंद शरणागति स्तोत्रम्', 'RSf6TNrcXnU', 'Devbhoomi Mantra'),

  // ── Charbhuja Nath ──────────────────────────────────────────────────────
  _RjRow('Charbhuja Nath', _aarti, 'Charbhuja Ji Ki Aarti', 'चारभुजाजी की आरती', 'nG4OGFJrHKo', 'Bhakti Dhara'),
  _RjRow('Charbhuja Nath', _chalisa, 'Chaturbhuj Chalisa', 'चतुर्भुज चालीसा', 'VQv28U_HT34', 'Parbhu Joshi'),
  _RjRow('Charbhuja Nath', _stotra, 'Chaturbhuj Pachcheesi', 'चतुर्भुज पच्चीसी', 'FaAXjXwgHL8', 'Peeyush Bansal'),
];
