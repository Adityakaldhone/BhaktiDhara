import 'lyric_stanza.dart';

/// Metadata and lyrics for a single aarti / stuti / chalisa.
class AartiItem {
  /// Unique string identifier (used for routing / analytics).
  final String id;

  /// Display title shown in catalog and altar header (English).
  final String title;

  /// Title in Hindi.
  final String titleHi;

  /// Title in Marathi.
  final String titleMr;

  /// Deity associated with this aarti (English).
  final String deity;

  /// Deity name in Hindi.
  final String deityHi;

  /// Deity name in Marathi.
  final String deityMr;

  /// Singer / performer attribution.
  final String singer;

  /// Primary YouTube video ID.
  final String youtubeVideoId;

  /// Fallback video IDs tried in order if the primary returns error 100/150.
  final List<String> backupVideoIds;

  /// Human-readable duration string shown in the catalog (e.g. "9:48").
  final String durationText;

  /// Ordered list of timestamped stanzas.
  final List<LyricStanza> lyrics;

  /// Hex string for deity-specific accent colour.
  final String accentColorHex;

  /// Unicode emoji for the deity chip icon.
  final String deityEmoji;

  /// Content type tags (e.g. ['Aarti', 'Chalisa', 'Bhajan']).
  final List<String> tags;

  /// Short description / spiritual significance (Devanagari Marathi).
  final String aboutMr;

  /// Short description (Hindi).
  final String aboutHi;

  /// Short description (English).
  final String about;

  const AartiItem({
    required this.id,
    required this.title,
    this.titleHi = '',
    this.titleMr = '',
    required this.deity,
    this.deityHi = '',
    this.deityMr = '',
    required this.singer,
    required this.youtubeVideoId,
    this.backupVideoIds = const [],
    required this.durationText,
    required this.lyrics,
    required this.accentColorHex,
    required this.deityEmoji,
    this.tags = const ['Aarti'],
    this.about = '',
    this.aboutHi = '',
    this.aboutMr = '',
  });

  /// Returns the localized title based on locale code.
  String localizedTitle(String localeCode) {
    switch (localeCode) {
      case 'hi':
        return titleHi.isNotEmpty ? titleHi : title;
      case 'mr':
        return titleMr.isNotEmpty ? titleMr : title;
      default:
        return title;
    }
  }

  /// Returns the localized deity name based on locale code.
  String localizedDeity(String localeCode) {
    switch (localeCode) {
      case 'hi':
        return deityHi.isNotEmpty ? deityHi : deity;
      case 'mr':
        return deityMr.isNotEmpty ? deityMr : deity;
      default:
        return deity;
    }
  }

  /// Returns the localized description / about text based on locale code.
  String localizedAbout(String localeCode) {
    switch (localeCode) {
      case 'hi':
        return aboutHi.isNotEmpty ? aboutHi : (aboutMr.isNotEmpty ? aboutMr : about);
      case 'mr':
        return aboutMr.isNotEmpty ? aboutMr : (aboutHi.isNotEmpty ? aboutHi : about);
      default:
        return about.isNotEmpty ? about : (aboutMr.isNotEmpty ? aboutMr : aboutHi);
    }
  }

  /// Returns the active video ID, or the first backup if override is needed.
  String videoIdWithFallback(int fallbackIndex) {
    if (fallbackIndex == 0) return youtubeVideoId;
    final idx = fallbackIndex - 1;
    return (idx < backupVideoIds.length) ? backupVideoIds[idx] : youtubeVideoId;
  }

  /// Returns the canonical collection title for the deity, e.g. "Shri Gondavlekar Maharaj Aarti",
  /// "श्री गोंदवलेकर महाराज आरती", "Shri Swami Samarth Aarti", "Shri Gajanan Maharaj Aarti".
  String deityAartiTitle(String localeCode) {
    return getDeityAartiTitle(deity, localeCode);
  }

