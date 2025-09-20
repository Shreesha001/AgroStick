// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Agrostick App';

  @override
  String get profile => 'Profile';

  @override
  String get personalInformation => 'Personal Information';

  @override
  String get name => 'Name';

  @override
  String get phone => 'Phone';

  @override
  String get farmName => 'Farm Name';

  @override
  String get language => 'Language';

  @override
  String get saveProfile => 'Save Profile';

  @override
  String get logout => 'Logout';

  @override
  String get profileUpdated => 'Profile updated successfully';

  @override
  String profileUpdateError(Object error) {
    return 'Error updating profile: $error';
  }

  @override
  String get welcome => 'Welcome!';

  @override
  String get hi => 'Hi';

  @override
  String get weeklyWeather => 'Weekly Weather';

  @override
  String get fetchingWeather => 'Fetching 7-day weather…';

  @override
  String get weatherUnavailable => 'Weather unavailable';

  @override
  String get espStatus => 'ESP32-S3 Status';

  @override
  String get connected => 'Connected';

  @override
  String get disconnected => 'Disconnected';

  @override
  String get batteryLevel => 'Battery Level';

  @override
  String get temperature => 'Temperature';

  @override
  String get sprayStatus => 'Spray Status';

  @override
  String get idle => 'Idle';

  @override
  String get spraying => 'Spraying';

  @override
  String get blogs => 'Blogs';

  @override
  String get viewAll => 'View All';
}
