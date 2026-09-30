import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/greeting_card_prefs_repository.dart';
import '../../data/repositories/greeting_photo_store.dart';
import '../../domain/entities/greeting_card.dart';
import '../../domain/logic/greeting_card_logic.dart';
import '../../services/backend_service.dart';
import '../../services/card_renderer.dart';
import '../greeting/greeting_card_builder.dart';
import '../widgets/greeting/card_canvas.dart';
import 'locale_provider.dart';
import 'premium_provider.dart';

final greetingClockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

/// Remote kill switch (`feature_flags.status_cards`). On by default, so the
/// feature keeps working offline or if the server is down.
final statusCardsEnabledProvider = FutureProvider<bool>((ref) async {
  final flags = await BackendService.fetchFeatureFlags();
  return flags['status_cards'] ?? true;
});

/// Remote switch for the sender photo (`feature_flags.status_card_photo`).
final statusCardPhotoEnabledProvider = FutureProvider<bool>((ref) async {
  if (!GreetingPhotoStore.supported) return false;
  final flags = await BackendService.fetchFeatureFlags();
  return flags['status_card_photo'] ?? true;
});

final greetingPhotoStoreProvider = Provider<GreetingPhotoStore>((ref) => GreetingPhotoStore());

final greetingCardPrefsRepositoryProvider =
    Provider<GreetingCardPrefsRepository>((ref) => GreetingCardPrefsRepository());

class GreetingCardPrefsNotifier extends StateNotifier<GreetingCardPrefs> {
  GreetingCardPrefsNotifier(this._repo, this._photos) : super(const GreetingCardPrefs()) {
    _ready = _load();
  }

  final GreetingCardPrefsRepository _repo;
  final GreetingPhotoStore _photos;
  late final Future<void> _ready;

  Future<void> get ready => _ready;

  Future<void> _load() async {
    final loaded = await _repo.load();
    if (mounted) state = loaded;
  }

  void _update(GreetingCardPrefs next) {
    state = next;
    unawaited(_repo.save(next));
  }

  void setDeity(String? deityId) => _update(state.copyWith(deityId: () => deityId));

  void setStyle(CardStyle? style) => _update(state.copyWith(style: () => style));

  void setGreeting(GreetingChoice greeting) => _update(state.copyWith(greeting: greeting));

  /// Stores the sanitised name, or clears it when the input is empty/unsafe.
  void setSenderName(String raw) {
    final name = GreetingCardLogic.sanitizeName(raw);
    _update(state.copyWith(senderName: () => name, askedForName: true));
  }

  void markAskedForName() => _update(state.copyWith(askedForName: true));

  /// Saves [raw] as the card photo. False when it isn't a usable image.
  Future<bool> setPhoto(Uint8List raw) async {
    final saved = await _photos.save(raw);
    if (saved && mounted) {
      _update(state.copyWith(photoStamp: () => DateTime.now().millisecondsSinceEpoch));
    }
    return saved;
  }

  void setEmojis(String raw) =>
      _update(state.copyWith(emojis: () => GreetingCardLogic.sanitizeEmojis(raw)));

  Future<void> removePhoto() async {
    _update(state.copyWith(photoStamp: () => null));
    await _photos.delete();
  }
}

final greetingCardPrefsProvider =
    StateNotifierProvider<GreetingCardPrefsNotifier, GreetingCardPrefs>((ref) {
  return GreetingCardPrefsNotifier(
    ref.watch(greetingCardPrefsRepositoryProvider),
    ref.watch(greetingPhotoStoreProvider),
  );
});

final greetingCardProvider = Provider.autoDispose<GreetingCardData>((ref) {
  final prefs = ref.watch(greetingCardPrefsProvider);
  final now = ref.read(greetingClockProvider)();
  final photoEnabled = ref.watch(statusCardPhotoEnabledProvider).valueOrNull ?? false;
  final isPremium = ref.watch(isPremiumProvider);
  return GreetingCardBuilder.build(
    now: now,
    lang: ref.watch(localeProvider).languageCode,
    style: prefs.style ?? GreetingCardLogic.autoStyle(GreetingCardLogic.cardDay(now)),
    deityOverride: prefs.deityId,
    greeting: prefs.greeting,
    senderName: prefs.senderName,
    photoStamp: photoEnabled ? prefs.photoStamp : null,
    emojis: prefs.emojis,
    isPremium: isPremium,
  );
});

typedef CardImagesKey = ({String deityId, int? photoStamp});

final cardImagesProvider = FutureProvider.family<CardImages, CardImagesKey>((ref, key) {
  return CardRenderer.loadImages(key.deityId, photoStamp: key.photoStamp);
});
