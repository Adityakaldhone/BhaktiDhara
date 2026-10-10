import 'package:flutter/material.dart';

import '../../data/datasources/vitthal_songs_catalog.dart';
import 'deity_songs_screen.dart';

/// YouTube Search Results style screen for Lord Vitthal (Pandurang / Vithoba) songs, abhangs, and wari geet.
/// Wraps [DeitySongsScreen] with Lord Vitthal configuration.
class VitthalSongsScreen extends StatelessWidget {
  const VitthalSongsScreen({super.key});

  static const List<String> categories = [
    'All',
    'Vitthal Bhaktigeet',
    'Sant Abhang',
    'Wari & Dindi',
    'Aarti & Gajar',
    'South & Regional',
    'Haripath & Stotra',
  ];

  @override
  Widget build(BuildContext context) {
    return const DeitySongsScreen(
      deityKey: 'Lord Vitthal',
      title: 'Shri Vitthal Songs',
      searchHint: 'Search Vitthal, Pandurang, abhang, wari songs...',
      emptySearchHint: 'Try searching Bhakta Pundalika, Deh Vitthal, or Kanada Raja Pandharicha',
      songs: kVitthalSongsCatalog,
      categories: categories,
      accentColor: Color(0xFFFFB300),
      blessingMessage: 'पुंडलिक वरदा हरि विठ्ठल! श्री ज्ञानदेव तुकाराम! पंढरीनाथ महाराज की जय! 🚩🪷',
    );
  }
}
