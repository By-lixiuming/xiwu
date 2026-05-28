import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:xiwu/services/database_service.dart';
import 'package:xiwu/services/settings_service.dart';
import 'package:xiwu/lang/translation_service.dart';
import 'package:xiwu/theme/app_theme.dart';
import 'package:xiwu/views/main_scaffold.dart';
import 'package:xiwu/views/login_page.dart';
import 'package:xiwu/services/api_service.dart';
import 'package:xiwu/services/auth_service.dart';
import 'package:xiwu/services/sync_engine.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize date formatting for zh_CN
  await initializeDateFormatting('zh_CN', null);
  
  // Initialize Hive
  await Hive.initFlutter();
  
  // Initialize Database Service
  final dbService = DatabaseService();
  await dbService.init();
  Get.put(dbService);

  // Initialize Network & Auth
  final apiService = ApiService();
  await apiService.init();
  Get.put(apiService);

  final authService = AuthService();
  await authService.init();
  Get.put(authService);

  // Initialize Sync Engine
  final syncEngine = SyncEngine();
  await syncEngine.init();
  Get.put(syncEngine);

  // Initialize Settings Service
  final settingsService = SettingsService();
  await settingsService.init();
  Get.put(settingsService);
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsService = Get.find<SettingsService>();
    
    return GetMaterialApp(
      title: 'Xiwu',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: settingsService.currentThemeMode,
      translations: TranslationService(),
      locale: settingsService.currentLocale,
      fallbackLocale: const Locale('en', 'US'),
      initialRoute: Get.find<AuthService>().isLoggedIn.value ? '/home' : '/login',
      getPages: [
        GetPage(name: '/login', page: () => LoginPage()),
        GetPage(name: '/home', page: () => const MainScaffold()),
      ],
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('zh', 'CN'),
        Locale('zh', 'TW'),
        Locale('en', 'US'),
        Locale('ja', 'JP'),
      ],
    );
  }
}
