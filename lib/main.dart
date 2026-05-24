import 'core/theme/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'core/database/offline_sync_service.dart';
import 'core/di/service_locator.dart';
import 'features/splash/splash_screen.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';
import 'core/providers/locale_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint('Warning: Could not load .env file: $e');
  }
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  await Hive.initFlutter();
  await Hive.openBox('saved_recipes');
  await Hive.openBox('my_recipes');
  await Hive.openBox('shopping_list');
  await Hive.openBox('viewed_recipes');
  
  // Offline cache kutularını aç
  await OfflineSyncService.init();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Color(0xFFF9F9F9),
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  
  final prefs = await SharedPreferences.getInstance();
  final showHome = prefs.getBool('showHome') ?? false;

  // Günlük giriş streak kaydı
  final currentUser = ServiceLocator.auth.currentUser;
  if (currentUser != null) {
    ServiceLocator.gamification.recordDailyLogin(currentUser.uid);
  }

  runApp(
    ProviderScope(
      child: AuraCookApp(showHome: showHome),
    ),
  );
}

class AuraCookApp extends ConsumerWidget {
  final bool showHome;
  
  const AuraCookApp({super.key, required this.showHome});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch themeProvider to rebuild the entire app when theme changes
    final isDark = ref.watch(themeProvider);
    final lang = ref.watch(localeProvider);

    return MaterialApp(
      key: ValueKey('${isDark}_$lang'), // Force complete rebuild to ensure all colors and localized strings update
      title: 'AuraCook',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      locale: Locale(lang),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('tr', ''),
        Locale('en', ''),
      ],
      home: SplashScreen(showHome: showHome),
    );
  }
}


