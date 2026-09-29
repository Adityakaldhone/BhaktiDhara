import 'package:intl/intl.dart';

/// Marathi / Hindi / English copy for the Naam Jaap feature.
///
/// Tone rules: gentle and devotional, never guilt-inducing.
class JaapStrings {
  final String lang;

  const JaapStrings(this.lang);

  String _t(String mr, String hi, String en) => switch (lang) {
        'hi' => hi,
        'en' => en,
        _ => mr,
      };

  // ── General ───────────────────────────────────────────────────────────────
  String get title => _t('नामजप', 'नाम जप', 'Naam Jaap');
  String get mala => _t('माळ', 'माला', 'Mala');
  String get jaap => _t('जप', 'जप', 'jaap');
  String get start => _t('आरंभ करा 🙏', 'आरंभ करें 🙏', 'Begin 🙏');
  String get continueJaap => _t('जप सुरू ठेवा 🙏', 'जप जारी रखें 🙏', 'Continue Jaap 🙏');
  String get startJaap => _t('आजचा जप सुरू करा 🙏', 'आज का जप शुरू करें 🙏', "Start today's jaap 🙏");
  String get done => _t('पूर्ण', 'पूर्ण', 'Done');
  String get back => _t('मागे', 'वापस', 'Back');
  String get tapAnywhere => _t('कुठेही टॅप करा', 'कहीं भी टैप करें', 'Tap anywhere');
  String get tapToBegin => _t(
        'जप सुरू करण्यासाठी कुठेही टॅप करा',
        'जप शुरू करने के लिए कहीं भी टैप करें',
        'Tap anywhere to begin',
      );
  String get undo => _t('एक कमी', 'एक कम', 'Undo');
  String get settings => _t('सेटिंग्ज', 'सेटिंग्स', 'Settings');
  String get changeMantra => _t('मंत्र बदला', 'मंत्र बदलें', 'Change mantra');

  String ofBeads(int total) => _t('/ $total मणी', '/ $total मनके', 'of $total');
  String beadSemantics(int bead, int total, int mala) => _t(
        'मणी $bead पैकी $total, माळ $mala',
        'मनका $bead / $total, माला $mala',
        'Bead $bead of $total, Mala $mala',
      );

  // ── Streak ────────────────────────────────────────────────────────────────
  String streakDays(int n) => _t('सलग $n दिवस', 'लगातार $n दिन', '$n day streak');
  String get firstDay => _t('आज पहिला दिवस', 'आज पहला दिन', 'Today is day 1');
  String dayN(int n) => _t('$n वा दिवस', 'दिन $n', 'Day $n');
  String get streak => _t('सलग दिवस', 'लगातार दिन', 'Streak');
  String get bestStreak => _t('सर्वोत्तम', 'सर्वश्रेष्ठ', 'Best');
  String get lifetime => _t('एकूण जप', 'कुल जप', 'Lifetime');

  // ── Today / goal ──────────────────────────────────────────────────────────
  String get today => _t('आज', 'आज', 'Today');
  String malaProgress(int done, int goal) =>
      _t('माळ $done / $goal', 'माला $done / $goal', 'Mala $done / $goal');
  String todayProgress(int done, int goal) => _t(
        'आज: $done / $goal माळ',
        'आज: $done / $goal माला',
        'Today: $done of $goal mala',
      );
  String minutes(int seconds) {
    final m = (seconds / 60).round();
    return _t('$m मिनिटे', '$m मिनट', '$m min');
  }

