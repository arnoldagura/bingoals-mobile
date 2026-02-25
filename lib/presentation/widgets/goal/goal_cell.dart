import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/theme/typography.dart';
import '../../../data/models/goal.dart';

class GoalCell extends StatefulWidget {
  final int index;
  final String? goalTitle;
  final GoalStatus status;
  final int progress;
  final String? icon;
  final String? imageUrl;
  final int commentCount;
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
    this.commentCount = 0,
    this.onTap,
    this.onLongPress,
  });

  @override
  State<GoalCell> createState() => _GoalCellState();
}

class _GoalCellState extends State<GoalCell>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      reverseDuration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.93).animate(
      CurvedAnimation(
        parent: _scaleController,
        curve: Curves.easeInOut,
        reverseCurve: Curves.elasticOut,
      ),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  bool get isEmpty => widget.goalTitle == null || widget.goalTitle!.isEmpty;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTapDown: (_) => _scaleController.forward(),
      onTapUp: (_) {
        _scaleController.reverse();
        widget.onTap?.call();
      },
      onTapCancel: () => _scaleController.reverse(),
      onLongPress: () {
        _scaleController.reverse();
        widget.onLongPress?.call();
      },
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) =>
            Transform.scale(scale: _scaleAnimation.value, child: child),
        child: Container(
          decoration: BoxDecoration(
            color: _backgroundColor(colorScheme),
            border: Border.all(
              color: colorScheme.outline.withValues(alpha: 0.15),
              width: 1,
            ),
            borderRadius: BorderRadius.circular(10),
            boxShadow: widget.status == GoalStatus.completed && !isEmpty
                ? [
                    BoxShadow(
                      color: colorScheme.primary.withValues(alpha: 0.25),
                      blurRadius: 12,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          clipBehavior: Clip.antiAlias,
          child: isEmpty
              ? _buildEmptyCell(colorScheme)
              : _buildFilledCell(colorScheme),
        ),
      ),
    );
  }

  Color _backgroundColor(ColorScheme cs) {
    if (isEmpty) return cs.surfaceContainerHighest;
    switch (widget.status) {
      case GoalStatus.inProgress:
        // Subtle primary tint — distinct from not-started without being dark
        return cs.primary.withValues(alpha: 0.08);
      case GoalStatus.completed:
        if (widget.imageUrl != null && widget.imageUrl!.isNotEmpty) {
          return Colors.transparent;
        }
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
    if (widget.status == GoalStatus.completed &&
        widget.imageUrl != null &&
        widget.imageUrl!.isNotEmpty) {
      return _buildPhotoCell(cs);
    }
    if (widget.status == GoalStatus.completed &&
        widget.icon != null &&
        widget.icon!.isNotEmpty) {
      return _buildIconCell(cs);
    }
    return _buildTextCell(cs);
  }

  Widget _buildPhotoCell(ColorScheme cs) {
    final fullUrl = widget.imageUrl!.startsWith('http')
        ? widget.imageUrl!
        : '${ApiConstants.baseUrl}${widget.imageUrl}';
    return Stack(
      fit: StackFit.expand,
      children: [
        CachedNetworkImage(
          imageUrl: fullUrl,
          fit: BoxFit.cover,
          placeholder: (_, _) => Container(color: cs.primaryContainer),
          errorWidget: (_, _, _) => Container(
            color: cs.primaryContainer,
            child: Icon(Icons.check_circle, color: cs.primary, size: 24),
          ),
        ),
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
              widget.goalTitle!,
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
        Positioned(
          top: 4,
          right: 4,
          child: Container(
            padding: const EdgeInsets.all(1),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.check_circle, color: cs.primary, size: 14),
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
              Text(widget.icon!, style: const TextStyle(fontSize: 28)),
              const SizedBox(height: 2),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  widget.goalTitle!,
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
        if (widget.commentCount > 0)
          Positioned(
            bottom: 3,
            right: 3,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.chat_bubble_outline,
                  size: 8,
                  color: cs.onPrimaryContainer.withValues(alpha: 0.5),
                ),
                const SizedBox(width: 2),
                Text(
                  '${widget.commentCount}',
                  style: TextStyle(
                    fontSize: 7,
                    color: cs.onPrimaryContainer.withValues(alpha: 0.5),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildTextCell(ColorScheme cs) {
    return Stack(
      children: [
        Center(
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Text(
              widget.goalTitle!,
              style: AppTypography.bodySmall.copyWith(
                color: widget.status == GoalStatus.completed
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
        Positioned(top: 3, right: 3, child: _buildStatusIndicator(cs)),
        // Long-press hint for not-started goals
        if (widget.status == GoalStatus.notStarted &&
            widget.onLongPress != null)
          Positioned(
            bottom: 3,
            left: 3,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.touch_app,
                  size: 8,
                  color: cs.onSurface.withValues(alpha: 0.3),
                ),
                const SizedBox(width: 1),
                Text(
                  'hold',
                  style: TextStyle(
                    fontSize: 7,
                    color: cs.onSurface.withValues(alpha: 0.3),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        // Comment count badge
        if (widget.commentCount > 0)
          Positioned(
            bottom: 3,
            right: 3,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.chat_bubble_outline,
                  size: 8,
                  color: cs.onSurface.withValues(alpha: 0.4),
                ),
                const SizedBox(width: 2),
                Text(
                  '${widget.commentCount}',
                  style: TextStyle(
                    fontSize: 7,
                    color: cs.onSurface.withValues(alpha: 0.4),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        if (widget.status == GoalStatus.inProgress)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(10),
              ),
              child: LinearProgressIndicator(
                value: widget.progress / 100,
                minHeight: 3,
                backgroundColor: cs.onSurface.withValues(alpha: 0.08),
                valueColor: AlwaysStoppedAnimation<Color>(cs.primary),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildStatusIndicator(ColorScheme cs) {
    switch (widget.status) {
      case GoalStatus.inProgress:
        return SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            value: widget.progress / 100,
            strokeWidth: 3,
            strokeCap: StrokeCap.round,
            backgroundColor: cs.onSurface.withValues(alpha: 0.12),
            color: cs.primary,
          ),
        );
      case GoalStatus.completed:
        return Icon(Icons.check_circle, color: cs.primary, size: 16);
      case GoalStatus.notStarted:
        return const SizedBox.shrink();
    }
  }
}
