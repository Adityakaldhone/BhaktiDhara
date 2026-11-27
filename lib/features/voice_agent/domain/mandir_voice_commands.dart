import 'home_voice_commands.dart';

typedef MandirVoiceHandler =
    HomeVoiceReply? Function(
      String transcript,
      String language, {
      MandirCommand? prediction,
      String? pendingTopic,
    });

/// Screen-scoped voice commands for `RealGarbhagrihaScreen` (Mandir).
sealed class MandirCommand {
  const MandirCommand();

  /// Topics that ask a follow-up and keep the mic open.
  static const clarificationTopics = {
    'clarify_jyot',
    'clarify_aarti',
    'clarify_food',
    'clarify_deity',
    'clarify_offering',
    'clarify',
  };

  static MandirCommand? fromPrediction(dynamic data) {
    final type = data is Map ? data['type'] : data;
    if (type is! String) return null;
    return switch (type) {
      'offer_ghee' => const OfferGheeMandir(),
      'read_ghee' => const ReadGheeMandir(),
      'read_time' => const ReadTimeMandir(),
      'read_streak' => const ReadStreakMandir(),
      'explain_ghee' => const ExplainMandirTopic('explain_ghee'),
      'ring_bell' => const RingBellMandir(),
      'explain_bell' => const ExplainMandirTopic('explain_bell'),
      'blow_conch' => const BlowConchMandir(),
      'explain_conch' => const ExplainMandirTopic('explain_conch'),
      'offer_flowers' => const OfferFlowersMandir(),
      'explain_flowers' => const ExplainMandirTopic('explain_flowers'),
      'offer_food' => const OfferFoodMandir(),
      'read_food' => const ReadFoodMandir(),
      'explain_food' => const ExplainMandirTopic('explain_food'),
      'start_aarti' => const StartAartiMandir(),
      'stop_aarti' => const StopAartiMandir(),
      'read_aarti' => const ReadAartiMandir(),
      'explain_aarti' => const ExplainMandirTopic('explain_aarti'),
      'explain_player' => const ExplainMandirTopic('explain_player'),
      'change_deity' => const ChangeDeityMandir(),
      'read_deity' => const ReadDeityMandir(),
      'explain_deity' => const ExplainMandirTopic('explain_deity'),
      'overview' => const ExplainMandirTopic('overview'),
      'clarify_jyot' => const ExplainMandirTopic('clarify_jyot'),
      'clarify_aarti' => const ExplainMandirTopic('clarify_aarti'),
      'clarify_food' => const ExplainMandirTopic('clarify_food'),
      'clarify_deity' => const ExplainMandirTopic('clarify_deity'),
      'clarify_offering' => const ExplainMandirTopic('clarify_offering'),
      'clarify' => const ExplainMandirTopic('clarify'),
      'cancel' => const CancelMandir(),
      'unavailable' => const ExplainMandirTopic('unavailable'),
      'other' => const OtherMandir(),
      _ => null,
    };
  }

  static final _cancelRe = RegExp(
    r"(?:^|\s)(?:don't|don’t|do not|never|forget|leave .+ quiet)\b|"
    r"(?:मत |नको|नका|रद्द|राहू दे|रहने दो|रहने दे)|"
    r'\b(?:mat|nako|rahu de|rehne do)\b',
    caseSensitive: false,
  );

  static final _questionRe = RegExp(
    r'\b(?:how|where|which|what|explain|guide|help)\b|'
    r'कैसे|कसा|कसे|कशी|कहाँ|कुठे|किधर|काय|क्या|समझाओ|समजावून',
    caseSensitive: false,
  );

  static final _unavailableRe = RegExp(
    r'\b(?:tilak|kumkum|ticket|book|prasad delivery|aarti pass|vip darshan)\b|'
    r'तिलक|कुंकू|टिकट|बुक',
    caseSensitive: false,
  );

  static final _jyotNouns = RegExp(
    r'ghee|tup|diya|lamp|jyot|jyoti|kalash|घी|तूप|दिवा|दीया|दीपक|ज्योत|कलश',
    caseSensitive: false,
  );

  static final _offerCue = RegExp(
    r'offer|refill|top up|pour|fill|chadha|taka|घाल|भर|अर्पण|डाल|चढ़ा',
    caseSensitive: false,
  );

