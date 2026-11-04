import '../../services/grahan/grahan_engine.dart';
import '../kundali/kundali_strings.dart';

/// Grahan screen copy in Marathi, Hindi and English.
class GrahanStrings {
  GrahanStrings(this.lang) : fmt = KundaliStrings(lang);

  final String lang;

  /// Shared number / date / time formatting.
  final KundaliStrings fmt;

  String _t(String mr, String hi, String en) =>
      lang == 'en' ? en : (lang == 'hi' ? hi : mr);

  String get title => _t('ग्रहण', 'ग्रहण', 'Grahan (Eclipses)');
  String get subtitle => _t(
        'सूर्य व चंद्र ग्रहणाच्या वेळा, सुतक आणि दृश्यता',
        'सूर्य व चंद्र ग्रहण का समय, सूतक और दृश्यता',
        'Solar & lunar eclipse timings, sutak and visibility',
      );
  String get location => _t('स्थान:', 'स्थान:', 'Location:');
  String get change => _t('बदला', 'बदलें', 'Change');
  String get loading => _t('ग्रहणांची गणना होत आहे...', 'ग्रहण की गणना हो रही है...', 'Calculating eclipses...');
  String get loadError => _t('ग्रहण माहिती तयार करता आली नाही.', 'ग्रहण जानकारी नहीं बन सकी।', 'Could not calculate eclipses.');
  String get upcoming => _t('आगामी ग्रहणे', 'आगामी ग्रहण', 'Upcoming eclipses');
  String get next => _t('पुढील', 'अगला', 'Next');
  String get ongoing => _t('सुरू आहे', 'जारी है', 'Ongoing');

  String kind(GrahanKind k) => k == GrahanKind.surya
      ? _t('सूर्यग्रहण', 'सूर्य ग्रहण', 'Solar eclipse')
      : _t('चंद्रग्रहण', 'चंद्र ग्रहण', 'Lunar eclipse');

  String type(GrahanType t) => switch (t) {
        GrahanType.total => _t('खग्रास', 'खग्रास', 'Total'),
        GrahanType.annular => _t('कंकणाकृती', 'वलयाकार', 'Annular'),
        GrahanType.hybrid => _t('संकरित', 'संकर', 'Hybrid'),
        GrahanType.partial => _t('खंडग्रास', 'खंडग्रास', 'Partial'),
        GrahanType.penumbral => _t('छायाकल्प (मांद्य)', 'उपच्छाया', 'Penumbral'),
      };

  String get partialHere => _t('येथे खंडग्रास', 'यहाँ खंडग्रास', 'Partial here');
  String get visible => _t('तुमच्या शहरातून दिसेल', 'आपके शहर से दिखेगा', 'Visible from your city');
  String get notVisible =>
      _t('तुमच्या शहरातून दिसणार नाही', 'आपके शहर से नहीं दिखेगा', 'Not visible from your city');
  String get notVisibleNote => _t(
        'येथे ग्रहण दिसत नसल्याने सुतक व ग्रहण नियम पाळण्याची आवश्यकता नाही.',
        'यहाँ ग्रहण दिखाई नहीं देगा, इसलिए सूतक व ग्रहण नियम लागू नहीं होते।',
        'Not visible here, so sutak and eclipse observances do not apply.',
      );
  String get penumbralNote => _t(
        'छायाकल्प ग्रहणात चंद्र केवळ किंचित धूसर होतो; याचे सुतक किंवा धार्मिक पालन केले जात नाही.',
        'उपच्छाया ग्रहण में चंद्रमा केवल हल्का धुंधला होता है; इसका सूतक या धार्मिक पालन नहीं होता।',
        'The Moon only dims slightly in a penumbral eclipse; no sutak or rituals are observed.',
      );

  String get sparsh => _t('स्पर्श (प्रारंभ)', 'स्पर्श (प्रारंभ)', 'Begins (Sparsh)');
  String get madhya => _t('मध्य', 'मध्य', 'Maximum (Madhya)');
  String get moksha => _t('मोक्ष (समाप्ती)', 'मोक्ष (समाप्ति)', 'Ends (Moksha)');
  String get totality => _t('खग्रास काळ', 'खग्रास काल', 'Totality');
  String get visibleWindow => _t('येथे दिसण्याची वेळ', 'यहाँ दिखने का समय', 'Visible here');
  String get sutak => _t('सुतक प्रारंभ', 'सूतक प्रारंभ', 'Sutak begins');
  String get sutakRelaxed => _t(
        'बालक, वृद्ध व रुग्णांसाठी सुतक',
        'बच्चे, बुजुर्ग व रोगियों के लिए सूतक',
        'Sutak for children, elderly & unwell',
      );
  String get duration => _t('कालावधी', 'अवधि', 'Duration');
  String get coverage => _t('ग्रासमान', 'ग्रास', 'Coverage');

  String durationText(Duration d) {
    final h = d.inHours, m = d.inMinutes % 60;
    if (lang == 'en') return h > 0 ? '${h}h ${m}m' : '${m}m';
    final hs = h > 0 ? '${fmt.num(h)} ${_t('तास', 'घंटे', '')} ' : '';
    return '$hs${fmt.num(m)} ${_t('मिनिटे', 'मिनट', '')}';
  }

