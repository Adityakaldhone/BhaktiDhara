import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:webview_flutter/webview_flutter.dart';
// ignore: depend_on_referenced_packages
import 'package:webview_flutter_android/webview_flutter_android.dart';
// ignore: depend_on_referenced_packages
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../domain/entities/aarti_item.dart';
import '../../services/audio_service.dart';
import '../../services/backend_service.dart';
import '../widgets/lyric_card.dart';

/// App origin used as Referer so YouTube embeds avoid Error 153 /
/// "Watch on YouTube" interstitial.
const String _kYoutubeEmbedOrigin = 'https://com.kaldhone.bhaktidhara';

/// Screen 2 — Chanting Altar (In-App Embedded Video Player & Devotional Manuscript).
///
/// Top area (Header, Video, Pooja Tools) is fixed.
/// Lyrics below are manually scrollable (no audio sync).
class AartiAltarScreen extends StatefulWidget {
  final AartiItem aarti;
  const AartiAltarScreen({super.key, required this.aarti});

  @override
  State<AartiAltarScreen> createState() => _AartiAltarScreenState();
}

class _AartiAltarScreenState extends State<AartiAltarScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  WebViewController? _webController;
  bool _isLoading = true;
  // ignore: unused_field
  bool _isScreenAwake = true;
  bool _isDeepakLit = false;
  bool _showUnmuteHint = false;
  int _videoFallbackIndex = 0;

  // Accessibility font scaler for 50+ demographic
  static const _fontScales = [1.0, 1.25, 1.5];
  // ignore: prefer_final_fields
  int _fontScaleIndex = 0;
  double get _fontScale => _fontScales[_fontScaleIndex];

  final AudioService _audio = AudioService();

  // Animations for pooja tools
  late final AnimationController _bellController;
  late final AnimationController _shankhController;
  late final AnimationController _deepakController;
  late final AnimationController _petalsController;

  final List<_FlowerParticle> _petals = [];
  final math.Random _random = math.Random();
  ui.Image? _pushpaImage;

  String get _activeVideoId =>
      widget.aarti.videoIdWithFallback(_videoFallbackIndex);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    BackendService.trackEvent(
      'aarti_open',
      item: widget.aarti.title,
      props: {'id': widget.aarti.id, 'deity': widget.aarti.deity},
    );
    try {
      WakelockPlus.enable();
    } catch (_) {}
    _loadPushpaAsset();

    // 1. Tool animations
    _bellController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _shankhController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    // Continuous breathing flame flicker for diya
    _deepakController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _petalsController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..addListener(() {
        if (_petals.isNotEmpty) {
          setState(() {
            for (var p in _petals) {
              p.update();
            }
            _petals.removeWhere((p) => p.y > 1.15);
            if (_petals.isEmpty) {
              _petalsController.stop();
            }
          });
        }
      });

    // 2. Embedded YouTube Player
    if (!kIsWeb) {
      _initMobileWebViewController();
    } else {
      _isLoading = false;
    }
  }

  void _initMobileWebViewController() {
    try {
      final videoId = _activeVideoId;
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
      var reportedMuted = false;
      var playerCreated = false;

      function post(msg) {
        try {
          if (window.PlayerBridge && PlayerBridge.postMessage) {
            PlayerBridge.postMessage(String(msg));
          }
        } catch (e) {}
      }

      function reportMuteState() {
        if (!player || !player.isMuted) return;
        try {
          if (player.isMuted()) {
            if (!reportedMuted) {
              reportedMuted = true;
              post('muted');
            }
          } else if (reportedMuted) {
            reportedMuted = false;
            post('unmuted');
          }
        } catch (e) {}
      }

      function onYouTubeIframeAPIReady() {
        if (playerCreated) return;
        playerCreated = true;
        player = new YT.Player('player', {
          height: '100%',
          width: '100%',
          videoId: '$videoId',
          host: 'https://www.youtube.com',
          playerVars: {
            autoplay: 1,
            mute: 1,
            playsinline: 1,
            rel: 0,
            controls: 1,
            fs: 0,
            iv_load_policy: 3,
            enablejsapi: 1,
            origin: '$_kYoutubeEmbedOrigin'
          },
          events: {
            onReady: function () {
              try { player.playVideo(); } catch (e) {}
              reportMuteState();
            },
            onStateChange: function () {
              reportMuteState();
            },
            onError: function (event) {
              post('error:' + event.data);
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
        ..addJavaScriptChannel(
          'PlayerBridge',
          onMessageReceived: _onPlayerBridgeMessage,
        )
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageFinished: (_) {
              if (mounted) setState(() => _isLoading = false);
            },
            onNavigationRequest: (request) {
              final url = request.url;
              if (url.startsWith('https://www.youtube.com/embed') ||
                  url.startsWith('https://www.youtube-nocookie.com/embed') ||
                  url.startsWith('about:') ||
                  url.startsWith('https://www.youtube.com/iframe_api') ||
                  url.contains('youtube.com/s/player') ||
                  url.contains('googlevideo.com') ||
                  url.contains('google.com') ||
                  url.contains('ytimg.com') ||
                  url.contains('gstatic.com')) {
                return NavigationDecision.navigate;
              }
              if (url.contains('youtube.com/watch') ||
                  url.contains('youtu.be/') ||
                  url.contains('youtube.com/@') ||
                  url.contains('youtube.com/channel')) {
                final uri = Uri.tryParse(url);
                if (uri != null) {
                  launchUrl(uri, mode: LaunchMode.externalApplication);
                }
                return NavigationDecision.prevent;
              }
              return NavigationDecision.navigate;
            },
          ),
        )
        ..loadHtmlString(embedHtml, baseUrl: '$_kYoutubeEmbedOrigin/');

      _webController = controller;
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onPlayerBridgeMessage(JavaScriptMessage message) {
    if (!mounted) return;
    final data = message.message;

    if (data == 'muted') {
      if (!_showUnmuteHint) setState(() => _showUnmuteHint = true);
      return;
    }
    if (data == 'unmuted') {
      if (_showUnmuteHint) setState(() => _showUnmuteHint = false);
      return;
    }
    if (data.startsWith('error:')) {
      final code = int.tryParse(data.substring(6)) ?? 0;
      if (code == 100 || code == 101 || code == 150 || code == 153) {
        _tryNextBackupVideo();
      }
    }
  }

  void _tryNextBackupVideo() {
    final maxIndex = widget.aarti.backupVideoIds.length;
    if (_videoFallbackIndex >= maxIndex) return;
    setState(() {
      _videoFallbackIndex += 1;
      _isLoading = true;
      _showUnmuteHint = false;
    });
    _initMobileWebViewController();
  }

  Future<void> _unmuteFromUserTap() async {
    setState(() => _showUnmuteHint = false);
    await _webController?.runJavaScript('''
      if (player) {
        try {
          player.unMute();
          player.playVideo();
        } catch (e) {}
      }
    ''');
  }

  Future<void> _loadPushpaAsset() async {
    try {
      final byteData = await rootBundle.load('assets/aarti_screen/pushpa.png');
      final bytes = byteData.buffer.asUint8List();
      final codec = await ui.instantiateImageCodec(
        bytes,
        targetWidth: 80,
        targetHeight: 80,
      );
      final frame = await codec.getNextFrame();
      if (mounted) {
        setState(() {
          _pushpaImage = frame.image;
        });
      }
    } catch (_) {}
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      if (!kIsWeb && _webController != null) {
        _webController?.runJavaScript(
          'if(player && player.pauseVideo) player.pauseVideo();',
        );
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    try {
      WakelockPlus.disable();
    } catch (_) {}
    _audio.dispose();
    _bellController.dispose();
    _shankhController.dispose();
    _deepakController.dispose();
    _petalsController.dispose();
    super.dispose();
  }

  // ── Pooja Tool Handlers ──────────────────────────────────────────────────

  // ignore: unused_element
  void _toggleScreenAwake(bool value) {
    setState(() => _isScreenAwake = value);
    try {
      if (value) {
        WakelockPlus.enable();
      } else {
        WakelockPlus.disable();
      }
    } catch (_) {}
  }

  Future<void> _onGhantiTap() async {
    _bellController.forward(from: 0.0);
    await _audio.playBell();
  }

  Future<void> _onShankhTap() async {
    _shankhController.forward(from: 0.0);
    await _audio.playConch();
  }

  void _onDeepakTap() {
    HapticFeedback.mediumImpact();
    setState(() {
      _isDeepakLit = !_isDeepakLit;
      if (_isDeepakLit) {
        _deepakController.repeat(reverse: true);
      } else {
        _deepakController.stop();
        _deepakController.reset();
      }
    });
  }

  void _onPushpaTap() {
    HapticFeedback.mediumImpact();
    for (int i = 0; i < 36; i++) {
      final typeIndex = i % 5;
      final type = FlowerType.values[typeIndex];
      final baseSize =
          (type == FlowerType.blossom || type == FlowerType.marigoldFlower)
              ? 26.0 + _random.nextDouble() * 12.0
              : 18.0 + _random.nextDouble() * 10.0;

      _petals.add(
        _FlowerParticle(
          x: _random.nextDouble(),
          y: -_random.nextDouble() * 0.45,
          size: baseSize,
          speedY: 0.0035 + _random.nextDouble() * 0.0045,
          swingSpeed: 0.02 + _random.nextDouble() * 0.035,
          swingAmplitude: 0.015 + _random.nextDouble() * 0.03,
          rotation: _random.nextDouble() * 2 * math.pi,
          rotationSpeed: (_random.nextDouble() - 0.5) * 0.05,
          flipProgress: _random.nextDouble() * math.pi,
          flipSpeed: 0.03 + _random.nextDouble() * 0.04,
          type: type,
        ),
      );
    }
    if (!_petalsController.isAnimating) {
      _petalsController.repeat();
    }
  }

  String _toDevanagariNumeral(int number) {
    const digits = ['०', '१', '२', '३', '४', '५', '६', '७', '८', '९'];
    return number
        .toString()
        .split('')
        .map((ch) => digits[int.parse(ch)])
        .join();
  }

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    final titleText = widget.aarti.localizedTitle(locale);
    // ignore: unused_local_variable
    final aboutText = widget.aarti.localizedAbout(locale);

    return Scaffold(
      backgroundColor: const Color(0xFFFBEBD2),
      body: Stack(
        children: [
          // 1. Full Temple Background
          Positioned.fill(
            child: Image.asset(
              'assets/aarti_screen/bg.png',
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
            ),
          ),

          // 2. Main Content inside SafeArea
          SafeArea(
            bottom: false,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final availableHeight = constraints.maxHeight;
                    final videoMaxHeight =
                        (availableHeight * 0.30).clamp(150.0, 240.0);

                    return Column(
                      children: [
                        const SizedBox(height: 4),

                        // ── FIXED TOP SECTION ───────────────────────────────────
                        // Header Bar
                        _buildHeaderBar(context, titleText),

                        const SizedBox(height: 6),

                        // Video Card
                        _buildVideoCard(maxHeight: videoMaxHeight),

                        const SizedBox(height: 6),

                        // Pooja Controls Card (Compact, perfect background match)
                        _buildPoojaToolsCard(locale),

                        const SizedBox(height: 6),

                        // ── SCROLLABLE SECTION (manual scroll only) ─────────────
                        Expanded(
                          child: ListView.builder(
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(16, 2, 16, 36),
                            itemCount: widget.aarti.lyrics.length,
                            itemBuilder: (context, index) {
                              final stanza = widget.aarti.lyrics[index];
                              return LyricCard(
                                devanagari: stanza.devanagari,
                                transliteration: stanza.transliteration,
                                fontScale: _fontScale,
                                stanzaNumber: _toDevanagariNumeral(index + 1),
                              );
                            },
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),

          // 3. Flower Petals Shower Particle Layer
          if (_petals.isNotEmpty)
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _PetalsPainter(
                    petals: _petals,
                    pushpaImage: _pushpaImage,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── Header Bar ─────────────────────────────────────────────────────────────

  Widget _buildHeaderBar(BuildContext context, String titleText) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        height: 64,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Center Title & Om
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/aarti_screen/om.png',
                  width: 120,
                  height: 48,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 2),
                Image.asset(
                  'assets/decorations/horizontal_bar.png',
                  width: 140,
                  height: 10,
                  fit: BoxFit.contain,
                ),
              ],
            ),

            // Left Back Button
            Align(
              alignment: Alignment.centerLeft,
              child: GestureDetector(
                onTap: () => Navigator.maybePop(context),
                child: Image.asset(
                  'assets/aarti_screen/back_button.png',
                  width: 60,
                  height: 60,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Video Card ─────────────────────────────────────────────────────────────

  Widget _buildVideoCard({double? maxHeight}) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 520,
          maxHeight: maxHeight ?? 240,
        ),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFDCA65D), width: 1.8),
            boxShadow: const [
              BoxShadow(
                color: Color(0x332E1104),
                blurRadius: 14,
                spreadRadius: 1,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                children: [
                  if (kIsWeb)
                    HtmlElementView.fromTagName(
                      key: ValueKey(_activeVideoId),
                      tagName: 'iframe',
                      onElementCreated: (Object element) {
                        final iframe = element as dynamic;
                        iframe.src =
                            'https://www.youtube.com/embed/$_activeVideoId'
                            '?autoplay=1&mute=1&playsinline=1&rel=0'
                            '&enablejsapi=1&origin=$_kYoutubeEmbedOrigin';
                        iframe.style.border = 'none';
                        iframe.style.width = '100%';
                        iframe.style.height = '100%';
                        iframe.allow =
                            'accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture';
                        iframe.referrerPolicy = 'strict-origin-when-cross-origin';
                        iframe.allowFullscreen = true;
                      },
                    )
                  else if (_webController != null)
                    WebViewWidget(
                      key: ValueKey('yt_$_activeVideoId'),
                      controller: _webController!,
                    )
                  else
                    const SizedBox.shrink(),
                  if (!kIsWeb && _isLoading)
                    Container(
                      color: Colors.black,
                      child: const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFFE9B170),
                        ),
                      ),
                    ),
                  if (!kIsWeb && _showUnmuteHint && !_isLoading)
                    Positioned(
                      top: 10,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: GestureDetector(
                          onTap: _unmuteFromUserTap,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE9B170).withValues(alpha: 0.92),
                              borderRadius: BorderRadius.circular(28),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 8,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.volume_up_rounded,
                                  color: Color(0xFF2E1104),
                                  size: 18,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Tap video to unmute',
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF2E1104),
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Pooja Tools Card ───────────────────────────────────────────────────────

  Widget _buildPoojaToolsCard(String locale) {
    // ignore: unused_local_variable
    final awakeLabel = locale == 'mr'
        ? 'स्क्रीन चालू ठेवा'
        : 'स्क्रीन चालू रखें';

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          decoration: const BoxDecoration(
            image: DecorationImage(
          image: AssetImage('assets/aarti_screen/ghanti_card_container_bg.png'),
          fit: BoxFit.fill,
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x182E1104),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 4 Pooja Tools
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildToolItem(
                label: 'पूजा घंटी',
                onTap: _onGhantiTap,
                iconWidget: AnimatedBuilder(
                  animation: _bellController,
                  builder: (context, child) {
                    final angle =
                        math.sin(_bellController.value * 6 * math.pi) *
                        (1.0 - _bellController.value) *
                        0.22;
                    return Transform.rotate(angle: angle, child: child);
                  },
                  child: Image.asset(
                    'assets/aarti_screen/ghanti.png',
                    width: 30,
                    height: 30,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              _buildToolItem(
                label: 'शंख',
                onTap: _onShankhTap,
                iconWidget: AnimatedBuilder(
                  animation: _shankhController,
                  builder: (context, child) {
                    final scale =
                        1.0 +
                        math.sin(_shankhController.value * math.pi) * 0.08;
                    return Transform.scale(scale: scale, child: child);
                  },
                  child: Image.asset(
                    'assets/aarti_screen/shankh.png',
                    width: 28,
                    height: 28,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              _buildToolItem(
                label: 'दीपक',
                onTap: _onDeepakTap,
                iconWidget: AnimatedBuilder(
                  animation: _deepakController,
                  builder: (context, child) {
                    if (!_isDeepakLit) return child!;
                    final glow =
                        0.72 +
                        0.28 * math.sin(_deepakController.value * math.pi);
                    return Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFFB300)
                                .withValues(alpha: 0.75 * glow),
                            blurRadius: 18 * glow,
                            spreadRadius: 4 * glow,
                          ),
                          BoxShadow(
                            color: const Color(0xFFFF6D00)
                                .withValues(alpha: 0.55 * glow),
                            blurRadius: 8 * glow,
                            spreadRadius: 2 * glow,
                          ),
                          BoxShadow(
                            color: const Color(0xFFFFF9C4)
                                .withValues(alpha: 0.85 * glow),
                            blurRadius: 3,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: child,
                    );
                  },
                  child: Image.asset(
                    'assets/aarti_screen/deepak.png',
                    width: 28,
                    height: 28,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              _buildToolItem(
                label: 'पुष्प',
                onTap: _onPushpaTap,
                iconWidget: Image.asset(
                  'assets/aarti_screen/pushpa.png',
                  width: 28,
                  height: 28,
                  fit: BoxFit.contain,
                ),
              ),
            ],
          ),
        ],
      ),
        ),
      ),
    );
  }

  Widget _buildToolItem({
    required String label,
    required VoidCallback onTap,
    required Widget iconWidget,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Circular Flower Badge with Icon
          SizedBox(
            width: 68,
            height: 68,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Image.asset(
                  'assets/aarti_screen/icons_bg.png',
                  width: 68,
                  height: 68,
                  fit: BoxFit.contain,
                ),
                iconWidget,
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.notoSansDevanagari(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF9B0B08),
            ),
          ),
        ],
      ),
    );
  }

  // ── About this Aarti Card ──────────────────────────────────────────────────

  // ignore: unused_element
  Widget _buildAboutAartiCard(String aboutText) {
    return GestureDetector(
      onTap: () {
        // Show full description dialog on tap if user wants to read more
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: const Color(0xFFFDF3E1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(color: Color(0xFFD9A052), width: 1.5),
            ),
            title: Row(
              children: [
                Image.asset(
                  'assets/aarti_screen/book.png',
                  width: 32,
                  height: 32,
                ),
                const SizedBox(width: 8),
                Text(
                  'About this Aarti',
                  style: GoogleFonts.cormorantGaramond(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF9B0B08),
                  ),
                ),
              ],
            ),
            content: Text(
              aboutText,
              style: GoogleFonts.notoSansDevanagari(
                fontSize: 15,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF5C2C0A),
                height: 1.5,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(
                  'OK',
                  style: GoogleFonts.notoSansDevanagari(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF9B0B08),
                  ),
                ),
              ),
            ],
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage(
              'assets/aarti_screen/about_this_aarti_card_bg.png',
            ),
            fit: BoxFit.fill,
          ),
          boxShadow: [
            BoxShadow(
              color: Color(0x182E1104),
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Image.asset(
                  'assets/aarti_screen/book.png',
                  width: 28,
                  height: 28,
                  fit: BoxFit.contain,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'About this Aarti',
                    style: GoogleFonts.cormorantGaramond(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF9B0B08),
                    ),
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  color: Color(0xFF9B0B08),
                  size: 18,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              aboutText,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.notoSansDevanagari(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF6E6257),
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Lyrics Header ──────────────────────────────────────────────────────────

  // ignore: unused_element
  Widget _buildLyricsHeader() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/aarti_screen/book.png',
              width: 20,
              height: 20,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 6),
            Text(
              'Lyrics',
              style: GoogleFonts.cormorantGaramond(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF9B0B08),
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Image.asset(
          'assets/decorations/horizontal_bar.png',
          width: 120,
          height: 10,
          fit: BoxFit.contain,
        ),
      ],
    );
  }
}

// ── Diverse Realistic Flower Types ───────────────────────────────────────────

enum FlowerType {
  blossom, // Sacred whole red/gold pushpa blossom
  marigoldFlower, // Full golden genda blossom
  rosePetal, // Velvety red rose petal
  marigoldPetal, // Saffron/gold marigold petal
  jasmineBud, // Ivory white mogra flower
}

class _FlowerParticle {
  double x;
  double y;
  final double size;
  final double speedY;
  final double swingSpeed;
  final double swingAmplitude;
  double rotation;
  final double rotationSpeed;
  double flipProgress;
  final double flipSpeed;
  final FlowerType type;
  double swingProgress = 0;

  _FlowerParticle({
    required this.x,
    required this.y,
    required this.size,
    required this.speedY,
    required this.swingSpeed,
    required this.swingAmplitude,
    required this.rotation,
    required this.rotationSpeed,
    required this.flipProgress,
    required this.flipSpeed,
    required this.type,
  });

  void update() {
    y += speedY;
    swingProgress += swingSpeed;
    x += math.sin(swingProgress) * swingAmplitude * 0.08;
    rotation += rotationSpeed;
    flipProgress += flipSpeed;
  }
}

// ── Realistic Flower Shower Custom Painter ───────────────────────────────────

class _PetalsPainter extends CustomPainter {
  final List<_FlowerParticle> petals;
  final ui.Image? pushpaImage;

  _PetalsPainter({required this.petals, this.pushpaImage});

  @override
  void paint(Canvas canvas, Size size) {
    for (var p in petals) {
      if (p.y < -0.1 || p.y > 1.15) continue;

      final px = p.x * size.width;
      final py = p.y * size.height;

      canvas.save();
      canvas.translate(px, py);
      canvas.rotate(p.rotation);

      switch (p.type) {
        case FlowerType.blossom:
          _drawPushpaBlossom(canvas, p);
          break;
        case FlowerType.marigoldFlower:
          _drawMarigoldFlower(canvas, p);
          break;
        case FlowerType.rosePetal:
          _drawRosePetal(canvas, p);
          break;
        case FlowerType.marigoldPetal:
          _drawMarigoldPetal(canvas, p);
          break;
        case FlowerType.jasmineBud:
          _drawJasmineFlower(canvas, p);
          break;
      }

      canvas.restore();
    }
  }

  void _drawPushpaBlossom(Canvas canvas, _FlowerParticle p) {
    final flipScale = math.cos(p.flipProgress).abs().clamp(0.25, 1.0);
    canvas.scale(flipScale, 1.0);

    if (pushpaImage != null) {
      final src = Rect.fromLTWH(
        0,
        0,
        pushpaImage!.width.toDouble(),
        pushpaImage!.height.toDouble(),
      );
      final dst = Rect.fromCenter(
        center: Offset.zero,
        width: p.size,
        height: p.size,
      );
      canvas.drawImageRect(pushpaImage!, src, dst, Paint());
    } else {
      // Fallback layered blossom
      final r = p.size * 0.45;
      final paint = Paint()..color = const Color(0xFFD32F2F);
      canvas.drawCircle(Offset.zero, r, paint);
    }
  }

  void _drawMarigoldFlower(Canvas canvas, _FlowerParticle p) {
    final r = p.size * 0.5;
    final flipScale = math.cos(p.flipProgress).abs().clamp(0.35, 1.0);
    canvas.scale(flipScale, 1.0);

    // Outer golden petal layer (12 petals)
    final outerPaint = Paint()..color = const Color(0xFFFFB300);
    for (int i = 0; i < 12; i++) {
      final angle = i * (2 * math.pi / 12);
      canvas.save();
      canvas.translate(math.cos(angle) * r * 0.55, math.sin(angle) * r * 0.55);
      canvas.drawCircle(Offset.zero, r * 0.40, outerPaint);
      canvas.restore();
    }

    // Middle saffron petal layer (8 petals)
    final midPaint = Paint()..color = const Color(0xFFFF8F00);
    for (int i = 0; i < 8; i++) {
      final angle = i * (2 * math.pi / 8) + 0.25;
      canvas.save();
      canvas.translate(math.cos(angle) * r * 0.32, math.sin(angle) * r * 0.32);
      canvas.drawCircle(Offset.zero, r * 0.34, midPaint);
      canvas.restore();
    }

    // Center rich core
    final centerPaint = Paint()..color = const Color(0xFFE65100);
    canvas.drawCircle(Offset.zero, r * 0.26, centerPaint);

    final dotPaint = Paint()..color = const Color(0xFFBF360C);
    canvas.drawCircle(Offset.zero, r * 0.12, dotPaint);
  }

  void _drawRosePetal(Canvas canvas, _FlowerParticle p) {
    final flipScale = math.cos(p.flipProgress).clamp(-1.0, 1.0);
    canvas.scale(flipScale, 1.0);

    final halfW = p.size * 0.42;
    final halfH = p.size * 0.65;

    final path = Path()
      ..moveTo(0, -halfH)
      ..cubicTo(halfW * 1.15, -halfH * 0.4, halfW * 0.9, halfH * 0.5, 0, halfH)
      ..cubicTo(-halfW * 0.9, halfH * 0.5, -halfW * 1.15, -halfH * 0.4, 0, -halfH)
      ..close();

    final gradient = ui.Gradient.radial(
      Offset(0, -halfH * 0.2),
      halfH * 1.1,
      const [Color(0xFFE53935), Color(0xFFB71C1C), Color(0xFF880E4F)],
      [0.0, 0.65, 1.0],
    );

    final paint = Paint()..shader = gradient;
    canvas.drawPath(path, paint);

    // Subtle satin highlight sheen
    final highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    canvas.drawPath(path, highlightPaint);
  }

  void _drawMarigoldPetal(Canvas canvas, _FlowerParticle p) {
    final flipScale = math.cos(p.flipProgress).clamp(-1.0, 1.0);
    canvas.scale(1.0, flipScale);

    final w = p.size * 0.32;
    final h = p.size * 0.70;

    final path = Path()
      ..moveTo(0, -h * 0.5)
      ..lineTo(w * 0.45, -h * 0.42)
      ..lineTo(w * 0.5, -h * 0.32)
      ..quadraticBezierTo(w * 0.7, 0, 0, h * 0.5)
      ..quadraticBezierTo(-w * 0.7, 0, -w * 0.5, -h * 0.32)
      ..lineTo(-w * 0.45, -h * 0.42)
      ..close();

    final gradient = ui.Gradient.linear(
      Offset(0, h * 0.5),
      Offset(0, -h * 0.5),
      const [Color(0xFFE65100), Color(0xFFFF9800), Color(0xFFFFEB3B)],
      [0.0, 0.45, 1.0],
    );

    final paint = Paint()..shader = gradient;
    canvas.drawPath(path, paint);
  }

  void _drawJasmineFlower(Canvas canvas, _FlowerParticle p) {
    final r = p.size * 0.45;
    final flipScale = math.cos(p.flipProgress).abs().clamp(0.35, 1.0);
    canvas.scale(flipScale, 1.0);

    final petalPaint = Paint()..color = const Color(0xFFFFFDE7);
    for (int i = 0; i < 5; i++) {
      final angle = i * (2 * math.pi / 5);
      canvas.save();
      canvas.translate(math.cos(angle) * r * 0.5, math.sin(angle) * r * 0.5);
      final petalPath = Path()
        ..moveTo(0, -r * 0.45)
        ..quadraticBezierTo(r * 0.25, 0, 0, r * 0.45)
        ..quadraticBezierTo(-r * 0.25, 0, 0, -r * 0.45)
        ..close();
      canvas.drawPath(petalPath, petalPaint);
      canvas.restore();
    }

    // Soft green center
    final centerPaint = Paint()..color = const Color(0xFFAED581);
    canvas.drawCircle(Offset.zero, r * 0.22, centerPaint);

    final dotPaint = Paint()..color = const Color(0xFFFFF59D);
    canvas.drawCircle(Offset.zero, r * 0.10, dotPaint);
  }

  @override
  bool shouldRepaint(covariant _PetalsPainter oldDelegate) => true;
}