  static final _readLevelCue = RegExp(
    r'how much|level|percentage|still have|left|remaining ghee|shillak|'
    r'कितना|किती|status|शिल्लक|बचा|उरलं|बाकी|percent',
    caseSensitive: false,
  );

  static final _readTimeCue = RegExp(
    r'how long|run out|remaining|time left|कितनी देर|किती वेळ|किती तास|hours|timer',
    caseSensitive: false,
  );

  static final _streakCue = RegExp(
    r'streak|days|क्रम|सलग|दिवस|दिन|badge|आकडा|day count',
    caseSensitive: false,
  );

  static bool mightReferToMandir(String text) => RegExp(
    r'ghee|tup|diya|lamp|jyot|kalash|bell|ghant|conch|shankh|flower|petal|garland|'
    r'pushpanjali|phool|naivedya|bhog|food|thali|aarti|taat|deity|devta|dev|murti|'
    r'darshan|mandir|shrine|ritual|seva|offer|offering|streak|tilak|kumkum|ticket|book|'
    r'घी|तूप|दिवा|दीया|दीपक|ज्योत|कलश|घंटी|घंटा|शंख|फूल|फुले|पुष्पांज|हार|'
    r'नैवेद्य|भोग|थाली|ताट|आरती|देवता|दैवत|देव|मंदिर|सेवा|अर्पण|तिलक|कुंकू|टिकट',
    caseSensitive: false,
  ).hasMatch(text);

  /// Pending Mandir clarification topic from the previous turn (e.g. clarify_jyot).
  static MandirCommand? parse(String transcript, {String? pendingTopic}) {
    final fold = transcript.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
    if (fold.isEmpty) return null;

    if (_cancelRe.hasMatch(fold)) {
      if (_containsAny(fold, const ['thali', 'aarti', 'ताट', 'थाली', 'आरती']) &&
          _containsAny(fold, const ['stop', 'close', 'put away', 'band', 'बंद', 'हटा'])) {
        return const StopAartiMandir();
      }
      return const CancelMandir();
    }

    if (_unavailableRe.hasMatch(fold)) {
      return const ExplainMandirTopic('unavailable');
    }

    // Multi-turn: prefer a short follow-up answer; otherwise fall through so a
    // new full command (e.g. घंटी) is not trapped in clarify.
    if (pendingTopic == 'clarify_jyot') {
      final follow = _resolveJyotFollowUp(fold);
      if (follow != null) return follow;
    }
    if (pendingTopic == 'clarify_aarti') {
      final follow = _resolveAartiFollowUp(fold);
      if (follow != null) return follow;
    }
    if (pendingTopic == 'clarify_food') {
      final follow = _resolveFoodFollowUp(fold);
      if (follow != null) return follow;
    }
    if (pendingTopic == 'clarify_deity') {
      final follow = _resolveDeityFollowUp(fold);
      if (follow != null) return follow;
    }
    if (pendingTopic == 'clarify_offering') {
      final follow = _resolveOfferingFollowUp(fold);
      if (follow != null) return follow;
    }

    final isQ = _questionRe.hasMatch(fold);

    // Bare streak / day-count (even without saying diya).
    if (_containsAny(fold, const ['streak', 'क्रम', 'सलग', 'day count', 'badge']) &&
        !_containsAny(fold, const ['jaap', 'jap', 'chant', 'जप', 'जाप', 'नामजप'])) {
      return const ReadStreakMandir();
    }

    if (_jyotNouns.hasMatch(fold)) {
      final specific = _resolveJyotFollowUp(fold);
      if (specific != null && specific is! ExplainMandirTopic) {
        return specific;
      }
      if (isQ) return const ExplainMandirTopic('explain_ghee');
      if (_offerCue.hasMatch(fold)) return const OfferGheeMandir();
      // Ambiguous bare “ज्योत” / “diya” / “ghee” → ask what to do.
      return const ExplainMandirTopic('clarify_jyot');
    }

    if (_containsAny(fold, const ['bell', 'ghanta', 'ghanti', 'घंटी', 'घंटा', 'घंटानाद'])) {
      return isQ ? const ExplainMandirTopic('explain_bell') : const RingBellMandir();
    }

    if (_containsAny(fold, const ['conch', 'shankh', 'शंख'])) {
      return isQ ? const ExplainMandirTopic('explain_conch') : const BlowConchMandir();
    }

    if (_containsAny(fold, const [
      'flower', 'petal', 'garland', 'pushpanjali', 'phool', 'फूल', 'फुले', 'पुष्पांज', 'हार',
    ])) {
      return isQ ? const ExplainMandirTopic('explain_flowers') : const OfferFlowersMandir();
    }

    if (_containsAny(fold, const ['naivedya', 'bhog', 'food', 'नैवेद्य', 'भोग'])) {
      final specific = _resolveFoodFollowUp(fold);
      if (specific != null) return specific;
      if (isQ) return const ExplainMandirTopic('explain_food');
      return const ExplainMandirTopic('clarify_food');
    }

    if (_containsAny(fold, const [
      'video', 'verse', 'lyrics', 'sing myself', 'manual singing', 'पद्य', 'कडवे',
      'व्हिडिओ', 'वीडियो', 'बोल',
    ])) {
      return const ExplainMandirTopic('explain_player');
    }

    if (_containsAny(fold, const ['thali', 'taat', 'aarti', 'arti', 'थाली', 'ताट', 'आरती'])) {
      final specific = _resolveAartiFollowUp(fold);
      if (specific != null) return specific;
      if (isQ) return const ExplainMandirTopic('explain_aarti');
      return const ExplainMandirTopic('clarify_aarti');
    }

    // Bare darshan/दर्शन opens Mandir from home; not a deity clarify here.
    if (_containsAny(fold, const [
      'deity', 'devta', 'dev', 'murti', 'देवता', 'दैवत', 'देव', 'मूर्ति',
    ])) {
      final specific = _resolveDeityFollowUp(fold);
      if (specific != null) return specific;
      if (isQ) return const ExplainMandirTopic('explain_deity');
      return const ExplainMandirTopic('clarify_deity');
    }

    if (_containsAny(fold, const [
      'what can i do', 'choices', 'rituals', 'seva', 'सेवा', 'करता येतं', 'कर सकते',
    ])) {
      return const ExplainMandirTopic('overview');
    }

    if (_containsAny(fold, const ['offering', 'अर्पण', 'चढ़ाना', 'चढ़ावा']) && !isQ) {
      return const ExplainMandirTopic('clarify_offering');
    }

    return null;
  }

