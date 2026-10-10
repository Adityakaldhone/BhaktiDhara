import 'package:flutter/material.dart';

import '../../data/datasources/chandra_songs_catalog.dart';
import 'deity_songs_screen.dart';

/// YouTube Search Results style screen for Chandra Dev (Moon God / Soma) songs and mantras.
/// Wraps [DeitySongsScreen] with Chandra Dev configuration.
class ChandraSongsScreen extends StatelessWidget {
  const ChandraSongsScreen({super.key});

  static const List<String> categories = [
    'All',
    'Mantra & Jaap',
    'Stotram & Kavacham',
    'Aarti & Chalisa',
    'Devotional & Stuti',
  ];

  @override
  Widget build(BuildContext context) {
    return const DeitySongsScreen(
      deityKey: 'Chandra Dev',
      title: 'Shri Chandra Dev Songs',
      searchHint: 'Search Chandra Dev mantras, stotra, aarti...',
      emptySearchHint: 'Try searching Om Som Somaya Namah, Chandra Gayatri, or Chandra Kavacham',
      songs: kChandraSongsCatalog,
      categories: categories,
      accentColor: Color(0xFF5C6BC0),
      blessingMessage: 'ॐ सों सोमाय नमः। ॐ चं चंद्राय नमः। 🌙✨',
    );
  }
}
