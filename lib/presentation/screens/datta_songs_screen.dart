import 'package:flutter/material.dart';

import '../../data/datasources/datta_songs_catalog.dart';
import 'deity_songs_screen.dart';

/// YouTube Search Results style screen for Lord Datta (Shri Dattatreya / Shripad Shrivallabh) songs,
/// aartis, pradakshina, bhajans, stotrams, and mantras.
/// Wraps [DeitySongsScreen] with Lord Datta configuration.
class DattaSongsScreen extends StatelessWidget {
  const DattaSongsScreen({super.key});

  static const List<String> categories = [
    'All',
    'Aarti & Pradakshina',
    'Datta Bhajan',
    'Shripad & Vallabh',
    'Amritwani & Gajar',
    'Stotra & Kavach',
    'Mantra & Jap',
    'Chalisa',
    'Regional Bhakti',
  ];

  @override
  Widget build(BuildContext context) {
    return const DeitySongsScreen(
      deityKey: 'Lord Datta',
      title: 'Shri Dattatreya Songs',
      searchHint: 'Search Dattachi gani, aarti, stotra, pradakshina...',
      emptySearchHint: 'Try searching Dhanya Dhanya Ho Pradakshina, Jagat Vandya Avadhut, or Ghorakashtodharan',
      songs: kDattaSongsCatalog,
      categories: categories,
      accentColor: Color(0xFFE65100),
      blessingMessage: 'अवधूत चिंतन श्री गुरुदेव दत्त! दिगंबरा दिगंबरा श्रीपाद वल्लभ दिगंबरा! 🌸🪔',
    );
  }
}
