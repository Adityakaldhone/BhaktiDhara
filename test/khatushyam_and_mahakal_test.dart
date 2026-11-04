import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nitya_aarti/data/datasources/bhakti_deity_catalog.dart';
import 'package:nitya_aarti/data/datasources/catalog.dart';
import 'package:nitya_aarti/data/datasources/khatushyam_aartis_catalog.dart';
import 'package:nitya_aarti/data/datasources/khatushyam_songs_catalog.dart';
import 'package:nitya_aarti/data/datasources/khatushyam_stotras_catalog.dart';
import 'package:nitya_aarti/data/datasources/mahakal_aartis_catalog.dart';
import 'package:nitya_aarti/data/datasources/mahakal_songs_catalog.dart';
import 'package:nitya_aarti/data/datasources/mahakal_stotras_catalog.dart';
import 'package:nitya_aarti/domain/entities/bhakti_deity.dart';
import 'package:nitya_aarti/presentation/providers/aarti_providers.dart';
import 'package:nitya_aarti/presentation/providers/bhakti_darshan_providers.dart';

void main() {
  group('Khatu Shyam and Mahakal Catalog Integration Tests', () {
    test('Aartis catalog includes Khatu Shyam and Mahakal aartis in Sacred Collection', () {
      // Khatu Shyam Aartis
      expect(kKhatuShyamAartisCatalog.length, 3);
      for (final aarti in kKhatuShyamAartisCatalog) {
        expect(kDevotionalCatalog.any((item) => item.id == aarti.id), isTrue);
        expect(aarti.deity, 'Khatu Shyam');
        expect(aarti.tags, contains('Aarti'));
        expect(aarti.youtubeVideoId.isNotEmpty, isTrue);
      }

      // Mahakal Aartis
      expect(kMahakalAartisCatalog.length, 7);
      for (final aarti in kMahakalAartisCatalog) {
        expect(kDevotionalCatalog.any((item) => item.id == aarti.id), isTrue);
        expect(aarti.deity, 'Mahakal');
        expect(aarti.tags, contains('Aarti'));
        expect(aarti.youtubeVideoId.isNotEmpty, isTrue);
      }
    });

    test('Bhakti Tab Songs Catalogs contain 100 songs each', () {
      expect(kKhatuShyamSongsCatalog.length, 100);
      for (final song in kKhatuShyamSongsCatalog) {
        expect(song.videoId.isNotEmpty, isTrue);
        expect(song.song.isNotEmpty, isTrue);
      }

      expect(kMahakalSongsCatalog.length, 100);
      for (final song in kMahakalSongsCatalog) {
        expect(song.videoId.isNotEmpty, isTrue);
        expect(song.song.isNotEmpty, isTrue);
      }
    });

    test('Bhakti Tab Stotras Catalogs contain all stotras, chalisas, mantras, and stutis', () {
      expect(kKhatuShyamStotrasCatalog.length, 11);
      expect(kMahakalStotrasCatalog.length, 14);

      // Verify Khatu Shyam items
      expect(kKhatuShyamStotrasCatalog.any((s) => s.tags.contains('Chalisa')), isTrue);
      expect(kKhatuShyamStotrasCatalog.any((s) => s.tags.contains('Mantra')), isTrue);
      expect(kKhatuShyamStotrasCatalog.any((s) => s.tags.contains('Stuti') || s.tags.contains('Stotra')), isTrue);

      // Verify Mahakal items
      expect(kMahakalStotrasCatalog.any((s) => s.tags.contains('Chalisa')), isTrue);
      expect(kMahakalStotrasCatalog.any((s) => s.tags.contains('Mantra')), isTrue);
      expect(kMahakalStotrasCatalog.any((s) => s.tags.contains('Stotra')), isTrue);
    });

    test('Bhakti deities list includes Mahakal and Khatu Shyam', () {
      expect(kBhaktiDeities.any((d) => d.key == 'Mahakal'), isTrue);
      expect(kBhaktiDeities.any((d) => d.key == 'Khatu Shyam'), isTrue);
    });

    test('Providers correctly expose categories and content for both deities', () {
      final container = ProviderContainer();

      // Check categories for Mahakal
      final mahakalCategories = container.read(deityCategoriesProvider('Mahakal'));
      expect(mahakalCategories, contains(BhaktiCategory.aarti));
      expect(mahakalCategories, contains(BhaktiCategory.chalisa));
      expect(mahakalCategories, contains(BhaktiCategory.mantra));
      expect(mahakalCategories, contains(BhaktiCategory.stotra));
      expect(mahakalCategories, contains(BhaktiCategory.song));

      // Check categories for Khatu Shyam
      final khatuCategories = container.read(deityCategoriesProvider('Khatu Shyam'));
      expect(khatuCategories, contains(BhaktiCategory.aarti));
      expect(khatuCategories, contains(BhaktiCategory.chalisa));
      expect(khatuCategories, contains(BhaktiCategory.mantra));
      expect(khatuCategories, contains(BhaktiCategory.stotra));
      expect(khatuCategories, contains(BhaktiCategory.song));

      // Check content for Mahakal
      final mahakalContent = container.read(deityContentProvider('Mahakal'));
      expect(mahakalContent.length, greaterThanOrEqualTo(21)); // 7 aartis + 14 stotras

      // Check content for Khatu Shyam
      final khatuContent = container.read(deityContentProvider('Khatu Shyam'));
      expect(khatuContent.length, greaterThanOrEqualTo(14)); // 3 aartis + 11 stotras
    });

    test('Aarti search matches spiritual synonyms for Khatu Shyam and Mahakal', () {
      final khatuAarti = kKhatuShyamAartisCatalog.first;
      expect(matchAartiSearch(khatuAarti, 'shyam'), isTrue);
      expect(matchAartiSearch(khatuAarti, 'khatu'), isTrue);
      expect(matchAartiSearch(khatuAarti, 'खाटू'), isTrue);

      final mahakalAarti = kMahakalAartisCatalog.first;
      expect(matchAartiSearch(mahakalAarti, 'mahakal'), isTrue);
      expect(matchAartiSearch(mahakalAarti, 'ujjain'), isTrue);
      expect(matchAartiSearch(mahakalAarti, 'महाकाल'), isTrue);
    });
  });
}

