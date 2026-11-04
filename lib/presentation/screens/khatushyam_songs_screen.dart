import 'package:flutter/material.dart';

import '../../data/datasources/khatushyam_songs_catalog.dart';
import 'deity_songs_screen.dart';

/// YouTube Search Results style screen for Khatu Shyam songs,
/// bhajans, stotrams, and aartis.
/// Wraps [DeitySongsScreen] with Khatu Shyam configuration.
class KhatuShyamSongsScreen extends StatelessWidget {
  const KhatuShyamSongsScreen({super.key});

  static const List<String> categories = [
    'All',
    'Popular & Trending',
    'Devotional Bhajan',
    'Bhajan',
  ];

  @override
  Widget build(BuildContext context) {
    return const DeitySongsScreen(
      deityKey: 'Khatu Shyam',
      title: 'Khatu Shyam Songs',
      searchHint: 'Search Khatu Shyam, Teen Baan, Sanware bhajans...',
      emptySearchHint: 'Try searching Teen Baan Ke Dhari, Haare Ka Sahara, or Kanhaiya Mittal',
      songs: kKhatuShyamSongsCatalog,
      categories: categories,
      accentColor: Color(0xFF1565C0),
      blessingMessage: 'हारे का सहारा, बाबा श्याम हमारा! जय श्री श्याम! 🙏🌸',
    );
  }
}

