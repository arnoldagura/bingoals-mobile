import 'package:flutter/material.dart';

/// Bingoals color palette - black & white focus shade
class AppColors {
  AppColors._();

  // ============== PRIMARY (Black & White) ==============

  static const Color gold = Color(0xFF1A1A1A);       // Primary accent (black)
  static const Color goldLight = Color(0xFF404040);   // Lighter shade
  static const Color goldDark = Color(0xFF000000);    // Darkest shade

  // ============== LIGHT THEME ==============

  static const Color backgroundLight = Color(0xFFFAFAFA);
  static const Color surfaceLight = Color(0xFFFFFFFF);

  static const Color textPrimaryLight = Color(0xFF171717);
  static const Color textSecondaryLight = Color(0xFF525252);
  static const Color textMutedLight = Color(0xFF737373);

  // ============== DARK THEME ==============

  static const Color backgroundDark = Color(0xFF0A0A0A);
  static const Color surfaceDark = Color(0xFF171717);

  static const Color textPrimaryDark = Color(0xFFFAFAFA);
  static const Color textSecondaryDark = Color(0xFFA3A3A3);
  static const Color textMutedDark = Color(0xFF737373);

  // ============== SHARED COLORS ==============

  // Accent colors
  static const Color rose = Color(0xFF525252);
  static const Color roseLight = Color(0xFF737373);
  static const Color cream = Color(0xFFFAFAFA);

  // Status colors
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);

  // Grid colors
  static const Color goalCell = Color(0xFFFFFFFF);
  static const Color goalCellBorder = Color(0xFFD4D4D4);
  static const Color goalCellDashed = Color(0xFFA3A3A3);

  // Card and border colors
  static const Color cardBorderLight = Color(0xFFE5E5E5);
  static const Color cardBorderDark = Color(0xFF262626);
  static const Color divider = Color(0xFFE5E5E5);

  // Progress ring gradient (grayscale)
  static const List<Color> progressGradient = [
    Color(0xFF171717),
    Color(0xFF404040),
  ];

  // Confetti colors (celebration)
  static const List<Color> confettiColors = [
    Color(0xFFEF4444), // red
    Color(0xFFF59E0B), // amber
    Color(0xFF22C55E), // green
    Color(0xFF3B82F6), // blue
    Color(0xFF8B5CF6), // purple
    Color(0xFFEC4899), // pink
  ];

  // ============== ALIASES ==============
  static const Color background = backgroundLight;
  static const Color surface = surfaceLight;
  static const Color textPrimary = textPrimaryLight;
  static const Color textSecondary = textSecondaryLight;
  static const Color textMuted = textMutedLight;
  static const Color textOnDark = textPrimaryDark;
  static const Color cardBorder = cardBorderLight;
}
