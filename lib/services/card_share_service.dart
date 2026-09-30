import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Hands a rendered card to the system share sheet. Needs no permissions:
/// the file lives in the app's own temp folder and is cleaned up next time.
class CardShareService {
  CardShareService._();

  static const _packageId = 'com.kaldhone.bhaktidhara';

  /// Direct Play Store link with install attribution — no redirect server to
  /// run, pay for, or secure.
  static String playStoreLink() {
    final referrer = Uri.encodeComponent(
      'utm_source=whatsapp&utm_medium=status_card&utm_campaign=daily_card',
    );
    return 'https://play.google.com/store/apps/details?id=$_packageId&referrer=$referrer';
  }

  static Future<ShareResultStatus> share({
    required Uint8List png,
    required String caption,
    Rect? origin,
  }) async {
    final name = 'bhaktidhara_card_${DateTime.now().millisecondsSinceEpoch}.png';
    final XFile file;
    if (kIsWeb) {
      file = XFile.fromData(png, mimeType: 'image/png', name: name);
    } else {
      final dir = Directory('${(await getTemporaryDirectory()).path}/status_cards');
      await dir.create(recursive: true);
      await _cleanOldCards(dir);
      final path = '${dir.path}/$name';
      await File(path).writeAsBytes(png, flush: true);
      file = XFile(path, mimeType: 'image/png', name: name);
    }

    final result = await SharePlus.instance.share(ShareParams(
      files: [file],
      text: '$caption\n${playStoreLink()}',
      sharePositionOrigin: origin,
    ));
    return result.status;
  }

  static Future<void> _cleanOldCards(Directory dir) async {
    final cutoff = DateTime.now().subtract(const Duration(hours: 6));
    try {
      await for (final entity in dir.list()) {
        if (entity is File && (await entity.lastModified()).isBefore(cutoff)) {
          await entity.delete();
        }
      }
    } catch (_) {
      // The OS may clear temp files itself; nothing to do.
    }
  }
}