  static MandirCommand? _resolveJyotFollowUp(String fold) {
    if (_streakCue.hasMatch(fold)) return const ReadStreakMandir();
    if (_readTimeCue.hasMatch(fold)) return const ReadTimeMandir();
    if (_readLevelCue.hasMatch(fold)) return const ReadGheeMandir();
    if (_questionRe.hasMatch(fold)) {
      return const ExplainMandirTopic('explain_ghee');
    }
    if (_offerCue.hasMatch(fold)) return const OfferGheeMandir();
    // Short answers after clarify: “भरो”, “शिल्लक”, “streak”
    if (_containsAny(fold, const [
      'refill', 'fill', 'pour', 'offer', 'full', 'भरो', 'भरा', 'डालो', 'घात', 'भर',
    ])) {
      return const OfferGheeMandir();
    }
    if (_containsAny(fold, const [
      'left', 'level', 'percent', 'kitna', 'kiti', 'शिल्लक', 'बचा', 'उरलं', 'बाकी',
    ])) {
      return const ReadGheeMandir();
    }
    return null;
  }

  static MandirCommand? _resolveOfferingFollowUp(String fold) {
    if (_containsAny(fold, const ['ghee', 'tup', 'diya', 'lamp', 'घी', 'तूप', 'दिवा', 'दीया'])) {
      return const OfferGheeMandir();
    }
    if (_containsAny(fold, const [
      'flower', 'phool', 'pushpanjali', 'फूल', 'फुले', 'पुष्पांज', 'हार',
    ])) {
      return const OfferFlowersMandir();
    }
    if (_containsAny(fold, const ['naivedya', 'bhog', 'food', 'नैवेद्य', 'भोग'])) {
      return const OfferFoodMandir();
    }
    return null;
  }

