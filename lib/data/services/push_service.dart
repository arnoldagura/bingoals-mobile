import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:logger/logger.dart';

/// Handles FCM token management and foreground notification display.
/// Singleton — access via [PushService.instance].
class PushService {
  PushService._();
  static final instance = PushService._();

  final _log = Logger(printer: PrettyPrinter(methodCount: 0));
  final _messaging = FirebaseMessaging.instance;
  final _localNotifications = FlutterLocalNotificationsPlugin();

  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  /// Called once from main(). Requests permission, grabs token,
  /// and sets up foreground display.
  Future<void> init() async {
    // Request permission (iOS prompts user, Android auto-grants)
    await _messaging.requestPermission();

    // Get current token
    _fcmToken = await _messaging.getToken();
    _log.i('FCM token: $_fcmToken');

    // Listen for token refresh
    _messaging.onTokenRefresh.listen((token) {
      _fcmToken = token;
      _onTokenRefresh?.call(token);
    });

    // Setup foreground notification display
    await _initLocalNotifications();

    // Show notification when app is in foreground
    FirebaseMessaging.onMessage.listen(_showForegroundNotification);
  }

  // --- Token refresh callback (set by auth provider) ---

  void Function(String token)? _onTokenRefresh;

  void setTokenRefreshCallback(void Function(String token)? callback) {
    _onTokenRefresh = callback;
  }

  // --- Local notifications for foreground display ---

  Future<void> _initLocalNotifications() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iOS = DarwinInitializationSettings();
    const settings = InitializationSettings(android: android, iOS: iOS);

    await _localNotifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    // Android notification channel
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(
          const AndroidNotificationChannel(
            'default',
            'Default',
            importance: Importance.high,
          ),
        );
  }

  void _showForegroundNotification(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'default',
          'Default',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      payload: jsonEncode(message.data),
    );
  }

  void _onNotificationTap(NotificationResponse response) {
    // Navigation handled via GoRouter — could deeplink in future
    _log.d('Notification tapped: ${response.payload}');
  }
}
