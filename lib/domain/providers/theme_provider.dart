import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Modo de tema de la aplicacion
enum AppThemeMode { light, dark, system }

/// Provider para manejar el tema de la aplicacion
class ThemeNotifier extends Notifier<AppThemeMode> {
  static const _key = 'app_theme_mode';

  @override
  AppThemeMode build() {
    _loadSaved();
    return AppThemeMode.system;
  }

  /// Carga la preferencia guardada
  Future<void> _loadSaved() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_key);
    if (saved != null) {
      final mode = AppThemeMode.values.firstWhere(
        (e) => e.name == saved,
        orElse: () => AppThemeMode.system,
      );
      state = mode;
    }
  }

  /// Cambia el modo del tema y persiste la preferencia
  Future<void> setThemeMode(AppThemeMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, mode.name);
  }

  /// Convierte AppThemeMode a ThemeMode de Flutter
  ThemeMode get flutterThemeMode {
    switch (state) {
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.dark:
        return ThemeMode.dark;
      case AppThemeMode.system:
        return ThemeMode.system;
    }
  }
}

/// Provider del notificador de tema
final themeNotifierProvider = NotifierProvider<ThemeNotifier, AppThemeMode>(
  ThemeNotifier.new,
);

/// Provider para obtener el ThemeMode de Flutter
final themeModeProvider = Provider<ThemeMode>((ref) {
  final themeNotifier = ref.watch(themeNotifierProvider.notifier);
  // Necesitamos watch del state tambien para reactividad
  ref.watch(themeNotifierProvider);
  return themeNotifier.flutterThemeMode;
});
