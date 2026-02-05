import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Common utility functions
class Helpers {
  Helpers._();

  /// Format a date to readable string
  static String formatDate(DateTime date) {
    return DateFormat('MMM d, yyyy').format(date);
  }

  /// Format a date to relative string (e.g., "2 days ago")
  static String formatRelativeDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()} year(s) ago';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()} month(s) ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} day(s) ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour(s) ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute(s) ago';
    } else {
      return 'Just now';
    }
  }

  /// Calculate grid size from total goals
  static int calculateGridSize(int totalGoals) {
    for (int i = 3; i <= 7; i++) {
      if (i * i == totalGoals) return i;
    }
    return 5; // default
  }

  /// Get position from row and column
  static int getPosition(int row, int col, int gridSize) {
    return row * gridSize + col;
  }

  /// Get row and column from position
  static (int row, int col) getRowCol(int position, int gridSize) {
    return (position ~/ gridSize, position % gridSize);
  }

  /// Show a snackbar message
  static void showSnackBar(BuildContext context, String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade700 : null,
      ),
    );
  }

  /// Validate percentage (0-100)
  static bool isValidPercentage(int value) {
    return value >= 0 && value <= 100;
  }

  /// Get current year
  static int get currentYear => DateTime.now().year;
}
