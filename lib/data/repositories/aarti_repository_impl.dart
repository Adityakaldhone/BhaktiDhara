import '../../domain/entities/aarti_item.dart';
import '../../domain/repositories/aarti_repository.dart';
import '../datasources/catalog.dart';

/// Implementation of the AartiRepository using the local static catalog.
class AartiRepositoryImpl implements AartiRepository {
  @override
  Future<List<AartiItem>> fetchCatalog() async {
    // In a real app, this might fetch from a database or API.
    // For now, it returns the static list with a small simulated delay.
    await Future.delayed(const Duration(milliseconds: 300));
    return kDevotionalCatalog;
  }
}
