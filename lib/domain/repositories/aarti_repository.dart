import '../entities/aarti_item.dart';

/// Abstract repository for fetching devotional catalog items.
abstract class AartiRepository {
  Future<List<AartiItem>> fetchCatalog();
}
