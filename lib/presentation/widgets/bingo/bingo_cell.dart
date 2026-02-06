import 'package:flutter/material.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';

/// Individual BINGO cell with dashed circle and "Add Goal" text
class BingoCell extends StatelessWidget {
  final int index;
  final String? goalTitle;
  final bool isCompleted;
  final bool isGrace; // Free space in the center
  final VoidCallback? onTap;

  const BingoCell({
    super.key,
    required this.index,
    this.goalTitle,
    this.isCompleted = false,
    this.isGrace = false,
    this.onTap,
  });

  bool get isEmpty => goalTitle == null || goalTitle!.isEmpty;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Grace cell (free space)
    if (isGrace) {
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.primary.withValues(alpha: 0.15),
              colorScheme.secondary.withValues(alpha: 0.1),
            ],
          ),
          border: Border.all(
            color: AppColors.bingoCellBorder,
            width: 1,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.star,
                color: colorScheme.primary,
                size: 32,
              ),
              const SizedBox(height: 4),
            ],
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.bingoCell,
          border: Border.all(
            color: AppColors.bingoCellBorder,
            width: 1,
          ),
        ),
        child: isEmpty ? _buildEmptyCell() : _buildFilledCell(),
      ),
    );
  }

  Widget _buildEmptyCell() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Dashed circle with plus icon
        CustomPaint(
          size: const Size(40, 40),
          painter: _DashedCirclePainter(
            color: AppColors.bingoCellDashed,
            strokeWidth: 1.5,
            dashLength: 4,
            gapLength: 3,
          ),
          child: const SizedBox(
            width: 40,
            height: 40,
            child: Center(
              child: Icon(
                Icons.add,
                color: AppColors.bingoCellDashed,
                size: 20,
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Add Goal',
          style: AppTypography.caption.copyWith(
            color: AppColors.bingoCellDashed,
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildFilledCell() {
    return Stack(
      children: [
        Center(
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Text(
              goalTitle!,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textPrimaryLight,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        if (isCompleted)
          Positioned(
            top: 4,
            right: 4,
            child: Icon(
              Icons.check_circle,
              color: AppColors.success,
              size: 16,
            ),
          ),
      ],
    );
  }
}

/// Custom painter for dashed circle
class _DashedCirclePainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double dashLength;
  final double gapLength;

  _DashedCirclePainter({
    required this.color,
    this.strokeWidth = 1.5,
    this.dashLength = 5,
    this.gapLength = 3,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    final circumference = 2 * 3.14159 * radius;
    final dashCount = (circumference / (dashLength + gapLength)).floor();

    for (int i = 0; i < dashCount; i++) {
      final startAngle = (i * (dashLength + gapLength) / radius);
      final sweepAngle = dashLength / radius;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
