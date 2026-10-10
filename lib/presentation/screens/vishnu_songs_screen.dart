import 'package:flutter/material.dart';

import '../../data/datasources/vishnu_songs_catalog.dart';
import 'deity_songs_screen.dart';

/// YouTube Search Results style screen for Lord Vishnu (Narayan / Hari) songs, bhajans, and dhun.
/// Wraps [DeitySongsScreen] with Lord Vishnu configuration.
class VishnuSongsScreen extends StatelessWidget {
  const VishnuSongsScreen({super.key});

  static const List<String> categories = [
    'All',
    'Popular & Trending',
    'Vishnu Bhajan',
    'Mantra & Dhun',
    'Stotram & Sahasranama',
    'Aarti & Chalisa',
  ];

  @override
  Widget build(BuildContext context) {
    return const DeitySongsScreen(
      deityKey: 'Lord Vishnu',
      title: 'Shri Vishnu Songs',
      searchHint: 'Search Shri Vishnu, Narayan, Hari bhajans, dhun...',
      emptySearchHint: 'Try searching Narayan Mil Jayega, Shreeman Narayan, or Vishnu Sahasranamam',
      songs: kVishnuSongsCatalog,
      categories: categories,
      accentColor: Color(0xFF1E88E5),
      blessingMessage: 'ॐ नमो भगवते वासुदेवाय। ॐ विष्णवे नमः। 🪷🐚',
    );
  }
}
