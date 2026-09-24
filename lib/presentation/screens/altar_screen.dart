import 'package:flutter/material.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:webview_flutter/webview_flutter.dart';
// ignore: depend_on_referenced_packages
import 'package:webview_flutter_android/webview_flutter_android.dart';
// ignore: depend_on_referenced_packages
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';
import '../../l10n/app_localizations.dart';

import '../../core/theme/theme.dart';
import '../../domain/entities/aarti_item.dart';
import '../../services/audio_service.dart';
import '../widgets/lyric_card.dart';

/// Screen 2 — Chanting Altar (Strict In-App Embedded Video Player).
///
/// Implements the user's requirement to strictly keep users inside the app
/// using `webview_flutter` with a `NavigationDelegate` that blocks exits.
///
/// The lyrics are displayed as a static scrollable list without auto-sync,
/// providing a clean, high-contrast reading experience tailored for a 50+ demographic.
///
/// STRICT POLICY: Zero AdMob ads on this screen (Spec §5).
class AartiAltarScreen extends StatefulWidget {
  final AartiItem aarti;
  const AartiAltarScreen({super.key, required this.aarti});

  @override
  State<AartiAltarScreen> createState() => _AartiAltarScreenState();
}

class _AartiAltarScreenState extends State<AartiAltarScreen>
    with WidgetsBindingObserver {

  late final WebViewController _webController;
  bool _isLoading = true;

  // ── E7: Accessibility font scaler ────────────────────────────────────────
  static const _fontScales = [1.0, 1.25, 1.5]; // Larger default fonts for seniors
  int _fontScaleIndex = 0;
  double get _fontScale => _fontScales[_fontScaleIndex];

  final AudioService _audio = AudioService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WakelockPlus.enable();

    final embedHtml = '''
      <!DOCTYPE html>
      <html>
        <head>
          <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
          <style>
            body { margin: 0; background-color: #000; display: flex; justify-content: center; align-items: center; height: 100vh; overflow: hidden; }
            #player { width: 100%; height: 100%; border: none; }
          </style>
        </head>
        <body>
          <div id="player"></div>
          <script src="https://www.youtube.com/iframe_api"></script>
          <script>
            var player;
            function onYouTubeIframeAPIReady() {
              player = new YT.Player('player', {
                height: '100%',
                width: '100%',
                videoId: '${widget.aarti.youtubeVideoId}',
                playerVars: {
                  'autoplay': 1,
                  'playsinline': 1,
                  'rel': 0,
                  'modestbranding': 1,
                  'fs': 0,
                  'iv_load_policy': 3
                }
              });
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

    _webController = WebViewController.fromPlatformCreationParams(params);

    if (_webController.platform is AndroidWebViewController) {
      (_webController.platform as AndroidWebViewController)
          .setMediaPlaybackRequiresUserGesture(false);
    }

    _webController
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            if (mounted) setState(() => _isLoading = false);
          },
          onNavigationRequest: (request) {
            if (request.url.startsWith('https://www.youtube-nocookie.com') || 
                request.url.startsWith('https://www.youtube.com/iframe_api') ||
                request.url.contains('embed')) {
              return NavigationDecision.navigate;
            }
            return NavigationDecision.prevent; 
          },
        ),
      )
      ..loadHtmlString(embedHtml, baseUrl: 'https://www.youtube-nocookie.com');
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _webController.runJavaScript('if(player && player.pauseVideo) player.pauseVideo();');
    }
  }

  Future<void> _triggerPoojaTool({required bool isBell}) async {
    if (isBell) {
      await _audio.playBell();
    } else {
      await _audio.playConch();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    WakelockPlus.disable();
    _audio.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.aarti.title),
        actions: [
          TextButton.icon(
            onPressed: () => setState(() => _fontScaleIndex = (_fontScaleIndex + 1) % _fontScales.length),
            icon: const Icon(Icons.format_size, size: 24),
            label: Text(
              '${(_fontScale * 100).toInt()}%',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            style: TextButton.styleFrom(foregroundColor: MandirTheme.primarySaffron),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // 1. Embedded YouTube Video (Strictly inside the app)
          Container(
            height: 240, // Slightly taller for better visibility
            width: double.infinity,
            color: Colors.black,
            child: Stack(
              children: [
                WebViewWidget(controller: _webController),
                if (_isLoading)
                  const Center(
                    child: CircularProgressIndicator(color: MandirTheme.primarySaffron),
                  ),
              ],
            ),
          ),

          // 2. Chanting Altar Banner (Pooja Tools)
          Container(
            color: MandirTheme.surfaceWhite,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                const Icon(Icons.screen_lock_portrait, size: 20, color: MandirTheme.textMuted),
                const SizedBox(width: 8),
                Text(
                  l10n.screenAwake,
                  style: const TextStyle(fontSize: 14, color: MandirTheme.textMuted),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => _triggerPoojaTool(isBell: true),
                  icon: const Icon(Icons.notifications_active),
                  color: MandirTheme.primarySaffron,
                  iconSize: 32,
                  tooltip: l10n.playBell,
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => _triggerPoojaTool(isBell: false),
                  icon: const Icon(Icons.air),
                  color: Colors.orangeAccent,
                  iconSize: 32,
                  tooltip: l10n.blowConch,
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Colors.black12),

          // 3. Static Lyrics List (Like a book)
          Expanded(
            child: Container(
              color: MandirTheme.backgroundCream, // Reading background
              child: ListView.builder(
                itemCount: widget.aarti.lyrics.length,
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
                itemBuilder: (context, index) {
                  final stanza = widget.aarti.lyrics[index];
                  return LyricCard(
                    devanagari: stanza.devanagari,
                    transliteration: stanza.transliteration,
                    fontScale: _fontScale,
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
