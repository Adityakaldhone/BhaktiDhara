import '../../domain/entities/greeting_card.dart';

/// Status-card screen copy in Marathi, Hindi and English.
class GreetingStrings {
  const GreetingStrings(this.lang);

  final String lang;

  String _t(String mr, String hi, String en) =>
      lang == 'en' ? en : (lang == 'hi' ? hi : mr);

  String get dashboardTitle =>
      _t('आजचे शुभेच्छा कार्ड', 'आज का शुभकामना कार्ड', "Today's greeting card");
  String get dashboardHint => _t(
        'कुटुंबाला व मित्रांना पाठवा',
        'परिवार व मित्रों को भेजें',
        'Send to family & friends',
      );
  String get sendWhatsApp =>
      _t('WhatsApp वर पाठवा', 'WhatsApp पर भेजें', 'Send on WhatsApp');
  String get view => _t('पहा', 'देखें', 'View');
  String get change => _t('बदला', 'बदलें', 'Change');
  String get previewTitle => _t('शुभेच्छा कार्ड', 'शुभकामना कार्ड', 'Greeting card');
  String get preparing =>
      _t('कार्ड तयार होत आहे...', 'कार्ड तैयार हो रहा है...', 'Preparing card...');
  String get shareFailed => _t(
        'कार्ड पाठवता आले नाही. पुन्हा प्रयत्न करा.',
        'कार्ड नहीं भेजा जा सका। फिर से कोशिश करें।',
        'Could not share the card. Please try again.',
      );

  // Edit sheet
  String get editTitle => _t('कार्ड बदला', 'कार्ड बदलें', 'Change card');
  String get chooseDeity => _t('देव निवडा', 'भगवान चुनें', 'Choose deity');
  String get autoDeity => _t('आजचे दैवत', 'आज के देव', "Today's deity");
  String get chooseDesign => _t('डिझाइन निवडा', 'डिज़ाइन चुनें', 'Choose design');
  String get dailyNew => _t('रोज नवीन', 'रोज़ नया', 'New daily');

  String styleName(CardStyle style) => switch (style) {
        CardStyle.templeArch => _t('मंदिर', 'मंदिर', 'Temple'),
        CardStyle.suryoday => _t('सूर्योदय', 'सूर्योदय', 'Sunrise'),
        CardStyle.darshan => _t('दर्शन', 'दर्शन', 'Darshan'),
        CardStyle.poojaThali => _t('पूजा', 'पूजा', 'Pooja'),
        CardStyle.rangoli => _t('रांगोळी', 'रंगोली', 'Rangoli'),
        CardStyle.kamal => _t('कमळ', 'कमल', 'Lotus'),
        CardStyle.rajwada => _t('राजवाडा', 'राजसी', 'Royal'),
        CardStyle.om => _t('ॐ', 'ॐ', 'Om'),
      };

  String get chooseGreeting => _t('शुभेच्छा निवडा', 'शुभकामना चुनें', 'Choose greeting');
  String get yourName => _t('तुमचे नाव', 'आपका नाम', 'Your name');
  String get nameHint => _t('उदा. आदित्य काका', 'जैसे: राम भैया', 'e.g. Aditya');
  String get nameInvalid => _t(
        'नावात फक्त अक्षरे लिहा (लिंक किंवा नंबर नको)',
        'नाम में केवल अक्षर लिखें (लिंक या नंबर नहीं)',
        'Use letters only (no links or numbers)',
      );
  String get done => _t('पूर्ण', 'पूर्ण', 'Done');
  String get emojiTitle => _t('इमोजी', 'इमोजी', 'Emojis');
  String get emojiHint => _t(
        'कार्डच्या तळाशी दिसतील. कीबोर्डवरून कोणतेही इमोजी टाका (जास्तीत जास्त 8).',
        'कार्ड के नीचे दिखेंगे। कीबोर्ड से कोई भी इमोजी डालें (अधिकतम 8)।',
        'Shown at the bottom of the card. Type any emoji from your keyboard (up to 8).',
      );
  String get clear => _t('काढा', 'हटाएँ', 'Clear');
  String get yourPhoto => _t('तुमचा फोटो', 'आपकी फ़ोटो', 'Your photo');
  String get addPhoto => _t('फोटो लावा', 'फ़ोटो लगाएँ', 'Add photo');
  String get changePhoto => _t('फोटो बदला', 'फ़ोटो बदलें', 'Change photo');
  String get removePhoto => _t('काढा', 'हटाएँ', 'Remove');
  String get photoHint => _t(
        'फोटो नावाशेजारी दिसतो. तो फक्त या फोनवर राहतो.',
        'फ़ोटो नाम के पास दिखती है। यह केवल इसी फ़ोन पर रहती है।',
        'Shown next to your name. It stays on this phone only.',
      );
  String get photoFailed => _t(
        'हा फोटो वापरता आला नाही. दुसरा निवडा.',
        'यह फ़ोटो इस्तेमाल नहीं हो सकी। दूसरी चुनें।',
        "Couldn't use this photo. Please pick another.",
      );

  // First-share name prompt
  String get askNameTitle => _t(
        'कार्डवर तुमचे नाव लिहायचे?',
        'कार्ड पर अपना नाम लिखें?',
        'Add your name to the card?',
      );
  String get askNameBody => _t(
        'नाव फक्त या फोनवर राहते, कुठेही पाठवले जात नाही.',
        'नाम केवल इसी फोन पर रहता है, कहीं भेजा नहीं जाता।',
        'Your name stays on this phone only.',
      );
  String get addName => _t('नाव लिहा', 'नाम लिखें', 'Add name');
  String get skipName => _t('नको, असेच पाठवा', 'नहीं, ऐसे ही भेजें', 'No, send as is');

  String caption(String title) => _t(
        '🙏 $title 🙏\nरोजचे पंचांग, आरती व शुभेच्छा कार्ड — BhaktiDhara ॲप:',
        '🙏 $title 🙏\nरोज़ का पंचांग, आरती व शुभकामना कार्ड — BhaktiDhara ऐप:',
        '🙏 $title 🙏\nDaily Panchang, aarti & greeting cards — BhaktiDhara app:',
      );

  // Daily limit for free tier
  String get dailyLimitTitle => _t(
        'आजचे १ मोफत कार्ड पाठवले गेले आहे',
        'आज का 1 मुफ्त कार्ड भेजा जा चुका है',
        "Today's 1 free card already shared",
      );
  String get dailyLimitBody => _t(
        'मोफत आवृत्तीत दररोज १ कार्ड शेअर करता येते. दररोज अमर्याद कार्ड्स, सर्व डिझाईन्स व वॉटरमार्क काढण्यासाठी भक्तीधारा प्रीमियम सुरू करा.',
        'मुफ्त प्लान में प्रतिदिन 1 कार्ड शेयर कर सकते हैं। प्रतिदिन असीमित कार्ड, सभी डिज़ाइन व वॉटरमार्क हटाने हेतु भक्तिधारा प्रीमियम लें।',
        'Free tier includes 1 card share per day. Unlock unlimited daily cards, all designs, and remove watermark with BhaktiDhara Premium.',
      );
  String get viewPremiumPlans => _t(
        'प्रीमियम प्लॅन्स पहा (₹५१/मा. पासून)',
        'प्रीमियम प्लान्स देखें (₹51/मा. से)',
        'View Premium Plans (From ₹51/mo)',
      );
  String get tryAgainTomorrow => _t(
        'उद्या पुन्हा मोफत शेअर करा',
        'कल पुनः मुफ्त शेयर करें',
        'Share again free tomorrow',
      );
}
