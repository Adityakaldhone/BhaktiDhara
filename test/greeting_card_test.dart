import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nitya_aarti/data/datasources/greeting_content.dart';
import 'package:nitya_aarti/data/repositories/greeting_card_prefs_repository.dart';
import 'package:nitya_aarti/data/repositories/greeting_photo_store.dart';
import 'package:nitya_aarti/domain/entities/greeting_card.dart';
import 'package:nitya_aarti/domain/logic/greeting_card_logic.dart';
import 'package:nitya_aarti/presentation/greeting/greeting_card_builder.dart';
import 'package:nitya_aarti/presentation/providers/greeting_card_providers.dart';
import 'package:nitya_aarti/presentation/providers/locale_provider.dart';
import 'package:nitya_aarti/presentation/screens/greeting_card_screen.dart';
import 'package:nitya_aarti/presentation/widgets/greeting/card_canvas.dart';
import 'package:nitya_aarti/presentation/widgets/greeting/card_templates.dart';
import 'package:nitya_aarti/services/card_renderer.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('card day', () {
    test('cards roll over at 4 AM, not midnight', () {
      expect(GreetingCardLogic.cardDay(DateTime(2026, 9, 29, 3, 59)), DateTime(2026, 9, 28));
      expect(GreetingCardLogic.cardDay(DateTime(2026, 9, 29, 4, 0)), DateTime(2026, 9, 29));
      expect(GreetingCardLogic.cardDay(DateTime(2026, 1, 1, 1, 0)), DateTime(2025, 12, 31));
    });

    test('weekday deity follows language-specific tradition', () {
      final thursday = DateTime(2026, 10, 1);
      final sunday = DateTime(2026, 10, 4);
      expect(GreetingCardLogic.weekdayDeity(DateTime(2026, 9, 28), 'mr'), 'mahadev');
      expect(GreetingCardLogic.weekdayDeity(thursday, 'mr'), 'datta');
      expect(GreetingCardLogic.weekdayDeity(thursday, 'hi'), 'saibaba');
      expect(GreetingCardLogic.weekdayDeity(sunday, 'mr'), 'khandoba');
      expect(GreetingCardLogic.weekdayDeity(sunday, 'en'), 'vishnu');
    });

    test('every weekday deity exists in the catalog with an image', () {
      for (var d = 0; d < 7; d++) {
        for (final lang in ['mr', 'hi', 'en']) {
          final id = GreetingCardLogic.weekdayDeity(DateTime(2026, 9, 28 + d), lang);
          expect(GreetingContent.deity(id).id, id);
        }
      }
    });
  });

  test('रोज नवीन rotates through every style, one per day', () {
    final start = DateTime(2026, 9, 29);
    final week = [
      for (var i = 0; i < CardStyle.values.length; i++)
        GreetingCardLogic.autoStyle(start.add(Duration(days: i))),
    ];
    expect(week.toSet(), CardStyle.values.toSet());
    expect(GreetingCardLogic.autoStyle(start), GreetingCardLogic.autoStyle(DateTime(2026, 9, 29, 23, 59)));
  });

  test('chosen style is saved and restored; null means रोज नवीन', () {
    const prefs = GreetingCardPrefs(style: CardStyle.kamal, senderName: 'राम');
    final restored = GreetingCardPrefs.fromJson(prefs.toJson());
    expect(restored.style, CardStyle.kamal);
    expect(GreetingCardPrefs.fromJson(const GreetingCardPrefs().toJson()).style, isNull);
    expect(GreetingCardPrefs.fromJson({'style': 'removedStyle'}).style, isNull);
  });

  group('emoji sanitizer', () {
    test('keeps any emoji, including skin tones, flags and family sequences', () {
      expect(GreetingCardLogic.sanitizeEmojis('🙏🪔🌺'), '🙏🪔🌺');
      expect(GreetingCardLogic.sanitizeEmojis('🙏🏽🇮🇳👨‍👩‍👧❤️🕉️'), '🙏🏽🇮🇳👨‍👩‍👧❤️🕉️');
    });

    test('drops letters, digits, keycaps and links, and caps the count', () {
      expect(GreetingCardLogic.sanitizeEmojis('जय🙏 hi 98765 www.x.com 1️⃣'), '🙏');
      expect(GreetingCardLogic.sanitizeEmojis('abc 123'), isNull);
      expect(GreetingCardLogic.sanitizeEmojis('🌸' * 20), '🌸' * GreetingCardLogic.maxEmojis);
    });
  });

  group('sender name sanitizer', () {
    test('keeps normal names in any script', () {
      expect(GreetingCardLogic.sanitizeName('  आदित्य   काका '), 'आदित्य काका');
      expect(GreetingCardLogic.sanitizeName('Sharma Family'), 'Sharma Family');
    });

    test('rejects links, handles and phone numbers', () {
      for (final spam in [
        'www.spam.com',
        'visit http://x',
        'bit.ly/abc',
        '@promo',
        '98765 43210',
        '९८७६५४३२१०',
      ]) {
        expect(GreetingCardLogic.sanitizeName(spam), isNull, reason: spam);
      }
    });

    test('strips control and bidi characters and caps length', () {
      expect(GreetingCardLogic.sanitizeName('Ram\u202E\u200Bu'), 'Ram u');
      final long = GreetingCardLogic.sanitizeName('अ' * 40)!;
      expect(long.runes.length, GreetingCardLogic.maxNameLength);
      expect(GreetingCardLogic.sanitizeName('   '), isNull);
    });
  });

  group('card builder', () {
    final tuesday = DateTime(2026, 9, 29, 7);

    test('default card needs no input: weekday deity with शुभ सकाळ', () {
      final card = GreetingCardBuilder.build(now: tuesday, lang: 'mr');
      expect(card.deityId, 'ganesh');
      expect(card.title, 'शुभ सकाळ');
      expect(card.jaykar, 'गणपती बाप्पा मोरया');
      expect(card.senderName, isNull);
      expect(card.template, CardTemplate.marigold);
    });

    test('user choices change deity, headline and sender', () {
      final card = GreetingCardBuilder.build(
        now: tuesday,
        lang: 'mr',
        deityOverride: 'vitthal',
        greeting: GreetingChoice.jaykar,
        senderName: 'Visit www.x.com',
      );
      expect(card.deityId, 'vitthal');
      expect(card.title, 'जय हरी विठ्ठल');
      expect(card.jaykar, 'शुभ सकाळ');
      expect(card.senderName, isNull);
    });
  });

  test('every template keeps text readable (WCAG AA 4.5:1)', () {
    for (final template in CardTemplate.values) {
      final p = CardPalette.of(template);
      for (final bg in [p.top, p.bottom]) {
        for (final (name, fg) in [('title', p.title), ('muted', p.muted)]) {
          expect(contrastRatio(fg, bg), greaterThanOrEqualTo(4.5), reason: '${template.name} $name');
        }
      }
    }
  });

  testWidgets('card never overflows for any style, deity, greeting or language', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    for (final lang in ['mr', 'hi', 'en']) {
      for (final deity in GreetingContent.deities) {
        for (final (i, greeting) in GreetingChoice.values.indexed) {
          final card = GreetingCardBuilder.build(
            style: CardStyle.values[(i + deity.id.length) % CardStyle.values.length],
            now: DateTime(2026, 9, 29, 7),
            lang: lang,
            deityOverride: deity.id,
            greeting: greeting,
            senderName: 'अ' * GreetingCardLogic.maxNameLength,
          );
          await tester.pumpWidget(Center(child: GreetingCardCanvas(data: card)));
          expect(tester.takeException(), isNull, reason: '$lang ${deity.id} ${greeting.name} ${card.style.name}');
        }
      }
    }
  });

  testWidgets('photo, longest name and emojis fit every style, deity and language', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final photo = (await tester.runAsync(() async {
      await CardRenderer.warmUpFonts();
      return _solidImage(180, 180);
    }))!;
    final deities = (await tester.runAsync(() => Future.wait([
          for (final d in GreetingContent.deities) CardRenderer.loadImages(d.id),
        ])))!;
    for (final lang in ['mr', 'hi', 'en']) {
      for (final style in CardStyle.values) {
        for (final (i, deity) in GreetingContent.deities.indexed) {
          final card = GreetingCardBuilder.build(
            style: style,
            now: DateTime(2026, 9, 29, 7),
            lang: lang,
            deityOverride: deity.id,
            senderName: 'अ' * GreetingCardLogic.maxNameLength,
            photoStamp: 1,
            emojis: '🙏🪔🌺🌸🌼💐🔱🚩',
          );
          final images = CardImages(deity: deities[i].deity, deityIsCutout: deities[i].deityIsCutout, photo: photo);
          await tester.pumpWidget(Center(child: GreetingCardCanvas(data: card, images: images)));
          expect(find.byKey(const Key('card-sender-photo')), findsOneWidget);
          expect(find.byKey(const Key('card-emoji-row')), findsOneWidget);
          expect(tester.takeException(), isNull, reason: '$lang ${style.name} ${deity.id}');
        }
      }
    }
    await tester.pumpWidget(Center(
      child: GreetingCardCanvas(
        data: GreetingCardBuilder.build(now: DateTime(2026, 9, 29, 7), lang: 'mr'),
        images: CardImages(photo: photo),
      ),
    ));
    expect(find.byKey(const Key('card-sender-photo')), findsNothing, reason: 'no photo unless the card asks for it');
  });

  testWidgets('photos are cropped square, downsized and re-encoded', (tester) async {
    final result = await tester.runAsync(() async {
      final tall = await _solidImage(600, 1200);
      final bytes = (await tall.toByteData(format: ui.ImageByteFormat.png))!.buffer.asUint8List();
      final png = await GreetingPhotoStore.normalize(bytes);
      final codec = await ui.instantiateImageCodec(png!);
      final image = (await codec.getNextFrame()).image;
      return (image.width, image.height, await GreetingPhotoStore.normalize(Uint8List.fromList([1, 2, 3])));
    });
    expect(result!.$1, GreetingPhotoStore.size);
    expect(result.$2, GreetingPhotoStore.size);
    expect(result.$3, isNull, reason: 'non-images are rejected');
  });

  test('photo choice is saved and changes the rendered card', () {
    final restored = GreetingCardPrefs.fromJson(const GreetingCardPrefs(photoStamp: 42, emojis: '🙏').toJson());
    expect(restored.photoStamp, 42);
    expect(restored.emojis, '🙏');
    expect(GreetingCardPrefs.fromJson(const GreetingCardPrefs().toJson()).photoStamp, isNull);
    final plain = GreetingCardBuilder.build(now: DateTime(2026, 9, 29, 7), lang: 'mr');
    final withPhoto = GreetingCardBuilder.build(now: DateTime(2026, 9, 29, 7), lang: 'mr', photoStamp: 42);
    expect(plain.cacheKey, isNot(withPhoto.cacheKey));
    expect(withPhoto.withStyle(CardStyle.om).photoStamp, 42);
  });

  testWidgets('edit sheet shows the saved photo and can remove it', (tester) async {
    SharedPreferences.setMockInitialValues({'greeting_card_prefs_v1': '{"photoStamp": 7, "askedForName": true}'});
    await tester.binding.setSurfaceSize(const Size(400, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final store = _FakePhotoStore();

    await tester.pumpWidget(ProviderScope(
      overrides: [
        localeProvider.overrideWith((ref) => const Locale('mr')),
        greetingClockProvider.overrideWithValue(() => DateTime(2026, 9, 29, 7)),
        cardImagesProvider.overrideWith((ref, key) async => const CardImages()),
        statusCardPhotoEnabledProvider.overrideWith((ref) async => true),
        greetingPhotoStoreProvider.overrideWithValue(store),
      ],
      child: const MaterialApp(home: GreetingCardScreen()),
    ));
    await tester.pumpAndSettle();
    final container = ProviderScope.containerOf(tester.element(find.byType(GreetingCardScreen)));
    expect(container.read(greetingCardProvider).photoStamp, 7);

    await tester.tap(find.byKey(const Key('greeting-edit-button')));
    await tester.pumpAndSettle();
    expect(find.text('तुमचा फोटो'), findsOneWidget);
    expect(find.text('फोटो बदला'), findsOneWidget);
    await tester.ensureVisible(find.byKey(const Key('greeting-photo-remove')));
    await tester.tap(find.byKey(const Key('greeting-photo-remove')));
    await tester.pumpAndSettle();

    expect(container.read(greetingCardProvider).photoStamp, isNull);
    expect(store.deleted, isTrue);
    expect(find.text('फोटो लावा'), findsOneWidget);

    await tester.ensureVisible(find.byKey(const Key('greeting-emoji-🙏')));
    await tester.tap(find.byKey(const Key('greeting-emoji-🙏')));
    await tester.tap(find.byKey(const Key('greeting-emoji-🪔')));
    await tester.pumpAndSettle();
    expect(container.read(greetingCardProvider).emojis, '🙏🪔');
    await tester.enterText(find.byKey(const Key('greeting-edit-emoji')), '🙏 call 98765 🌺');
    await tester.pumpAndSettle();
    expect(container.read(greetingCardProvider).emojis, '🙏🌺');
    await tester.tap(find.byKey(const Key('greeting-emoji-clear')));
    await tester.pumpAndSettle();
    expect(container.read(greetingCardProvider).emojis, '🙏');
  });

  testWidgets('photo option is hidden when switched off remotely', (tester) async {
    SharedPreferences.setMockInitialValues({'greeting_card_prefs_v1': '{"photoStamp": 7}'});
    await tester.pumpWidget(ProviderScope(
      overrides: [
        localeProvider.overrideWith((ref) => const Locale('mr')),
        greetingClockProvider.overrideWithValue(() => DateTime(2026, 9, 29, 7)),
        cardImagesProvider.overrideWith((ref, key) async => const CardImages()),
        statusCardPhotoEnabledProvider.overrideWith((ref) async => false),
      ],
      child: const MaterialApp(home: GreetingCardScreen()),
    ));
    await tester.pumpAndSettle();
    final container = ProviderScope.containerOf(tester.element(find.byType(GreetingCardScreen)));
    expect(container.read(greetingCardProvider).photoStamp, isNull);
    await tester.tap(find.byKey(const Key('greeting-edit-button')));
    await tester.pumpAndSettle();
    expect(find.text('तुमचा फोटो'), findsNothing);
  });

  testWidgets('renders a full-resolution 1080x1920 PNG offscreen', (tester) async {
    final data = GreetingCardBuilder.build(now: DateTime(2026, 9, 29, 7), lang: 'mr');
    final bytes = await tester.runAsync(() => CardRenderer.renderPng(data));
    expect(bytes, isNotNull);
    expect(bytes!.sublist(1, 4), 'PNG'.codeUnits);
    final image = await tester.runAsync(() async {
      final codec = await ui.instantiateImageCodec(bytes);
      return (await codec.getNextFrame()).image;
    });
    expect(image!.width, 1080);
    expect(image.height, 1920);
  });

  testWidgets('preview screen shows one card with send and change buttons', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.binding.setSurfaceSize(const Size(400, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(ProviderScope(
      overrides: [
        localeProvider.overrideWith((ref) => const Locale('mr')),
        greetingClockProvider.overrideWithValue(() => DateTime(2026, 9, 29, 7)),
        cardImagesProvider.overrideWith((ref, key) async => const CardImages()),
      ],
      child: const MaterialApp(home: GreetingCardScreen()),
    ));
    await tester.pumpAndSettle();

    expect(find.byType(GreetingCardCanvas), findsOneWidget);
    expect(find.byType(ChoiceChip), findsNothing);
    expect(find.text('WhatsApp वर पाठवा'), findsOneWidget);
    expect(find.text('बदला'), findsOneWidget);
    expect(tester.takeException(), isNull);

    final container = ProviderScope.containerOf(tester.element(find.byType(GreetingCardScreen)));
    expect(container.read(greetingCardProvider).style, GreetingCardLogic.autoStyle(DateTime(2026, 9, 29)));

    await tester.tap(find.byKey(const Key('greeting-edit-button')));
    await tester.pumpAndSettle();
    expect(find.text('डिझाइन निवडा'), findsOneWidget);
    expect(find.text('रोज नवीन'), findsOneWidget);
    await tester.tap(find.byKey(const Key('greeting-style-suryoday')));
    await tester.pumpAndSettle();
    expect(container.read(greetingCardProvider).style, CardStyle.suryoday);
    expect(find.text('देव निवडा'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('greeting-edit-name')), 'आदित्य');
    await tester.ensureVisible(find.byKey(const Key('greeting-edit-done')));
    await tester.tap(find.byKey(const Key('greeting-edit-done')));
    await tester.pumpAndSettle();

    expect(container.read(greetingCardPrefsProvider).senderName, 'आदित्य');
    expect(container.read(greetingCardProvider).senderName, 'आदित्य');
  });
}

Future<ui.Image> _solidImage(int width, int height) {
  final recorder = ui.PictureRecorder();
  ui.Canvas(recorder).drawRect(
    ui.Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
    ui.Paint()..color = const Color(0xFF8844AA),
  );
  return recorder.endRecording().toImage(width, height);
}

class _FakePhotoStore extends GreetingPhotoStore {
  bool deleted = false;

  @override
  Future<void> delete() async => deleted = true;

  @override
  Future<Uint8List?> read() async => null;
}
