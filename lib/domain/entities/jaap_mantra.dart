/// A mantra that can be chanted on the digital mala.
class JaapMantra {
  final String id;

  /// Deity key understood by `MandirTheme.getDeityImageAsset`.
  final String deity;

  /// Mantra text in Devanagari script.
  final String devanagari;

  /// Latin transliteration shown under the Devanagari text.
  final String transliteration;

  /// Short name shown in pickers, e.g. {'mr': 'श्रीराम', 'hi': 'श्री राम', 'en': 'Shri Ram'}.
  final Map<String, String> name;

  final bool isPremium;

  /// Chant-along audio is free for this mantra; otherwise it needs premium.
  final bool freeAudio;

  const JaapMantra({
    required this.id,
    required this.deity,
    required this.devanagari,
    required this.transliteration,
    required this.name,
    this.isPremium = false,
    this.freeAudio = false,
  });

  /// One recorded repetition, relative to `assets/` (audioplayers convention).
  String get audioAsset => 'sounds/jaap/$id.m4a';

  /// Long mantras (Gayatri, Mahamrityunjaya, Hare Krishna) need a scrollable
  /// text card instead of a single headline.
  bool get isLong => devanagari.length > 40;

  String localizedName(String langCode) =>
      name[langCode] ?? name['en'] ?? transliteration;
}
