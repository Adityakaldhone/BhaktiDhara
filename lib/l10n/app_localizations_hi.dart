// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get appTitle => 'भक्तिधारा';

  @override
  String get appSubtitle => 'आरती संग्रह';

  @override
  String get appTagline => 'भक्ति की धारा, हर घर, हर दिन';

  @override
  String get clearFilter => 'फ़िल्टर हटाएं';

  @override
  String get noAartiFound => 'इस देवता के लिए कोई आरती नहीं मिली।';

  @override
  String get readAndPlay => 'पढ़ें और बजाएं';

  @override
  String get screenAwake => 'स्क्रीन हमेशा चालू रहेगी';

  @override
  String get playBell => 'घंटी बजाएं';

  @override
  String get blowConch => 'शंख बजाएं';

  @override
  String get bellPlayed => '🔔 पवित्र घंटी बजी';

  @override
  String get conchBlown => '🐚 शंखनाद हुआ';

  @override
  String get loadingError =>
      'कैटलॉग लोड नहीं हो सका।\nकृपया अपना कनेक्शन जांचें।';

  @override
  String get searchHint => 'खोजें आरती, चालीसा, भजन...';

  @override
  String get sacredCollection => 'पवित्र संग्रह';

  @override
  String get seeAll => 'सभी देखें';

  @override
  String get filterAll => 'सभी';

  @override
  String get navHome => 'मुख्य';

  @override
  String get navFavorites => 'पसंदीदा';

  @override
  String get navLanguage => 'भाषा';

  @override
  String get navMore => 'अधिक';
}
