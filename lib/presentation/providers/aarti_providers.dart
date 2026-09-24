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

/// Derived provider that applies the filter to the catalog.
final filteredCatalogProvider = Provider<AsyncValue<List<AartiItem>>>((ref) {
  final catalogAsync = ref.watch(aartiCatalogProvider);
  final filter = ref.watch(selectedDeityFilterProvider);

  return catalogAsync.whenData((catalog) {
    if (filter == null) return catalog;
    return catalog.where((item) => item.deity == filter).toList();
  });
});
