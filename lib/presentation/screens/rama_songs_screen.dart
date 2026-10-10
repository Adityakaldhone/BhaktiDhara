import 'package:flutter/material.dart';

import '../../data/datasources/rama_songs_catalog.dart';
import 'deity_songs_screen.dart';

/// YouTube Search Results style screen for Prabhu Shri Ram songs.
/// Wraps [DeitySongsScreen] with Prabhu Shri Ram configuration.
class RamaSongsScreen extends StatelessWidget {
  const RamaSongsScreen({super.key});

  static const List<String> categories = [
    'All',
    'Ayodhya & Trending',
    'Ram Bhajan',
    'Ramayan & Chaupai',
    'Naam Jap & Dhun',
    'Stotra & Ashtak',
    'Aarti',
    'Regional Bhakti',
  ];

  @override
  Widget build(BuildContext context) {
    return const DeitySongsScreen(
      deityKey: 'Lord Rama',
      title: 'Prabhu Shri Ram Songs',
      searchHint: 'Search Shri Ram songs, bhajans, chaupai, dhun...',
      emptySearchHint: 'Try searching Ram Siya Ram, Ram Aayenge, or Ramcharitmanas',
      songs: kRamaSongsCatalog,
      categories: categories,
      accentColor: Color(0xFFFF6F00),
      blessingMessage: 'सियावर रामचंद्र की जय! मंगल भवन अमंगल हारी, द्रवहु सुदसरथ अजर बिहारी! 🚩🏹',
    );
  }
}