  String get dailyGoal => _t('रोजचे लक्ष्य', 'दैनिक लक्ष्य', 'Daily goal');
  String get dailyGoalQuestion => _t(
        'रोज किती माळ जप करायचा?',
        'रोज़ कितनी माला जप करना है?',
        'How many malas each day?',
      );
  String goalMalas(int n) => _t('$n माळ', '$n माला', n == 1 ? '1 mala' : '$n malas');
  String goalJaaps(int n) {
    final count = grouped(n * 108);
    return _t('$count जप', '$count जप', '$count jaaps');
  }
  String get goalFromTomorrow => _t(
        'नवीन लक्ष्य उद्यापासून लागू होईल',
        'नया लक्ष्य कल से लागू होगा',
        'Your new goal starts tomorrow',
      );
  // ── Onboarding ────────────────────────────────────────────────────────────
  String get welcomeTitle => _t('नामजपात स्वागत 🙏', 'नाम जप में स्वागत 🙏', 'Welcome to Naam Jaap 🙏');
  String get welcomeSubtitle => _t(
        'आपल्या इष्टदेवतेचा मंत्र निवडा',
        'अपने इष्टदेव का मंत्र चुनें',
        'Choose the mantra you wish to chant',
      );
  String get next => _t('पुढे', 'आगे', 'Next');
  String get goalHint => _t(
        'सुरुवातीला १ माळ पुरेशी आहे. नंतर कधीही बदलू शकता.',
        'शुरुआत में 1 माला काफी है। बाद में कभी भी बदल सकते हैं।',
        '1 mala is a good start. You can change it any time.',
      );
  String get cardTagline => _t(
        '१०८ मण्यांची डिजिटल जपमाळ',
        '108 मनकों की डिजिटल जपमाला',
        'Your 108-bead digital mala',
      );
  String get goalDoneToday => _t(
        'आजचा संकल्प पूर्ण 🙏',
        'आज का संकल्प पूर्ण 🙏',
        "Today's sankalp complete 🙏",
      );

  // ── Encouragement ─────────────────────────────────────────────────────────
  String get welcomeBack => _t(
        'पुन्हा स्वागत 🙏 प्रत्येक दिवस नवी सुरुवात आहे.',
        'फिर से स्वागत है 🙏 हर दिन एक नई शुरुआत है।',
        'Welcome back 🙏 Every day is a new beginning.',
      );
  String get protectorUsed => _t(
        'आपला सलग जप सुरक्षित आहे — क्षमा दिन वापरला 🙏',
        'आपकी लगातार साधना सुरक्षित है — क्षमा दिन उपयोग हुआ 🙏',
        'Your streak is safe — a Kshama Din was used 🙏',
      );
  String get malaComplete => _t('माळ पूर्ण 🙏', 'माला पूर्ण 🙏', 'Mala complete 🙏');
  String get sankalpPurna => _t('संकल्प पूर्ण', 'संकल्प पूर्ण', 'Sankalp Purna');
  String get blessing => _t(
        'आपली भक्ती स्वीकार होवो 🙏',
        'आपकी भक्ति स्वीकार हो 🙏',
        'May your devotion be accepted 🙏',
      );
  String get keepChanting => _t('जप सुरू ठेवा', 'जप जारी रखें', 'Keep chanting');
  String milestoneReached(String n) => _t(
        '$n जप पूर्ण! 🌸',
        '$n जप पूर्ण! 🌸',
        '$n jaaps complete! 🌸',
      );

  // ── Chant along with audio ────────────────────────────────────────────────
  String get chantWithAudio => _t(
        'ऑडिओसोबत जप करा 🎧',
        'ऑडियो के साथ जप करें 🎧',
        'Chant along with audio 🎧',
      );
  String get chantAlongHint => _t(
        'ऑडिओसोबत मंत्र म्हणा — मणी आपोआप पुढे सरकतील',
        'ऑडियो के साथ मंत्र बोलें — मनके अपने-आप आगे बढ़ेंगे',
        'Chant along — the beads move on their own',
      );
  String get pause => _t('थांबा', 'रोकें', 'Pause');
  String get resume => _t('पुन्हा सुरू', 'फिर शुरू करें', 'Resume');
  String get stop => _t('बंद करा', 'बंद करें', 'Stop');
  String get audioError => _t(
        'ऑडिओ सुरू होऊ शकला नाही',
        'ऑडियो शुरू नहीं हो सका',
        "Couldn't start the audio",
      );
  String tappedVsAudio(int tapped, int audio) => _t(
        'टॅप करून ${grouped(tapped)} · ऑडिओसोबत ${grouped(audio)}',
        'टैप से ${grouped(tapped)} · ऑडियो के साथ ${grouped(audio)}',
        'Tapped ${grouped(tapped)} · With audio ${grouped(audio)}',
      );

