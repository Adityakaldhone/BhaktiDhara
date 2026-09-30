import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/greeting_card.dart';

/// The user's card choices. Stored only on this phone — the sender name and
/// photo are never sent to the backend or telemetry.
class GreetingCardPrefs {
  final String? deityId;
  final GreetingChoice greeting;

  /// Null means "रोज नवीन": the style rotates every day.
  final CardStyle? style;
  final String? senderName;

  /// Set while a photo is saved on this phone; changes whenever it's replaced.
  final int? photoStamp;
  final String? emojis;
  final bool askedForName;

  const GreetingCardPrefs({
    this.deityId,
    this.greeting = GreetingChoice.morning,
    this.style,
    this.senderName,
    this.photoStamp,
    this.emojis,
    this.askedForName = false,
  });

  GreetingCardPrefs copyWith({
    String? Function()? deityId,
    GreetingChoice? greeting,
    CardStyle? Function()? style,
    String? Function()? senderName,
    int? Function()? photoStamp,
    String? Function()? emojis,
    bool? askedForName,
  }) {
    return GreetingCardPrefs(
      deityId: deityId != null ? deityId() : this.deityId,
      greeting: greeting ?? this.greeting,
      style: style != null ? style() : this.style,
      senderName: senderName != null ? senderName() : this.senderName,
      photoStamp: photoStamp != null ? photoStamp() : this.photoStamp,
      emojis: emojis != null ? emojis() : this.emojis,
      askedForName: askedForName ?? this.askedForName,
    );
  }

  Map<String, dynamic> toJson() => {
        if (deityId != null) 'deityId': deityId,
        'greeting': greeting.name,
        if (style != null) 'style': style!.name,
        if (senderName != null) 'senderName': senderName,
        if (photoStamp != null) 'photoStamp': photoStamp,
        if (emojis != null) 'emojis': emojis,
        'askedForName': askedForName,
      };

  factory GreetingCardPrefs.fromJson(Map<String, dynamic> json) {
    return GreetingCardPrefs(
      deityId: json['deityId'] as String?,
      greeting: GreetingChoice.values.firstWhere(
        (g) => g.name == json['greeting'],
        orElse: () => GreetingChoice.morning,
      ),
      style: CardStyle.values.where((v) => v.name == json['style']).firstOrNull,
      senderName: json['senderName'] as String?,
      photoStamp: (json['photoStamp'] as num?)?.toInt(),
      emojis: json['emojis'] as String?,
      askedForName: json['askedForName'] == true,
    );
  }
}

class GreetingCardPrefsRepository {
  static const _key = 'greeting_card_prefs_v1';

  Future<GreetingCardPrefs> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null) return const GreetingCardPrefs();
      return GreetingCardPrefs.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return const GreetingCardPrefs();
    }
  }

  Future<void> save(GreetingCardPrefs value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, jsonEncode(value.toJson()));
    } catch (_) {}
  }
}
