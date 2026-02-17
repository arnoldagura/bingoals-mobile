import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/typography.dart';
import '../../../data/models/app_notification.dart';
import '../../../data/providers/notifications_provider.dart';
import '../../widgets/common/gradient_mesh_background.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final notifsAsync = ref.watch(notificationsProvider);
    final actions = ref.read(notificationActionsProvider);

    return GradientMeshScaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => context.pop(),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text('Notifications',
                        style: AppTypography.headlineMedium.copyWith(
                          color: colorScheme.onSurface,
                        )),
                  ),
                  TextButton(
                    onPressed: () => actions.markAllRead(),
                    child: const Text('Mark all read'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: notifsAsync.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (_, __) => Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline, size: 48),
                      const SizedBox(height: 12),
                      Text('Failed to load notifications',
                          style: AppTypography.bodyMedium),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: () =>
                            ref.invalidate(notificationsProvider),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
                data: (page) {
                  if (page.notifications.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.notifications_none,
                              size: 64,
                              color: colorScheme.onSurface
                                  .withValues(alpha: 0.2)),
                          const SizedBox(height: 16),
                          Text(
                            'No notifications yet',
                            style: AppTypography.bodyMedium.copyWith(
                              color: colorScheme.onSurface
                                  .withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: page.notifications.length,
                    itemBuilder: (context, index) {
                      final notif = page.notifications[index];
                      return _NotificationTile(
                        notification: notif,
                        onTap: () {
                          if (!notif.read) {
                            actions.markRead(notif.id);
                          }
                          _handleNotificationTap(context, notif);
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleNotificationTap(
      BuildContext context, AppNotification notif) {
    if (notif.metadata == null) return;
    try {
      final meta = jsonDecode(notif.metadata!) as Map<String, dynamic>;
      final boardId = meta['boardId'] as String?;
      if (boardId != null) {
        context.push('/board/$boardId');
      }
    } catch (_) {}
  }
}

class _NotificationTile extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback? onTap;

  const _NotificationTile({
    required this.notification,
    this.onTap,
  });

  IconData get _icon {
    switch (notification.type) {
      case 'goal_completed':
        return Icons.check_circle_outline;
      case 'reaction_received':
        return Icons.favorite_outline;
      case 'member_joined':
        return Icons.person_add_outlined;
      case 'board_invite':
        return Icons.mail_outline;
      default:
        return Icons.notifications_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final diff = DateTime.now().difference(notification.createdAt);
    final ago = diff.inDays > 0
        ? '${diff.inDays}d ago'
        : diff.inHours > 0
            ? '${diff.inHours}h ago'
            : diff.inMinutes > 0
                ? '${diff.inMinutes}m ago'
                : 'Just now';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: notification.read
              ? Colors.transparent
              : colorScheme.primary.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: notification.read
                ? colorScheme.outline.withValues(alpha: 0.1)
                : colorScheme.primary.withValues(alpha: 0.15),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(_icon, size: 18, color: colorScheme.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.title,
                    style: AppTypography.bodyMedium.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight:
                          notification.read ? FontWeight.normal : FontWeight.w600,
                    ),
                  ),
                  if (notification.body.isNotEmpty)
                    Text(
                      notification.body,
                      style: AppTypography.bodySmall.copyWith(
                        color:
                            colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 4),
                  Text(
                    ago,
                    style: AppTypography.caption.copyWith(
                      color:
                          colorScheme.onSurface.withValues(alpha: 0.4),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            if (!notification.read)
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(top: 6),
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
