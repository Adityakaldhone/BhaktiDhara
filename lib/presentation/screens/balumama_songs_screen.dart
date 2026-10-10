import 'package:flutter/material.dart';

import '../../data/datasources/balumama_songs_catalog.dart';
import 'deity_songs_screen.dart';

/// YouTube Search Results style screen for Sant Balumama (Adamapur) songs,
/// aartis, mantras, japs, and mendhar/bhandara geet.
/// Wraps [DeitySongsScreen] with Sant Balumama configuration.
class BalumamaSongsScreen extends StatelessWidget {
  const BalumamaSongsScreen({super.key});

  static const List<String> categories = [
    'All',
    'Popular & Trending',
    'Bhandara & Mendhar Geet',
    'Aarti & Gajar',
    'Mantra & Jap',
    'Admapur & Palkhi',
    'Granth & Amrutwani',
  ];

  @override
  Widget build(BuildContext context) {
    return const DeitySongsScreen(
      deityKey: 'Sant Balumama',
      title: 'Sant Balumama Songs',
      searchHint: 'Search Balumama songs, aarti, mendhar geet...',
      emptySearchHint: 'Try searching Balumamachi Mendhar, Jaydev Jaydev Jay Balumama, or Bhandara',
      songs: kBalumamaSongsCatalog,
      categories: categories,
      accentColor: Color(0xFFFFB300),
      blessingMessage: 'बाळूमामाच्या नावानं चांगभलं! आदमापूरच्या राजा की जय! 🚩🟡',
    );
  }
}
