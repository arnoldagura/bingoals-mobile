import 'package:flutter/material.dart';

/// Predefined board categories with icons and accent colors
class BoardCategory {
  final String key;
  final String label;
  final IconData icon;
  final Color color;

  const BoardCategory({
    required this.key,
    required this.label,
    required this.icon,
    required this.color,
  });

  static const List<BoardCategory> all = [
    BoardCategory(
      key: 'fitness',
      label: 'Fitness',
      icon: Icons.fitness_center,
      color: Color(0xFFEF4444),
    ),
    BoardCategory(
      key: 'career',
      label: 'Career',
      icon: Icons.work_outline,
      color: Color(0xFF3B82F6),
    ),
    BoardCategory(
      key: 'habits',
      label: 'Habits',
      icon: Icons.repeat,
      color: Color(0xFF8B5CF6),
    ),
    BoardCategory(
      key: 'learning',
      label: 'Learning',
      icon: Icons.school_outlined,
      color: Color(0xFFF59E0B),
    ),
    BoardCategory(
      key: 'wellness',
      label: 'Wellness',
      icon: Icons.spa_outlined,
      color: Color(0xFF10B981),
    ),
    BoardCategory(
      key: 'finance',
      label: 'Finance',
      icon: Icons.savings_outlined,
      color: Color(0xFF06B6D4),
    ),
    BoardCategory(
      key: 'creative',
      label: 'Creative',
      icon: Icons.palette_outlined,
      color: Color(0xFFEC4899),
    ),
    BoardCategory(
      key: 'custom',
      label: 'Custom',
      icon: Icons.dashboard_customize_outlined,
      color: Color(0xFF6B7280),
    ),
  ];

  static BoardCategory? fromKey(String? key) {
    if (key == null) return null;
    try {
      return all.firstWhere((c) => c.key == key);
    } catch (_) {
      return null;
    }
  }
}
