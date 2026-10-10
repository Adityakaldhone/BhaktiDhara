import 'package:flutter/material.dart';

import '../../data/datasources/gondavalekar_maharaj_songs_catalog.dart';
import 'deity_songs_screen.dart';

/// YouTube Search Results style screen for Shri Brahmachaitanya Gondavalekar Maharaj songs.
/// Wraps [DeitySongsScreen] with Shri Gondavalekar Maharaj configuration.
class GondavalekarMaharajSongsScreen extends StatelessWidget {
  const GondavalekarMaharajSongsScreen({super.key});

  static const List<String> categories = [
    'All',
    'Abhang & Bhajan',
    'Popular & Pravachan',
    'Naam Jap & Dhun',
    'Aarti & Upasana',
    'Stotra & Ashtak',
    'Bhaktigeet',
  ];

  @override
  Widget build(BuildContext context) {
    return const DeitySongsScreen(
      deityKey: 'Gondavalekar Maharaj',
      title: 'Shri Gondavalekar Maharaj Songs',
      searchHint: 'Search Gondavalekar Maharaj songs, abhang, Ram naam...',
      emptySearchHint: 'Try searching Shri Ram Jay Ram, Rahul Deshpande, or Subodh',
      songs: kGondavalekarMaharajSongsCatalog,
      categories: categories,
      accentColor: Color(0xFFE2B04F),
      blessingMessage: 'श्रीराम जय राम जय जय राम! नामातच सर्व सुख सामावले आहे! 🙏🌸',
    );
  }
}
