import 'package:nitya_aarti/features/mandir/widgets/mandir_murti.dart';
import 'package:nitya_aarti/features/mandir/widgets/mandir_stage.dart';
import 'package:flutter/foundation.dart';
import 'package:nitya_aarti/domain/logic/ishta_devta.dart';
import 'package:nitya_aarti/features/mandir/widgets/mandir_aarti_session.dart';
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

Future<void> _openJournal(WidgetTester tester) async {
  await tester.tap(find.byTooltip('नित्य पूजा संकल्प'));
  await _frames(tester, 450);
}

void main() {
  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    SharedPreferences.setMockInitialValues({
      // Skip first-visit thali coach so the drag assertions stay deterministic.
      'mandir_thali_coach_seen': true,
    });
  });

  testWidgets('Light rendering limits ambient ticks and suspends them behind another route', (tester) async {
    final source = ValueNotifier<double>(0);
    addTearDown(source.dispose);
    late ValueListenable<double> clock;
    final nav = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: nav,
        home: MandirStage(
          clock: source,
          lightRendering: true,
          child: Builder(
            builder: (context) {
              clock = MandirClockScope.of(context);
              return const SizedBox.expand();
            },
          ),
        ),
      ),
    );
    var ticks = 0;
    clock.addListener(() => ticks++);
    await tester.pump(const Duration(seconds: 1));
    expect(ticks, inInclusiveRange(29, 31));
    nav.currentState!.push(MaterialPageRoute<void>(builder: (_) => const SizedBox.expand()));
    await tester.pumpAndSettle();
    final coveredTicks = ticks;
    await tester.pump(const Duration(milliseconds: 300));
    expect(ticks, coveredTicks);
    nav.currentState!.pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 100));
    expect(ticks, greaterThan(coveredTicks));
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('Loaded abhishek portraits adapt across deities of varied height and width', (tester) async {
    for (final (key, liquid) in [
      ('Lord Ganesha', Abhishek.milk),
      ('Lord Hanuman', Abhishek.water),
      ('Lord Shiva', Abhishek.water),
      ('Lord Vishnu', Abhishek.milk),
    ]) {
      final deity = ishtaOrDefault(key);
      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: SizedBox(
              width: 120,
              height: 180,
              child: AnimatedSwitcher(
                duration: Duration.zero,
                child: MandirMurti(
                  key: ValueKey(key),
                  deity: deity,
                  decodeWidth: 160,
                  progress: const AlwaysStoppedAnimation(.5),
                  liquid: liquid,
                  lightRendering: liquid == Abhishek.water,
                ),
              ),
            ),
          ),
        ),
      );
      final context = tester.element(find.byType(MandirMurti).last);
      await tester.runAsync(() => precacheImage(ResizeImage(AssetImage(deity.imageAsset), width: 160), context));
      await tester.pump();
      final painted = find.descendant(of: find.byType(MandirMurti).last, matching: find.byType(CustomPaint));
      expect(tester.getSize(painted), const Size(120, 180));
    }
  });

  testWidgets('Garbhagriha opens, lights the diya and runs every seva', (tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    // Drop the tree before the binding tears down so a late system-font
    // notification cannot schedule a frame on a disposed RenderObject.
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [mandirLightRenderingProvider.overrideWith((_) async => true)],
        child: const MaterialApp(home: RealGarbhagrihaScreen()),
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

    final session = tester.widget<MandirAartiSession>(find.byType(MandirAartiSession));
    final lamp = tester.getRect(find.bySemanticsLabel('घी अर्पण करें').first);
    expect(lamp.bottom, lessThan(session.panel.top));
    expect(session.panel.bottom, lessThanOrEqualTo(tester.getRect(find.text('आरती थाली')).top));

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
    expect(find.text('श्री हनुमान'), findsNWidgets(2));
    expect(prefs.getString('ishta_devta_key'), 'Lord Hanuman');

    await tester.tap(find.text('घी अर्पण करें +').last);
    await _frames(tester, 3000);
    await _openJournal(tester);
    expect(find.textContaining('100%'), findsOneWidget);
    expect(find.textContaining('24 घंटे 00 मिनट बाकी'), findsOneWidget);
    await tester.tapAt(const Offset(10, 50));
    await _frames(tester, 400);

    expect(tester.takeException(), isNull);
  });

  testWidgets('Abhishek, Charan Sparsh, Pure Darshan and daily sankalp persist', (tester) async {
    tester.view.physicalSize = const Size(960, 1704);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    });

    await tester.pumpWidget(const ProviderScope(child: MaterialApp(home: RealGarbhagrihaScreen())));
    await _frames(tester, 1600);

    // Initial Sankalp progress badge shows 0/5.
    await _openJournal(tester);
    expect(find.text('0/5'), findsOneWidget);
    await tester.tapAt(const Offset(10, 50));
    await _frames(tester, 400);

    expect(find.text('कुमकुम तिलक'), findsNothing);
    for (final (button, confirmation) in [('जलाभिषेक', 'जल अर्पित'), ('दुग्धाभिषेक', 'दूध अर्पित')]) {
      await tester.tap(find.text(button));
      await _frames(tester, 450);
      expect(find.text(confirmation), findsOneWidget);
    }

    // Direct touch on murti feet triggers Charan Sparsh whisper.
    await tester.tap(find.bySemanticsLabel('चरण स्पर्श').first);
    await _frames(tester, 800);
    expect(find.text('🙏 चरण स्पर्श · सदा कल्याण हो'), findsOneWidget);

    // Toggle Pure Darshan hides the ritual tray and shows the restore pill.
    await tester.tap(find.byIcon(Icons.visibility_outlined));
    await _frames(tester, 500);
    expect(find.text('सेवा दिखाएं'), findsOneWidget);
    await tester.tap(find.text('सेवा दिखाएं'));
    await _frames(tester, 500);
    expect(find.text('सेवा दिखाएं'), findsNothing);

    // Open Daily Seva Sankalp sheet and trigger Offer Ghee from inside it.
    await _openJournal(tester);
    expect(find.text('1/5'), findsOneWidget);
    await _frames(tester, 500);
    expect(find.text('नित्य पूजा संकल्प'), findsOneWidget);
    await tester.tap(find.text('अर्पण →').first);
    await _frames(tester, 2800);
    await _openJournal(tester);
    expect(find.text('2/5'), findsOneWidget);

    // Wait out whisper timer, unmount and remount to verify same-day persistence.
    await _frames(tester, 1000);
    final prefs = await SharedPreferences.getInstance();
    expect(
      prefs.getStringList('mandir_sevas_today'),
      containsAll(['jalabhishek', 'dugdhabhishek', 'charan_sparsh', 'ghee']),
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.pumpWidget(const ProviderScope(child: MaterialApp(home: RealGarbhagrihaScreen())));
    await _frames(tester, 1600);
    await _openJournal(tester);
    expect(find.text('2/5'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
