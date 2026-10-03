import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/review_service.dart';
import '../../services/review_storage_service.dart';

/// Provides [ReviewService] as a lazy singleton, backed by SharedPreferences.
///
/// Usage:
/// ```dart
/// final review = ref.read(reviewServiceProvider);
/// if (review.isEligibleForPrompt()) { … }
/// ```
final reviewServiceProvider = Provider<ReviewService>((ref) {
  // SharedPreferences.getInstance() caches after the first call, so
  // this synchronous throw is only hit if the provider is read before
  // SharedPreferences was ever awaited (which the app already does on
  // startup via several other services).
  throw UnimplementedError(
    'reviewServiceProvider must be overridden with a valid instance.',
  );
});

/// Initialises the review service and returns an override suitable for
/// `ProviderScope.overrides`.
///
/// Call once during app startup:
/// ```dart
/// final reviewOverride = await createReviewServiceOverride();
/// ```
Future<Override> createReviewServiceOverride() async {
  final prefs = await SharedPreferences.getInstance();
  final storage = ReviewStorageService(prefs);
  final service = ReviewService(storage);
  // Track this app-open for the distinct-days counter.
  await service.trackAppOpen();
  return reviewServiceProvider.overrideWithValue(service);
}
