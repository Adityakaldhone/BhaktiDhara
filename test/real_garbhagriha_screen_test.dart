import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nitya_aarti/features/mandir/screens/real_garbhagriha_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _frames(WidgetTester tester, int ms) async {
  for (var t = 0; t < ms; t += 50) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Garbhagriha opens, lights the diya and runs every seva', (tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: RealGarbhagrihaScreen(),
        ),
      ),
    );
    await _frames(tester, 2000);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt('diya_last_refill_ms'), isNotNull);
    expect(prefs.getInt('diya_streak_days'), 1);
    expect(prefs.getString('diya_last_streak_date'), isNotNull);

    // Default first-launch language is Hindi.
    for (final label in ['आरती थाली', 'पुष्पांजलि', 'घंटा नाद', 'शंखनाद', 'नैवेद्य भोग']) {
      await tester.tap(find.text(label));
      await _frames(tester, 400);
    }

    // The aarti thali follows the finger in any direction, not just a circle.
    final drag = await tester.startGesture(const Offset(195, 300));
    for (final p in const [Offset(120, 360), Offset(260, 250), Offset(300, 420), Offset(90, 200)]) {
      await drag.moveTo(p);
      await _frames(tester, 150);
    }
    await drag.up();
    await _frames(tester, 300);

    // No WebView in tests, so the aarti runs as "sing myself": lyrics on the
    // chowki advance verse by verse until the aarti completes.
    expect(find.textContaining('पद 1/'), findsOneWidget);
    for (var i = 0; i < 40 && find.text('आरती संपन्न • जय हो').evaluate().isEmpty; i++) {
      await tester.tap(find.byIcon(Icons.chevron_right_rounded));
      await _frames(tester, 300);
    }
    expect(find.text('आरती संपन्न • जय हो'), findsOneWidget);

    // Seat a different deity from inside the Mandir.
    await tester.tap(find.text('देवता बदलें'));
    await _frames(tester, 600);
    expect(find.text('अपने इष्ट देव चुनें'), findsOneWidget);
    await tester.tap(find.byKey(const Key('mandir-deity-Lord Hanuman')));
    await _frames(tester, 900);
    expect(find.text('अपने इष्ट देव चुनें'), findsNothing);
    expect(find.text('श्री हनुमान'), findsOneWidget);
    expect(prefs.getString('ishta_devta_key'), 'Lord Hanuman');

    await tester.tap(find.text('घी अर्पण करें +').first);
    await _frames(tester, 3000);
    expect(find.textContaining('100%'), findsOneWidget);
    expect(find.textContaining('24 घंटे 00 मिनट बाकी'), findsOneWidget);
    expect(find.text('दिन 1'), findsOneWidget);

    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await _frames(tester, 6000);
  });
}
