import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/greeting_image.dart';
import '../../services/backend_service.dart';

/// Loads greeting categories and images from the backend. The first page of
/// each category is cached so the screen still opens offline; the image files
/// themselves are cached on disk by the image loader.
class GreetingRepository {
  static const _timeout = Duration(seconds: 8);
  static const pageSize = 24;

  String get _base => BackendService.backendUrl.trim();

  Future<List<GreetingCategory>> fetchCategories(String lang) async {
    final cacheKey = 'greeting_categories_v1_$lang';
    try {
      final uri = Uri.parse('$_base/api/v1/greetings/categories')
          .replace(queryParameters: {'lang': lang});
      final response = await http.get(uri).timeout(_timeout);
      if (response.statusCode == 200) {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        final list = _parseCategories(decoded is Map ? decoded['categories'] : null, _base);
        await _writeCache(cacheKey, list.map((c) => c.toJson()).toList());
        return list;
      }
    } catch (_) {}
    final cached = await _readCache(cacheKey);
    if (cached != null) return _parseCategories(cached, _base);
    throw const GreetingLoadException();
  }

  Future<GreetingPage> fetchImages({
    required String category,
    required String lang,
    required bool premium,
    int offset = 0,
  }) async {
    final cacheKey = 'greeting_images_v1_${category}_${lang}_${premium ? 'p' : 'f'}';
    try {
      final uri = Uri.parse('$_base/api/v1/greetings/images').replace(queryParameters: {
        'category': category,
        'lang': lang,
        'deviceId': await BackendService.getAnonymousDeviceId(),
        'offset': '$offset',
        'limit': '$pageSize',
      });
      final response = await http.get(uri).timeout(_timeout);
      if (response.statusCode == 200) {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        if (decoded is Map) {
          final page = GreetingPage(
            images: _parseImages(decoded['images'], _base),
            hasMore: decoded['hasMore'] == true,
            nextOffset: (decoded['nextOffset'] as num?)?.toInt() ?? offset,
          );
          if (offset == 0) {
            await _writeCache(cacheKey, page.images.map((i) => i.toJson()).toList());
          }
          return page;
        }
      }
    } catch (_) {}
    if (offset == 0) {
      final cached = await _readCache(cacheKey);
      if (cached != null) {
        final images = _parseImages(cached, _base);
        return GreetingPage(images: images, hasMore: false, nextOffset: images.length);
      }
    }
    throw const GreetingLoadException();
  }

  void recordShare(int imageId) {
    http
        .post(Uri.parse('$_base/api/v1/greetings/images/$imageId/share'))
        .timeout(_timeout)
        .then((_) {}, onError: (_) {});
  }

  static List<GreetingCategory> _parseCategories(Object? list, String base) => list is List
      ? list.map((e) => GreetingCategory.fromJson(e, baseUrl: base)).whereType<GreetingCategory>().toList()
      : const [];

  static List<GreetingImage> _parseImages(Object? list, String base) => list is List
      ? list.map((e) => GreetingImage.fromJson(e, baseUrl: base)).whereType<GreetingImage>().toList()
      : const [];

  static Future<void> _writeCache(String key, Object value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, jsonEncode(value));
    } catch (_) {}
  }

  static Future<Object?> _readCache(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(key);
      return raw == null ? null : jsonDecode(raw);
    } catch (_) {
      return null;
    }
  }
}

class GreetingLoadException implements Exception {
  const GreetingLoadException();
}

/// Favourite images, stored whole on this phone so the Favourites tab works
/// offline and survives the image moving category.
class GreetingFavoritesRepository {
  static const _key = 'greeting_favorites_v1';

  Future<List<GreetingImage>> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null) return const [];
      return GreetingRepository._parseImages(jsonDecode(raw), BackendService.backendUrl);
    } catch (_) {
      return const [];
    }
  }

  Future<void> save(List<GreetingImage> images) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, jsonEncode(images.map((i) => i.toJson()).toList()));
    } catch (_) {}
  }
}
