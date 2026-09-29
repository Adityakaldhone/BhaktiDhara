import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/bhajan_catalog.dart';
import '../../domain/entities/aarti_item.dart';

/// Provider for the full static list of Bhajans & Kirtans.
final bhajanCatalogProvider = Provider<List<AartiItem>>((ref) {
  return kBhajanCatalog;
});

/// Selected deity/category filter for Bhajans.
/// Values can be 'All', 'Lord Krishna', 'Lord Rama', 'Lord Shiva', 'Lord Vitthal', 'Goddess Durga', 'Lord Ganesha', or 'Kirtan'.
final selectedBhajanCategoryProvider = StateProvider<String>((ref) => 'All');

/// Active search query for the Bhajan tab.
final bhajanSearchQueryProvider = StateProvider<String>((ref) => '');

/// Checks if a Bhajan item matches the search query.
bool matchBhajanSearch(AartiItem item, String rawQuery) {
  final query = rawQuery.trim().toLowerCase();
  if (query.isEmpty) return true;

  // 1. Titles in all languages
  if (item.title.toLowerCase().contains(query) ||
      item.titleHi.toLowerCase().contains(query) ||
      item.titleMr.toLowerCase().contains(query)) {
    return true;
  }

  // 2. Deity names
  if (item.deity.toLowerCase().contains(query) ||
      item.deityHi.toLowerCase().contains(query) ||
      item.deityMr.toLowerCase().contains(query)) {
    return true;
  }

  // 3. Singer attribution and tags
  if (item.singer.toLowerCase().contains(query) ||
      item.tags.any((tag) => tag.toLowerCase().contains(query))) {
    return true;
  }

  // 4. Lyrics matching (Devanagari and transliteration)
  for (final stanza in item.lyrics) {
    if (stanza.devanagari.toLowerCase().contains(query) ||
        stanza.transliteration.toLowerCase().contains(query)) {
      return true;
    }
  }

  return false;
}

/// Filtered Bhajan list applying both search query and category/deity chips.
final filteredBhajanCatalogProvider = Provider<List<AartiItem>>((ref) {
  final allBhajans = ref.watch(bhajanCatalogProvider);
  final category = ref.watch(selectedBhajanCategoryProvider);
  final query = ref.watch(bhajanSearchQueryProvider).trim();

  return allBhajans.where((item) {
    // 1. Check category filter
    if (category != 'All') {
      if (category == 'Kirtan') {
        final isKirtan = item.tags.any(
          (t) => t.toLowerCase().contains('kirtan') || t.toLowerCase().contains('dhun'),
        );
        if (!isKirtan) return false;
      } else {
        if (!item.deity.toLowerCase().contains(category.toLowerCase())) {
          return false;
        }
      }
    }

    // 2. Check search query
    if (query.isNotEmpty) {
      return matchBhajanSearch(item, query);
    }

    return true;
  }).toList();
});
