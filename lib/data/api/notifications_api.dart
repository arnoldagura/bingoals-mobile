import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/api_constants.dart';
import '../models/app_notification.dart';
import 'api_client.dart';

final notificationsApiProvider = Provider<NotificationsApi>((ref) {
  return NotificationsApi(ref.watch(apiClientProvider));
});

class NotificationsApi {
  final Dio _dio;

  NotificationsApi(this._dio);

  Future<NotificationPage> getNotifications({int page = 1, int limit = 20}) async {
    final response = await _dio.get(
      ApiConstants.notifications,
      queryParameters: {'page': page, 'limit': limit},
    );
    return NotificationPage.fromJson(response.data);
  }

  Future<void> markRead(String id) async {
    await _dio.put(ApiConstants.markNotificationRead(id));
  }

  Future<void> markAllRead() async {
    await _dio.post(ApiConstants.markAllNotificationsRead);
  }

  Future<void> registerDeviceToken(String token) async {
    await _dio.post(ApiConstants.deviceToken, data: {'token': token});
  }
}
