import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/birth_profile.dart';
import '../../services/kundali/kundali_service.dart';

class KundaliProfilesNotifier extends StateNotifier<List<BirthProfile>?> {
  KundaliProfilesNotifier() : super(null) {
    _init();
  }

  Future<void> _init() async {
    state = await KundaliService.loadProfiles();
  }

  /// Inserts [profile] at the top, replacing any profile with the same id.
  Future<void> upsert(BirthProfile profile) async {
    final next = [profile, ...?state?.where((p) => p.id != profile.id)];
    state = next;
    await KundaliService.saveProfiles(next);
  }

  Future<void> remove(String id) async {
    final next = [...?state?.where((p) => p.id != id)];
    state = next;
    await KundaliService.saveProfiles(next);
  }
}

/// Saved birth profiles, newest first; `null` while loading.
final kundaliProfilesProvider =
    StateNotifierProvider<KundaliProfilesNotifier, List<BirthProfile>?>(
  (ref) => KundaliProfilesNotifier(),
);
