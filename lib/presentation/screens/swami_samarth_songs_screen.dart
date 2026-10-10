import 'package:flutter/material.dart';

import '../../data/datasources/swami_samarth_songs_catalog.dart';
import 'deity_songs_screen.dart';

/// YouTube Search Results style screen for Shri Swami Samarth songs.
/// Wraps [DeitySongsScreen] with Shri Swami Samarth configuration.
class SwamiSamarthSongsScreen extends StatelessWidget {
  const SwamiSamarthSongsScreen({super.key});

  static const List<String> categories = [
    'All',
    'Bhaktigeet',
    'Popular & Trending',
    'Aarti & Bhupali',
    'Tarak Mantra & Jaap',
    'Parayan & Katha',
  ];

  @override
  Widget build(BuildContext context) {
    return const DeitySongsScreen(
      deityKey: 'Swami Samarth',
      title: 'Shri Swami Samarth Songs',
      searchHint: 'Search Swami Samarth songs, bhaktigeet, tarak mantra...',
      emptySearchHint: 'Try searching Tarak Mantra, Avadhoot Gandhi, or Suresh Wadkar',
      songs: kSwamiSamarthSongsCatalog,
      categories: categories,
      accentColor: Color(0xFFE65100),
      blessingMessage: 'अशक्य ही शक्य करतील स्वामी! भिऊ नकोस, मी तुझ्या पाठीशी आहे! 🙏✨',
    );
  }
}
