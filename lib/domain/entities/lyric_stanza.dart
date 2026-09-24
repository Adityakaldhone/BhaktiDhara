/// A single timestamped stanza (verse) of an aarti or chalisa.
///
/// [startTimeMs] is the integer millisecond offset from the start of the
/// YouTube video at which this stanza begins. Using integers avoids
/// floating-point drift (Spec §2 — Precision requirement).
class LyricStanza {
  /// Video offset in milliseconds (integer — no fractional drift).
  final int startTimeMs;

  /// Primary script: Devanagari Sanskrit / Hindi.
  final String devanagari;

  /// Romanised phonetic transliteration for non-Hindi readers.
  final String transliteration;

  const LyricStanza({
    required this.startTimeMs,
    required this.devanagari,
    required this.transliteration,
  });

  @override
  String toString() =>
      'LyricStanza(startTimeMs: $startTimeMs, devanagari: "$devanagari")';
}
