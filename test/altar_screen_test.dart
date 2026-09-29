import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nitya_aarti/data/datasources/catalog.dart';
import 'package:nitya_aarti/presentation/screens/altar_screen.dart';
import 'package:nitya_aarti/presentation/widgets/lyric_card.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AartiAltarScreen & LyricCard Tests', () {
    test('AartiItem localizedAbout provides correct descriptions', () {
      final ganesh =
          kDevotionalCatalog.firstWhere((i) => i.id == 'ganesh_aarti');

      expect(ganesh.localizedAbout('mr'), contains('सुखकर्ता दुःखहर्ता'));
      expect(ganesh.localizedAbout('hi'), contains('सुखकर्ता दुःखहर्ता'));
      expect(ganesh.localizedAbout('en'), contains('Sukhkarta Dukhharta'));
    });

    testWidgets('LyricCard renders devanagari, transliteration and stanza badge',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LyricCard(
              devanagari: 'सुखकर्ता दुखहर्ता वार्ता विघ्नाची।',
              transliteration: 'Sukhkarta Dukhharta Varta Vighnachi,',
              fontScale: 1.0,
              stanzaNumber: '१',
            ),
          ),
        ),
      );

      // Verify devanagari lyrics are present
      expect(find.text('सुखकर्ता दुखहर्ता वार्ता विघ्नाची।'), findsOneWidget);

      // Verify transliteration is present
      expect(
          find.text('Sukhkarta Dukhharta Varta Vighnachi,'), findsOneWidget);

      // Verify stanza number badge is present
      expect(find.text('|| १ ||'), findsOneWidget);
    });

    testWidgets('LyricCard respects fontScale adjustment',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LyricCard(
              devanagari: 'जय देव जय देव',
              transliteration: 'Jai Dev Jai Dev',
              fontScale: 1.5,
              stanzaNumber: '२',
            ),
          ),
        ),
      );

      expect(find.text('जय देव जय देव'), findsOneWidget);
      expect(find.text('|| २ ||'), findsOneWidget);
    });

    testWidgets('AartiAltarScreen initializes gracefully without crashing on standard mobile',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final ganesh =
          kDevotionalCatalog.firstWhere((i) => i.id == 'ganesh_aarti');

      await tester.pumpWidget(
        MaterialApp(
          home: AartiAltarScreen(aarti: ganesh),
        ),
      );

      expect(find.byType(AartiAltarScreen), findsOneWidget);
    });

    testWidgets('AartiAltarScreen adapts to wide 1512px desktop screen without RenderFlex overflow',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1512, 850);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final ganesh =
          kDevotionalCatalog.firstWhere((i) => i.id == 'ganesh_aarti');

      await tester.pumpWidget(
        MaterialApp(
          home: AartiAltarScreen(aarti: ganesh),
        ),
      );

      expect(find.byType(AartiAltarScreen), findsOneWidget);
    });

    testWidgets('AartiAltarScreen adapts to standard 800x600 window without overflow',
        (WidgetTester tester) async {
      final ganesh =
          kDevotionalCatalog.firstWhere((i) => i.id == 'ganesh_aarti');

      await tester.pumpWidget(
        MaterialApp(
          home: AartiAltarScreen(aarti: ganesh),
        ),
      );

      expect(find.byType(AartiAltarScreen), findsOneWidget);
    });
  });
}
