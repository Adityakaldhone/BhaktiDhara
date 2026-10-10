import 'package:flutter/material.dart';

import '../../data/datasources/lakshmi_songs_catalog.dart';
import 'deity_songs_screen.dart';

/// YouTube Search Results style screen for Goddess Mahalakshmi songs.
/// Wraps [DeitySongsScreen] with Goddess Mahalakshmi configuration.
class LakshmiSongsScreen extends StatelessWidget {
  const LakshmiSongsScreen({super.key});

  static const List<String> categories = [
    'All',
    'Aarti & Harathi',
    'Stotra & Suktam',
    'Mantra & Jaap',
    'Diwali & Bhajans',
    'Kolhapur & Marathi',
    'South Devotional',
    'Chalisa & Katha',
  ];

  @override
  Widget build(BuildContext context) {
    return const DeitySongsScreen(
      deityKey: 'Goddess Lakshmi',
      title: 'Shri Mahalakshmi Songs',
      searchHint: 'Search Mahalakshmi songs, stotras, aartis, bhajans...',
      emptySearchHint: 'Try searching Shri Suktam, Kanakadhara, or Om Jai Lakshmi Mata',
      songs: kLakshmiSongsCatalog,
      categories: categories,
      accentColor: Color(0xFFC2185B),
      blessingMessage: 'ॐ श्रीं ह्रीं क्लीं महालक्ष्म्यै नमः! अष्टलक्ष्मींचा आशीर्वाद सदैव तुमच्या पाठीशी असो! 🪷✨',
    );
  }
}
