import 'package:characters/characters.dart';

import '../entities/greeting_card.dart';
import 'panchang_timing.dart';

/// Pure rules behind the daily card. Everything here is deterministic for a
/// given date so the card never changes during the day and needs no server
/// or manual updates.
class GreetingCardLogic {
  static const maxNameLength = 24;
  static const maxEmojis = 8;

  /// Cards roll over at 4 AM, the same boundary as the jaap streak, so a
  /// card shared after midnight still belongs to the previous night.
  static DateTime cardDay(DateTime now) {
    final shifted = now.subtract(const Duration(hours: 4));
    return DateTime(shifted.year, shifted.month, shifted.day);
  }

  static String weekdayDeity(DateTime day, String lang) {
    switch (day.weekday) {
      case DateTime.monday:
        return 'mahadev';
      case DateTime.tuesday:
        return 'ganesh';
      case DateTime.wednesday:
        return 'vitthal';
      case DateTime.thursday:
        return lang == 'mr' ? 'datta' : 'saibaba';
      case DateTime.friday:
        return 'lakshmi';
      case DateTime.saturday:
        return 'hanuman';
      default:
        return lang == 'mr' ? 'khandoba' : 'vishnu';
    }
  }

  /// "रोज नवीन": a different card style each day, same for everyone that day.
  static CardStyle autoStyle(DateTime day) {
    final days = DateTime.utc(day.year, day.month, day.day).difference(DateTime.utc(2024)).inDays;
    return CardStyle.values[days % CardStyle.values.length];
  }

  static CardTemplate templateForDeity(String deityId) {
    switch (deityId) {
      case 'mahadev':
      case 'durga':
      case 'bhairavnath':
        return CardTemplate.templeDusk;
      case 'ganesh':
      case 'hanuman':
      case 'khandoba':
      case 'santoshi_mata':
      case 'surya':
        return CardTemplate.marigold;
      case 'vitthal':
      case 'krishna':
        return CardTemplate.tulsiGreen;
      case 'vishnu':
      case 'venkatesh':
      case 'rama':
      case 'shani':
      case 'chandra':
      case 'narmada':
        return CardTemplate.royalBlue;
      default:
        return CardTemplate.sandalGold;
    }
  }

  static final _unsafeChars = RegExp(
    r'[\u0000-\u001F\u007F\u200B\u200E\u200F\u202A-\u202E\u2066-\u2069\uFEFF]',
  );
  static final _linkLike = RegExp(
    r'https?:|www\.|://|@|\.(com|in|net|org|me|ly|io|co)\b',
    caseSensitive: false,
  );

  /// Cleans the sender name printed on shared cards. Returns null when the
  /// input is empty or looks like a link, handle or phone number, so the
  /// app's branded card cannot be used to spread spam contacts.
  static String? sanitizeName(String raw) {
    var name = raw.replaceAll(_unsafeChars, ' ');
    name = name.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (name.isEmpty || _linkLike.hasMatch(name)) return null;
    final digits = RegExp(r'\d')
        .allMatches(PanchangWindow.toAsciiDigits(name))
        .length;
    if (digits >= 5) return null;
    if (name.characters.length > maxNameLength) {
      name = name.characters.take(maxNameLength).toString().trim();
    }
    return name;
  }

  static bool _isPictograph(int c) =>
      (c >= 0x1F000 && c <= 0x1FAFF) ||
      (c >= 0x2600 && c <= 0x27BF) ||
      (c >= 0x2300 && c <= 0x23FF) ||
      (c >= 0x2B00 && c <= 0x2BFF) ||
      (c >= 0x2190 && c <= 0x21FF) ||
      (c >= 0x25A0 && c <= 0x25FF) ||
      (c >= 0x2900 && c <= 0x297F) ||
      c == 0x3030 ||
      c == 0x303D ||
      c == 0x3297 ||
      c == 0x3299 ||
      c == 0x00A9 ||
      c == 0x00AE ||
      c == 0x2122;

  /// Joiners, variation selectors and flag tags that glue emoji sequences.
  static bool _isEmojiGlue(int c) =>
      c == 0x200D || c == 0xFE0F || c == 0xFE0E || c == 0x20E3 || (c >= 0xE0020 && c <= 0xE007F);

  /// Keeps only whole emoji (any type: faces, flags, skin tones, family
  /// sequences), up to [maxEmojis]. Letters, digits and keycaps are dropped so
  /// the row can't carry text, numbers or links. Null when nothing is left.
  static String? sanitizeEmojis(String raw) {
    final kept = raw.characters.where((g) {
      final runes = g.runes;
      return runes.any(_isPictograph) && runes.every((c) => _isPictograph(c) || _isEmojiGlue(c));
    }).take(maxEmojis);
    final out = kept.join();
    return out.isEmpty ? null : out;
  }
}
