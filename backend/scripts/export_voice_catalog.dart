import 'dart:convert';
import 'dart:io';

import 'package:nitya_aarti/data/datasources/bundled_aarti_catalog.dart';
import 'package:nitya_aarti/data/datasources/bundled_song_catalog.dart';

void main() {
  stdout.write(
    jsonEncode({
      'aartis': [
        for (final item in bundledAartiCatalog)
          {
            'id': item.id,
            'title': item.title,
            'titleMr': item.titleMr,
            'titleHi': item.titleHi,
            'deity': item.deity,
            'deityMr': item.deityMr,
            'deityHi': item.deityHi,
            'youtubeVideoId': item.youtubeVideoId,
            'about': item.about,
            'aboutHi': item.aboutHi,
            'aboutMr': item.aboutMr,
            'durationText': item.durationText,
            'singer': item.singer,
          },
      ],
      'songs': [
        for (final video in catalogVideosById.values)
          {
            'id': video.song.id,
            'title': video.song.song,
            'singer': video.song.artist,
            'durationText': video.song.durationText,
            'youtubeVideoId': video.song.videoId,
            'names': spokenSongTitles(video.song).toSet().toList(),
          },
      ],
    }),
  );
}
