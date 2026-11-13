import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
// ignore: depend_on_referenced_packages
import 'package:webview_flutter_android/webview_flutter_android.dart';
// ignore: depend_on_referenced_packages
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

import '../../../core/youtube_embed_guard.dart';
import '../../../domain/entities/aarti_item.dart';

/// App origin used as Referer so YouTube embeds avoid Error 153 /
/// "Watch on YouTube" interstitial.
const String _kEmbedOrigin = 'https://com.kaldhone.bhaktidhara';

/// Embedded YouTube aarti that reports its playback position, so the
/// Garbhagriha can follow the lyrics with the song.
class MandirAartiPlayer extends ChangeNotifier {
  MandirAartiPlayer(this.aarti, {this.onEnded}) {
    _load();
  }

  final AartiItem aarti;
  final VoidCallback? onEnded;

  WebViewController? web;
  int positionMs = 0;
  int durationMs = 0;
  bool playing = false;
  bool ready = false;

  /// Every video id (main and backups) refused to play.
  bool failed = false;

  int _fallback = 0;
  bool _disposed = false;

  /// Whether this platform can embed a WebView at all.
  static bool get supported => !kIsWeb && WebViewPlatform.instance != null;

  Future<void> seekTo(int ms) => _js('player.seekTo(${ms / 1000}, true); player.playVideo();');

  Future<void> togglePlay() => _js(playing ? 'player.pauseVideo();' : 'player.playVideo();');

  Future<void> pause() => _js('player.pauseVideo();');

  Future<void> _js(String body) async {
    try {
      await web?.runJavaScript('if (player) { try { $body } catch (e) {} }');
    } catch (_) {}
  }

  void _load() {
    if (!supported) {
      failed = true;
      return;
    }
    try {
      final params = WebViewPlatform.instance is WebKitWebViewPlatform
          ? WebKitWebViewControllerCreationParams(
              allowsInlineMediaPlayback: true,
              mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
            )
          : const PlatformWebViewControllerCreationParams();
      final controller = WebViewController.fromPlatformCreationParams(params);
      if (controller.platform is AndroidWebViewController) {
        (controller.platform as AndroidWebViewController).setMediaPlaybackRequiresUserGesture(false);
      }
      controller
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(Colors.black)
        ..addJavaScriptChannel('PlayerBridge', onMessageReceived: _onMessage)
        ..setNavigationDelegate(NavigationDelegate(onNavigationRequest: _onNavigation))
        ..loadHtmlString(_embedHtml(aarti.videoIdWithFallback(_fallback)), baseUrl: '$_kEmbedOrigin/');
      web = controller;
    } catch (_) {
      failed = true;
    }
  }

  NavigationDecision _onNavigation(NavigationRequest request) {
    final url = request.url;
    if (isSignInUrl(url)) return NavigationDecision.prevent;
    if (url.contains('youtube.com/watch') ||
        url.contains('youtu.be/') ||
        url.contains('youtube.com/@') ||
        url.contains('youtube.com/channel')) {
      final uri = Uri.tryParse(url);
      if (uri != null) launchUrl(uri, mode: LaunchMode.externalApplication);
      return NavigationDecision.prevent;
    }
    return NavigationDecision.navigate;
  }

  void _onMessage(JavaScriptMessage message) {
    if (_disposed) return;
    final data = message.message;
    if (data.startsWith('t:')) {
      final parts = data.substring(2).split(':');
      if (parts.length < 3) return;
      positionMs = int.tryParse(parts[0]) ?? positionMs;
      durationMs = int.tryParse(parts[1]) ?? durationMs;
      playing = parts[2] == '1';
      ready = true;
      notifyListeners();
    } else if (data == 'ended') {
      playing = false;
      notifyListeners();
      onEnded?.call();
    } else if (data.startsWith('error:')) {
      final code = int.tryParse(data.substring(6)) ?? 0;
      if (code == 100 || code == 101 || code == 150 || code == 153) _tryBackup();
    }
  }

  void _tryBackup() {
    if (_fallback >= aarti.backupVideoIds.length) {
      failed = true;
      notifyListeners();
      return;
    }
    _fallback++;
    ready = false;
    positionMs = 0;
    web?.loadHtmlString(_embedHtml(aarti.videoIdWithFallback(_fallback)), baseUrl: '$_kEmbedOrigin/');
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    pause();
    super.dispose();
  }
}

String _embedHtml(String videoId) =>
    '''
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
      var playerCreated = false;

      function post(msg) {
        try {
          if (window.PlayerBridge && PlayerBridge.postMessage) PlayerBridge.postMessage(String(msg));
        } catch (e) {}
      }

      setInterval(function () {
        if (!player || !player.getCurrentTime) return;
        try {
          post('t:' + Math.round(player.getCurrentTime() * 1000) + ':' +
               Math.round((player.getDuration() || 0) * 1000) + ':' + player.getPlayerState());
        } catch (e) {}
      }, 400);

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
            playsinline: 1,
            rel: 0,
            controls: 1,
            fs: 0,
            iv_load_policy: 3,
            enablejsapi: 1,
            origin: '$_kEmbedOrigin'
          },
          events: {
            onReady: function () {
              try { player.unMute(); player.setVolume(100); player.playVideo(); } catch (e) {}
            },
            onStateChange: function (event) {
              if (event && event.data === 0) post('ended');
            },
            onError: function (event) { post('error:' + event.data); }
          }
        });
      }

      window.onYouTubeIframeAPIReady = onYouTubeIframeAPIReady;
      if (window.YT && window.YT.Player) onYouTubeIframeAPIReady();
    </script>
  </body>
</html>
''';

/// Index of the stanza being sung at [positionMs]: the last one already started.
int stanzaAt(List<int> starts, int positionMs) {
  var index = 0;
  for (var i = 0; i < starts.length; i++) {
    if (starts[i] <= positionMs) index = i;
  }
  return index;
}

/// Whether the stanza timestamps were hand-timed to the video. Placeholder
/// timings are all zero or step in identical gaps (0, 30000, 60000…).
bool lyricsAreTimed(List<int> starts) {
  if (starts.length < 2 || starts.last <= 0) return false;
  final gaps = <int>{};
  for (var i = 1; i < starts.length; i++) {
    final gap = starts[i] - starts[i - 1];
    if (gap <= 0) return false;
    gaps.add(gap);
  }
  return gaps.length > 1;
}
