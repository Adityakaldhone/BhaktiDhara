/// A greeting category served by `/api/v1/greetings/categories`
/// (Good Morning, Love, Motivation...). [name] is already in the app language.
class GreetingCategory {
  final String slug;
  final String name;
  final String emoji;
  final int count;
  final String? coverUrl;

  const GreetingCategory({
    required this.slug,
    required this.name,
    this.emoji = '',
    this.count = 0,
    this.coverUrl,
  });

  static GreetingCategory? fromJson(Object? json, {required String baseUrl}) {
    if (json is! Map) return null;
    final slug = json['slug'];
    final name = json['name'];
    if (slug is! String || slug.isEmpty || name is! String) return null;
    return GreetingCategory(
      slug: slug,
      name: name,
      emoji: json['emoji'] as String? ?? '',
      count: (json['count'] as num?)?.toInt() ?? 0,
      coverUrl: _absolute(json['coverUrl'], baseUrl),
    );
  }

  Map<String, dynamic> toJson() => {
        'slug': slug,
        'name': name,
        'emoji': emoji,
        'count': count,
        'coverUrl': coverUrl,
      };
}

/// One greeting image. [hdUrl] is null while [locked] (premium image, free user).
class GreetingImage {
  final int id;
  final String category;
  final String thumbUrl;
  final String? hdUrl;
  final int width;
  final int height;
  final bool premium;
  final bool locked;

  const GreetingImage({
    required this.id,
    required this.category,
    required this.thumbUrl,
    required this.hdUrl,
    required this.width,
    required this.height,
    this.premium = false,
    this.locked = false,
  });

  double get aspectRatio => (width > 0 && height > 0) ? width / height : 9 / 16;

  static GreetingImage? fromJson(Object? json, {required String baseUrl}) {
    if (json is! Map) return null;
    final id = json['id'];
    final thumb = _absolute(json['thumbUrl'], baseUrl);
    if (id is! num || thumb == null) return null;
    return GreetingImage(
      id: id.toInt(),
      category: json['category'] as String? ?? '',
      thumbUrl: thumb,
      hdUrl: _absolute(json['hdUrl'], baseUrl),
      width: (json['width'] as num?)?.toInt() ?? 0,
      height: (json['height'] as num?)?.toInt() ?? 0,
      premium: json['premium'] == true,
      locked: json['locked'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'category': category,
        'thumbUrl': thumbUrl,
        'hdUrl': hdUrl,
        'width': width,
        'height': height,
        'premium': premium,
        'locked': locked,
      };
}

class GreetingPage {
  final List<GreetingImage> images;
  final bool hasMore;
  final int nextOffset;

  const GreetingPage({required this.images, required this.hasMore, required this.nextOffset});
}

/// The server sends paths like `/api/v1/greetings/media/x.jpg`; cached JSON already
/// holds absolute URLs.
String? _absolute(Object? url, String baseUrl) {
  if (url is! String || url.isEmpty) return null;
  if (url.startsWith('http://') || url.startsWith('https://')) return url;
  final base = baseUrl.trim().replaceAll(RegExp(r'/+$'), '');
  return '$base${url.startsWith('/') ? '' : '/'}$url';
}
