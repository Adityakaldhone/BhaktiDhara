import 'package:flutter/material.dart';

import '../../data/datasources/narmada_songs_catalog.dart';
import 'deity_songs_screen.dart';

/// YouTube Search Results style screen for Goddess Narmada (Maa Rewa) songs, bhajans, and lokgeet.
/// Wraps [DeitySongsScreen] with Goddess Narmada configuration.
class NarmadaSongsScreen extends StatelessWidget {
  const NarmadaSongsScreen({super.key});

  static const List<String> categories = [
    'All',
    'Popular & Trending',
    'Narmada Bhajan',
    'Rewa & Nimadi Lokgeet',
    'Ashtakam & Parikrama',
    'Aarti & Chalisa',
  ];

  @override
  Widget build(BuildContext context) {
    return const DeitySongsScreen(
      deityKey: 'Goddess Narmada',
      title: 'Maa Narmada Songs',
      searchHint: 'Search Maa Narmada, Rewa Maiya bhajans, lokgeet...',
      emptySearchHint: 'Try searching Maine Tumhare Bharose, Narmada Ashtakam, or Gehri Narbada',
      songs: kNarmadaSongsCatalog,
      categories: categories,
      accentColor: Color(0xFF00ACC1),
      blessingMessage: 'नर्मदे हर! त्वदीय पादपंकजं नमामि देवि नर्मदे! 🌊🪷',
    );
  }
}
