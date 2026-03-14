import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConstants {
  // ─── External API Base URLs ────────────────────────────────────────────────
  static const String agroBaseUrl     = 'https://agromonitoring.com/api/v1';
  static const String weatherBaseUrl  = 'https://api.openweathermap.org/data/2.5';
  static String get sat2farmBaseUrl   => dotenv.maybeGet('SAT2FARM_API_URL') ?? 'https://badal023-testapi.hf.space';

  // ─── Supabase ──────────────────────────────────────────────────────────────
  static String get supabaseUrl       => dotenv.maybeGet('SUPABASE_URL')      ?? '';
  static String get supabaseAnonKey   => dotenv.maybeGet('SUPABASE_ANON_KEY') ?? '';

  // ─── AI ───────────────────────────────────────────────────────────────────
  static String get geminiApiKey      => dotenv.maybeGet('GEMINI_API_KEY')    ?? '';

  // ─── MapTiler (optional alternative tiles) ────────────────────────────────
  static String get mapTilerApiKey    => dotenv.maybeGet('MAPTILER_API_KEY')  ?? '';

  // ─── Hive Box Names ────────────────────────────────────────────────────────
  static const String farmsBox        = 'farms_box';
  static const String ndviHistoryBox  = 'ndvi_history_box';
  static const String settingsBox     = 'settings_box';

  // ─── Settings Keys ─────────────────────────────────────────────────────────
  static const String keyAgroApiKey   = 'agro_api_key';
  static const String keyWeatherApiKey= 'weather_api_key';
  static const String keyGoogleMapsKey= 'google_maps_key';
  static const String keyLanguage     = 'language';
  static const String keyOnboardingDone = 'onboarding_done';
}
