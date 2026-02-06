import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Circular progress indicator with percentage display
class CircularProgress extends StatelessWidget {
  final int progress;
  final double size;
  final double strokeWidth;
  final Color? progressColor;
  final Color? backgroundColor;
  final TextStyle? textStyle;

  const CircularProgress({
    super.key,
    required this.progress,
    this.size = 80,
    this.strokeWidth = 6,
    this.progressColor,
    this.backgroundColor,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progressCol = progressColor ?? theme.colorScheme.primary;
    final bgCol = backgroundColor ?? theme.dividerColor;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background circle
          CustomPaint(
            size: Size(size, size),
            painter: _CircleProgressPainter(
              progress: progress,
              strokeWidth: strokeWidth,
              progressColor: progressCol,
              backgroundColor: bgCol,
            ),
          ),
          // Percentage text
          Text(
            '$progress%',
            style: textStyle ??
                TextStyle(
                  fontSize: size * 0.22,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
          ),
        ],
      ),
    );
  }
}

class _CircleProgressPainter extends CustomPainter {
  final int progress;
  final double strokeWidth;
  final Color progressColor;
  final Color backgroundColor;

  _CircleProgressPainter({
    required this.progress,
    required this.strokeWidth,
    required this.progressColor,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Background circle
    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, radius, bgPaint);

    // Progress arc
    final progressPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final sweepAngle = (progress / 100) * 2 * math.pi;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2, // Start from top
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _CircleProgressPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
