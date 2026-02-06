import 'package:flutter/material.dart';

/// Available theme presets matching the web app
enum ThemePreset {
  light('Light', 'Clean and minimal'),
  dark('Dark', 'Easy on the eyes'),
  olive('Olive', 'Natural and calm'),
  midnight('Midnight', 'Deep and focused'),
  rose('Rose', 'Warm and elegant'),
  ocean('Ocean', 'Cool and refreshing');

  final String displayName;
  final String description;

  const ThemePreset(this.displayName, this.description);
}

/// Theme preset colors
class ThemePresetColors {
  final Color primary;
  final Color accent;
  final Color background;
  final Color foreground;
  final Color card;
  final Color border;
  final Color muted;
  final Brightness brightness;

  const ThemePresetColors({
    required this.primary,
    required this.accent,
    required this.background,
    required this.foreground,
    required this.card,
    required this.border,
    required this.muted,
    required this.brightness,
  });

  /// Get colors for a preset
  static ThemePresetColors forPreset(ThemePreset preset) {
    switch (preset) {
      case ThemePreset.light:
        return const ThemePresetColors(
          primary: Color(0xFF171717),
          accent: Color(0xFF525252),
          background: Color(0xFFFAFAFA),
          foreground: Color(0xFF171717),
          card: Color(0xFFFFFFFF),
          border: Color(0xFFE5E5E5),
          muted: Color(0xFF737373),
          brightness: Brightness.light,
        );

      case ThemePreset.dark:
        return const ThemePresetColors(
          primary: Color(0xFFFAFAFA),
          accent: Color(0xFFA3A3A3),
          background: Color(0xFF0A0A0A),
          foreground: Color(0xFFFAFAFA),
          card: Color(0xFF171717),
          border: Color(0xFF262626),
          muted: Color(0xFFA3A3A3),
          brightness: Brightness.dark,
        );

      case ThemePreset.olive:
        return const ThemePresetColors(
          primary: Color(0xFFFAF8F5),
          accent: Color(0xFFD0CCC8),
          background: Color(0xFF3D4A3A),
          foreground: Color(0xFFFAF8F5),
          card: Color(0xFF2F3A2D),
          border: Color(0xFF4A5A47),
          muted: Color(0xFF9A9590),
          brightness: Brightness.dark,
        );

      case ThemePreset.midnight:
        return const ThemePresetColors(
          primary: Color(0xFF818CF8),
          accent: Color(0xFFA78BFA),
          background: Color(0xFF0F172A),
          foreground: Color(0xFFF1F5F9),
          card: Color(0xFF1E293B),
          border: Color(0xFF334155),
          muted: Color(0xFF94A3B8),
          brightness: Brightness.dark,
        );

      case ThemePreset.rose:
        return const ThemePresetColors(
          primary: Color(0xFFC4918E),
          accent: Color(0xFFD4A5A2),
          background: Color(0xFFFAF8F5),
          foreground: Color(0xFF1A1814),
          card: Color(0xFFFFFFFF),
          border: Color(0xFFE8E4E0),
          muted: Color(0xFF6B6560),
          brightness: Brightness.light,
        );

      case ThemePreset.ocean:
        return const ThemePresetColors(
          primary: Color(0xFF0EA5E9),
          accent: Color(0xFF38BDF8),
          background: Color(0xFF0C4A6E),
          foreground: Color(0xFFF0F9FF),
          card: Color(0xFF075985),
          border: Color(0xFF0369A1),
          muted: Color(0xFF7DD3FC),
          brightness: Brightness.dark,
        );
    }
  }
}
