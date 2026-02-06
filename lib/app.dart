import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_presets.dart';
import 'router/app_router.dart';

/// Theme preset provider - defaults to light (black & white)
final themePresetProvider = StateProvider<ThemePreset>((ref) => ThemePreset.light);

class BingoalsApp extends ConsumerWidget {
  const BingoalsApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final preset = ref.watch(themePresetProvider);
    final theme = AppTheme.fromPreset(preset);

    return MaterialApp.router(
      title: 'Bingoals',
      debugShowCheckedModeBanner: false,
      theme: theme,
      routerConfig: router,
    );
  }
}
