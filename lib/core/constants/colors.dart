import 'package:flutter/material.dart';

/// Paleta de colores para modo oscuro con tonos rojizos pastel
class AppColors {
  AppColors._();

  // Fondos
  static const Color backgroundDark = Color(0xFF121212);
  static const Color surfaceDark = Color(0xFF1E1E1E);
  static const Color surfaceVariant = Color(0xFF2D2D2D);
  static const Color cardBackground = Color(0xFF252525);

  // Colores primarios rojizos pastel
  static const Color primaryRed = Color(0xFFE57373);
  static const Color primaryRedLight = Color(0xFFFFAB91);
  static const Color primaryRedDark = Color(0xFFD32F2F);

  // Acentos
  static const Color accentCoral = Color(0xFFFF8A80);
  static const Color accentPeach = Color(0xFFFFCCBC);
  static const Color accentRose = Color(0xFFF48FB1);

  // Textos
  static const Color textPrimary = Color(0xFFF5F5F5);
  static const Color textSecondary = Color(0xFFBDBDBD);
  static const Color textTertiary = Color(0xFF757575);
  static const Color textDisabled = Color(0xFF616161);

  // Estados
  static const Color success = Color(0xFF81C784);
  static const Color warning = Color(0xFFFFD54F);
  static const Color error = Color(0xFFE57373);
  static const Color info = Color(0xFF64B5F6);

  // Bordes y divisores
  static const Color divider = Color(0xFF424242);
  static const Color border = Color(0xFF383838);

  // Colores para horarios (distintos tonos para diferenciar materias)
  static const List<Color> scheduleColors = [
    Color(0xFFE57373), // Rojo pastel
    Color(0xFFFFB74D), // Naranja pastel
    Color(0xFFFFF176), // Amarillo pastel
    Color(0xFF81C784), // Verde pastel
    Color(0xFF4FC3F7), // Celeste pastel
    Color(0xFF9575CD), // Morado pastel
    Color(0xFFF48FB1), // Rosa pastel
    Color(0xFF4DD0E1), // Cyan pastel
    Color(0xFFAED581), // Lima pastel
    Color(0xFFFFCC80), // Melocoton pastel
    Color(0xFFCE93D8), // Lavanda pastel
    Color(0xFF90CAF9), // Azul pastel
  ];

  /// Obtiene un color consistente basado en un string (para asignar colores a materias)
  static Color getColorForString(String value) {
    final index = value.hashCode.abs() % scheduleColors.length;
    return scheduleColors[index];
  }
}
