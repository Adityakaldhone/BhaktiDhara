import 'package:flutter/material.dart';

import '../../data/datasources/siddhanath_songs_catalog.dart';
import 'deity_songs_screen.dart';

/// YouTube Search Results style screen for Lord Siddhanath (Kharsundi / Halsiddhanath) songs.
/// Wraps [DeitySongsScreen] with Lord Siddhanath configuration.
class SiddhanathSongsScreen extends StatelessWidget {
  const SiddhanathSongsScreen({super.key});

  static const List<String> categories = [
    'All',
    'Kharsundi Bhaktigeet',
    'Aarti & Stuti',
    'Jagran & Gondhal',
    'Halsiddhanath & Appachiwadi',
    'Palkhi, Sasan & Gaji',
    'Mantra & Jaap',
  ];

  @override
  Widget build(BuildContext context) {
    return const DeitySongsScreen(
      deityKey: 'Lord Siddhanath',
      title: 'Shri Siddhanath Songs',
      searchHint: 'Search Siddhanath, Kharsundi, Halsiddhanath songs...',
      emptySearchHint: 'Try searching Siddhanathacha Jagran Gondhal, Kharsundicha Raja, or Changbhala',
      songs: kSiddhanathSongsCatalog,
      categories: categories,
      accentColor: Color(0xFFFF6F00),
      blessingMessage: 'नाथबाबाच्या नावानं चांगभलं! सिद्धनाथ जोगेश्वरी माता की जय! 🚩🟡',
    );
  }
}