  /// Static helper returning the canonical Deity Aarti collection title based on locale.
  static String getDeityAartiTitle(String deity, String localeCode) {
    final clean = deity.trim();
    switch (clean) {
      case 'Lord Ganesha':
      case 'Ganesh':
      case 'Ganesha':
        return localeCode == 'en' ? 'Shri Ganesh Aarti' : 'श्री गणेश आरती';
      case 'Lord Hanuman':
      case 'Hanuman':
        return localeCode == 'en' ? 'Shri Hanuman Aarti' : 'श्री हनुमान आरती';
      case 'Lord Shiva':
      case 'Shiva':
      case 'Shiv':
        return localeCode == 'en' ? 'Shri Shiv Aarti' : 'श्री शिव आरती';
      case 'Goddess Durga':
      case 'Durga':
        return localeCode == 'en' ? 'Shri Durga Aarti' : 'श्री दुर्गा आरती';
      case 'Lord Vitthal':
      case 'Vitthal':
        return localeCode == 'en'
            ? 'Shri Vitthal Aarti'
            : (localeCode == 'hi' ? 'श्री विट्ठल आरती' : 'श्री विठ्ठल आरती');
      case 'Lord Krishna':
      case 'Krishna':
        return localeCode == 'en' ? 'Shri Krishna Aarti' : 'श्री कृष्ण आरती';
      case 'Lord Rama':
      case 'Rama':
      case 'Ram':
        return localeCode == 'en' ? 'Shri Ram Aarti' : 'श्री राम आरती';
      case 'Lord Datta':
      case 'Datta':
      case 'Dattatreya':
        return localeCode == 'en'
            ? 'Shri Datta Aarti'
            : (localeCode == 'hi' ? 'श्री दत्तात्रेय आरती' : 'श्री दत्त आरती');
      case 'Goddess Lakshmi':
      case 'Lakshmi':
        return localeCode == 'en' ? 'Shri Mahalakshmi Aarti' : 'श्री महालक्ष्मी आरती';
      case 'Goddess Santoshi Mata':
      case 'Santoshi Mata':
        return localeCode == 'en' ? 'Shri Santoshi Mata Aarti' : 'श्री संतोषी माता आरती';
      case 'Goddess Tulsi':
      case 'Tulsi':
        return localeCode == 'en'
            ? 'Shri Tulsi Mata Aarti'
            : (localeCode == 'hi' ? 'श्री तुलसी माता आरती' : 'श्री तुळशी माता आरती');
      case 'Lord Vishnu':
      case 'Vishnu':
        return localeCode == 'en'
            ? 'Shri Vishnu Aarti'
            : (localeCode == 'hi' ? 'श्री विष्णु आरती' : 'श्री विष्णू आरती');
      case 'Lord Satyanarayan':
      case 'Satyanarayan':
        return localeCode == 'en' ? 'Shri Satyanarayan Aarti' : 'श्री सत्यनारायण आरती';
      case 'Lord Venkatesh':
      case 'Venkatesh':
      case 'Balaji':
        return localeCode == 'en'
            ? 'Shri Venkatesh Aarti'
            : (localeCode == 'hi' ? 'श्री वेंकटेश आरती' : 'श्री व्यंकटेश आरती');
      case 'Lord Khandoba':
      case 'Khandoba':
        return localeCode == 'en' ? 'Shri Khandoba Aarti' : 'श्री खंडोबा आरती';
      case 'Lord Shani':
      case 'Shani':
        return localeCode == 'en'
            ? 'Shri Shani Dev Aarti'
            : (localeCode == 'hi' ? 'श्री शनि देव आरती' : 'श्री शनिदेव आरती');
      case 'Sai Baba':
        return localeCode == 'en'
            ? 'Shri Sai Baba Aarti'
            : (localeCode == 'hi' ? 'श्री साईं बाबा आरती' : 'श्री साई बाबा आरती');
      case 'Gajanan Maharaj':
      case 'Shri Gajanan Maharaj':
        return localeCode == 'en' ? 'Shri Gajanan Maharaj Aarti' : 'श्री गजानन महाराज आरती';
      case 'Sant':
        return localeCode == 'en' ? 'Sant Aarti Sangrah' : 'संत आरती संग्रह';
      case 'Lord Siddhanath':
      case 'Siddhanath':
        return localeCode == 'en' ? 'Shri Siddhanath Aarti' : 'श्री सिद्धनाथ आरती';
      case 'Goddess Renuka Mata':
      case 'Renuka Mata':
        return localeCode == 'en' ? 'Shri Renuka Mata Aarti' : 'श्री रेणुका माता आरती';
      case 'Sant Balumama':
      case 'Balumama':
        return localeCode == 'en'
            ? 'Shri Balumama Aarti'
            : (localeCode == 'hi' ? 'श्री बालूमामा आरती' : 'श्री बाळूमामा आरती');
      case 'Gondavalekar Maharaj':
      case 'Gondavlekar Maharaj':
      case 'Brahmachaitanya Gondavalekar Maharaj':
        return localeCode == 'en' ? 'Shri Gondavlekar Maharaj Aarti' : 'श्री गोंदवलेकर महाराज आरती';
      case 'Navnath':
        return localeCode == 'en' ? 'Shri Navnath Aarti' : 'श्री नवनाथ आरती';
      case 'Swami Samarth':
      case 'Shri Swami Samarth':
        return localeCode == 'en' ? 'Shri Swami Samarth Aarti' : 'श्री स्वामी समर्थ आरती';
      case 'Lord Bhairavnath':
      case 'Bhairavnath':
        return localeCode == 'en'
            ? 'Shri Bhairavnath Aarti'
            : (localeCode == 'hi' ? 'श्री कालभैरव आरती' : 'श्री काळभैरवनाथ आरती');
      case 'Chandra Dev':
      case 'Chandra':
        return localeCode == 'en' ? 'Shri Chandra Dev Aarti' : 'श्री चंद्र देव आरती';
      case 'Goddess Narmada':
      case 'Narmada':
        return localeCode == 'en' ? 'Shri Narmada Mata Aarti' : 'श्री नर्मदा माता आरती';
      case 'Surya Dev':
      case 'Surya':
        return localeCode == 'en' ? 'Shri Surya Dev Aarti' : 'श्री सूर्य देव आरती';
      case 'Goddess Gayatri':
      case 'Gayatri':
        return localeCode == 'en' ? 'Shri Gayatri Mata Aarti' : 'श्री गायत्री माता आरती';
      default:
        return localeCode == 'en' ? '$deity Aarti' : 'श्री $deity आरती';
    }
  }
}
