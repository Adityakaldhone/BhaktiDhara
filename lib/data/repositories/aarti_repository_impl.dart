import '../../domain/entities/aarti_item.dart';
import '../../domain/repositories/aarti_repository.dart';
import '../datasources/catalog.dart';
import '../datasources/gujarati_deities_catalog.dart';
import '../datasources/rajasthani_deities_catalog.dart';
import '../datasources/uttarakhand_deities_catalog.dart';

/// Implementation of the AartiRepository using the local static catalog.
class AartiRepositoryImpl implements AartiRepository {
  @override
  Future<List<AartiItem>> fetchCatalog() async {
    return [
      ...kDevotionalCatalog,
      ...kGujaratiDeitiesCatalog,
      ...kRajasthaniDeitiesCatalog,
      ...kUttarakhandDeitiesCatalog,
    ];
  }
}
