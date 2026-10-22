import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/review_service.dart';
import '../../services/review_storage_service.dart';

/// Provides [ReviewService] as a self-initializing lazy singleton.
final reviewServiceProvider = Provider<ReviewService>((ref) {
  final storage = ReviewStorageService();
  final service = ReviewService(storage);
  service.trackAppOpen();
  return service;
});

/// Optional helper for tests or pre-warming.
Future<Override> createReviewServiceOverride() async {
  final prefs = await SharedPreferences.getInstance();
  final storage = ReviewStorageService(prefs);
  final service = ReviewService(storage);
  await service.trackAppOpen();
  return reviewServiceProvider.overrideWithValue(service);
}
