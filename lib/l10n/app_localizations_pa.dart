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

  @override
  String get welcome => 'ਸਵਾਗਤ ਹੈ!';

  @override
  String get hi => 'ਸਤ ਸ੍ਰੀ ਅਕਾਲ';

  @override
  String get weeklyWeather => 'ਹਫ਼ਤਾਵਾਰੀ ਮੌਸਮ';

  @override
  String get fetchingWeather => '7-ਦਿਨਾਂ ਦਾ ਮੌਸਮ ਲੈ ਰਹੇ ਹਾਂ…';

  @override
  String get weatherUnavailable => 'ਮੌਸਮ ਜਾਣਕਾਰੀ ਉਪਲਬਧ ਨਹੀਂ';

  @override
  String get espStatus => 'ESP32-S3 ਹਾਲਤ';

  @override
  String get connected => 'ਜੁੜਿਆ ਹੋਇਆ';

  @override
  String get disconnected => 'ਅਣਜੁੜਿਆ';

  @override
  String get batteryLevel => 'ਬੈਟਰੀ ਪੱਧਰ';

  @override
  String get temperature => 'ਤਾਪਮਾਨ';

  @override
  String get sprayStatus => 'ਸਪਰੇ ਹਾਲਤ';

  @override
  String get idle => 'ਨਿਸ਼ਕ੍ਰਿਆ';

  @override
  String get spraying => 'ਸਪਰੇ ਕਰ ਰਹੇ ਹਾਂ';

  @override
  String get blogs => 'ਬਲੌਗ';

  @override
  String get viewAll => 'ਸਭ ਵੇਖੋ';
}
