// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Panjabi Punjabi (`pa`).
class AppLocalizationsPa extends AppLocalizations {
  AppLocalizationsPa([String locale = 'pa']) : super(locale);

  @override
  String get appTitle => 'ਐਗਰੋਸਟਿਕ ਐਪ';

  @override
  String get profile => 'ਪ੍ਰੋਫਾਈਲ';

  @override
  String get personalInformation => 'ਨਿੱਜੀ ਜਾਣਕਾਰੀ';

  @override
  String get name => 'ਨਾਮ';

  @override
  String get phone => 'ਫ਼ੋਨ';

  @override
  String get farmName => 'ਖੇਤ ਦਾ ਨਾਮ';

  @override
  String get language => 'ਭਾਸ਼ਾ';

  @override
  String get saveProfile => 'ਪ੍ਰੋਫਾਈਲ ਸੰਭਾਲੋ';

  @override
  String get logout => 'ਲਾਗਆਉਟ';

  @override
  String get profileUpdated => 'ਪ੍ਰੋਫਾਈਲ ਸਫਲਤਾਪੂਰਵਕ ਅਪਡੇਟ ਕੀਤੀ ਗਈ';

  @override
  String profileUpdateError(Object error) {
    return 'ਪ੍ਰੋਫਾਈਲ ਅਪਡੇਟ ਕਰਨ ਵਿੱਚ ਗਲਤੀ: $error';
  }
}
