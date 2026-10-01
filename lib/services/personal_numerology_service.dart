import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/entities/horoscope.dart';

const String kSavedInitialKey = 'bhaktidhara_user_name_initial';

/// Model representing a personalized Vedic calculation by name initial.
class PersonalVedicReading {
  final String initial;
  final int luckyScore;
  final String statusLabel;
  final String headline;
  final String dosGuidance;
  final String dontsGuidance;
  final String nakshatraPillar;

  const PersonalVedicReading({
    required this.initial,
    required this.luckyScore,
    required this.statusLabel,
    required this.headline,
    required this.dosGuidance,
    required this.dontsGuidance,
    required this.nakshatraPillar,
  });
}

/// Service that computes authentic Vedic personalized scores and guidance.
class PersonalVedicService {
  static const List<String> popularInitialsMr = [
    'अ', 'आ', 'स', 'र', 'म', 'द', 'प', 'क', 'व', 'न', 'श', 'इतर'
  ];

  static const List<String> popularInitialsEn = [
    'A', 'S', 'R', 'M', 'P', 'K', 'V', 'D', 'N', 'B', 'T', 'More'
  ];

  static PersonalVedicReading calculateReading({
    required String initial,
    required Rashi rashi,
    required String langCode,
  }) {
    final effectiveInitial = initial.trim().isNotEmpty
        ? initial.trim()
        : (langCode == 'en' ? 'A' : 'अ');

    final now = DateTime.now();
    final charVal = effectiveInitial.codeUnitAt(0);
    // Deterministic daily vibration based on date, initial, and zodiac sign
    final seed = (now.year * 1000 + now.month * 50 + now.day * 7 + charVal + rashi.id.hashCode).abs();
    final score = 65 + (seed % 30); // 65% to 94%

    String statusLabel;
    if (score >= 85) {
      statusLabel = langCode == 'mr'
          ? 'अतिशुभ राजयोग (उत्कृष्ट)'
          : (langCode == 'hi' ? 'अतिशुभ राजयोग (उत्कृष्ट)' : 'Highly Auspicious');
    } else if (score >= 75) {
      statusLabel = langCode == 'mr'
          ? 'शुभ अनुकूल योग (मध्यम)'
          : (langCode == 'hi' ? 'शुभ अनुकूल योग' : 'Favorable Alignment');
    } else {
      statusLabel = langCode == 'mr'
          ? 'संयम व दक्षता योग'
          : (langCode == 'hi' ? 'संयम व सतर्कता योग' : 'Prudent Balance');
    }

    final headline = langCode == 'mr'
        ? '\'$effectiveInitial\' अक्षरावरून नाव असणाऱ्यांसाठी आजचा विशेष भाग्य संदेश'
        : (langCode == 'hi'
            ? '\'$effectiveInitial\' अक्षर वाले जातकों के लिए आज का व्यक्तिगत भाग्य संदेश'
            : 'Personal Astrological Resonance for Name Initial \'$effectiveInitial\'');

    final dos = langCode == 'mr'
        ? 'आज काय करावे: महत्त्वपूर्ण कामात पुढाकार घ्या. पूर्व किंवा उत्तर दिशेकडे तोंड करून काम सुरू केल्यास उत्तम यश व आर्थिक प्राप्तीचे योग आहेत.'
        : (langCode == 'hi'
            ? 'आज क्या करें: महत्वपूर्ण कार्यों में स्वयं पहल करें। उत्तर या पूर्व दिशा की ओर मुख करके कार्य आरंभ करने से उत्तम सफलता मिलेगी।'
            : 'What to Do: Take confident initiative in key projects. Facing North or East during work enhances concentration and positive outcomes.');

    final donts = langCode == 'mr'
        ? 'काय टाळावे: कोणाच्याही दबावाखाली घाईने आर्थिक करार करू नका. जुन्या मतभेदांना आज पुन्हा उकरून काढणे टाळावे.'
        : (langCode == 'hi'
            ? 'क्या न करें: किसी के दबाव में आकर जल्दबाजी में धन का फैसला न लें। पुराने मतभेदों को आज बढ़ावा न दें।'
            : 'What to Avoid: Refrain from hasty financial commitments under pressure. Avoid rekindling old arguments or debates.');

    final pillar = langCode == 'mr'
        ? 'ध्वनी कंपन: \'${rashi.rulingPlanet.split('(')[0].trim()}\' ग्रहाचा शुभ प्रभाव'
        : (langCode == 'hi'
            ? 'ध्वनि कंपन: \'${rashi.rulingPlanet.split('(')[0].trim()}\' ग्रह का सकारात्मक प्रभाव'
            : 'Vibration Resonance: Harmonic synergy with ${rashi.rulingPlanet}');

    return PersonalVedicReading(
      initial: effectiveInitial,
      luckyScore: score,
      statusLabel: statusLabel,
      headline: headline,
      dosGuidance: dos,
      dontsGuidance: donts,
      nakshatraPillar: pillar,
    );
  }
}

/// Riverpod StateNotifier for remembering the user's chosen initial.
class UserInitialNotifier extends StateNotifier<String> {
  UserInitialNotifier() : super('अ') {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(kSavedInitialKey);
    if (saved != null && saved.isNotEmpty) {
      state = saved;
    }
  }

  Future<void> setInitial(String initial) async {
    state = initial;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(kSavedInitialKey, initial);
  }
}

final userInitialProvider = StateNotifierProvider<UserInitialNotifier, String>((ref) {
  return UserInitialNotifier();
});
