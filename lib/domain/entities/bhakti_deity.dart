/// A deity shown in the Bhakti darshan carousel.
class BhaktiDeity {
  /// Canonical deity key, matching [AartiItem.deity] in the catalogs.
  final String key;

  /// Extra [AartiItem.deity] values that belong to this deity.
  final List<String> aliases;

  final String nameEn;
  final String nameHi;
  final String nameMr;

  /// Realistic transparent cut-out shown inside the mandap frame.
  final String imageAsset;

  /// Optional network image for remotely published deities.
  final String imageUrl;

  /// Admin / remote catalog display order for Sacred Collection. Lower = earlier.
  final int sortOrder;

  static const int unsetSortOrder = 1000000;

  const BhaktiDeity({
    required this.key,
    this.aliases = const [],
    required this.nameEn,
    required this.nameHi,
    required this.nameMr,
    required this.imageAsset,
    this.imageUrl = '',
    this.sortOrder = unsetSortOrder,
  });

  factory BhaktiDeity.fromJson(Map<String, dynamic> json) {
    final aliasesRaw = json['aliases'];
    final aliases = aliasesRaw is List
        ? aliasesRaw.map((e) => e.toString().trim()).where((e) => e.isNotEmpty).toList()
        : const <String>[];
    final nameEn = (json['nameEn'] as String?)?.trim() ?? '';
    final rawOrder = json['sortOrder'];
    final parsedOrder = rawOrder is num
        ? rawOrder.toInt()
        : int.tryParse('$rawOrder') ?? unsetSortOrder;
    return BhaktiDeity(
      key: (json['key'] as String?)?.trim() ?? '',
      aliases: aliases,
      nameEn: nameEn,
      nameHi: (json['nameHi'] as String?)?.trim() ?? nameEn,
      nameMr: (json['nameMr'] as String?)?.trim() ?? nameEn,
      imageAsset: (json['imageAsset'] as String?)?.trim().isNotEmpty == true
          ? (json['imageAsset'] as String).trim()
          : 'assets/bhakti/durga.webp',
      imageUrl: (json['imageUrl'] as String?)?.trim() ?? '',
      sortOrder: parsedOrder,
    );
  }

  Map<String, dynamic> toJson() => {
        'key': key,
        'aliases': aliases,
        'nameEn': nameEn,
        'nameHi': nameHi,
        'nameMr': nameMr,
        'imageAsset': imageAsset,
        'imageUrl': imageUrl,
        'sortOrder': sortOrder,
      };

  BhaktiDeity copyWithSortOrder(int order) => BhaktiDeity(
        key: key,
        aliases: aliases,
        nameEn: nameEn,
        nameHi: nameHi,
        nameMr: nameMr,
        imageAsset: imageAsset,
        imageUrl: imageUrl,
        sortOrder: order,
      );

  bool get isValidRemote => key.isNotEmpty && nameEn.isNotEmpty;

  bool matches(String deity) => deity == key || aliases.contains(deity);

  String localizedName(String localeCode) {
    switch (localeCode) {
      case 'hi':
        return nameHi;
      case 'mr':
        return nameMr;
      default:
        return nameEn;
    }
  }

  /// Screen title, e.g. "श्री गणेश दर्शन" / "Shri Ganesh Darshan".
  String darshanTitle(String localeCode) {
    final name = localizedName(localeCode);
    return localeCode == 'en' ? '$name Darshan' : '$name दर्शन';
  }
}

/// Content categories rendered as round buttons under the shrine.
enum BhaktiCategory {
  aarti(['aarti', 'kakadaarti', 'karpuraarti']),
  chalisa(['chalisa']),
  mantra(['mantra', 'shloka', 'namavani']),
  bhajan(['bhajan', 'kirtan', 'dhun', 'bhaktigeet']),
  stotra(['stotra', 'stuti', 'prarthana', 'pushpanjali']),
  song(['song', 'songs', 'geet', 'bhaktigeet']);

  /// Lower-cased [AartiItem.tags] values that place an item in this category.
  final List<String> tags;

  const BhaktiCategory(this.tags);

  bool matchesTags(List<String> itemTags) =>
      itemTags.any((t) => tags.contains(t.toLowerCase()));

  String label(String localeCode) {
    switch (this) {
      case BhaktiCategory.aarti:
        return localeCode == 'en' ? 'Aarti' : 'आरती';
      case BhaktiCategory.chalisa:
        return localeCode == 'en' ? 'Chalisa' : 'चालीसा';
      case BhaktiCategory.mantra:
        return localeCode == 'en' ? 'Mantra' : 'मंत्र';
      case BhaktiCategory.bhajan:
        if (localeCode == 'en') return 'Bhajan';
        return localeCode == 'mr' ? 'भजने' : 'भजन';
      case BhaktiCategory.stotra:
        return localeCode == 'en' ? 'Stotra' : 'स्तोत्र';
      case BhaktiCategory.song:
        if (localeCode == 'en') return 'Songs';
        return localeCode == 'mr' ? 'गाणी' : 'गाने';
    }
  }
}
