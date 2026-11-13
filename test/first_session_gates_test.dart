import 'package:flutter_test/flutter_test.dart';
import 'package:nitya_aarti/presentation/widgets/festive_offer_popup.dart';
import 'package:nitya_aarti/services/review_service.dart';
import 'package:nitya_aarti/services/review_storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('festive offer waits until the devotee returns for a second session', () {
    expect(FestiveOfferPopup.deferForFirstSession(true), isTrue);
    expect(FestiveOfferPopup.deferForFirstSession(false), isFalse);
  });

  test('review prompt stays off on the first session', () async {
    SharedPreferences.setMockInitialValues({});
    final storage = ReviewStorageService(await SharedPreferences.getInstance());
    final service = ReviewService(storage);

    expect(service.isFirstSession, isTrue);
    expect(service.isEligibleForAartiExitPrompt(), isFalse);

    await service.trackAppOpen();
    expect(service.isFirstSession, isTrue);
    expect(service.isEligibleForAartiExitPrompt(), isFalse);
  });
}
