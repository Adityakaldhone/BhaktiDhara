import 'package:flutter/material.dart';

import '../../domain/entities/ganesha_song_item.dart';
import 'deity_video_watch_screen.dart';

/// YouTube-style mobile watch screen for Lord Ganesha songs.
/// Wraps [DeityVideoWatchScreen] with Lord Ganesha configuration.
class GaneshaVideoWatchScreen extends StatelessWidget {
  final GaneshaSongItem initialSong;
  final List<GaneshaSongItem> allSongs;

  const GaneshaVideoWatchScreen({
    super.key,
    required this.initialSong,
    required this.allSongs,
  });

  @override
  Widget build(BuildContext context) {
    return DeityVideoWatchScreen(
      initialSong: initialSong,
      allSongs: allSongs,
      deityTitle: 'Lord Ganesha',
      blessingMessage: 'श्री गणपती बाप्पांचा आशीर्वाद तुमच्या पाठीशी असो! 🙏🌸',
      accentColor: const Color(0xFFE2B04F),
    );
  }
}
