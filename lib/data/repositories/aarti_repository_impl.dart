import '../../domain/entities/aarti_item.dart';
import '../../domain/repositories/aarti_repository.dart';
import '../datasources/catalog.dart';

/// Implementation of the AartiRepository using the local static catalog.
class AartiRepositoryImpl implements AartiRepository {
  @override
  Future<List<AartiItem>> fetchCatalog() async {
    return kDevotionalCatalog;
  }
}
