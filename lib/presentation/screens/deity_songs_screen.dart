import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';

import '../../domain/entities/devotional_song_item.dart';
import 'deity_video_watch_screen.dart';

/// Common reusable YouTube Search Results style screen for devotional songs.
/// Displays devotional songs with search bar, filter chips,
/// YouTube-format video cards (16:9 thumbnail, duration badge, channel info, views),
/// and navigates to [DeityVideoWatchScreen] upon selecting any video.
class DeitySongsScreen extends StatefulWidget {
  final String deityKey;
  final String title;
  final String searchHint;
  final List<DevotionalSongItem> songs;
  final List<String> categories;
  final Color accentColor;
  final String blessingMessage;
  final String emptySearchHint;
  final void Function(DevotionalSongItem song, List<DevotionalSongItem> allSongs)? onOpenVideo;

  const DeitySongsScreen({
    super.key,
    required this.deityKey,
    required this.title,
    required this.searchHint,
    required this.songs,
    required this.categories,
    this.accentColor = const Color(0xFFE2B04F),
    this.blessingMessage = 'प्रभूंचे आशीर्वाद सदैव तुमच्या पाठीशी असोत! 🙏✨',
    this.emptySearchHint = '',
    this.onOpenVideo,
  });

  @override
  State<DeitySongsScreen> createState() => _DeitySongsScreenState();
}

class _DeitySongsScreenState extends State<DeitySongsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All';
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<DevotionalSongItem> get _filteredSongs {
    return widget.songs.where((song) {
      final matchesCategory = _selectedCategory == 'All' ||
          song.category.toLowerCase() == _selectedCategory.toLowerCase();

      final q = _searchQuery.toLowerCase().trim();
      final matchesQuery = q.isEmpty ||
          song.song.toLowerCase().contains(q) ||
          song.videoTitle.toLowerCase().contains(q) ||
          song.artist.toLowerCase().contains(q) ||
          song.channel.toLowerCase().contains(q);

      return matchesCategory && matchesQuery;
    }).toList();
  }

  void _openVideo(DevotionalSongItem song) {
    HapticFeedback.lightImpact();
    if (widget.onOpenVideo != null) {
      widget.onOpenVideo!(song, widget.songs);
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DeityVideoWatchScreen(
          initialSong: song,
          allSongs: widget.songs,
          deityTitle: widget.title,
          blessingMessage: widget.blessingMessage,
          accentColor: widget.accentColor,
        ),
      ),
    );
  }

  void _showMoreOptions(DevotionalSongItem song) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF222222),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.play_arrow_rounded, color: Colors.white),
                title: const Text('Play Now', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(ctx);
                  _openVideo(song);
                },
              ),
              ListTile(
                leading: const Icon(Icons.share_rounded, color: Colors.white),
                title: const Text('Share Song', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(ctx);
                  SharePlus.instance.share(
                    ShareParams(
                      text: 'Watch ${song.song} on YouTube: https://www.youtube.com/watch?v=${song.videoId}',
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.copy_rounded, color: Colors.white),
                title: const Text('Copy YouTube Link', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Clipboard.setData(ClipboardData(
                    text: 'https://www.youtube.com/watch?v=${song.videoId}',
                  ));
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('YouTube link copied to clipboard'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final songs = _filteredSongs;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: const Color(0xFF0F0F0F),
        appBar: AppBar(
          backgroundColor: const Color(0xFF0F0F0F),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          titleSpacing: 0,
          title: Container(
            height: 40,
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF222222),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFF333333)),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val),
              style: const TextStyle(color: Colors.white, fontSize: 14),
              cursorColor: widget.accentColor,
              decoration: InputDecoration(
                hintText: widget.searchHint,
                hintStyle: const TextStyle(color: Color(0xFF888888), fontSize: 13),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: Color(0xFFAAAAAA),
                  size: 20,
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
        ),
        body: Column(
          children: [
            // ── Filter Chips Row (YouTube Pills) ──────────────────────────
            Container(
              height: 46,
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: widget.categories.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (ctx, index) {
                  final cat = widget.categories[index];
                  final isSelected = cat == _selectedCategory;
                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _selectedCategory = cat);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.white : const Color(0xFF272727),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: isSelected ? Colors.white : Colors.white10,
                        ),
                      ),
                      child: Text(
                        cat,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? Colors.black : Colors.white,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const Divider(color: Colors.white12, height: 1),

            // ── Video Feed / Search Results List ──────────────────────────
            Expanded(
              child: songs.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.search_off_rounded,
                            size: 64,
                            color: Colors.white38,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No songs found for "$_searchQuery"',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              color: Colors.white70,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (widget.emptySearchHint.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              widget.emptySearchHint,
                              style: const TextStyle(fontSize: 12.5, color: Colors.white38),
                            ),
                          ],
                          const SizedBox(height: 16),
                          TextButton.icon(
                            style: TextButton.styleFrom(
                              foregroundColor: widget.accentColor,
                            ),
                            icon: const Icon(Icons.refresh_rounded),
                            label: const Text('Reset Search'),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                                _selectedCategory = 'All';
                              });
                            },
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
                      itemCount: songs.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 20),
                      itemBuilder: (ctx, index) {
                        final song = songs[index];
                        return _buildYouTubeCard(song);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildYouTubeCard(DevotionalSongItem song) {
    return GestureDetector(
      onTap: () => _openVideo(song),
      child: Container(
        color: Colors.transparent,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 16:9 Thumbnail Container
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      song.thumbnailUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Container(
                        color: const Color(0xFF222222),
                        child: Center(
                          child: Icon(
                            Icons.music_video_rounded,
                            size: 48,
                            color: widget.accentColor,
                          ),
                        ),
                      ),
                    ),
                    // YouTube duration badge at bottom right
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2.5),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          song.durationText,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Video Details below thumbnail
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Channel Avatar circle
                CircleAvatar(
                  radius: 18,
                  backgroundColor: widget.accentColor,
                  child: Text(
                    song.channel.isNotEmpty ? song.channel[0].toUpperCase() : 'D',
                    style: const TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Title, Channel, Views & Category
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        song.song,
                        style: GoogleFonts.inter(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          height: 1.25,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              song.channel,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFFAAAAAA),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.check_circle_rounded,
                            size: 13,
                            color: Colors.white60,
                          ),
                          Text(
                            ' • ${song.viewsText}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFFAAAAAA),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${song.artist} • ${song.category}',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          color: widget.accentColor.withValues(alpha: 0.9),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                // Three-dots menu button
                IconButton(
                  icon: const Icon(
                    Icons.more_vert_rounded,
                    color: Colors.white70,
                    size: 20,
                  ),
                  onPressed: () => _showMoreOptions(song),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
