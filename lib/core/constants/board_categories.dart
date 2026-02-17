import 'package:flutter/material.dart';


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

class BoardPreset {
  final String label;
  final String suggestedTitle;
  final IconData icon;
  final Color color;
  final String boardType; // personal or shared
  final int gridSize;
  final String? category;
  final int maxMembers;

  const BoardPreset({
    required this.label,
    required this.suggestedTitle,
    required this.icon,
    required this.color,
    this.boardType = 'shared',
    this.gridSize = 5,
    this.category,
    this.maxMembers = 5,
  });

  static const List<BoardPreset> all = [
    BoardPreset(
      label: 'Couple Goals',
      suggestedTitle: 'Couple Goals 2026',
      icon: Icons.favorite_outline,
      color: Color(0xFFEC4899),
      boardType: 'shared',
      gridSize: 5,
      category: 'wellness',
      maxMembers: 2,
    ),
    BoardPreset(
      label: 'Friend Board',
      suggestedTitle: 'Barkada Goals 2026',
      icon: Icons.people_outline,
      color: Color(0xFF8B5CF6),
      boardType: 'shared',
      gridSize: 5,
      category: 'habits',
      maxMembers: 6,
    ),
    BoardPreset(
      label: 'Team Board',
      suggestedTitle: 'Team Goals 2026',
      icon: Icons.groups_outlined,
      color: Color(0xFF3B82F6),
      boardType: 'shared',
      gridSize: 5,
      category: 'career',
      maxMembers: 10,
    ),
    BoardPreset(
      label: 'Family Board',
      suggestedTitle: 'Family Goals 2026',
      icon: Icons.home_outlined,
      color: Color(0xFF10B981),
      boardType: 'shared',
      gridSize: 3,
      category: 'wellness',
      maxMembers: 8,
    ),
  ];
}
