/// Festival-season boosts for the Home Sacred Collection order.
///
/// Featured deities are prepended ahead of affinity-ranked tops so a
/// festival-day deity (e.g. Tulsi Mata on Tulsi Vivah) is easy to find.
List<String> festivalFeaturedDeityKeys(DateTime now) {
  final day = DateTime(now.year, now.month, now.day);

  // Tulsi Vivah / Dev Uthani Kartika window (2026 observance around 20–23 Nov).
  if (!day.isBefore(DateTime(2026, 11, 20)) &&
      !day.isAfter(DateTime(2026, 11, 23))) {
    return const ['Goddess Tulsi'];
  }

  return const [];
}
