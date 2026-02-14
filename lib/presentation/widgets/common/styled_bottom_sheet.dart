import 'package:flutter/material.dart';
import '../../../core/theme/typography.dart';

/// Shows a modern bottom sheet with drag handle, rounded corners,
/// and keyboard-aware padding.
Future<T?> showStyledBottomSheet<T>({
  required BuildContext context,
  required Widget Function(BuildContext) builder,
  bool isScrollControlled = true,
  bool isDismissible = true,
  bool enableDrag = true,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    isDismissible: isDismissible,
    enableDrag: enableDrag,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(sheetContext).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: Theme.of(sheetContext).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
        ),
        child: builder(sheetContext),
      ),
    ),
  );
}

/// Content wrapper for styled bottom sheets.
/// Provides drag handle, optional title with close button, and padding.
class StyledBottomSheetContent extends StatelessWidget {
  final String? title;
  final bool showClose;
  final bool showDragHandle;
  final Widget child;
  final EdgeInsetsGeometry? padding;

  const StyledBottomSheetContent({
    super.key,
    this.title,
    this.showClose = false,
    this.showDragHandle = true,
    required this.child,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showDragHandle)
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 4),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.onSurface.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        if (title != null || showClose)
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title ?? '',
                    style: AppTypography.headlineSmall.copyWith(
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
                if (showClose)
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(
                      Icons.close_rounded,
                      color: colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
          ),
        Flexible(
          child: Padding(
            padding: padding ?? const EdgeInsets.all(24),
            child: child,
          ),
        ),
      ],
    );
  }
}
