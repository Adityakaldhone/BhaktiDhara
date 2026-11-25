import '../../domain/entities/aarti_item.dart';
import 'bhajan_catalog.dart';
import 'catalog.dart';
import 'khatushyam_stotras_catalog.dart';
import 'mahakal_stotras_catalog.dart';
import 'gujarati_deities_catalog.dart';
import 'rajasthani_deities_catalog.dart';
import 'uttarakhand_deities_catalog.dart';

/// The locally openable titles, in the same order used by Sacred Collection.
final bundledAartiCatalog = <AartiItem>[
  ...kDevotionalCatalog,
  ...kBhajanCatalog,
  ...kKhatuShyamStotrasCatalog,
  ...kMahakalStotrasCatalog,
  ...kGujaratiDeitiesCatalog,
  ...kRajasthaniDeitiesCatalog,
  ...kUttarakhandDeitiesCatalog,
];
