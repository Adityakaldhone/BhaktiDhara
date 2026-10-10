import 'package:flutter/material.dart';

import '../../data/datasources/venkatesh_songs_catalog.dart';
import 'deity_songs_screen.dart';

/// YouTube Search Results style screen for Lord Venkatesh (Tirupati Balaji / Srinivasa) songs,
/// Annamacharya kirtanas, and suprabhatam.
/// Wraps [DeitySongsScreen] with Lord Venkatesh configuration.
class VenkateshSongsScreen extends StatelessWidget {
  const VenkateshSongsScreen({super.key});

  static const List<String> categories = [
    'All',
    'Popular & Trending',
    'Annamacharya Kirtanas',
    'Tirumala Bhaktigeet',
    'Govinda Namavali',
    'Suprabhatam & Stotram',
    'Marathi Vyankatesh',
  ];

  @override
  Widget build(BuildContext context) {
    return const DeitySongsScreen(
      deityKey: 'Lord Venkatesh',
      title: 'Shri Venkatesh Balaji Songs',
      searchHint: 'Search Venkateshwara, Balaji, Annamacharya, Suprabhatam...',
      emptySearchHint: 'Try searching Sri Venkateswara Suprabhatam, Govinda Namalu, or Sriman Narayana',
      songs: kVenkateshSongsCatalog,
      categories: categories,
      accentColor: Color(0xFFFFA000),
      blessingMessage: 'गोविंदा गोविंदा! ॐ नमो वेङ्कटेशाय! 🚩🙏',
    );
  }
}
