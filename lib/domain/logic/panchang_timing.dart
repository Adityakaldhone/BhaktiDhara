import '../entities/panchang.dart';

/// A time window parsed from Panchang text such as `'१०:३० AM - १२:०० PM'`.
/// Minutes are counted from midnight; [end] may exceed 1440 when the window
/// crosses midnight.
class PanchangWindow {
  final int start;
  final int end;

  const PanchangWindow(this.start, this.end);

  static final _time = RegExp(r'(\d{1,2})[:.](\d{2})\s*([AaPp])?\.?\s*[Mm]?\.?');

  /// Returns null unless [raw] contains exactly a start and an end time.
  static PanchangWindow? parse(String raw) {
    final matches = _time.allMatches(toAsciiDigits(raw)).toList();
    if (matches.length != 2) return null;
    final start = _minutes(matches[0]);
    var end = _minutes(matches[1]);
    if (start == null || end == null) return null;
    if (end <= start) end += 24 * 60;
    return PanchangWindow(start, end);
  }

  static int? _minutes(RegExpMatch m) {
    var hour = int.parse(m.group(1)!);
    final minute = int.parse(m.group(2)!);
    final meridiem = m.group(3)?.toLowerCase();
    if (minute > 59 || hour > 23) return null;
    if (meridiem != null) {
      if (hour < 1 || hour > 12) return null;
      if (meridiem == 'p' && hour != 12) hour += 12;
      if (meridiem == 'a' && hour == 12) hour = 0;
    }
    return hour * 60 + minute;
  }

  static String toAsciiDigits(String input) {
    final buffer = StringBuffer();
    for (final unit in input.runes) {
      if (unit >= 0x0966 && unit <= 0x096F) {
        buffer.writeCharCode(0x30 + unit - 0x0966);
      } else {
        buffer.writeCharCode(unit);
      }
    }
    return buffer.toString();
  }

  bool contains(int minute) => minute >= start && minute < end;

  bool isOverAt(int minute) => minute >= end;
}

enum PanchangSlotKind {
  brahma,
  abhijit,
  amrit,
  vijaya,
  godhuli,
  rahu,
  yamaganda,
  gulika,
  durmuhurat,
  bhadra,
}

class PanchangSlot {
  final PanchangSlotKind kind;
  final String raw;
  final PanchangWindow? window;

  PanchangSlot(this.kind, this.raw) : window = PanchangWindow.parse(raw);

  bool get isGood => kind.index <= PanchangSlotKind.godhuli.index;

  bool get isBest =>
      kind == PanchangSlotKind.abhijit || kind == PanchangSlotKind.rahu;

  /// Start and end text exactly as provided, e.g. `('१०:३० AM', '१२:०० PM')`.
  (String, String)? get rangeParts {
    final parts = raw.split(RegExp(r'\s+[-–—]\s+|\s*[–—]\s*|\s+to\s+'));
    if (parts.length != 2) return null;
    return (parts[0].trim(), parts[1].trim());
  }
}

/// All good and bad windows of the day, timed ones first in chronological
/// order, untimed ones (e.g. Bhadra "none") last.
List<PanchangSlot> panchangSlots(PanchangData p) {
  final slots = [
    PanchangSlot(PanchangSlotKind.brahma, p.brahmaMuhurat),
    PanchangSlot(PanchangSlotKind.abhijit, p.abhijitMuhurat),
    PanchangSlot(PanchangSlotKind.amrit, p.amritKaal),
    PanchangSlot(PanchangSlotKind.vijaya, p.vijayaMuhurat),
    PanchangSlot(PanchangSlotKind.godhuli, p.godhuliMuhurat),
    PanchangSlot(PanchangSlotKind.rahu, p.rahuKaal),
    PanchangSlot(PanchangSlotKind.yamaganda, p.yamaganda),
    PanchangSlot(PanchangSlotKind.gulika, p.gulikaKaal),
    PanchangSlot(PanchangSlotKind.durmuhurat, p.durmuhurat),
    PanchangSlot(PanchangSlotKind.bhadra, p.bhadra),
  ].where((s) => s.raw.trim().isNotEmpty).toList();

  final timed = slots.where((s) => s.window != null).toList()
    ..sort((a, b) => a.window!.start.compareTo(b.window!.start));
  final untimed = slots.where((s) => s.window == null);
  return [...timed, ...untimed];
}

enum PanchangNowKind { avoid, good, nextGood }

class PanchangNow {
  final PanchangNowKind kind;
  final PanchangSlot slot;

  const PanchangNow(this.kind, this.slot);
}

/// What matters at [minute]: an ongoing window to avoid wins over an ongoing
/// good one; otherwise the next upcoming good window. Null when nothing
/// relevant remains today.
PanchangNow? panchangNow(List<PanchangSlot> slots, int minute) {
  final timed = slots.where((s) => s.window != null);
  for (final s in timed) {
    if (!s.isGood && s.window!.contains(minute)) {
      return PanchangNow(PanchangNowKind.avoid, s);
    }
  }
  for (final s in timed) {
    if (s.isGood && s.window!.contains(minute)) {
      return PanchangNow(PanchangNowKind.good, s);
    }
  }
  for (final s in timed) {
    if (s.isGood && s.window!.start > minute) {
      return PanchangNow(PanchangNowKind.nextGood, s);
    }
  }
  return null;
}
