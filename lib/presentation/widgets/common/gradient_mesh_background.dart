import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Animated gradient mesh background matching the web design
class GradientMeshBackground extends StatefulWidget {
  final Widget child;
  final Color primaryColor;
  final Color accentColor;
  final Color backgroundColor;

  const GradientMeshBackground({
    super.key,
    required this.child,
    required this.primaryColor,
    required this.accentColor,
    required this.backgroundColor,
  });

  @override
  State<GradientMeshBackground> createState() => _GradientMeshBackgroundState();
}

class _GradientMeshBackgroundState extends State<GradientMeshBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 25),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            color: widget.backgroundColor,
          ),
          child: Stack(
            children: [
              // Animated gradient blobs
              Positioned.fill(
                child: CustomPaint(
                  painter: _GradientMeshPainter(
                    animation: _controller.value,
                    primaryColor: widget.primaryColor,
                    accentColor: widget.accentColor,
                  ),
                ),
              ),
              // Content
              child!,
            ],
          ),
        );
      },
      child: widget.child,
    );
  }
}

class _GradientMeshPainter extends CustomPainter {
  final double animation;
  final Color primaryColor;
  final Color accentColor;

  _GradientMeshPainter({
    required this.animation,
    required this.primaryColor,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Primary color blob - top left
    _drawBlob(
      canvas,
      Offset(
        size.width * (0.2 + 0.02 * math.sin(animation * 2 * math.pi)),
        size.height * (0.4 - 0.03 * math.cos(animation * 2 * math.pi)),
      ),
      size.width * 0.8,
      size.height * 0.5,
      primaryColor.withValues(alpha: 0.15),
    );

    // Accent color blob - top right
    _drawBlob(
      canvas,
      Offset(
        size.width * (0.8 - 0.02 * math.cos(animation * 2 * math.pi)),
        size.height * (0.2 + 0.03 * math.sin(animation * 2 * math.pi)),
      ),
      size.width * 0.6,
      size.height * 0.8,
      accentColor.withValues(alpha: 0.2),
    );

    // Primary color blob - bottom left
    _drawBlob(
      canvas,
      Offset(
        size.width * (0.4 + 0.01 * math.sin(animation * 2 * math.pi + 1)),
        size.height * (0.8 - 0.02 * math.cos(animation * 2 * math.pi + 1)),
      ),
      size.width * 0.5,
      size.height * 0.6,
      primaryColor.withValues(alpha: 0.1),
    );

    // Accent color blob - bottom right
    _drawBlob(
      canvas,
      Offset(
        size.width * (0.7 - 0.01 * math.cos(animation * 2 * math.pi + 2)),
        size.height * (0.7 + 0.02 * math.sin(animation * 2 * math.pi + 2)),
      ),
      size.width * 0.7,
      size.height * 0.4,
      accentColor.withValues(alpha: 0.12),
    );
  }

  void _drawBlob(Canvas canvas, Offset center, double width, double height, Color color) {
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [color, color.withValues(alpha: 0)],
        stops: const [0.0, 1.0],
      ).createShader(
        Rect.fromCenter(
          center: center,
          width: width,
          height: height,
        ),
      )
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 50);

    canvas.drawOval(
      Rect.fromCenter(center: center, width: width, height: height),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _GradientMeshPainter oldDelegate) {
    return oldDelegate.animation != animation;
  }
}

/// Simple wrapper for screens that need the gradient mesh background
class GradientMeshScaffold extends StatelessWidget {
  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? floatingActionButton;

  const GradientMeshScaffold({
    super.key,
    required this.body,
    this.appBar,
    this.floatingActionButton,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      extendBodyBehindAppBar: true,
      appBar: appBar,
      floatingActionButton: floatingActionButton,
      body: GradientMeshBackground(
        primaryColor: colorScheme.primary,
        accentColor: colorScheme.secondary,
        backgroundColor: theme.scaffoldBackgroundColor,
        child: body,
      ),
    );
  }
}
