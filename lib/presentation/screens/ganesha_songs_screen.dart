import 'package:flutter/material.dart';

import '../../data/datasources/ganesha_songs_catalog.dart';
import 'deity_songs_screen.dart';
import 'ganesha_video_watch_screen.dart';

/// YouTube Search Results style screen for Lord Ganesha songs.
/// Wraps [DeitySongsScreen] with Lord Ganesha configuration.
class GaneshaSongsScreen extends StatelessWidget {
  const GaneshaSongsScreen({super.key});

  static const List<String> categories = [
    'All',
    'Bollywood',
    'Aarti',
    'Marathi Bhaktigeet',
    'Mantra & Stotra',
    'DJ & Dhol',
  ];

  @override
  Widget build(BuildContext context) {
    return DeitySongsScreen(
      deityKey: 'Lord Ganesha',
      title: 'Shri Ganesh Songs',
      searchHint: 'Search Ganesha songs, aartis, bhajans...',
      emptySearchHint: 'Try searching Aarti, Agneepath, or Shankar Mahadevan',
      songs: kGaneshaSongsCatalog,
      categories: categories,
      accentColor: const Color(0xFFE2B04F),
      blessingMessage: 'श्री गणपती बाप्पांचा आशीर्वाद तुमच्या पाठीशी असो! 🙏🌸',
      onOpenVideo: (song, all) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => GaneshaVideoWatchScreen(
              initialSong: song,
              allSongs: all,
            ),
          ),
        );
      },
    );
  }
}
