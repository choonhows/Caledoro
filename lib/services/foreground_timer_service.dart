import 'dart:io';

import 'package:flutter_foreground_task/flutter_foreground_task.dart';

class ForegroundTimerService {
  static const int _serviceId = 256;
  static const String _channelId = 'pomodoro_foreground_timer';
  static const String _channelName = 'Pomodoro Timer';

  static void init() {
    FlutterForegroundTask.initCommunicationPort();
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: _channelId,
        channelName: _channelName,
        channelDescription: 'Foreground timer updates',
        onlyAlertOnce: true,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: false,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.nothing(),
        allowWakeLock: true,
      ),
    );
  }

  static Future<void> requestPermissions() async {
    final permission = await FlutterForegroundTask.checkNotificationPermission();
    if (permission != NotificationPermission.granted) {
      await FlutterForegroundTask.requestNotificationPermission();
    }

    if (Platform.isAndroid) {
      if (!await FlutterForegroundTask.isIgnoringBatteryOptimizations) {
        await FlutterForegroundTask.requestIgnoreBatteryOptimization();
      }
    }
  }

  static Future<void> start({
    required String title,
    required String text,
  }) async {
    if (await FlutterForegroundTask.isRunningService) {
      await FlutterForegroundTask.updateService(
        notificationTitle: title,
        notificationText: text,
        notificationIcon: const NotificationIcon(
          metaDataName: 'com.caledoro.foreground_timer_icon',
        ),
      );
      return;
    }

    await FlutterForegroundTask.startService(
      serviceId: _serviceId,
      notificationTitle: title,
      notificationText: text,
      notificationIcon: const NotificationIcon(
        metaDataName: 'com.caledoro.foreground_timer_icon',
      ),
    );
  }

  static Future<void> update({
    required String title,
    required String text,
  }) async {
    if (!await FlutterForegroundTask.isRunningService) return;
    await FlutterForegroundTask.updateService(
      notificationTitle: title,
      notificationText: text,
      notificationIcon: const NotificationIcon(
        metaDataName: 'com.caledoro.foreground_timer_icon',
      ),
    );
  }

  static Future<void> stop() async {
    if (!await FlutterForegroundTask.isRunningService) return;
    await FlutterForegroundTask.stopService();
  }
}
