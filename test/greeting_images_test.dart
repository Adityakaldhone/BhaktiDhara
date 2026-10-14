import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:nitya_aarti/data/repositories/greeting_repository.dart';
import 'package:nitya_aarti/domain/entities/greeting_image.dart';
import 'package:nitya_aarti/presentation/providers/greeting_providers.dart';
import 'package:nitya_aarti/presentation/screens/greetings_screen.dart';
import 'package:nitya_aarti/presentation/widgets/greeting/greeting_tile.dart';
import 'package:nitya_aarti/services/greeting_image_composer.dart';

const _base = 'http://example.test';

GreetingImage _image(int id, {String category = 'morning', bool premium = false, bool locked = false}) =>
    GreetingImage(
      id: id,
      category: category,
      thumbUrl: '$_base/media/greetings/t$id.webp',
      hdUrl: locked ? null : '$_base/media/greetings/h$id.jpg',
      width: 1080,
      height: 1350 + id * 10,
      premium: premium,
      locked: locked,
    );

class _FakeRepository extends GreetingRepository {
  final requested = <String>[];

  @override
  Future<List<GreetingCategory>> fetchCategories(String lang) async => const [
        GreetingCategory(slug: 'morning', name: 'शुभ सकाळ', emoji: '🌅', count: 3),
        GreetingCategory(slug: 'love', name: 'प्रेम', emoji: '❤️', count: 1),
        GreetingCategory(slug: 'night', name: 'शुभ रात्री', emoji: '🌙', count: 0),
      ];

  @override
  Future<GreetingPage> fetchImages({
    required String category,
    required String lang,
    required bool premium,
    int offset = 0,
  }) async {
    requested.add(category);
    final images = category == 'morning'
        ? [_image(1), _image(2), _image(3, premium: true, locked: true)]
        : [_image(10, category: 'love')];
    return GreetingPage(images: images, hasMore: false, nextOffset: images.length);
  }
}

Future<Uint8List> _solidPng(int width, int height, Color color) async {
  final recorder = ui.PictureRecorder();
  ui.Canvas(recorder).drawRect(
    Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
    ui.Paint()..color = color,
  );
  final image = await recorder.endRecording().toImage(width, height);
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  return data!.buffer.asUint8List();
}

void main() {
  group('GreetingImage JSON', () {
    test('turns server paths into absolute URLs and keeps locked images without HD', () {
      final image = GreetingImage.fromJson({
        'id': 7,
        'category': 'morning',
        'thumbUrl': '/media/greetings/a.webp',
        'hdUrl': null,
        'width': 1080,
        'height': 1920,
        'premium': true,
        'locked': true,
      }, baseUrl: '$_base/');

      expect(image!.thumbUrl, '$_base/media/greetings/a.webp');
      expect(image.hdUrl, isNull);
      expect(image.locked, isTrue);
      expect(image.aspectRatio, closeTo(1080 / 1920, 1e-9));
      expect(greetingLocked(image, premiumAccess: true), isTrue);
    });

    test('round-trips through the offline cache format', () {
      final original = _image(4, premium: true);
      final copy = GreetingImage.fromJson(original.toJson(), baseUrl: 'http://other.test')!;
      expect(copy.hdUrl, original.hdUrl);
      expect(copy.thumbUrl, original.thumbUrl);
      expect(greetingLocked(copy, premiumAccess: false), isTrue);
      expect(greetingLocked(copy, premiumAccess: true), isFalse);
    });

    test('rejects malformed entries', () {
      expect(GreetingImage.fromJson({'id': 1}, baseUrl: _base), isNull);
      expect(GreetingCategory.fromJson({'name': 'x'}, baseUrl: _base), isNull);
    });
  });

  group('GreetingPhotoLayout', () {
    test('places the circle at the bottom-left inside the image', () {
      final rect = GreetingPhotoLayout.circle(const Size(1080, 1920));
      expect(rect.left, closeTo(1080 * GreetingPhotoLayout.margin, 1e-9));
      expect(rect.bottom, closeTo(1920 - 1080 * GreetingPhotoLayout.margin, 1e-9));
      expect(rect.width, closeTo(rect.height, 1e-9));
    });

    testWidgets('composes the photo into the HD image at full size', (tester) async {
      await tester.runAsync(() async {
        final base = await _solidPng(400, 600, const Color(0xFFFF9800));
        final photo = await _solidPng(100, 100, const Color(0xFF1565C0));
        final out = await GreetingImageComposer.withPhoto(base, photo);

        final codec = await ui.instantiateImageCodec(out);
        final image = (await codec.getNextFrame()).image;
        expect(image.width, 400);
        expect(image.height, 600);

        final pixels = (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!;
        Color at(Offset p) {
          final i = (p.dy.toInt() * image.width + p.dx.toInt()) * 4;
          return Color.fromARGB(255, pixels.getUint8(i), pixels.getUint8(i + 1), pixels.getUint8(i + 2));
        }

        final circle = GreetingPhotoLayout.circle(const Size(400, 600));
        expect(at(circle.center), const Color(0xFF1565C0));
        expect(at(const Offset(300, 100)), const Color(0xFFFF9800));
        image.dispose();
      });
    });
  });

  group('GreetingsScreen', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    Future<_FakeRepository> pumpScreen(WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 3000);
      tester.view.devicePixelRatio = 2.5;
      addTearDown(tester.view.reset);
      final repo = _FakeRepository();
      await tester.pumpWidget(ProviderScope(
        overrides: [greetingRepositoryProvider.overrideWithValue(repo)],
        child: const MaterialApp(home: GreetingsScreen()),
      ));
      await tester.pump();
      await tester.pump();
      return repo;
    }

    testWidgets('shows categories with images and opens on Good Morning', (tester) async {
      final repo = await pumpScreen(tester);

      expect(find.byKey(const Key('greeting-category-morning')), findsOneWidget);
      expect(find.byKey(const Key('greeting-category-love')), findsOneWidget);
      expect(find.byKey(const Key('greeting-category-night')), findsNothing);
      expect(find.byKey(const Key('greeting-category-favorites')), findsOneWidget);
      expect(repo.requested.first, 'morning');
      expect(find.byType(GreetingTile), findsNWidgets(3));
      expect(find.byKey(const Key('greeting-fav-3')), findsNothing, reason: 'locked images cannot be favourited');
    });

    testWidgets('switching category loads that category', (tester) async {
      final repo = await pumpScreen(tester);

      await tester.tap(find.byKey(const Key('greeting-category-love')));
      await tester.pump();
      await tester.pump();

      expect(repo.requested.last, 'love');
      expect(find.byType(GreetingTile), findsOneWidget);
    });

    testWidgets('favourites tab lists hearted images', (tester) async {
      await pumpScreen(tester);

      await tester.tap(find.byKey(const Key('greeting-fav-1')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('greeting-category-favorites')));
      await tester.pump();

      expect(find.byType(GreetingTile), findsOneWidget);
      expect(find.byKey(const Key('greeting-fav-1')), findsOneWidget);
    });
  });
}
