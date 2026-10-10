import 'package:flutter/material.dart';

import '../../data/datasources/shiva_songs_catalog.dart';
import 'deity_songs_screen.dart';

/// YouTube Search Results style screen for Lord Shiva (Mahadev / Bholenath / Shankar) songs,
/// bhajans, stotrams, and mantras.
/// Wraps [DeitySongsScreen] with Lord Shiva configuration.
class ShivaSongsScreen extends StatelessWidget {
  const ShivaSongsScreen({super.key});

  static const List<String> categories = [
    'All',
    'Popular & Trending',
    'Shiv Bhajan',
    'Stotram & Ashtakam',
    'Mantra & Dhun',
    'Aarti & Chalisa',
    'South & Regional',
  ];

  @override
  Widget build(BuildContext context) {
    return const DeitySongsScreen(
      deityKey: 'Lord Shiva',
      title: 'Mahadev Shiva Songs',
      searchHint: 'Search Mahadev, Shiv Tandav, Bholenath songs...',
      emptySearchHint: 'Try searching Namo Namo, Shiv Tandav Stotram, or Mahamrityunjaya Mantra',
      songs: kShivaSongsCatalog,
      categories: categories,
      accentColor: Color(0xFF0288D1),
      blessingMessage: 'हर हर महादेव! ॐ नमः शिवाय! कर्पूरगौरं करुणावतारम्! 🔱🌙',
    );
  }
}
