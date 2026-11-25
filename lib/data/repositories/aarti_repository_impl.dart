import '../../domain/entities/aarti_item.dart';
import '../../domain/entities/remote_devotional_catalog.dart';
import '../../domain/repositories/aarti_repository.dart';
import '../../services/backend_service.dart';
import '../datasources/catalog.dart';
import '../datasources/gujarati_deities_catalog.dart';
import '../datasources/rajasthani_deities_catalog.dart';
import '../datasources/uttarakhand_deities_catalog.dart';

/// Local bundled catalogs plus server-published aartis (local ids win).
class AartiRepositoryImpl implements AartiRepository {
  @override
  Future<List<AartiItem>> fetchCatalog() async {
    final local = [
      ...kDevotionalCatalog,
      ...kGujaratiDeitiesCatalog,
      ...kRajasthaniDeitiesCatalog,
      ...kUttarakhandDeitiesCatalog,
    ];
    final catalog = BackendService.remoteCatalog;
    return mergeAartiCatalogs(
      local,
      catalog.aartis,
      aartiSort: catalog.aartiSort,
    );
  }
}
