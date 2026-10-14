import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gal/gal.dart';
import 'package:image_picker/image_picker.dart';

import '../../domain/entities/greeting_image.dart';
import '../../services/backend_service.dart';
import '../../services/card_share_service.dart';
import '../../services/greeting_image_composer.dart';
import '../providers/greeting_providers.dart';
import '../providers/locale_provider.dart';
import '../providers/review_provider.dart';
import 'greeting_strings.dart';

bool _busy = false;

/// The image exactly as it will be sent: HD plus the user's photo circle.
Future<GreetingExport> _export(WidgetRef ref, GreetingImage image) async {
  final stamp = ref.read(greetingPhotoEnabledProvider) ? ref.read(greetingPhotoProvider) : null;
  final photo = stamp == null ? null : await ref.read(greetingPhotoBytesProvider(stamp).future);
  return GreetingImageComposer.build(image.hdUrl!, photo: photo);
}

Future<void> shareGreetingImage(
  BuildContext context,
  WidgetRef ref,
  GreetingImage image, {
  required String categoryName,
  Rect? origin,
}) async {
  if (_busy || image.hdUrl == null) return;
  _busy = true;
  final s = GreetingStrings(ref.read(localeProvider).languageCode);
  final messenger = ScaffoldMessenger.maybeOf(context);
  try {
    messenger?.showSnackBar(SnackBar(content: Text(s.preparing), duration: const Duration(seconds: 2)));
    final export = await _export(ref, image);
    messenger?.hideCurrentSnackBar();
    await CardShareService.share(
      bytes: export.bytes,
      mimeType: export.mimeType,
      extension: export.extension,
      caption: s.caption(categoryName),
      origin: origin,
    );
    ref.read(greetingRepositoryProvider).recordShare(image.id);
    BackendService.trackEvent('greeting_share', item: '${image.id}', props: {
      'category': image.category,
      'premium': image.premium,
      'photo': export.mimeType == 'image/png',
    });
    ref.read(reviewServiceProvider).trackCardShared();
  } catch (_) {
    messenger?.hideCurrentSnackBar();
    messenger?.showSnackBar(SnackBar(content: Text(s.shareFailed)));
  } finally {
    _busy = false;
  }
}

Future<void> saveGreetingImage(BuildContext context, WidgetRef ref, GreetingImage image) async {
  if (_busy || image.hdUrl == null) return;
  _busy = true;
  final s = GreetingStrings(ref.read(localeProvider).languageCode);
  final messenger = ScaffoldMessenger.maybeOf(context);
  try {
    if (!await Gal.hasAccess(toAlbum: true) && !await Gal.requestAccess(toAlbum: true)) {
      throw StateError('Gallery access denied');
    }
    final export = await _export(ref, image);
    await Gal.putImageBytes(
      export.bytes,
      album: 'BhaktiDhara',
      name: 'bhaktidhara_${image.id}_${DateTime.now().millisecondsSinceEpoch}',
    );
    messenger?.showSnackBar(SnackBar(content: Text(s.saved)));
    BackendService.trackEvent('greeting_save', item: '${image.id}', props: {'category': image.category});
  } catch (_) {
    messenger?.showSnackBar(SnackBar(content: Text(s.saveFailed)));
  } finally {
    _busy = false;
  }
}

/// Opens the system photo picker and stores the result as the circle photo.
Future<void> pickGreetingPhoto(BuildContext context, WidgetRef ref) async {
  final s = GreetingStrings(ref.read(localeProvider).languageCode);
  final messenger = ScaffoldMessenger.maybeOf(context);
  var saved = false;
  try {
    // The system photo picker needs no permission; requestFullMetadata
    // false keeps iOS from asking for photo-library access.
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1080,
      maxHeight: 1080,
      requestFullMetadata: false,
    );
    if (file == null) return;
    saved = await ref.read(greetingPhotoProvider.notifier).set(await file.readAsBytes());
    if (saved) BackendService.trackEvent('greeting_photo_added');
  } catch (_) {
    saved = false;
  }
  if (!saved) messenger?.showSnackBar(SnackBar(content: Text(s.photoFailed)));
}