  static MandirCommand? _resolveAartiFollowUp(String fold) {
    if (_containsAny(fold, const ['stop', 'close', 'put away', 'band', 'बंद', 'हटा', 'थांब'])) {
      return const StopAartiMandir();
    }
    if (_containsAny(fold, const [
      'status', 'open?', 'started', 'चालू', 'खुली', 'suru', 'running',
    ])) {
      return const ReadAartiMandir();
    }
    if (_questionRe.hasMatch(fold) ||
        _containsAny(fold, const ['how', 'explain', 'कैसे', 'कसा', 'समझा'])) {
      return const ExplainMandirTopic('explain_aarti');
    }
    if (_containsAny(fold, const [
      'lyrics', 'verse', 'video', 'पद्य', 'कडवे', 'बोल', 'व्हिडिओ',
    ])) {
      return const ExplainMandirTopic('explain_player');
    }
    if (_containsAny(fold, const [
      'open', 'start', 'begin', 'खोल', 'उघड', 'शुरू', 'सुरू', 'चालू कर',
    ])) {
      return const StartAartiMandir();
    }
    return null;
  }

  static MandirCommand? _resolveFoodFollowUp(String fold) {
    if (_containsAny(fold, const [
      'already', 'is there', 'have i', 'status', 'आधीच', 'रखा', 'ठेवला', 'placed',
    ])) {
      return const ReadFoodMandir();
    }
    if (_questionRe.hasMatch(fold) ||
        _containsAny(fold, const ['how', 'explain', 'कैसे', 'कसा'])) {
      return const ExplainMandirTopic('explain_food');
    }
    if (_containsAny(fold, const [
      'place', 'offer', 'lagao', 'theva', 'लगा', 'ठेव', 'रख', 'अर्पण', 'chadha',
    ])) {
      return const OfferFoodMandir();
    }
    return null;
  }

  static MandirCommand? _resolveDeityFollowUp(String fold) {
    if (_containsAny(fold, const [
      'which', 'who', 'name', 'seeing', 'seated', 'कौन', 'कोण', 'विराजमान', 'current',
    ])) {
      return const ReadDeityMandir();
    }
    if (_questionRe.hasMatch(fold) ||
        _containsAny(fold, const ['how', 'explain', 'कैसे', 'कसा'])) {
      return const ExplainMandirTopic('explain_deity');
    }
    if (_containsAny(fold, const [
      'change', 'switch', 'replace', 'pick', 'choose', 'बदल', 'चुन', 'निवड', 'खोल', 'उघड',
    ])) {
      return const ChangeDeityMandir();
    }
    return null;
  }

  static bool _containsAny(String haystack, List<String> needles) {
    for (final needle in needles) {
      if (haystack.contains(needle)) return true;
    }
    return false;
  }

  String? get pendingTopic =>
      this is ExplainMandirTopic &&
          clarificationTopics.contains((this as ExplainMandirTopic).topic)
      ? (this as ExplainMandirTopic).topic
      : null;
}

class OfferGheeMandir extends MandirCommand {
  const OfferGheeMandir();
}

class ReadGheeMandir extends MandirCommand {
  const ReadGheeMandir();
}

class ReadTimeMandir extends MandirCommand {
  const ReadTimeMandir();
}

class ReadStreakMandir extends MandirCommand {
  const ReadStreakMandir();
}

class RingBellMandir extends MandirCommand {
  const RingBellMandir();
}

class BlowConchMandir extends MandirCommand {
  const BlowConchMandir();
}

class OfferFlowersMandir extends MandirCommand {
  const OfferFlowersMandir();
}

class OfferFoodMandir extends MandirCommand {
  const OfferFoodMandir();
}

class ReadFoodMandir extends MandirCommand {
  const ReadFoodMandir();
}

class StartAartiMandir extends MandirCommand {
  const StartAartiMandir();
}

class StopAartiMandir extends MandirCommand {
  const StopAartiMandir();
}

class ReadAartiMandir extends MandirCommand {
  const ReadAartiMandir();
}

class ChangeDeityMandir extends MandirCommand {
  const ChangeDeityMandir();
}

class ReadDeityMandir extends MandirCommand {
  const ReadDeityMandir();
}

class CancelMandir extends MandirCommand {
  const CancelMandir();
}

class OtherMandir extends MandirCommand {
  const OtherMandir();
}

class ExplainMandirTopic extends MandirCommand {
  const ExplainMandirTopic(this.topic);
  final String topic;
}
