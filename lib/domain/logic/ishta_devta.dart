import '../../data/datasources/bhakti_deity_catalog.dart';
import '../entities/aarti_item.dart';
import '../entities/bhakti_deity.dart';

/// SharedPreferences key holding the chosen [BhaktiDeity.key].
const kIshtaPrefsKey = 'ishta_devta_key';

/// Most-chosen deities, shown first on the Ishta Devta picker; every other
/// deity follows in catalog order.
const kIshtaDeityKeys = [
  'Lord Ganesha',
  'Khatu Shyam',
  'Goddess Durga',
  'Lord Shiva',
  'Lord Hanuman',
  'Lord Vitthal',
  'Lord Krishna',
  'Lord Rama',
  'Sai Baba',
  'Goddess Lakshmi',
  'Swami Samarth',
  'Lord Datta',
];

List<BhaktiDeity> ishtaDeities() => [
      for (final key in kIshtaDeityKeys)
        ...kBhaktiDeities.where((d) => d.key == key),
      ...kBhaktiDeities.where((d) => !kIshtaDeityKeys.contains(d.key)),
    ];

/// The deity saved as Ishta Devta, or Shri Ganesh when none was picked.
BhaktiDeity ishtaOrDefault(String? key) => kBhaktiDeities.firstWhere(
      (d) => d.key == key,
      orElse: () => kBhaktiDeities.firstWhere((d) => d.key == kIshtaDeityKeys.first),
    );

/// The aarti opened for [deity] after it is picked: its first item tagged
/// Aarti, otherwise its first item of any kind.
AartiItem? mainAartiFor(BhaktiDeity deity, List<AartiItem> catalog) {
  final items = catalog.where((i) => deity.matches(i.deity)).toList();
  if (items.isEmpty) return null;
  return items.firstWhere(
    (i) => i.tags.any((t) => t.toLowerCase() == 'aarti'),
    orElse: () => items.first,
  );
}
