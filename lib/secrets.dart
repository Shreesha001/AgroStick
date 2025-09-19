import 'package:flutter_dotenv/flutter_dotenv.dart';

// WARNING: Do not commit real secrets in production. Use env/remote config.
String get geminiApiKey => dotenv.env['GEMINI_API_KEY'] ?? '';


