import 'package:flutter/material.dart';

import '../../data/datasources/radha_songs_catalog.dart';
import 'deity_songs_screen.dart';

/// YouTube Search Results style screen for Radha Rani (Shri Radha / Kishori Ji / Barsane Wali)
/// bhajans, kirtans, and Braj devotional songs.
/// Wraps [DeitySongsScreen] with Radha Rani configuration.
class RadhaSongsScreen extends StatelessWidget {
  const RadhaSongsScreen({super.key});

  static const List<String> categories = [
    'All',
    'Popular & Trending',
    'Barsane Ki Kishori',
    'Radhe Krishna Bhajan',
    'Kirtan & Naam Jaap',
    'Braj Rasiya & Folk',
  ];

  @override
  Widget build(BuildContext context) {
    return const DeitySongsScreen(
      deityKey: 'Radha',
      title: 'Radha Rani Songs',
      searchHint: 'Search Radha Rani, Barsane Wali, Kishori songs...',
      emptySearchHint: 'Try searching Radhe Radhe, Mithe Ras Se Bharyo, or Kishori Kuch Aisa',
      songs: kRadhaSongsCatalog,
      categories: categories,
      accentColor: Color(0xFFE91E63),
      blessingMessage: 'राधे राधे! जय श्री राधे! श्री किशोरी जी की कृपा सदा बनी रहे! 🌸🪷',
    );
  }
}
