import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nitya_aarti/core/theme/theme.dart';
import 'package:nitya_aarti/data/datasources/catalog.dart';
import 'package:nitya_aarti/data/datasources/marathi_aarti_catalog.dart';
import 'package:nitya_aarti/presentation/screens/deity_aarti_list_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DeityAartiListScreen Widget Tests', () {
    test('Catalog contains all 6 Ganesh aartis matching reference mockup', () {
      final ganeshAartis =
          kDevotionalCatalog.where((i) => i.deity == 'Lord Ganesha').toList();
      expect(ganeshAartis.length, greaterThanOrEqualTo(6));

      final titles = ganeshAartis.map((i) => i.titleMr).toList();
      expect(titles, contains('श्री गणेश आरती'));
      expect(titles, contains('शेंदूर लाल चढायो आरती'));
      expect(titles, contains('जय गणेश जय गणेश देवा'));
      expect(titles, contains('गणपती बाप्पा मोरया आरती'));
      expect(titles, contains('सिद्धिविनायक आरती'));
      expect(titles, contains('मंगलमूर्ती मोरया आरती'));
    });

    testWidgets('Renders header, shloka, search bar and aarti items',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: DeityAartiListScreen(
              deity: 'Lord Ganesha',
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check Header title and subtitle
      expect(find.text('श्री गणेश'), findsOneWidget);
      expect(find.text('आरती संग्रह'), findsOneWidget);

      // Check Shloka is rendered
      expect(find.textContaining('वक्रतुण्ड महाकाय'), findsOneWidget);

      // Check Search bar hint
      expect(find.text('आरती शोधा...'), findsOneWidget);

      // Check that aarti cards are rendered
      expect(find.text('श्री गणेश आरती'), findsOneWidget);
      expect(find.text('शेंदूर लाल चढायो आरती'), findsOneWidget);
    });

    testWidgets('Search input filters aartis dynamically',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: DeityAartiListScreen(
              deity: 'Lord Ganesha',
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Enter search text "शेंदूर"
      await tester.enterText(find.byType(TextField), 'शेंदूर');
      await tester.pumpAndSettle();

      // Shendur should be visible, others filtered out
      expect(find.text('शेंदूर लाल चढायो आरती'), findsOneWidget);
      expect(find.text('जय गणेश जय गणेश देवा'), findsNothing);
    });
  });

  group('Marathi aarti sangraha catalog', () {
    test('adds PDF aartis under existing and new deity cards', () {
      final deities = kDevotionalCatalog.map((i) => i.deity).toSet();
      expect(deities, contains('Lord Vitthal'));
      expect(deities, contains('Lord Datta'));
      expect(deities, contains('Lord Krishna'));
      expect(deities, contains('Lord Rama'));
      expect(deities, contains('Goddess Lakshmi'));
      expect(deities, contains('Sai Baba'));
      expect(deities, contains('Sant'));

      final vitthal = kDevotionalCatalog
          .firstWhere((i) => i.id == 'vitthal_yuge_atthavis');
      expect(vitthal.lyrics.first.devanagari, contains('युगे अठ्ठावीस'));
      expect(vitthal.youtubeVideoId, 'arPJkd2JUkg');

      final datta =
          kDevotionalCatalog.firstWhere((i) => i.id == 'datta_aarti');
      expect(datta.lyrics.first.devanagari, contains('त्रिगुणात्मक'));

      final durge = kDevotionalCatalog
          .firstWhere((i) => i.id == 'durga_durge_durghatbhari');
      expect(durge.lyrics.first.devanagari, contains('दुर्गे दुर्घटभारी'));

      expect(deities, contains('Lord Vishnu'));
      expect(deities, contains('Lord Khandoba'));
      expect(deities, contains('Lord Venkatesh'));
      expect(deities, contains('Goddess Tulsi'));
      expect(deities, contains('Lord Siddhanath'));
      expect(deities, contains('Goddess Renuka Mata'));
      expect(deities, contains('Sant Balumama'));
      expect(deities, contains('Gondavalekar Maharaj'));
      expect(deities, contains('Navnath'));
      expect(deities, contains('Swami Samarth'));
      expect(
        kDevotionalCatalog.where((i) => i.deity == 'Swami Samarth').length,
        5,
      );

      final lakshmi =
          kDevotionalCatalog.firstWhere((i) => i.id == 'lakshmi_aarti');
      expect(lakshmi.lyrics.first.devanagari, contains('जय महालक्ष्मी'));
      expect(
        kDevotionalCatalog.where((i) => i.deity == 'Gondavalekar Maharaj').length,
        3,
      );

      final renuka =
          kDevotionalCatalog.firstWhere((i) => i.id == 'renuka_mata_aarti');
      expect(renuka.lyrics.first.devanagari, contains('जय जय रेणुके'));

      final dattaDurmil =
          kDevotionalCatalog.firstWhere((i) => i.id == 'datta_durmil_aarti');
      expect(dattaDurmil.deity, 'Lord Datta');
      expect(dattaDurmil.youtubeVideoId, 'raCt3EQkIBQ');
      expect(dattaDurmil.lyrics.first.devanagari, contains('श्री गुरु दत्तराज मूर्ती'));
    });

    test('never maps one god portrait onto another god', () {
      expect(MandirTheme.getDeityImageAsset('Lord Shiva'),
          'assets/bhakti/shiva.png');
      expect(MandirTheme.getDeityImageAsset('Lord Hanuman'),
          'assets/bhakti/hanuman.png');
      expect(MandirTheme.getDeityImageAsset('Lord Ganesha'),
          'assets/bhakti/ganesh.png');
      expect(MandirTheme.getDeityImageAsset('Lord Vitthal'),
          'assets/bhakti/vitthal.png');
      expect(MandirTheme.getDeityImageAsset('Lord Rama'),
          'assets/bhakti/rama.png');
      expect(MandirTheme.getDeityImageAsset('Lord Krishna'),
          'assets/bhakti/krishna.png');
      expect(MandirTheme.getDeityImageAsset('Goddess Durga'),
          'assets/bhakti/durga.png');
      expect(MandirTheme.getDeityImageAsset('Lord Datta'),
          'assets/bhakti/dutt.png');
      expect(MandirTheme.getDeityImageAsset('Sai Baba'),
          'assets/bhakti/saibaba.png');
      expect(MandirTheme.getDeityImageAsset('Gajanan Maharaj'),
          'assets/bhakti/gajanan_maharaj.png');
      expect(MandirTheme.getDeityImageAsset('Lord Vishnu'),
          'assets/bhakti/vishnu.png');
      expect(MandirTheme.getDeityImageAsset('Lord Khandoba'),
          'assets/bhakti/khandoba.png');
      expect(MandirTheme.getDeityImageAsset('Lord Shani'),
          'assets/bhakti/shanidev.png');
      expect(MandirTheme.getDeityImageAsset('Goddess Lakshmi'),
          'assets/bhakti/laxmi.png');
      expect(MandirTheme.getDeityImageAsset('Lord Venkatesh'),
          'assets/bhakti/Venkateswara.png');
      expect(MandirTheme.getDeityImageAsset('Goddess Tulsi'),
          'assets/bhakti/tulasi.png');
      expect(MandirTheme.getDeityImageAsset('Goddess Santoshi Mata'),
          'assets/decorations/santoshi_mata.png');
      expect(MandirTheme.getDeityImageAsset('Goddess Renuka Mata'),
          'assets/bhakti/renuka.png');
      expect(MandirTheme.getDeityImageAsset('Lord Siddhanath'),
          'assets/bhakti/siddhanth.png');
      expect(MandirTheme.getDeityImageAsset('Sant Balumama'),
          'assets/bhakti/balumama.png');
      expect(MandirTheme.getDeityImageAsset('Gondavalekar Maharaj'),
          'assets/bhakti/gondavalekar_maharaj.png');
      expect(MandirTheme.getDeityImageAsset('Navnath'),
          'assets/bhakti/navnath.png');
      expect(MandirTheme.getDeityImageAsset('Swami Samarth'),
          'assets/bhakti/swami_samartha.png');
      expect(MandirTheme.getDeityImageAsset('Sant'),
          'assets/bhakti/dnyaneshwar.png');
      expect(MandirTheme.getDeityImageAsset('Lord Bhairavnath'),
          'assets/bhakti/bhairavnath.png');
      expect(MandirTheme.getDeityImageAsset('Chandra Dev'),
          'assets/bhakti/chandra.png');
      expect(MandirTheme.getDeityImageAsset('Surya Dev'),
          'assets/bhakti/surya.png');
      expect(MandirTheme.getDeityImageAsset('Goddess Narmada'),
          'assets/bhakti/narmada.png');
      expect(MandirTheme.getDeityImageAsset('Goddess Gayatri'),
          'assets/decorations/gayatri.png');
      expect(MandirTheme.getDeityImageAsset('Gayatri'),
          'assets/decorations/gayatri.png');
      expect(MandirTheme.getDeityImageAsset('Radha'),
          'assets/bhakti/radha.png');
    });

    test('Marathi aartis have valid matching YouTube videos and full lyrics', () {
      expect(
        kDevotionalCatalog
            .firstWhere((i) => i.id == 'datta_aarti')
            .youtubeVideoId,
        'Grt4TFx1E8M',
      );
      expect(
        kDevotionalCatalog
            .firstWhere((i) => i.id == 'shiv_lavthavti')
            .youtubeVideoId,
        'dcJv2RiUc0k',
      );
      expect(
        kDevotionalCatalog
            .firstWhere((i) => i.id == 'hanuman_satrane')
            .youtubeVideoId,
        'VcAScMm21j4',
      );
      expect(
        kDevotionalCatalog
            .firstWhere((i) => i.id == 'durga_durge_durghatbhari')
            .youtubeVideoId,
        'Lqu5sRHpiyc',
      );

      for (final aarti in kMarathiAartiCatalog) {
        expect(aarti.youtubeVideoId.isNotEmpty, isTrue);
        expect(aarti.lyrics.isNotEmpty, isTrue);
        expect(aarti.titleMr.isNotEmpty, isTrue);
      }
    });
  });
}
