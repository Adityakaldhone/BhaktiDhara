import 'package:flutter/material.dart';

import '../../data/datasources/gayatri_songs_catalog.dart';
import 'deity_songs_screen.dart';

/// YouTube Search Results style screen for Goddess Gayatri (Vedmata / AWGP Shantikunj / Gayatri Pariwar)
/// mantras, stotras, chalisas, aartis, and Pragya geets.
/// Wraps [DeitySongsScreen] with Goddess Gayatri configuration.
class GayatriSongsScreen extends StatelessWidget {
  const GayatriSongsScreen({super.key});

  static const List<String> categories = [
    'All',
    'Popular & Trending',
    'Gayatri Mantra & Jaap',
    'Stotram & Kavacham',
    'Aarti & Chalisa',
    'Pragya Geet & Bhajan',
  ];

  @override
  Widget build(BuildContext context) {
    return const DeitySongsScreen(
      deityKey: 'Goddess Gayatri',
      title: 'Gayatri Mata Songs',
      searchHint: 'Search Gayatri Mantra, Chalisa, Pragya Geet...',
      emptySearchHint: 'Try searching Gayatri Mantra 108, Gayatri Chalisa, or Jayati Jay Gayatri Mata',
      songs: kGayatriSongsCatalog,
      categories: categories,
      accentColor: Color(0xFFFFA000),
      blessingMessage: 'ॐ भूर्भुवः स्वः तत्सवितुर्वरेण्यं भर्गो देवस्य धीमहि धियो यो नः प्रचोदयात्॥ ☀️🪷',
    );
  }
}
