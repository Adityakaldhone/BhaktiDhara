import 'package:flutter/material.dart';

import '../../data/datasources/khandoba_songs_catalog.dart';
import 'deity_songs_screen.dart';

/// YouTube Search Results style screen for Shri Khandoba (Malhari Martand / Mallanna) songs.
/// Wraps [DeitySongsScreen] with Shri Khandoba configuration.
class KhandobaSongsScreen extends StatelessWidget {
  const KhandobaSongsScreen({super.key});

  static const List<String> categories = [
    'All',
    'Bhaktigeet',
    'Popular & Trending',
    'Mallanna (Telugu)',
    'Mylaralinga (Kannada)',
    'Aarti & Harathi',
    'Jagran & Gondhal',
    'Mantra & Jaap',
  ];

  @override
  Widget build(BuildContext context) {
    return const DeitySongsScreen(
      deityKey: 'Lord Khandoba',
      title: 'Shri Khandoba Songs',
      searchHint: 'Search Khandoba, Malhari, Mallanna songs...',
      emptySearchHint: 'Try searching Dev Malhari, Banu Navri Natli, or Mallanna',
      songs: kKhandobaSongsCatalog,
      categories: categories,
      accentColor: Color(0xFFFF8F00),
      blessingMessage: 'येळकोट येळकोट जय मल्हार! सदानंदाचा येळकोट! 🚩🟡',
    );
  }
}
