/// A person's birth details, as entered (local wall-clock time at the place).
class BirthProfile {
  const BirthProfile({
    required this.id,
    required this.name,
    required this.birthLocal,
    required this.place,
  });

  final String id;
  final String name;

  /// Wall-clock time at [place]. Only the date/time fields are meaningful.
  final DateTime birthLocal;
  final BirthPlace place;

  BirthProfile copyWith({String? name, DateTime? birthLocal, BirthPlace? place}) =>
      BirthProfile(
        id: id,
        name: name ?? this.name,
        birthLocal: birthLocal ?? this.birthLocal,
        place: place ?? this.place,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'birth': [
          birthLocal.year,
          birthLocal.month,
          birthLocal.day,
          birthLocal.hour,
          birthLocal.minute,
        ],
        'place': place.toJson(),
      };

  factory BirthProfile.fromJson(Map<String, dynamic> json) {
    final b = (json['birth'] as List).cast<int>();
    return BirthProfile(
      id: json['id'] as String,
      name: json['name'] as String,
      birthLocal: DateTime(b[0], b[1], b[2], b[3], b[4]),
      place: BirthPlace.fromJson(json['place'] as Map<String, dynamic>),
    );
  }
}

class BirthPlace {
  const BirthPlace({
    required this.name,
    required this.region,
    required this.latitude,
    required this.longitude,
    required this.timezone,
  });

  final String name;

  /// State / country line shown under the name.
  final String region;
  final double latitude;
  final double longitude;

  /// IANA zone, e.g. `Asia/Kolkata`.
  final String timezone;

  String get label => region.isEmpty ? name : '$name, $region';

  Map<String, dynamic> toJson() => {
        'name': name,
        'region': region,
        'lat': latitude,
        'lon': longitude,
        'tz': timezone,
      };

  factory BirthPlace.fromJson(Map<String, dynamic> json) => BirthPlace(
        name: json['name'] as String,
        region: json['region'] as String? ?? '',
        latitude: (json['lat'] as num).toDouble(),
        longitude: (json['lon'] as num).toDouble(),
        timezone: json['tz'] as String,
      );
}
