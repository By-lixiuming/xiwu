import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';

class SettingsService extends GetxService {
  late Box _box;

  final RxString themeMode = 'system'.obs;
  final RxString language = 'zh_CN'.obs;

  Future<SettingsService> init() async {
    _box = await Hive.openBox('settings');
    themeMode.value = _box.get('themeMode', defaultValue: 'system');
    language.value = _box.get('language', defaultValue: 'zh_CN');
    return this;
  }

  void changeThemeMode(String mode) {
    themeMode.value = mode;
    _box.put('themeMode', mode);
    Get.changeThemeMode(_getThemeMode(mode));
  }

  ThemeMode _getThemeMode(String mode) {
    switch (mode) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }

  ThemeMode get currentThemeMode => _getThemeMode(themeMode.value);

  void changeLanguage(String langCode) {
    language.value = langCode;
    _box.put('language', langCode);
    final parts = langCode.split('_');
    Get.updateLocale(Locale(parts[0], parts.length > 1 ? parts[1] : null));
  }

  Locale get currentLocale {
    final parts = language.value.split('_');
    return Locale(parts[0], parts.length > 1 ? parts[1] : null);
  }
}
