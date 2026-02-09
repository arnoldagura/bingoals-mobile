import 'package:flutter/material.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../data/models/goal.dart';

class GoalCell extends StatelessWidget {
  final int index;
  final String? goalTitle;
  final GoalStatus status;
  final bool isGraceSquare;
  final int progress;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const GoalCell({
    super.key,
    required this.index,
    this.goalTitle,
    this.status = GoalStatus.notStarted,
    this.isGraceSquare = false,
    this.progress = 0,
    this.onTap,
    this.onLongPress,
  });

  bool get isEmpty => goalTitle == null || goalTitle!.isEmpty;

  @override
  Widget build(BuildContext context) {
    if (isGraceSquare) return _buildGraceSquare();

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        decoration: BoxDecoration(
          color: _backgroundColor,
          border: Border.all(
            color: _borderColor,
            width: 1,
          ),
        ),
        child: isEmpty ? _buildEmptyCell() : _buildFilledCell(),
      ),
    );
  }

  Color get _backgroundColor {
    if (isEmpty) return AppColors.goalCell;
    switch (status) {
      case GoalStatus.inProgress:
        return const Color(0xFFFFF7ED);
      case GoalStatus.completed:
        return const Color(0xFFF0FDF4);
      case GoalStatus.notStarted:
        return AppColors.goalCell;
    }
  }

  Color get _borderColor {
    if (isEmpty) return AppColors.goalCellBorder;
    switch (status) {
      case GoalStatus.inProgress:
        return const Color(0xFFFBBF24);
      case GoalStatus.completed:
        return AppColors.success;
      case GoalStatus.notStarted:
        return AppColors.goalCellBorder;
    }
  }

  Widget _buildEmptyCell() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CustomPaint(
          size: const Size(40, 40),
          painter: _DashedCirclePainter(
            color: AppColors.goalCellDashed,
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
                color: AppColors.goalCellDashed,
                size: 20,
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Add Goal',
          style: AppTypography.caption.copyWith(
            color: AppColors.goalCellDashed,
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
            padding: EdgeInsets.fromLTRB(6, 6, 6, progress > 0 ? 10 : 6),
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
        Positioned(
          top: 4,
          right: 4,
          child: _buildStatusIcon(),
        ),
        if (progress > 0 && progress < 100)
          Positioned(
            left: 4,
            right: 4,
            bottom: 4,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: progress / 100,
                minHeight: 3,
                backgroundColor: Colors.grey.shade200,
                color: const Color(0xFFFBBF24),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildStatusIcon() {
    switch (status) {
      case GoalStatus.inProgress:
        return const Icon(
          Icons.timelapse,
          color: Color(0xFFF59E0B),
          size: 16,
        );
      case GoalStatus.completed:
        return Icon(
          Icons.check_circle,
          color: AppColors.success,
          size: 16,
        );
      case GoalStatus.notStarted:
        return const SizedBox.shrink();
    }
  }

  Widget _buildGraceSquare() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.gold.withValues(alpha: 0.15),
            AppColors.gold.withValues(alpha: 0.25),
          ],
        ),
        border: Border.all(
          color: AppColors.gold.withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.auto_awesome,
            color: AppColors.gold,
            size: 20,
          ),
          const SizedBox(height: 4),
          Text(
            goalTitle ?? 'Grace',
            style: AppTypography.caption.copyWith(
              color: AppColors.gold,
              fontWeight: FontWeight.w600,
              fontSize: 10,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

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
