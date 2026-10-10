import 'package:flutter/material.dart';

import '../../data/datasources/hanuman_songs_catalog.dart';
import 'deity_songs_screen.dart';

/// YouTube Search Results style screen for Lord Hanuman songs.
/// Wraps [DeitySongsScreen] with Lord Hanuman configuration.
class HanumanSongsScreen extends StatelessWidget {
  const HanumanSongsScreen({super.key});

  static const List<String> categories = [
    'All',
    'Bhajan',
    'Lakkha Hits',
    'Balaji Special',
    'Chalisa',
    'Stotra & Mantra',
    'Amritwani & Path',
    'Aarti',
    'Regional Bhakti',
  ];

  @override
  Widget build(BuildContext context) {
    return const DeitySongsScreen(
      deityKey: 'Lord Hanuman',
      title: 'Shri Hanuman Songs',
      searchHint: 'Search Hanuman songs, bhajans, chalisas...',
      emptySearchHint: 'Try searching Lakhbir Singh Lakkha, Balaji, or Chalisa',
      songs: kHanumanSongsCatalog,
      categories: categories,
      accentColor: Color(0xFFE65100),
      blessingMessage: 'जय श्री राम! पवनपुत्र हनुमानजींचा आशीर्वाद तुमच्या पाठीशी असो! 🙏🚩',
    );
  }
}
