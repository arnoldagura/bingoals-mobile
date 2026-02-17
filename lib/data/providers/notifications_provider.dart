import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/notifications_api.dart';
import '../models/app_notification.dart';

final notificationsProvider = FutureProvider<NotificationPage>((ref) async {
  final api = ref.watch(notificationsApiProvider);
  return api.getNotifications();
});

final unreadCountProvider = Provider<int>((ref) {
  final notifs = ref.watch(notificationsProvider);
  return notifs.when(
    data: (page) => page.unread,
    loading: () => 0,
    error: (_, __) => 0,
  );
});

final notificationActionsProvider = Provider<NotificationActions>((ref) {
  return NotificationActions(ref);
});

class NotificationActions {
  final Ref _ref;

  NotificationActions(this._ref);

  NotificationsApi get _api => _ref.read(notificationsApiProvider);

  Future<void> markRead(String id) async {
    await _api.markRead(id);
    _ref.invalidate(notificationsProvider);
  }

  Future<void> markAllRead() async {
    await _api.markAllRead();
    _ref.invalidate(notificationsProvider);
  }
}
