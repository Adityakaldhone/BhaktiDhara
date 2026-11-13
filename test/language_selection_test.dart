import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nitya_aarti/presentation/screens/language_selection_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<void> pumpPicker(WidgetTester tester) {
    return tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: LanguageSelectionScreen()),
      ),
    );
  }

  testWidgets('lists Hindi, then Marathi, then English and preselects Hindi',
      (tester) async {
    await pumpPicker(tester);
    await tester.pumpAndSettle();

    final hindi = tester.getTopLeft(find.text('HI'));
    final marathi = tester.getTopLeft(find.text('MR'));
    final english = tester.getTopLeft(find.text('EN'));
    expect(hindi.dy, lessThan(marathi.dy));
    expect(marathi.dy, lessThan(english.dy));

    expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
    expect(
      tester.getTopLeft(find.byIcon(Icons.check_circle_rounded)).dy,
      closeTo(hindi.dy, 24),
    );
    expect(find.text('भाषा चुनें'), findsOneWidget);
    expect(find.text('आगे बढ़ें'), findsOneWidget);
  });

  testWidgets('tapping Marathi moves the selection and switches copy',
      (tester) async {
    await pumpPicker(tester);
    await tester.pumpAndSettle();

    await tester.tap(find.text('MR'));
    await tester.pumpAndSettle();

    expect(find.text('भाषा निवडा'), findsOneWidget);
    expect(find.text('पुढे चला'), findsOneWidget);
    final marathi = tester.getTopLeft(find.text('MR'));
    expect(
      tester.getTopLeft(find.byIcon(Icons.check_circle_rounded)).dy,
      closeTo(marathi.dy, 24),
    );
  });
}
