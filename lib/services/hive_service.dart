import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/task_model.dart';
import '../models/settings_model.dart';
import '../models/pomodoro_timer_model.dart';

class HiveService {
  static const tasksBoxName = 'tasksBox';
  static const settingsBoxName = 'settingsBox';
  static const widgetBoxName = 'widgetBox';
  static const timerBoxName = 'timerBox';

  static Future<void> init() async {
    try {
      await Hive.initFlutter();
    } catch (e) {
      debugPrint('Hive Flutter init failed: $e. Using fallback path.');
      final fallbackPath = '${Directory.current.path}/hive_data';
      try {
        Directory(fallbackPath).createSync(recursive: true);
        if (Platform.isLinux || Platform.isMacOS) {
          await Process.run('chmod', ['700', fallbackPath]);
        }
        Hive.init(fallbackPath);
      } catch (fallbackError) {
        debugPrint(
            'ERROR: Hive initialization failed completely: $fallbackError');
        rethrow;
      }
    }

    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(TaskPriorityAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(TaskModelAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(SettingsModelAdapter());
    }
    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(SubtaskCreatorAdapter());
    }
    if (!Hive.isAdapterRegistered(4)) {
      Hive.registerAdapter(SubtaskModelAdapter());
    }
    if (!Hive.isAdapterRegistered(5)) {
      Hive.registerAdapter(TaskSortModeAdapter());
    }
    if (!Hive.isAdapterRegistered(6)) {
      Hive.registerAdapter(PomodoroTimerModelAdapter());
    }

    await Hive.openBox<TaskModel>(tasksBoxName);
    await Hive.openBox<SettingsModel>(settingsBoxName);
    await Hive.openBox<Map>(widgetBoxName);
    await Hive.openBox<PomodoroTimerModel>(timerBoxName);

    final settingsBox = Hive.box<SettingsModel>(settingsBoxName);
    if (settingsBox.isEmpty) {
      await settingsBox.put('settings', SettingsModel());
    }
  }

  static Box<TaskModel> tasksBox() => Hive.box<TaskModel>(tasksBoxName);
  static Box<SettingsModel> settingsBox() =>
      Hive.box<SettingsModel>(settingsBoxName);
  static Box<Map> widgetBox() => Hive.box<Map>(widgetBoxName);
  static Box<PomodoroTimerModel> timerBox() =>
      Hive.box<PomodoroTimerModel>(timerBoxName);
}
