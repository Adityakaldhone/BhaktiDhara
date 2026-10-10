import 'package:flutter/material.dart';

import '../../data/datasources/durga_songs_catalog.dart';
import 'deity_songs_screen.dart';

/// YouTube Search Results style screen for Goddess Durga (Maa Durga / Sherawali / Jagdamba / Ambe Maa)
/// stotrams, mantras, chalisas, garbas, gondhals, and Navratri songs.
/// Wraps [DeitySongsScreen] with Goddess Durga configuration.
class DurgaSongsScreen extends StatelessWidget {
  const DurgaSongsScreen({super.key});

  static const List<String> categories = [
    'All',
    'Popular & Trending',
    'Stotram & Kavach',
    'Garba & Dandiya',
    'Gondhal & Jogwa',
    'Mantra & Chalisa',
    'Devi Bhajan & Geet',
  ];

  @override
  Widget build(BuildContext context) {
    return const DeitySongsScreen(
      deityKey: 'Goddess Durga',
      title: 'Maa Durga Songs',
      searchHint: 'Search Maa Durga, Aigiri Nandini, Garba, Gondhal...',
      emptySearchHint: 'Try searching Mahishasura Mardini, Moti Veraana, Durga Chalisa, or Gondhal',
      songs: kDurgaSongsCatalog,
      categories: categories,
      accentColor: Color(0xFFD32F2F),
      blessingMessage: 'जय माता दी! ॐ ऐं ह्रीं क्लीं चामुण्डायै विच्चे! सर्वमंगल मांगल्ये शिवे सर्वार्थ साधिके! 🚩🪷',
    );
  }
}
