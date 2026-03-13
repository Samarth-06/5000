import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive/hive.dart';

import 'core/constants/app_constants.dart';
import 'core/themes/app_theme.dart';
import 'models/farm_hive_model.dart';
import 'models/ndvi_history_model.dart';
import 'views/screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load .env
  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {}

  // Initialize Hive
  await Hive.initFlutter();

  // Register adapters
  Hive.registerAdapter(FarmHiveModelAdapter());
  Hive.registerAdapter(NdviHistoryModelAdapter());

  // Open boxes
  await Hive.openBox<FarmHiveModel>(AppConstants.farmsBox);
  await Hive.openBox<NdviHistoryModel>(AppConstants.ndviHistoryBox);
  final settingsBox = await Hive.openBox(AppConstants.settingsBox);

  // Seed API keys from .env if not already saved by user
  _seedIfAbsent(settingsBox, AppConstants.keyAgroApiKey,
      dotenv.maybeGet('AGRO_API_KEY') ?? 'YOUR_AGROMONITORING_API_KEY');
  _seedIfAbsent(settingsBox, AppConstants.keyWeatherApiKey,
      dotenv.maybeGet('WEATHER_API_KEY') ?? 'YOUR_OPENWEATHERMAP_API_KEY');
  _seedIfAbsent(settingsBox, AppConstants.keyGoogleMapsKey,
      dotenv.maybeGet('GOOGLE_MAPS_KEY') ?? 'YOUR_GOOGLE_MAPS_API_KEY');

  runApp(const ProviderScope(child: SmartFarmApp()));
}

void _seedIfAbsent(Box box, String key, String value) {
  if (!box.containsKey(key)) box.put(key, value);
}

class SmartFarmApp extends StatelessWidget {
  const SmartFarmApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sat2Farm',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const SplashScreen(),
    );
  }
}
