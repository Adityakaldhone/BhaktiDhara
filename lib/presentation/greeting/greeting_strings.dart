/// Greeting-image screens copy in Marathi, Hindi and English.
class GreetingStrings {
  const GreetingStrings(this.lang);

  final String lang;

  String _t(String mr, String hi, String en) =>
      lang == 'en' ? en : (lang == 'hi' ? hi : mr);

  String get title => _t('शुभेच्छा', 'शुभकामनाएँ', 'Greetings');
  String get popularCategories => _t('लोकप्रिय श्रेणी', 'लोकप्रिय श्रेणियाँ', 'Popular Categories');
  String get favorites => _t('आवडते', 'पसंदीदा', 'Favourites');

  String get dashboardTitle =>
      _t('शुभेच्छा इमेजेस', 'शुभकामना इमेजेस', 'Greeting images');
  String get dashboardHint => _t(
        'सुंदर HD शुभेच्छा कुटुंबाला व मित्रांना पाठवा',
        'सुंदर HD शुभकामनाएँ परिवार व मित्रों को भेजें',
        'Send beautiful HD wishes to family & friends',
      );
  String get view => _t('पहा', 'देखें', 'View');

  String get share => _t('शेअर करा', 'शेयर करें', 'Share');
  String get save => _t('सेव्ह', 'सेव', 'Save');
  String get favorite => _t('आवडते', 'पसंदीदा', 'Favourite');
  String get saved => _t('गॅलरीमध्ये सेव्ह झाले ✅', 'गैलरी में सेव हो गया ✅', 'Saved to gallery ✅');
  String get saveFailed => _t(
        'सेव्ह करता आले नाही. पुन्हा प्रयत्न करा.',
        'सेव नहीं हो सका। फिर से कोशिश करें।',
        'Could not save. Please try again.',
      );
  String get preparing => _t('इमेज तयार होत आहे...', 'इमेज तैयार हो रही है...', 'Preparing image...');
  String get shareFailed => _t(
        'इमेज पाठवता आली नाही. इंटरनेट तपासून पुन्हा प्रयत्न करा.',
        'इमेज नहीं भेजी जा सकी। इंटरनेट जाँचकर फिर कोशिश करें।',
        'Could not share the image. Check your internet and try again.',
      );

  String get loadFailed => _t(
        'इमेजेस लोड झाल्या नाहीत. इंटरनेट तपासा.',
        'इमेजेस लोड नहीं हुईं। इंटरनेट जाँचें।',
        "Couldn't load images. Check your internet.",
      );
  String get retry => _t('पुन्हा प्रयत्न करा', 'फिर कोशिश करें', 'Try again');
  String get emptyCategory => _t(
        'या श्रेणीत लवकरच नवीन इमेजेस येतील 🙏',
        'इस श्रेणी में जल्द ही नई इमेजेस आएँगी 🙏',
        'New images are coming to this category soon 🙏',
      );
  String get emptyFavorites => _t(
        'आवडलेल्या इमेजवर ♥ दाबा, त्या इथे दिसतील.',
        'पसंद आई इमेज पर ♥ दबाएँ, वह यहाँ दिखेगी।',
        'Tap ♥ on images you like and they will show up here.',
      );

  // Photo circle
  String get addPhoto => _t('तुमचा फोटो', 'आपकी फ़ोटो', 'Your photo');
  String get changePhoto => _t('फोटो बदला', 'फ़ोटो बदलें', 'Change photo');
  String get removePhoto => _t('फोटो काढा', 'फ़ोटो हटाएँ', 'Remove photo');
  String get photoHint => _t(
        'फोटो फक्त या फोनवर राहतो आणि शेअर केलेल्या इमेजवर दिसतो.',
        'फ़ोटो केवल इसी फ़ोन पर रहती है और शेयर की गई इमेज पर दिखती है।',
        'Your photo stays on this phone and appears on images you share.',
      );
  String get photoFailed => _t(
        'हा फोटो वापरता आला नाही. दुसरा निवडा.',
        'यह फ़ोटो इस्तेमाल नहीं हो सकी। दूसरी चुनें।',
        "Couldn't use this photo. Please pick another.",
      );

  // Premium
  String get premium => _t('प्रीमियम', 'प्रीमियम', 'Premium');
  String get lockedTitle => _t(
        'ही प्रीमियम शुभेच्छा आहे',
        'यह प्रीमियम शुभकामना है',
        'This is a premium greeting',
      );
  String get lockedBody => _t(
        'सर्व प्रीमियम HD इमेजेस मिळवण्यासाठी भक्तीधारा प्रीमियम सुरू करा.',
        'सभी प्रीमियम HD इमेजेस पाने के लिए भक्तिधारा प्रीमियम लें।',
        'Unlock every premium HD image with BhaktiDhara Premium.',
      );
  String get unlock => _t('अनलॉक करा', 'अनलॉक करें', 'Unlock');

  String caption(String category) => _t(
        '🙏 $category 🙏\nरोज नवीन शुभेच्छा, आरती व पंचांग — BhaktiDhara ॲप:',
        '🙏 $category 🙏\nरोज़ नई शुभकामनाएँ, आरती व पंचांग — BhaktiDhara ऐप:',
        '🙏 $category 🙏\nFresh daily greetings, aarti & panchang — BhaktiDhara app:',
      );
}
