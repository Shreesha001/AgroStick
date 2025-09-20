// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get appTitle => 'एग्रोस्टिक ऐप';

  @override
  String get profile => 'प्रोफाइल';

  @override
  String get personalInformation => 'व्यक्तिगत जानकारी';

  @override
  String get name => 'नाम';

  @override
  String get phone => 'फ़ोन';

  @override
  String get farmName => 'खेत का नाम';

  @override
  String get language => 'भाषा';

  @override
  String get saveProfile => 'प्रोफाइल सहेजें';

  @override
  String get logout => 'लॉगआउट';

  @override
  String get profileUpdated => 'प्रोफाइल सफलतापूर्वक अपडेट की गई';

  @override
  String profileUpdateError(Object error) {
    return 'प्रोफाइल अपडेट करने में त्रुटि: $error';
  }

  @override
  String get welcome => 'स्वागत है!';

  @override
  String get hi => 'नमस्ते';

  @override
  String get weeklyWeather => 'साप्ताहिक मौसम';

  @override
  String get fetchingWeather => '7-दिवसीय मौसम ला रहे हैं…';

  @override
  String get weatherUnavailable => 'मौसम जानकारी उपलब्ध नहीं';

  @override
  String get espStatus => 'ESP32-S3 स्थिति';

  @override
  String get connected => 'संबद्ध';

  @override
  String get disconnected => 'असंबद्ध';

  @override
  String get batteryLevel => 'बैटरी स्तर';

  @override
  String get temperature => 'तापमान';

  @override
  String get sprayStatus => 'स्प्रे स्थिति';

  @override
  String get idle => 'निष्क्रिय';

  @override
  String get spraying => 'स्प्रे कर रहे हैं';

  @override
  String get blogs => 'ब्लॉग';

  @override
  String get viewAll => 'सभी देखें';

  @override
  String get sprayHistory => 'स्प्रे इतिहास';

  @override
  String get today => 'आज';

  @override
  String get thisWeek => 'इस सप्ताह';

  @override
  String get thisMonth => 'इस महीने';

  @override
  String get sprays => 'स्प्रे';

  @override
  String get sprayDetails => 'स्प्रे विवरण';

  @override
  String get sprayTrend => 'स्प्रे रुझान';

  @override
  String get spray => 'स्प्रे';

  @override
  String get time => 'समय';

  @override
  String get amount => 'मात्रा';

  @override
  String get liters => 'लीटर';

  @override
  String sprayNumber(Object number) {
    return intl.Intl.message(
      'स्प्रे #$number',
      name: 'sprayNumber',
      args: [number],
      desc: 'Dynamic spray number like \'स्प्रे #1\'',
      examples: {'number': 1},
    );
  }
}