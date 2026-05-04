import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:xiwu/services/database_service.dart';
import 'package:xiwu/theme/app_theme.dart';
import 'package:xiwu/views/home_page.dart';
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
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: '惜物 Xiwu',
      theme: AppTheme.lightTheme,
      home: HomePage(),
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('zh', 'CN'),
      ],
      locale: const Locale('zh', 'CN'),
    );
  }
}
