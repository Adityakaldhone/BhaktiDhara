import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:nitya_aarti/services/review_service.dart';
import 'package:nitya_aarti/services/review_storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeInAppReview implements InAppReview {
  bool available = true;
  int requestReviewCallCount = 0;
  int openStoreListingCallCount = 0;
  String? lastAppStoreId;

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<void> requestReview() async {
    requestReviewCallCount++;
  }

  @override
  Future<void> openStoreListing({
    String? appStoreId,
    String? microsoftStoreId,
  }) async {
    openStoreListingCallCount++;
    lastAppStoreId = appStoreId;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ReviewService with in_app_review', () {
    late SharedPreferences prefs;
    late ReviewStorageService storage;
    late FakeInAppReview fakeInAppReview;
    late ReviewService service;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      storage = ReviewStorageService(prefs);
      fakeInAppReview = FakeInAppReview();
      service = ReviewService(storage, fakeInAppReview);
    });

    test('Initial state: not eligible for prompt until thresholds met', () {
      expect(service.isEligibleForPrompt(), isFalse);
    });

    test('Eligible when retention and engagement thresholds are met', () async {
      // Meet distinct open days threshold (>= 3)
      await prefs.setInt('review_distinct_open_days', 3);
      // Meet aarti completions threshold (>= 2)
      await service.trackAartiCompleted();
      await service.trackAartiCompleted();

      expect(service.isEligibleForPrompt(), isTrue);
    });

    test('requestInAppReview invokes in_app_review when available', () async {
      fakeInAppReview.available = true;

      await service.requestInAppReview();

      expect(fakeInAppReview.requestReviewCallCount, equals(1));
      expect(storage.hasRated, isTrue);
    });

    test('openStoreListing invokes in_app_review openStoreListing', () async {
      fakeInAppReview.available = true;

      await service.openStoreListing('com.kaldhone.panchang');

      expect(fakeInAppReview.openStoreListingCallCount, equals(1));
      expect(fakeInAppReview.lastAppStoreId, equals('com.kaldhone.panchang'));
      expect(storage.hasRated, isTrue);
    });

    test('Engagement tracking persists correctly', () async {
      await service.trackAartiCompleted();
      expect(storage.aartiCount, equals(1));

      await service.trackJaapMalaCompleted();
      expect(storage.jaapMalaCount, equals(1));

      await service.trackCardShared();
      expect(storage.cardShareCount, equals(1));
    });

    test('Aarti exit review prompt eligibility: 1st visit vs 2nd visit vs already rated', () async {
      // 1st visit: 1 open
      await service.trackAppOpen();
      expect(storage.appOpenCount, equals(1));
      expect(service.isFirstSession, isTrue);
      expect(service.isSecondTimeOrMore, isFalse);
      expect(service.isEligibleForAartiExitPrompt(), isFalse);

      // 2nd visit: 2nd open
      await service.trackAppOpen();
      expect(storage.appOpenCount, equals(2));
      expect(service.isFirstSession, isFalse);
      expect(service.isSecondTimeOrMore, isTrue);
      // Eligible because user hasn't rated yet
      expect(service.isEligibleForAartiExitPrompt(), isTrue);

      // Once shown in this session, don't spam again in the same session
      service.markPromptShownThisSession();
      expect(service.isEligibleForAartiExitPrompt(), isFalse);

      // If user rates, never prompt again even in future sessions
      final newSessionService = ReviewService(storage, fakeInAppReview);
      expect(newSessionService.isEligibleForAartiExitPrompt(), isTrue);
      await newSessionService.requestInAppReview();
      expect(storage.hasRated, isTrue);
      expect(newSessionService.isEligibleForAartiExitPrompt(), isFalse);
    });
  });
}
