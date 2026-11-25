import 'aarti_item.dart';
import 'bhakti_deity.dart';

/// Payload from `GET /api/v1/catalog`.
class RemoteDevotionalCatalog {
  final String version;
  final List<AartiItem> aartis;
  final List<BhaktiDeity> deities;

  /// Explicit admin pins: aarti id → sort order (lower = first).
  final Map<String, int> aartiSort;

  /// Explicit admin pins: deity key → sort order (lower = first).
  final Map<String, int> deitySort;

  const RemoteDevotionalCatalog({
    this.version = '',
    this.aartis = const [],
    this.deities = const [],
    this.aartiSort = const {},
    this.deitySort = const {},
  });

  static const empty = RemoteDevotionalCatalog();

  factory RemoteDevotionalCatalog.fromJson(
    Map<String, dynamic> json, {
    String mediaBaseUrl = '',
  }) {
    final aartis = <AartiItem>[];
    final aartisRaw = json['aartis'];
    if (aartisRaw is List) {
      for (final item in aartisRaw) {
        if (item is! Map) continue;
        final aarti = AartiItem.fromJson(Map<String, dynamic>.from(item));
        if (aarti.isValidRemote) aartis.add(aarti);
      }
    }

    final deities = <BhaktiDeity>[];
    final deitiesRaw = json['deities'];
    if (deitiesRaw is List) {
      for (final item in deitiesRaw) {
        if (item is! Map) continue;
        final map = Map<String, dynamic>.from(item);
        final rawUrl = (map['imageUrl'] as String?)?.trim() ?? '';
        if (rawUrl.isNotEmpty &&
            rawUrl.startsWith('/') &&
            mediaBaseUrl.trim().isNotEmpty) {
          map['imageUrl'] = '${mediaBaseUrl.trim().replaceAll(RegExp(r'/$'), '')}$rawUrl';
        }
        final deity = BhaktiDeity.fromJson(map);
        if (deity.isValidRemote) deities.add(deity);
      }
    }

    Map<String, int> parseSortMap(Object? raw) {
      if (raw is! Map) return const {};
      final out = <String, int>{};
      raw.forEach((key, value) {
        final id = key.toString().trim();
        if (id.isEmpty) return;
        final order = value is num ? value.toInt() : int.tryParse('$value');
        if (order != null) out[id] = order;
      });
      return out;
    }

    final sortRaw = json['sort'];
    final sortMap = sortRaw is Map ? Map<String, dynamic>.from(sortRaw) : const <String, dynamic>{};

    return RemoteDevotionalCatalog(
      version: (json['version'] as String?)?.trim() ?? '',
      aartis: aartis,
      deities: deities,
      aartiSort: parseSortMap(sortMap['aartis']),
      deitySort: parseSortMap(sortMap['deities']),
    );
  }

  Map<String, dynamic> toJson() => {
        'version': version,
        'aartis': aartis.map((a) => a.toJson()).toList(),
        'deities': deities.map((d) => d.toJson()).toList(),
        'sort': {'aartis': aartiSort, 'deities': deitySort},
      };
}

/// Local ids win on conflict; remotes append. [sort] pins then order the list.
List<AartiItem> mergeAartiCatalogs(
  List<AartiItem> local,
  List<AartiItem> remote, {
  Map<String, int> aartiSort = const {},
}) {
  final localIds = <String>{for (final item in local) item.id};
  final merged = <AartiItem>[
    ...local,
    for (final item in remote)
      if (!localIds.contains(item.id)) item,
  ];
  return applyAartiSortOrder(merged, aartiSort);
}

List<BhaktiDeity> mergeDeityCatalogs(
  List<BhaktiDeity> local,
  List<BhaktiDeity> remote, {
  Map<String, int> deitySort = const {},
}) {
  final seen = <String>{for (final item in local) item.key};
  final merged = <BhaktiDeity>[
    ...local,
    for (final item in remote)
      if (seen.add(item.key)) item,
  ];
  return applyDeitySortOrder(merged, deitySort);
}

/// Applies admin sort pins and sorts ascending (stable for unset).
List<AartiItem> applyAartiSortOrder(
  List<AartiItem> items,
  Map<String, int> aartiSort,
) {
  if (items.isEmpty) return items;
  final withOrder = <AartiItem>[
    for (final item in items)
      aartiSort.containsKey(item.id)
          ? item.copyWithSortOrder(aartiSort[item.id]!)
          : item,
  ];
  final indexed = [
    for (var i = 0; i < withOrder.length; i++) (i, withOrder[i]),
  ];
  indexed.sort((a, b) {
    final byOrder = a.$2.sortOrder.compareTo(b.$2.sortOrder);
    return byOrder != 0 ? byOrder : a.$1.compareTo(b.$1);
  });
  return [for (final e in indexed) e.$2];
}

List<BhaktiDeity> applyDeitySortOrder(
  List<BhaktiDeity> items,
  Map<String, int> deitySort,
) {
  if (items.isEmpty) return items;
  final withOrder = <BhaktiDeity>[
    for (final item in items)
      deitySort.containsKey(item.key)
          ? item.copyWithSortOrder(deitySort[item.key]!)
          : item,
  ];
  final indexed = [
    for (var i = 0; i < withOrder.length; i++) (i, withOrder[i]),
  ];
  indexed.sort((a, b) {
    final byOrder = a.$2.sortOrder.compareTo(b.$2.sortOrder);
    return byOrder != 0 ? byOrder : a.$1.compareTo(b.$1);
  });
  return [for (final e in indexed) e.$2];
}

/// Splits Sacred Collection cards into admin-pinned (sorted) + unpinned rest.
({List<AartiItem> pinned, List<AartiItem> rest}) splitAdminPinnedDeities(
  List<AartiItem> distinctByDeity,
  Map<String, int> deitySort,
  String Function(AartiItem item) deityKeyOf,
) {
  if (distinctByDeity.isEmpty) {
    return (pinned: const <AartiItem>[], rest: const <AartiItem>[]);
  }

  final pinned = <AartiItem>[];
  final rest = <AartiItem>[];
  for (final item in distinctByDeity) {
    final key = deityKeyOf(item);
    if (deitySort.containsKey(key) || deitySort.containsKey(item.deity)) {
      pinned.add(item);
    } else {
      rest.add(item);
    }
  }

  int orderOf(AartiItem item) {
    final key = deityKeyOf(item);
    return deitySort[key] ?? deitySort[item.deity] ?? AartiItem.unsetSortOrder;
  }

  pinned.sort((a, b) {
    final byOrder = orderOf(a).compareTo(orderOf(b));
    return byOrder != 0 ? byOrder : a.deity.compareTo(b.deity);
  });

  return (pinned: pinned, rest: rest);
}
