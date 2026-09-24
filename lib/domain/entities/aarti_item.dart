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

  /// Returns the active video ID, or the first backup if override is needed.
  String videoIdWithFallback(int fallbackIndex) {
    if (fallbackIndex == 0) return youtubeVideoId;
    final idx = fallbackIndex - 1;
    return (idx < backupVideoIds.length) ? backupVideoIds[idx] : youtubeVideoId;
  }
}
