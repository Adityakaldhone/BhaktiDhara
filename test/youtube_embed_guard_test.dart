import 'package:flutter_test/flutter_test.dart';
import 'package:nitya_aarti/core/youtube_embed_guard.dart';

void main() {
  test('Google / YouTube sign-in pages are blocked in embedded players', () {
    for (final url in [
      'https://accounts.google.com/ServiceLogin?service=youtube',
      'https://accounts.google.com/v3/signin/identifier?continue=x',
      'https://www.youtube.com/signin?action_handle_signin=true',
      'https://www.google.com/accounts/ServiceLogin',
    ]) {
      expect(isSignInUrl(url), isTrue, reason: url);
    }
  });

  test('player, video and asset URLs still load', () {
    for (final url in [
      'https://www.youtube.com/embed/abc123',
      'https://www.youtube.com/iframe_api',
      'https://www.youtube.com/s/player/x/base.js',
      'https://rr1---sn.googlevideo.com/videoplayback?id=1',
      'https://i.ytimg.com/vi/abc/hq.jpg',
      'https://www.gstatic.com/x.js',
    ]) {
      expect(isSignInUrl(url), isFalse, reason: url);
    }
  });
}
