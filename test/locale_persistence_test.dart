import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nitya_aarti/presentation/providers/locale_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('follows the device language until the user picks one', () async {
    SharedPreferences.setMockInitialValues({});
    expect(await loadUserLanguageCode(), isNull);
    expect(resolveStartupLocale(null), getInitialDeviceLocale());
  });

  test('a saved user choice wins over the device language', () async {
    SharedPreferences.setMockInitialValues({'user_selected_language': 'mr'});
    final code = await loadUserLanguageCode();
    expect(code, 'mr');

    final container = ProviderContainer(
      overrides: [userLanguageCodeProvider.overrideWithValue(code)],
    );
    addTearDown(container.dispose);
    expect(container.read(localeProvider), const Locale('mr'));
  });

  test('ignores an unsupported saved value', () async {
    SharedPreferences.setMockInitialValues({'user_selected_language': 'fr'});
    expect(await loadUserLanguageCode(), isNull);
  });

  testWidgets('selecting a language applies and remembers it', (tester) async {
    SharedPreferences.setMockInitialValues({});
    late WidgetRef widgetRef;
    await tester.pumpWidget(
      ProviderScope(
        child: Consumer(
          builder: (context, ref, _) {
            widgetRef = ref;
            return const SizedBox();
          },
        ),
      ),
    );

    selectAppLanguage(widgetRef, const Locale('hi'));
    await tester.pump();

    expect(widgetRef.read(localeProvider), const Locale('hi'));
    expect(await loadUserLanguageCode(), 'hi');
  });
}
