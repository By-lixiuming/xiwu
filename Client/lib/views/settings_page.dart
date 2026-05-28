import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:xiwu/services/settings_service.dart';
import 'package:xiwu/theme/app_theme.dart';
import 'package:xiwu/services/auth_service.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsService = Get.find<SettingsService>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: Text('settings'.tr),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // User Profile
          _buildUserProfile(isDark),
          const SizedBox(height: 24),

          // Theme Mode
          _buildSectionTitle('theme_mode'.tr),
          const SizedBox(height: 8),
          Obx(() => _buildThemeSelector(settingsService, isDark)),
          const SizedBox(height: 24),
          
          // Language
          _buildSectionTitle('language'.tr),
          const SizedBox(height: 8),
          Obx(() => _buildLanguageSelector(settingsService, isDark)),
          const SizedBox(height: 48),

          // Logout Button
          _buildLogoutButton(),
        ],
      ),
    );
  }

  Widget _buildUserProfile(bool isDark) {
    final authService = Get.find<AuthService>();
    return Obx(() {
      final user = authService.currentUser.value;
      if (user == null) return const SizedBox.shrink();

      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  user['avatar_emoji'] ?? '😊',
                  style: const TextStyle(fontSize: 32),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user['nickname'] ?? '惜物用户',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user['phone'] ?? '',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildLogoutButton() {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.red.shade50,
        foregroundColor: Colors.red,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 0,
      ),
      onPressed: () async {
        final authService = Get.find<AuthService>();
        await authService.logout();
        Get.offAllNamed('/login');
      },
      child: const Text(
        '退出登录',
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildThemeSelector(SettingsService service, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          _buildThemeOption(service, 'system', Icons.computer_rounded, 'theme_system'.tr),
          _buildThemeOption(service, 'light', Icons.wb_sunny_rounded, 'theme_light'.tr),
          _buildThemeOption(service, 'dark', Icons.nightlight_round, 'theme_dark'.tr),
        ],
      ),
    );
  }

  Widget _buildThemeOption(SettingsService service, String mode, IconData icon, String label) {
    final isSelected = service.themeMode.value == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () => service.changeThemeMode(mode),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? AppColors.primary : AppColors.textSecondary),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: isSelected ? AppColors.primary : AppColors.textSecondary,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageSelector(SettingsService service, bool isDark) {
    final languages = [
      {'code': 'zh_CN', 'label': '简体中文'},
      {'code': 'zh_TW', 'label': '繁体中文'},
      {'code': 'en_US', 'label': 'English'},
      {'code': 'ja_JP', 'label': '日本語'},
    ];

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: languages.map((lang) {
          final isSelected = service.language.value == lang['code']!;
          return ListTile(
            title: Text(lang['label']!, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
            trailing: isSelected ? const Icon(Icons.check, color: AppColors.primary) : null,
            onTap: () => service.changeLanguage(lang['code']!),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          );
        }).toList(),
      ),
    );
  }
}
