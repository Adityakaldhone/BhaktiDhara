import 'package:flutter/material.dart';

import '../../data/datasources/renuka_songs_catalog.dart';
import 'deity_songs_screen.dart';

/// YouTube Search Results style screen for Goddess Renuka Mata / Yellamma Devi songs.
/// Wraps [DeitySongsScreen] with Goddess Renuka Mata configuration.
class RenukaSongsScreen extends StatelessWidget {
  const RenukaSongsScreen({super.key});

  static const List<String> categories = [
    'All',
    'Telangana Bonalu',
    'Saundatti & Kannada',
    'Marathi Jogwa',
    'Aarti & Stuti',
    'Devi Bhaktigeet',
  ];

  @override
  Widget build(BuildContext context) {
    return const DeitySongsScreen(
      deityKey: 'Goddess Renuka Mata',
      title: 'Shri Renuka Yellamma Songs',
      searchHint: 'Search Renuka, Yellamma, Bonalu, Jogwa songs...',
      emptySearchHint: 'Try searching Naa Pere Yellamma, Lallati Bhandar, or Mangli',
      songs: kRenukaSongsCatalog,
      categories: categories,
      accentColor: Color(0xFFE91E63),
      blessingMessage: 'उदो बोला उदो अंबाबाई माऊलीचा! आई रेणुका यल्लम्मा देवी की जय! 🚩🪷',
    );
  }
}
