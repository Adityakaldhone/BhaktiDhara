import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
// ignore: depend_on_referenced_packages
import 'package:webview_flutter_android/webview_flutter_android.dart';
// ignore: depend_on_referenced_packages
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

import '../../domain/entities/devotional_song_item.dart';

const String _kYoutubeEmbedOrigin = 'https://com.kaldhone.bhaktidhara';

/// Common reusable YouTube-style mobile watch screen for any deity's devotional songs.
/// Plays video at top (no lyrics) with video details, channel info,
/// like/share actions, and suggested videos ("Up Next") below.
class DeityVideoWatchScreen extends StatefulWidget {
  final DevotionalSongItem initialSong;
  final List<DevotionalSongItem> allSongs;
  final String deityTitle;
  final String blessingMessage;
  final Color accentColor;

  const DeityVideoWatchScreen({
    super.key,
    required this.initialSong,
    required this.allSongs,
    this.deityTitle = 'Devotional Songs',
    this.blessingMessage = 'प्रभूंचे आशीर्वाद सदैव तुमच्या पाठीशी असोत! 🙏✨',
    this.accentColor = const Color(0xFFE2B04F),
  });

  @override
  State<DeityVideoWatchScreen> createState() => _DeityVideoWatchScreenState();
}

class _DeityVideoWatchScreenState extends State<DeityVideoWatchScreen>
    with WidgetsBindingObserver {
  late DevotionalSongItem _currentSong;
  WebViewController? _webController;
  bool _isLoading = true;
  bool _isLiked = false;
  bool _isSaved = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _currentSong = widget.initialSong;
    if (!kIsWeb) {
      _initWebViewController(_currentSong.videoId);
    } else {
      _isLoading = false;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pauseVideo();
    try {
      _webController?.loadHtmlString(
        '<!DOCTYPE html><html><body style="background:#000;"></body></html>',
      );
    } catch (_) {}
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden) {
      _pauseVideo();
    }
  }

  void _pauseVideo() {
    try {
      _webController?.runJavaScript(
        "try { if (window.player && typeof window.player.pauseVideo === 'function') { window.player.pauseVideo(); } } catch(e) {}",
      );
    } catch (_) {}
  }

  void _initWebViewController(String videoId) {
    try {
      final embedHtml = '''
<!DOCTYPE html>
<html>
  <head>
    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
    <meta name="referrer" content="strict-origin-when-cross-origin">
    <style>
      * { margin: 0; padding: 0; box-sizing: border-box; }
      html, body { width: 100%; height: 100%; background: #000; overflow: hidden; }
      #player { width: 100%; height: 100%; }
    </style>
  </head>
  <body>
    <div id="player"></div>
    <script>
      var tag = document.createElement('script');
      tag.src = 'https://www.youtube.com/iframe_api';
      document.head.appendChild(tag);

      var player;
      function onYouTubeIframeAPIReady() {
        player = new YT.Player('player', {
          height: '100%',
          width: '100%',
          videoId: '$videoId',
          host: 'https://www.youtube.com',
          playerVars: {
            autoplay: 1,
            playsinline: 1,
            rel: 0,
            controls: 1,
            fs: 1,
            origin: '$_kYoutubeEmbedOrigin'
          },
          events: {
            onReady: function() {
              try { player.playVideo(); } catch(e) {}
            }
          }
        });
      }
      window.onYouTubeIframeAPIReady = onYouTubeIframeAPIReady;
      if (window.YT && window.YT.Player) {
        onYouTubeIframeAPIReady();
      }
    </script>
  </body>
</html>
''';

      late final PlatformWebViewControllerCreationParams params;
      if (WebViewPlatform.instance is WebKitWebViewPlatform) {
        params = WebKitWebViewControllerCreationParams(
          allowsInlineMediaPlayback: true,
          mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
        );
      } else {
        params = const PlatformWebViewControllerCreationParams();
      }

      final controller = WebViewController.fromPlatformCreationParams(params);

      if (controller.platform is AndroidWebViewController) {
        final android = controller.platform as AndroidWebViewController;
        android.setMediaPlaybackRequiresUserGesture(false);
      }

      controller
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(Colors.black)
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageFinished: (_) {
              if (mounted) setState(() => _isLoading = false);
            },
          ),
        )
        ..loadHtmlString(embedHtml, baseUrl: _kYoutubeEmbedOrigin);

      _webController = controller;
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _switchSong(DevotionalSongItem newSong) {
    if (_currentSong.id == newSong.id) return;
    HapticFeedback.mediumImpact();
    _pauseVideo();
    setState(() {
      _currentSong = newSong;
      _isLoading = true;
    });

    _initWebViewController(newSong.videoId);

    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _shareCurrentSong() {
    final url = 'https://www.youtube.com/watch?v=${_currentSong.videoId}';
    SharePlus.instance.share(
      ShareParams(
        text: 'Listen to ${_currentSong.song} (${_currentSong.artist}) on BhaktiDhara:\n$url',
        subject: _currentSong.song,
      ),
    );
  }

  Future<void> _openInYouTube() async {
    HapticFeedback.lightImpact();
    _pauseVideo();
    final url = Uri.parse('https://www.youtube.com/watch?v=${_currentSong.videoId}');
    try {
      final launched = await launchUrl(url, mode: LaunchMode.externalApplication);
      if (!launched) {
        await launchUrl(url, mode: LaunchMode.platformDefault);
      }
    } catch (_) {
      // Fallback
    }
  }

  void _toggleLike() {
    HapticFeedback.lightImpact();
    setState(() {
      _isLiked = !_isLiked;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF272727),
        content: Text(
          _isLiked ? 'Added to Devotional Favorites 🙏' : 'Removed from Favorites',
          style: const TextStyle(color: Colors.white),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _toggleSave() {
    HapticFeedback.selectionClick();
    setState(() {
      _isSaved = !_isSaved;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF272727),
        content: Text(
          _isSaved ? 'Saved to Devotional Playlist' : 'Removed from Playlist',
          style: const TextStyle(color: Colors.white),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final suggestedSongs =
        widget.allSongs.where((s) => s.id != _currentSong.id).toList();

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: const Color(0xFF0F0F0F),
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              // ── 1. Video Player Container (Fixed at top) ─────────────────
              Stack(
                children: [
                  AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Container(
                      color: Colors.black,
                      child: _webController != null
                          ? WebViewWidget(controller: _webController!)
                          : Center(
                              child: CircularProgressIndicator(
                                color: widget.accentColor,
                              ),
                            ),
                    ),
                  ),
                  if (_isLoading)
                    Positioned.fill(
                      child: Center(
                        child: CircularProgressIndicator(
                          color: widget.accentColor,
                        ),
                      ),
                    ),
                  // Back button overlay in top left
                  Positioned(
                    top: 6,
                    left: 6,
                    child: Material(
                      color: Colors.black45,
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () => Navigator.pop(context),
                        child: const Padding(
                          padding: EdgeInsets.all(8),
                          child: Icon(
                            Icons.arrow_back_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // ── 2. Scrollable Body: Details + Actions + Up Next ─────────
              Expanded(
                child: ListView(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  children: [
                    // Video Title
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        _currentSong.videoTitle,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          height: 1.3,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Views & Category
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        '${_currentSong.viewsText} • ${_currentSong.category} • ${_currentSong.artist}',
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: Color(0xFFAAAAAA),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Channel Pill Row
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: widget.accentColor,
                            child: Text(
                              _currentSong.channel.isNotEmpty
                                  ? _currentSong.channel[0].toUpperCase()
                                  : 'D',
                              style: const TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        _currentSong.channel,
                                        style: GoogleFonts.inter(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(
                                      Icons.check_circle_rounded,
                                      size: 14,
                                      color: Colors.white70,
                                    ),
                                  ],
                                ),
                                const Text(
                                  'Official Content • Hosted on YouTube',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: Color(0xFFAAAAAA),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Actions Bar (Compliant Devotional & Official Links)
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          _buildActionPill(
                            icon: _isLiked
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            label: _isLiked ? 'Favorited' : 'Favorite',
                            isActive: _isLiked,
                            onTap: _toggleLike,
                          ),
                          const SizedBox(width: 8),
                          _buildActionPill(
                            icon: Icons.open_in_new_rounded,
                            label: 'Watch on YouTube',
                            onTap: _openInYouTube,
                          ),
                          const SizedBox(width: 8),
                          _buildActionPill(
                            icon: Icons.share_rounded,
                            label: 'Share',
                            onTap: _shareCurrentSong,
                          ),
                          const SizedBox(width: 8),
                          _buildActionPill(
                            icon: _isSaved
                                ? Icons.bookmark_rounded
                                : Icons.bookmark_border_rounded,
                            label: _isSaved ? 'Saved' : 'Save',
                            isActive: _isSaved,
                            onTap: _toggleSave,
                          ),
                          const SizedBox(width: 8),
                          _buildActionPill(
                            icon: Icons.temple_hindu_rounded,
                            label: 'Blessings',
                            onTap: () {
                              HapticFeedback.heavyImpact();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  backgroundColor: const Color(0xFFE65100),
                                  content: Text(
                                    widget.blessingMessage,
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Divider(color: Colors.white12, height: 1),
                    const SizedBox(height: 12),

                    // ── Up Next / Related Videos ─────────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Text(
                            'Up Next',
                            style: GoogleFonts.inter(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF272727),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${suggestedSongs.length}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.white70,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Suggested Videos List
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: suggestedSongs.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 14),
                      itemBuilder: (ctx, index) {
                        final song = suggestedSongs[index];
                        return _buildSuggestedCard(song);
                      },
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionPill({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isActive = false,
  }) {
    return Material(
      color: isActive ? Colors.white : const Color(0xFF272727),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 17,
                color: isActive ? Colors.black : Colors.white,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: isActive ? Colors.black : Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuggestedCard(DevotionalSongItem song) {
    return GestureDetector(
      onTap: () => _switchSong(song),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 16:9 Mini Thumbnail
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 130,
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
                        child: Icon(
                          Icons.music_note_rounded,
                          color: widget.accentColor,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 4,
                      right: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 1.5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Text(
                          song.durationText,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Metadata
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  song.song,
                  style: GoogleFonts.inter(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    height: 1.25,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  song.channel,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: Color(0xFFAAAAAA),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${song.viewsText} • ${song.category}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF888888),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
