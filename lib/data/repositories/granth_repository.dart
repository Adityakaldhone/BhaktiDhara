import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/granth.dart';
import '../../services/backend_service.dart';

class GranthRepository {
  static final GranthRepository instance = GranthRepository._();
  GranthRepository._();

  static const _booksCacheKey = 'granth_books_cache_v1';
  static const _chaptersCachePrefix = 'granth_chapters_cache_v1_';
  static const _chapterDetailPrefix = 'granth_chapter_detail_v1_';

  String get _baseUrl => BackendService.backendUrl.trim();

  Future<Map<String, String>> _headers() async {
    final deviceId = await BackendService.getAnonymousDeviceId();
    return {
      'Content-Type': 'application/json',
      'X-Device-Id': deviceId,
    };
  }

  /// Offline cache is best-effort: on some devices the preferences store
  /// fails to load, and that must not block the live API.
  Future<SharedPreferences?> _prefs() async {
    try {
      return await SharedPreferences.getInstance();
    } catch (e) {
      debugPrint('⚠️ Granth cache unavailable: $e');
      _reportError('prefs', e);
      return null;
    }
  }

  Future<void> _writeCache(SharedPreferences? prefs, String key, String value) async {
    try {
      await prefs?.setString(key, value);
    } catch (e) {
      debugPrint('⚠️ Granth cache write failed for $key: $e');
    }
  }

  static void _reportError(String stage, Object error) {
    final message = error.toString();
    BackendService.trackEvent(
      'granth_load_error',
      item: stage,
      props: {'error': message.length > 200 ? message.substring(0, 200) : message},
    );
  }

  /// Fetches the list of sacred scriptures.
  Future<List<GranthBook>> getBooks() async {
    final prefs = await _prefs();

    // Try live API first
    try {
      final res = await http
          .get(
            Uri.parse('$_baseUrl/api/v1/granth/books'),
            headers: await _headers(),
          )
          .timeout(const Duration(seconds: 8));

      if (res.statusCode == 200) {
        final data = json.decode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
        final rawList = data['books'] as List? ?? [];
        final books = rawList
            .whereType<Map<String, dynamic>>()
            .map((b) => GranthBook.fromJson(b))
            .toList();

        // Cache locally for offline support
        await _writeCache(prefs, _booksCacheKey, res.body);
        return books;
      }
      _reportError('books_http_${res.statusCode}', 'HTTP ${res.statusCode}');
    } catch (e) {
      debugPrint('⚠️ Error fetching granth books: $e');
      _reportError('books', e);
    }

    // Fallback to cache
    final cached = prefs?.getString(_booksCacheKey);
    if (cached != null) {
      try {
        final data = json.decode(cached) as Map<String, dynamic>;
        final rawList = data['books'] as List? ?? [];
        return rawList
            .whereType<Map<String, dynamic>>()
            .map((b) => GranthBook.fromJson(b))
            .toList();
      } catch (_) {}
    }

    return [];
  }

  /// Fetches all chapters of a book.
  Future<List<GranthChapter>> getChapters(String bookSlug) async {
    final prefs = await _prefs();
    final cacheKey = '$_chaptersCachePrefix$bookSlug';

    try {
      final res = await http
          .get(
            Uri.parse('$_baseUrl/api/v1/granth/books/$bookSlug/chapters'),
            headers: await _headers(),
          )
          .timeout(const Duration(seconds: 8));

      if (res.statusCode == 200) {
        final data = json.decode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
        final rawList = data['chapters'] as List? ?? [];
        final chapters = rawList
            .whereType<Map<String, dynamic>>()
            .map((c) => GranthChapter.fromJson(c))
            .toList();

        await _writeCache(prefs, cacheKey, res.body);
        return chapters;
      }
    } catch (e) {
      debugPrint('⚠️ Error fetching chapters for $bookSlug: $e');
    }

    final cached = prefs?.getString(cacheKey);
    if (cached != null) {
      try {
        final data = json.decode(cached) as Map<String, dynamic>;
        final rawList = data['chapters'] as List? ?? [];
        return rawList
            .whereType<Map<String, dynamic>>()
            .map((c) => GranthChapter.fromJson(c))
            .toList();
      } catch (_) {}
    }

    return [];
  }

  /// Fetches detailed chapter verses with lock status.
  Future<GranthChapterDetail?> getChapterDetail(String bookSlug, int chapterNum) async {
    final prefs = await _prefs();
    final cacheKey = '$_chapterDetailPrefix${bookSlug}_$chapterNum';

    try {
      final res = await http
          .get(
            Uri.parse('$_baseUrl/api/v1/granth/books/$bookSlug/chapter/$chapterNum'),
            headers: await _headers(),
          )
          .timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final data = json.decode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
        final detail = GranthChapterDetail.fromJson(data);
        // Only cache if full verses or unlocked
        if (!detail.isLocked) {
          await _writeCache(prefs, cacheKey, res.body);
        }
        return detail;
      }
    } catch (e) {
      debugPrint('⚠️ Error fetching chapter $chapterNum of $bookSlug: $e');
    }

    final cached = prefs?.getString(cacheKey);
    if (cached != null) {
      try {
        final data = json.decode(cached) as Map<String, dynamic>;
        return GranthChapterDetail.fromJson(data);
      } catch (_) {}
    }

    return null;
  }

  /// Fetches Pothi metadata for a book (if available).
  Future<GranthPothiInfo?> getPothiInfo(String bookSlug) async {
    final prefs = await _prefs();
    final cacheKey = 'granth_pothi_info_$bookSlug';

    try {
      final res = await http
          .get(
            Uri.parse('$_baseUrl/api/v1/granth/books/$bookSlug/pothi'),
            headers: await _headers(),
          )
          .timeout(const Duration(seconds: 8));

      if (res.statusCode == 200) {
        final data = json.decode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
        await _writeCache(prefs, cacheKey, res.body);
        return GranthPothiInfo.fromJson(data);
      }
    } catch (e) {
      debugPrint('⚠️ Error fetching pothi info for $bookSlug: $e');
    }

    final cached = prefs?.getString(cacheKey);
    if (cached != null) {
      try {
        final data = json.decode(cached) as Map<String, dynamic>;
        return GranthPothiInfo.fromJson(data);
      } catch (_) {}
    }

    return null;
  }

  /// Returns the streamable image URL for a given page number.
  String getPothiPageUrl(String bookSlug, int pageNumber) {
    return '$_baseUrl/api/v1/granth/books/$bookSlug/pothi/page/$pageNumber';
  }
}
