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

  const BhaktiDeity({
    required this.key,
    this.aliases = const [],
    required this.nameEn,
    required this.nameHi,
    required this.nameMr,
    required this.imageAsset,
  });

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
  stotra(['stotra', 'stuti', 'prarthana', 'pushpanjali']);

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
    }
  }
}
