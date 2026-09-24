// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'BhaktiDhara';

  @override
  String get appSubtitle => 'Aarti Sangrah';

  @override
  String get appTagline => 'Stream of devotion, every home, every day';

  @override
  String get clearFilter => 'Clear Filter';

  @override
  String get noAartiFound => 'No Aarti found for this deity.';

  @override
  String get readAndPlay => 'Read & Play';

  @override
  String get screenAwake => 'Screen stays awake automatically';

  @override
  String get playBell => 'Play Bell Sound';

  @override
  String get blowConch => 'Blow Conch';

  @override
  String get bellPlayed => '🔔 Sacred Bell Chimed';

  @override
  String get conchBlown => '🐚 Shankh Naad Blown';

  @override
  String get loadingError =>
      'Could not load catalog.\nPlease check your connection.';

  @override
  String get searchHint => 'Search Aarti, Chalisa, Bhajan...';

  @override
  String get sacredCollection => 'Sacred Collection';

  @override
  String get seeAll => 'See All';

  @override
  String get filterAll => 'All';

  @override
  String get navHome => 'Home';

  @override
  String get navFavorites => 'Favorites';

  @override
  String get navLanguage => 'Language';

  @override
  String get navMore => 'More';
}
