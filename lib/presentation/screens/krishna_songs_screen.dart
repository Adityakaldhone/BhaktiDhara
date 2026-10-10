import 'package:flutter/material.dart';

import '../../data/datasources/krishna_songs_catalog.dart';
import 'deity_songs_screen.dart';

/// YouTube Search Results style screen for Lord Krishna (Shri Krishna / Banke Bihari / Shyam) songs,
/// bhajans, kirtans, and aartis.
/// Wraps [DeitySongsScreen] with Lord Krishna configuration.
class KrishnaSongsScreen extends StatelessWidget {
  const KrishnaSongsScreen({super.key});

  static const List<String> categories = [
    'All',
    'Banke Bihari & Vrindavan',
    'Krishna Bhajan',
    'Radha Krishna & Dhun',
    'Bansi & Murli',
    'Aarti & Kirtan',
    'Khatu Shyam',
  ];

  @override
  Widget build(BuildContext context) {
    return const DeitySongsScreen(
      deityKey: 'Lord Krishna',
      title: 'Shri Krishna Songs',
      searchHint: 'Search Shri Krishna, Banke Bihari, Radhe Radhe...',
      emptySearchHint: 'Try searching Achyutam Keshavam, Radhe Radhe, or Banke Bihari',
      songs: kKrishnaSongsCatalog,
      categories: categories,
      accentColor: Color(0xFF0D5C9E),
      blessingMessage: 'हरे कृष्ण हरे कृष्ण, कृष्ण कृष्ण हरे हरे! राधे राधे! 🦚✨',
    );
  }
}