  String percent(double fraction) => fmt.num('${(fraction * 100).round()}%');

  // Reminders
  String get remind => _t('आठवण करा', 'याद दिलाएँ', 'Remind me');
  String get reminderOn => _t('आठवण लावली', 'रिमाइंडर लगा', 'Reminder set');
  String get reminderSet => _t(
        'सुतक व ग्रहण स्पर्शाच्या वेळी सूचना मिळेल.',
        'सूतक व ग्रहण स्पर्श के समय सूचना मिलेगी।',
        "You'll be notified at sutak and when the eclipse begins.",
      );
  String get reminderRemoved => _t('आठवण काढली', 'रिमाइंडर हटाया', 'Reminder removed');
  String get permissionNeeded => _t(
        'आठवणीसाठी सूचना परवानगी आवश्यक आहे.',
        'रिमाइंडर के लिए सूचना अनुमति आवश्यक है।',
        'Notification permission is needed for reminders.',
      );

  String notifySutakTitle(GrahanEvent e) => _t(
        '🌑 ${kind(e.kind)}: सुतक सुरू',
        '🌑 ${kind(e.kind)}: सूतक प्रारंभ',
        '🌑 ${kind(e.kind)}: Sutak begins',
      );
  String notifySparshTitle(GrahanEvent e) => _t(
        '🌑 ${kind(e.kind)} सुरू होत आहे',
        '🌑 ${kind(e.kind)} आरंभ हो रहा है',
        '🌑 ${kind(e.kind)} is beginning',
      );
  String notifyBody(String sparshTime, String mokshaTime) => _t(
        'स्पर्श $sparshTime • मोक्ष $mokshaTime. ग्रहण काळात नामस्मरण व जप करा.',
        'स्पर्श $sparshTime • मोक्ष $mokshaTime. ग्रहण काल में नाम जप करें।',
        'Begins $sparshTime • ends $mokshaTime. Chant and do jaap during the eclipse.',
      );

  // Guidance
  String get guidanceTitle => _t('ग्रहण काळात', 'ग्रहण काल में', 'During the eclipse');
  List<String> get guidance => [
        _t('इष्टदेवतेचे नामस्मरण, जप व स्तोत्रपठण करा.',
            'इष्टदेव का नाम जप, मंत्र जप व स्तोत्र पाठ करें।',
            'Chant your deity\'s name, mantras and stotras.'),
        _t('सुतक काळात व ग्रहणात भोजन टाळा; अन्नात तुळशीपत्र ठेवा.',
            'सूतक व ग्रहण काल में भोजन से बचें; भोजन में तुलसी पत्र रखें।',
            'Avoid eating during sutak and the eclipse; keep tulsi leaves in food.'),
        _t('देवपूजा व मूर्तिस्पर्श टाळा; मंदिरे बंद असतात.',
            'देव पूजा व मूर्ति स्पर्श न करें; मंदिर बंद रहते हैं।',
            'Avoid puja and touching idols; temples stay closed.'),
        _t('मोक्षानंतर स्नान करा, घरात गंगाजल शिंपडा व दान करा.',
            'मोक्ष के बाद स्नान करें, घर में गंगाजल छिड़कें व दान करें।',
            'After moksha, bathe, sprinkle Gangajal at home and give daan.'),
      ];
  String get safety => _t(
        'सूर्यग्रहण उघड्या डोळ्यांनी किंवा साध्या गॉगलने कधीही पाहू नका — प्रमाणित सोलर फिल्टर वापरा.',
        'सूर्य ग्रहण को नंगी आँखों या सामान्य चश्मे से कभी न देखें — प्रमाणित सोलर फ़िल्टर का उपयोग करें।',
        'Never look at a solar eclipse with naked eyes or sunglasses — use certified solar filters.',
      );
  String get accuracyNote => _t(
        'वेळा खगोलीय गणनेवर आधारित, ±२ मिनिटे. सुतक नियम परंपरेनुसार बदलू शकतात.',
        'समय खगोलीय गणना पर आधारित, ±२ मिनट। सूतक नियम परंपरा अनुसार भिन्न हो सकते हैं।',
        'Times are astronomically computed, ±2 min. Sutak customs vary by tradition.',
      );

  static const _weekMr = ['सोमवार', 'मंगळवार', 'बुधवार', 'गुरुवार', 'शुक्रवार', 'शनिवार', 'रविवार'];
  static const _weekHi = ['सोमवार', 'मंगलवार', 'बुधवार', 'गुरुवार', 'शुक्रवार', 'शनिवार', 'रविवार'];
  static const _weekEn = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  String weekday(DateTime d) =>
      (lang == 'en' ? _weekEn : (lang == 'hi' ? _weekHi : _weekMr))[d.weekday - 1];

  /// `Sat, 2 Aug 2027` style.
  String fullDate(DateTime local) => '${weekday(local)}, ${fmt.date(local)}';

  /// Time, prefixed with the date when it differs from [reference].
  String timeOn(DateTime local, DateTime reference) {
    final sameDay = local.year == reference.year &&
        local.month == reference.month &&
        local.day == reference.day;
    return sameDay ? fmt.time(local) : '${fmt.time(local)}, ${fmt.date(local)}';
  }
}
