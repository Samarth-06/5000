import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/constants/app_constants.dart';
import 'core/localization/app_localizations.dart';
import 'core/themes/app_theme.dart';
import 'models/farm_hive_model.dart';
import 'models/ndvi_history_model.dart';
import 'services/notification_service.dart';
import 'viewmodels/locale_provider.dart';
import 'views/screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load .env
  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {}

  // Initialize Hive (local cache)
  await Hive.initFlutter();
  Hive.registerAdapter(FarmHiveModelAdapter());
  Hive.registerAdapter(NdviHistoryModelAdapter());
  await Hive.openBox<FarmHiveModel>(AppConstants.farmsBox);
  await Hive.openBox<NdviHistoryModel>(AppConstants.ndviHistoryBox);
  await Hive.openBox(AppConstants.settingsBox);

  // Initialize Supabase
  try {
    await Supabase.initialize(
      url: AppConstants.supabaseUrl,
      anonKey: AppConstants.supabaseAnonKey,
    );
  } catch (_) {
    // Supabase init may fail with placeholder keys — app still works with local data
  }

  // Initialize Firebase + notifications.
  try {
    await Firebase.initializeApp();
    await NotificationService.init();
  } catch (_) {}

  runApp(const ProviderScope(child: SmartFarmApp()));
}

class SmartFarmApp extends ConsumerWidget {
  const SmartFarmApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);

    return MaterialApp(
      title: 'Sat2Farm',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const SplashScreen(),
    );
  }
}