  // ── Settings ──────────────────────────────────────────────────────────────
  String get tickSound => _t('मणी आवाज', 'मनका ध्वनि', 'Bead sound');
  String get bellSound => _t('माळ पूर्ण झाल्यावर घंटा', 'माला पूर्ण होने पर घंटी', 'Bell after each mala');
  String get vibration => _t('कंपन (व्हायब्रेशन)', 'कंपन (वाइब्रेशन)', 'Vibration');
  String get keepScreenOn => _t('स्क्रीन चालू ठेवा', 'स्क्रीन चालू रखें', 'Keep screen on');

  // ── Stats ─────────────────────────────────────────────────────────────────
  String get mySadhana => _t('माझी साधना', 'मेरी साधना', 'My Sadhana');
  String get thisWeek => _t('हा आठवडा', 'यह सप्ताह', 'This week');
  String get milestones => _t('टप्पे', 'पड़ाव', 'Milestones');
  String get mantraTotals => _t('मंत्रानुसार जप', 'मंत्र अनुसार जप', 'Jaap by mantra');
  String get lockedTitle => _t(
        'संपूर्ण साधना इतिहास अनलॉक करा',
        'संपूर्ण साधना इतिहास अनलॉक करें',
        'Unlock your full sadhana history',
      );
  String get lockedSubtitle => _t(
        'मंत्रानुसार जप व मागील महिन्यांचा हिशोब पहा.',
        'मंत्र अनुसार जप व पिछले महीनों का हिसाब देखें।',
        'See jaap by mantra and previous months.',
      );
  String nextMilestone(String n) =>
      _t('पुढील टप्पा: $n', 'अगला पड़ाव: $n', 'Next milestone: $n');
  String get protectorAvailable => _t(
        'क्षमा दिन उपलब्ध 🛡️',
        'क्षमा दिन उपलब्ध 🛡️',
        'Kshama Din available 🛡️',
      );

  List<String> get weekdayInitials => switch (lang) {
        'hi' => const ['सो', 'मं', 'बु', 'गु', 'शु', 'श', 'र'],
        'en' => const ['M', 'T', 'W', 'T', 'F', 'S', 'S'],
        _ => const ['सो', 'मं', 'बु', 'गु', 'शु', 'श', 'र'],
      };

  String monthName(int month) {
    const mr = ['जानेवारी', 'फेब्रुवारी', 'मार्च', 'एप्रिल', 'मे', 'जून', 'जुलै', 'ऑगस्ट', 'सप्टेंबर', 'ऑक्टोबर', 'नोव्हेंबर', 'डिसेंबर'];
    const hi = ['जनवरी', 'फ़रवरी', 'मार्च', 'अप्रैल', 'मई', 'जून', 'जुलाई', 'अगस्त', 'सितंबर', 'अक्टूबर', 'नवंबर', 'दिसंबर'];
    const en = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
    final list = switch (lang) { 'hi' => hi, 'en' => en, _ => mr };
    return list[month - 1];
  }

  // ── Numbers ───────────────────────────────────────────────────────────────
  static final NumberFormat _indian = NumberFormat.decimalPattern('en_IN');

  /// 108000 → "1,08,000".
  static String grouped(int n) => _indian.format(n);

  /// Short form with Lakh / Crore words: 240000 → "2.4 लाख", 999 → "999".
  String compact(int n) {
    String trim(double v) {
      final s = v.toStringAsFixed(2);
      return s.replaceFirst(RegExp(r'\.?0+$'), '');
    }

    if (n >= 10000000) {
      return '${trim(n / 10000000)} ${_t('कोटी', 'करोड़', 'Crore')}';
    }
    if (n >= 100000) {
      return '${trim(n / 100000)} ${_t('लाख', 'लाख', 'Lakh')}';
    }
    return grouped(n);
  }
}
