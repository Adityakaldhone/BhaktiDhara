/// Entity representing a YouTube-embeddable devotional song, bhajan, or stotra video.
class DevotionalSongItem {
  final String id;
  final String song;
  final String artist;
  final String videoId;
  final String videoTitle;
  final String channel;
  final String category;
  final String durationText;
  final String viewsText;

  const DevotionalSongItem({
    required this.id,
    required this.song,
    required this.artist,
    required this.videoId,
    required this.videoTitle,
    required this.channel,
    this.category = 'All',
    this.durationText = '5:24',
    this.viewsText = '12M views',
  });

  /// High quality thumbnail (480x360)
  String get thumbnailUrl => 'https://img.youtube.com/vi/$videoId/hqdefault.jpg';

  /// Max resolution thumbnail (1280x720)
  String get maxResThumbnailUrl => 'https://img.youtube.com/vi/$videoId/maxresdefault.jpg';

  /// Medium quality thumbnail (320x180)
  String get mqThumbnailUrl => 'https://img.youtube.com/vi/$videoId/mqdefault.jpg';
}

/// Backwards-compatible alias for Lord Ganesha songs.
typedef GaneshaSongItem = DevotionalSongItem;
