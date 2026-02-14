import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/theme/typography.dart';
import '../../../data/models/goal.dart';

class GoalCell extends StatelessWidget {
  final int index;
  final String? goalTitle;
  final GoalStatus status;
  final int progress;
  final String? icon;
  final String? imageUrl;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const GoalCell({
    super.key,
    required this.index,
    this.goalTitle,
    this.status = GoalStatus.notStarted,
    this.progress = 0,
    this.icon,
    this.imageUrl,
    this.onTap,
    this.onLongPress,
  });

  bool get isEmpty => goalTitle == null || goalTitle!.isEmpty;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        decoration: BoxDecoration(
          color: _backgroundColor(colorScheme),
          border: Border.all(
            color: colorScheme.outline.withValues(alpha: 0.15),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: isEmpty
            ? _buildEmptyCell(colorScheme)
            : _buildFilledCell(colorScheme),
      ),
    );
  }

  Color _backgroundColor(ColorScheme cs) {
    if (isEmpty) return cs.surfaceContainerHighest;
    switch (status) {
      case GoalStatus.inProgress:
        return cs.tertiaryContainer;
      case GoalStatus.completed:
        if (imageUrl != null && imageUrl!.isNotEmpty) return Colors.transparent;
        return cs.primaryContainer;
      case GoalStatus.notStarted:
        return cs.surfaceContainerHighest;
    }
  }

  Widget _buildEmptyCell(ColorScheme cs) {
    return Center(
      child: Icon(
        Icons.add_rounded,
        color: cs.onSurface.withValues(alpha: 0.2),
        size: 24,
      ),
    );
  }

  Widget _buildFilledCell(ColorScheme cs) {
    if (status == GoalStatus.completed &&
        imageUrl != null &&
        imageUrl!.isNotEmpty) {
      return _buildPhotoCell(cs);
    }
    if (status == GoalStatus.completed && icon != null && icon!.isNotEmpty) {
      return _buildIconCell(cs);
    }
    return _buildTextCell(cs);
  }

  Widget _buildPhotoCell(ColorScheme cs) {
    final fullUrl = imageUrl!.startsWith('http')
        ? imageUrl!
        : '${ApiConstants.baseUrl}$imageUrl';
    return Stack(
      fit: StackFit.expand,
      children: [
        CachedNetworkImage(
          imageUrl: fullUrl,
          fit: BoxFit.cover,
          placeholder: (_, __) =>
              Container(color: cs.primaryContainer),
          errorWidget: (_, __, ___) => Container(
            color: cs.primaryContainer,
            child: Icon(Icons.check_circle,
                color: cs.primary, size: 24),
          ),
        ),
        // Gradient overlay for text
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            padding: const EdgeInsets.fromLTRB(4, 14, 4, 5),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black54],
              ),
            ),
            child: Text(
              goalTitle!,
              style: AppTypography.caption.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 9,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        // Checkmark badge
        Positioned(
          top: 4,
          right: 4,
          child: Container(
            padding: const EdgeInsets.all(1),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child:
                Icon(Icons.check_circle, color: cs.primary, size: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildIconCell(ColorScheme cs) {
    return Stack(
      children: [
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(icon!, style: const TextStyle(fontSize: 28)),
              const SizedBox(height: 2),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  goalTitle!,
                  style: AppTypography.caption.copyWith(
                    color: cs.onPrimaryContainer,
                    fontWeight: FontWeight.w600,
                    fontSize: 9,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: Icon(Icons.check_circle, color: cs.primary, size: 14),
        ),
      ],
    );
  }

  Widget _buildTextCell(ColorScheme cs) {
    return Stack(
      children: [
        Center(
          child: Padding(
            padding: EdgeInsets.fromLTRB(6, 6, 6, progress > 0 ? 12 : 6),
            child: Text(
              goalTitle!,
              style: AppTypography.bodySmall.copyWith(
                color: status == GoalStatus.completed
                    ? cs.onPrimaryContainer
                    : cs.onSurface,
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
          child: _buildStatusIcon(cs),
        ),
        if (progress > 0 && progress < 100)
          Positioned(
            left: 4,
            right: 4,
            bottom: 4,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress / 100,
                minHeight: 4,
                backgroundColor: cs.outline.withValues(alpha: 0.2),
                color: cs.tertiary,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildStatusIcon(ColorScheme cs) {
    switch (status) {
      case GoalStatus.inProgress:
        return Icon(Icons.timelapse, color: cs.tertiary, size: 16);
      case GoalStatus.completed:
        return Icon(Icons.check_circle, color: cs.primary, size: 16);
      case GoalStatus.notStarted:
        return const SizedBox.shrink();
    }
  }

}
