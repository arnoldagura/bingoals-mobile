import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'theme_presets.dart';
import 'typography.dart';

/// App theme configuration with preset support
class AppTheme {
  AppTheme._();

  /// Create a theme from a preset
  static ThemeData fromPreset(ThemePreset preset) {
    final colors = ThemePresetColors.forPreset(preset);
    final isDark = colors.brightness == Brightness.dark;

    final onPrimary = colors.primary.computeLuminance() > 0.5
        ? Colors.black
        : Colors.white;

    return ThemeData(
      useMaterial3: true,
      brightness: colors.brightness,
      scaffoldBackgroundColor: colors.background,
      colorScheme: ColorScheme(
        brightness: colors.brightness,
        primary: colors.primary,
        onPrimary: onPrimary,
        secondary: colors.accent,
        onSecondary: colors.accent.computeLuminance() > 0.5
            ? Colors.black
            : Colors.white,
        surface: colors.card,
        onSurface: colors.foreground,
        error: const Color(0xFFDC2626),
        onError: Colors.white,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: colors.foreground,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: AppTypography.headlineMedium.copyWith(
          color: colors.foreground,
        ),
        systemOverlayStyle: isDark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
      ),
      cardTheme: CardThemeData(
        color: colors.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: colors.border),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.primary,
          foregroundColor: isDark ? colors.background : colors.card,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: AppTypography.button,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colors.foreground,
          side: BorderSide(color: colors.border),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: AppTypography.button,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colors.primary,
          textStyle: AppTypography.button,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.card,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.primary, width: 2),
        ),
        labelStyle: AppTypography.bodyMedium.copyWith(color: colors.foreground),
        hintStyle: AppTypography.bodyMedium.copyWith(color: colors.muted),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colors.card,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        titleTextStyle: AppTypography.headlineMedium.copyWith(
          color: colors.foreground,
        ),
        contentTextStyle: AppTypography.bodyMedium.copyWith(
          color: colors.foreground,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: colors.foreground,
        contentTextStyle: AppTypography.bodyMedium.copyWith(
          color: colors.background,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colors.primary,
      ),
      dividerTheme: DividerThemeData(
        color: colors.border,
        thickness: 1,
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: colors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      textTheme: _buildTextTheme(colors.foreground, colors.muted),
    );
  }

  static TextTheme _buildTextTheme(Color foreground, Color muted) {
    return TextTheme(
      displayLarge: AppTypography.displayLarge.copyWith(color: foreground),
      displayMedium: AppTypography.displayMedium.copyWith(color: foreground),
      displaySmall: AppTypography.displaySmall.copyWith(color: foreground),
      headlineLarge: AppTypography.headlineLarge.copyWith(color: foreground),
      headlineMedium: AppTypography.headlineMedium.copyWith(color: foreground),
      headlineSmall: AppTypography.headlineSmall.copyWith(color: foreground),
      bodyLarge: AppTypography.bodyLarge.copyWith(color: foreground),
      bodyMedium: AppTypography.bodyMedium.copyWith(color: foreground),
      bodySmall: AppTypography.bodySmall.copyWith(color: muted),
      labelLarge: AppTypography.labelLarge.copyWith(color: foreground),
      labelMedium: AppTypography.labelMedium.copyWith(color: foreground),
      labelSmall: AppTypography.labelSmall.copyWith(color: muted),
    );
  }

  // Legacy static getters for backward compatibility
  static ThemeData get light => fromPreset(ThemePreset.light);
  static ThemeData get dark => fromPreset(ThemePreset.olive);
}
