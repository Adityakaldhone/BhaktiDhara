import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/logic/akhand_diya.dart';
import '../../../presentation/providers/akhand_diya_provider.dart';
import '../../../presentation/widgets/akhand_jyot_flame.dart';

/// One full kalash of ghee burns for this many seconds.
const int kDiyaDecaySeconds = 86400;

/// Live view of the 24-hour Akhand Diya for the Home banner and the
/// Garbhagriha. State lives in [akhandDiyaProvider] (persisted by
/// `AkhandDiyaService` under `diya_last_refill_ms`, `diya_streak_days` and
/// `diya_last_streak_date`); this adds a 30-second clock and ghee maths.
class AkhandDiyaController extends ChangeNotifier {
  AkhandDiyaController(this._ref) {
    _ref.listen<AkhandDiyaState?>(akhandDiyaProvider, (_, _) => notifyListeners());
    if (jyotAnimationsEnabled) {
      _timer = Timer.periodic(const Duration(seconds: 30), (_) => notifyListeners());
    }
  }

  final Ref _ref;
  Timer? _timer;

  AkhandDiyaState? get state => _ref.read(akhandDiyaProvider);

  bool get isLoaded => state != null;
  bool get everLit => state?.everLit ?? false;
  int get streakDays => state?.streakDays ?? 0;
  DateTime? get lastRefill => state?.lastRefilledAt;
  JyotLevel get level => state?.level(DateTime.now()) ?? JyotLevel.out;

  int get elapsedSeconds {
    final last = lastRefill;
    if (last == null) return kDiyaDecaySeconds;
    final s = DateTime.now().difference(last).inSeconds;
    return s < 0 ? 0 : s;
  }

  /// 1.0 straight after a refill, 0.0 once 24 hours have passed.
  double get gheeRatio {
    if (!everLit) return 0;
    return ((kDiyaDecaySeconds - elapsedSeconds) / kDiyaDecaySeconds).clamp(0.0, 1.0);
  }

  Duration get remaining => Duration(seconds: (kDiyaDecaySeconds - elapsedSeconds).clamp(0, kDiyaDecaySeconds));
  int get remainingHours => remaining.inHours;
  int get remainingMinutes => remaining.inMinutes % 60;

  /// Lights the diya with a 1-day streak if it has never been lit.
  Future<void> ensureLit() async {
    final current = state ?? await _ref.read(akhandDiyaProvider.notifier).ready;
    if (!current.everLit) await pourGheeAndRefill(source: 'mandir_first_visit');
  }

  /// Fills the diya to 100% whenever the devotee offers ghee; the streak
  /// moves on at most once per calendar day.
  Future<void> pourGheeAndRefill({String source = 'mandir_kalash'}) async {
    await _ref.read(akhandDiyaProvider.notifier).refill(source: source);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final akhandDiyaControllerProvider = ChangeNotifierProvider.autoDispose<AkhandDiyaController>(
  (ref) => AkhandDiyaController(ref),
);
