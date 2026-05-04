import 'dart:io';

import 'package:caledoro/models/task_model.dart';
import 'package:caledoro/models/settings_model.dart';
import 'package:caledoro/services/hive_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

Future<void> initTestHive() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  final dir = await Directory.systemTemp.createTemp('caledoro_test_');
  Hive.init(dir.path);

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

  await Hive.openBox<TaskModel>(HiveService.tasksBoxName);
  await Hive.openBox<SettingsModel>(HiveService.settingsBoxName);
  await Hive.openBox<Map>(HiveService.widgetBoxName);

  final settingsBox = Hive.box<SettingsModel>(HiveService.settingsBoxName);
  await settingsBox.put('settings', SettingsModel());
}

Future<void> resetTestHive() async {
  await HiveService.tasksBox().clear();
  await HiveService.settingsBox().clear();
  await HiveService.settingsBox().put('settings', SettingsModel());
  await HiveService.widgetBox().clear();
}

Future<void> disposeTestHive() async {
  await Hive.close();
}
