import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/aarti_repository_impl.dart';
import '../../domain/entities/aarti_item.dart';
import '../../domain/repositories/aarti_repository.dart';

/// Provider for the repository implementation
final aartiRepositoryProvider = Provider<AartiRepository>((ref) {
  return AartiRepositoryImpl();
});

/// FutureProvider that fetches the catalog from the repository.
final aartiCatalogProvider = FutureProvider<List<AartiItem>>((ref) async {
  final repository = ref.watch(aartiRepositoryProvider);
  return repository.fetchCatalog();
});

/// StateProvider for filtering the catalog by deity.
final selectedDeityFilterProvider = StateProvider<String?>((ref) => null);

/// StateProvider for the active search query.
final searchQueryProvider = StateProvider<String>((ref) => '');

/// Checks if an Aarti item matches the search query.
/// Supports multi-lingual search in English, Hindi, and Marathi,
/// matching titles, deities, singers, tags, lyrics (Devanagari and transliteration),
/// and popular devotional synonyms/aliases.
bool matchAartiSearch(AartiItem item, String rawQuery) {
  final query = rawQuery.trim().toLowerCase();
  if (query.isEmpty) return true;

  // 1. Direct fields: English, Hindi, Marathi titles
  if (item.title.toLowerCase().contains(query) ||
      item.titleHi.toLowerCase().contains(query) ||
      item.titleMr.toLowerCase().contains(query)) {
    return true;
  }

  // 2. Deities in English, Hindi, Marathi
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

  // 4. Lyrics matching (both Devanagari script and English transliteration)
  for (final stanza in item.lyrics) {
    if (stanza.devanagari.toLowerCase().contains(query) ||
        stanza.transliteration.toLowerCase().contains(query)) {
      return true;
    }
  }

  // 5. Popular spiritual synonyms, colloquial names, and phonetic variations
  final synonyms = _getSpiritualSynonyms(item.id);
  for (final synonym in synonyms) {
    final syn = synonym.toLowerCase();
    if (syn.contains(query) || query.contains(syn)) {
      return true;
    }
  }

  return false;
}

List<String> _getSpiritualSynonyms(String aartiId) {
  if (aartiId.startsWith('ganesh')) {
    return const [
      'ganesh', 'ganesha', 'ganpati', 'ganapati', 'vinayak', 'vighnaharta',
      'lambodar', 'bappa', 'morya', 'modak',
      'गणेश', 'गणपती', 'विनायक', 'विघ्नहर्ता', 'लंबोदर',
      'बाप्पा', 'मोरया', 'मोदक', 'गजानन', 'भालचंद्र'
    ];
  }
  if (aartiId.startsWith('hanuman')) {
    return const [
      'hanuman', 'hanumaan', 'bajrangbali', 'maruti', 'anjaneya', 'pawanputra',
      'sankatmochan', 'chalisa', 'doha', 'chaupai', 'ram', 'shree ram', 'sita',
      'हनुमान', 'बजरंगबली', 'मारुती', 'अंजनेय', 'पवनपुत्र', 'संकटमोचन', 'चालीसा',
      'दोहा', 'चौपाई', 'राम', 'सीता', 'महारुद्र'
    ];
  }
  if (aartiId.startsWith('shiv')) {
    return const [
      'shiv', 'shiva', 'mahadev', 'bhole', 'bholenath', 'shankar', 'omkara',
      'trinetra', 'rudra', 'kailash', 'har har', 'aarti', 'arti', 'gangadhar',
      'शिव', 'महादेव', 'भोले', 'भोलेनाथ', 'शंकर', 'ओंकारा', 'त्रिनेत्र', 'रुद्र',
      'कैलाश', 'हर हर', 'आरती', 'गंगाधर', 'शिवशंकर'
    ];
  }
  if (aartiId.startsWith('durga') || aartiId.startsWith('santoshi')) {
    return const [
      'durga', 'ambe', 'ambey', 'mata', 'sherawali', 'bhavani', 'goddess',
      'jagjanani', 'gauri', 'aarti', 'arti', 'navratri', 'chandi', 'mahakali',
      'santoshi', 'दुर्गा', 'अम्बे', 'अंबे', 'माता', 'शेरावाली', 'भवानी', 'गौरी',
      'जगजननी', 'आरती', 'नवरात्रि', 'चंडी', 'महाकाली', 'संतोषी'
    ];
  }
  if (aartiId.startsWith('vitthal') || aartiId.startsWith('pasayadan')) {
    return const [
      'vitthal', 'vithoba', 'pandurang', 'pandhari', 'wari', 'namdev',
      'विठ्ठल', 'विठोबा', 'पांडुरंग', 'पंढरी', 'वारी', 'नामदेव'
    ];
  }
  if (aartiId.startsWith('datta')) {
    return const [
      'datta', 'dattatreya', 'gurudatta', 'eknath',
      'दत्त', 'दत्तात्रेय', 'गुरुदत्त', 'एकनाथ'
    ];
  }
  if (aartiId.startsWith('krishna')) {
    return const [
      'krishna', 'govinda', 'gopal', 'kunj', 'bihari', 'radha',
      'कृष्ण', 'गोविंद', 'गोपाल', 'कुंज', 'बिहारी', 'राधा'
    ];
  }
  if (aartiId.startsWith('rama')) {
    return const [
      'ram', 'rama', 'raghu', 'ayodhya', 'sita',
      'राम', 'रघु', 'अयोध्या', 'सीता'
    ];
  }
  if (aartiId.startsWith('lakshmi')) {
    return const [
      'lakshmi', 'laxmi', 'mahalakshmi', 'लक्ष्मी', 'महालक्ष्मी'
    ];
  }
  if (aartiId.startsWith('sai')) {
    return const [
      'sai', 'saibaba', 'shirdi', 'साई', 'शिर्डी'
    ];
  }
  return const [];
}

/// Derived provider that applies both the search query and the deity filter.
final filteredCatalogProvider = Provider<AsyncValue<List<AartiItem>>>((ref) {
  final catalogAsync = ref.watch(aartiCatalogProvider);
  final filter = ref.watch(selectedDeityFilterProvider);
  final query = ref.watch(searchQueryProvider).trim();

  return catalogAsync.whenData((catalog) {
    if (query.isNotEmpty) {
      // 1. Filter by search query across all localized titles, lyrics, and synonyms
      final searched = catalog.where((item) => matchAartiSearch(item, query)).toList();

      // If a deity filter is also active, narrow down within search results if there's a match
      if (filter != null && filter != 'All') {
        final filteredByDeity = searched.where((item) => item.deity == filter).toList();
        if (filteredByDeity.isNotEmpty) {
          return filteredByDeity;
        }
      }
      return searched;
    }

    // No search query: standard deity filter
    if (filter != null && filter != 'All') {
      return catalog.where((item) => item.deity == filter).toList();
    }

    // On the main dashboard (All deities): show one distinct card per deity
    final seenDeities = <String>{};
    return catalog.where((item) => seenDeities.add(item.deity)).toList();
  });
});
