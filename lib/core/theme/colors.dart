import 'package:flutter/material.dart';

/// Golden Memories color palette - matching the web app theme
class AppColors {
  AppColors._();

  // Primary colors
  static const Color gold = Color(0xFFD4A853);
  static const Color goldLight = Color(0xFFE5C77A);
  static const Color goldDark = Color(0xFFB8923F);

  // Background colors
  static const Color background = Color(0xFFFAF8F5);
  static const Color backgroundDark = Color(0xFF1A1814);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF2A2520);

  // Text colors
  static const Color textPrimary = Color(0xFF1A1814);
  static const Color textSecondary = Color(0xFF6B6560);
  static const Color textMuted = Color(0xFF9A9590);
  static const Color textOnDark = Color(0xFFFAF8F5);

  // Accent colors
  static const Color rose = Color(0xFFC4918E);
  static const Color roseLight = Color(0xFFD4A5A2);
  static const Color cream = Color(0xFFFAF8F5);

  // Status colors
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color error = Color(0xFFE53935);

  // Card and border colors
  static const Color cardBorder = Color(0xFFE8E4E0);
  static const Color divider = Color(0xFFE8E4E0);

  // Progress ring gradient
  static const List<Color> progressGradient = [
    Color(0xFFD4A853),
    Color(0xFFE5C77A),
  ];

  // Confetti colors
  static const List<Color> confettiColors = [
    Color(0xFFD4A853),
    Color(0xFFC4918E),
    Color(0xFFE5C77A),
    Color(0xFFB8923F),
  ];
}
