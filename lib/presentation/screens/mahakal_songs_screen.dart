import 'package:flutter/material.dart';

import '../../data/datasources/mahakal_songs_catalog.dart';
import 'deity_songs_screen.dart';

/// YouTube Search Results style screen for Mahakal (Ujjain) songs,
/// bhajans, stotrams, and mantras.
/// Wraps [DeitySongsScreen] with Mahakal configuration.
class MahakalSongsScreen extends StatelessWidget {
  const MahakalSongsScreen({super.key});

  static const List<String> categories = [
    'All',
    'Popular & Trending',
    'Devotional Bhajan',
    'Bhajan',
  ];

  @override
  Widget build(BuildContext context) {
    return const DeitySongsScreen(
      deityKey: 'Mahakal',
      title: 'Mahakal Ujjain Songs',
      searchHint: 'Search Mahakal, Bhasma Aarti, Ujjain bhajans...',
      emptySearchHint: 'Try searching Takdeer Mujhe Le Chal, Ujjain Ke Raja, or Jai Mahakal',
      songs: kMahakalSongsCatalog,
      categories: categories,
      accentColor: Color(0xFF1565C0),
      blessingMessage: 'जय श्री महाकाल! कालों के काल महाकाल आपके समस्त संकट हरें! 🔱🕉️',
    );
  }
}

