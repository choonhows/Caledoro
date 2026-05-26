import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static const int _timerNotificationId = 1001;
  static const String _timerChannelId = 'pomodoro_timer_channel';
  static const String _timerChannelName = 'Pomodoro Timer';
  static const String _timerChannelDescription =
      'Live pomodoro timer updates';

  static Future<void> init() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwin = DarwinInitializationSettings();
    const settings = InitializationSettings(android: android, iOS: darwin);

    await _plugin.initialize(
      settings: settings,
    );

    const channel = AndroidNotificationChannel(
      'pomodoro_channel',
      'Pomodoro Notifications',
      description: 'Pomodoro timer completion updates',
      importance: Importance.defaultImportance,
    );
    const timerChannel = AndroidNotificationChannel(
      _timerChannelId,
      _timerChannelName,
      description: _timerChannelDescription,
      importance: Importance.low,
    );
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(timerChannel);

    await _requestPermissions();
  }

  static Future<void> _requestPermissions() async {
    try {
      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
      await _plugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
      await _plugin
          .resolvePlatformSpecificImplementation<
              MacOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    } catch (e) {
      debugPrint('Notification permission request failed: $e');
    }
  }

  static Future<bool> isAuthorized() async {
    try {
      final android = await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.areNotificationsEnabled();
      if (android != null) return android;

      final ios = await _plugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: false, badge: false, sound: false);
      if (ios != null) return ios;

      final macos = await _plugin
          .resolvePlatformSpecificImplementation<
              MacOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: false, badge: false, sound: false);
      if (macos != null) return macos;
    } catch (_) {
      // Plugin may be unavailable in widget/unit tests before app init.
    }
    return false;
  }

  static Future<void> requestPermissions() async {
    await _requestPermissions();
  }

  static Future<void> showPhaseNotification({
    required String title,
    required String body,
  }) async {
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'pomodoro_channel',
        'Pomodoro Notifications',
        channelDescription: 'Pomodoro timer completion updates',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
      ),
      iOS: DarwinNotificationDetails(),
    );

    try {
      await _plugin.show(
        id: 0,
        title: title,
        body: body,
        notificationDetails: details,
      );
    } catch (e) {
      debugPrint('Notification failure: $e');
    }
  }

  static Future<void> showOngoingTimerNotification({
    required String title,
    required String body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      _timerChannelId,
      _timerChannelName,
      channelDescription: _timerChannelDescription,
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true,
      autoCancel: false,
      onlyAlertOnce: true,
      showWhen: false,
      icon: 'ic_launcher',
      enableVibration: false,
      playSound: false,
    );
    const details = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentSound: false,
        presentBadge: false,
      ),
    );

    try {
      await _plugin.show(
        id: _timerNotificationId,
        title: title,
        body: body,
        notificationDetails: details,
      );
    } catch (e) {
      debugPrint('Timer notification failure: $e');
    }
  }

  static Future<void> cancelTimerNotification() async {
    try {
      await _plugin.cancel(id: _timerNotificationId);
    } catch (e) {
      debugPrint('Timer notification cancel failed: $e');
    }
  }
}
