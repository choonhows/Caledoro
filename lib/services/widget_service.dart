import 'package:home_widget/home_widget.dart';

class WidgetService {
  static DateTime? _lastUpdateAt;
  static int? _lastSecondsRemaining;
  static bool? _lastIsWorking;
  static int? _lastCompletedTasks;

  static Future<void> updateWidgets({
    required int secondsRemaining,
    required bool isWorking,
    required int completedTasks,
    bool force = false,
  }) async {
    final now = DateTime.now();
    final phaseChanged = _lastIsWorking != null && _lastIsWorking != isWorking;
    final completedChanged =
        _lastCompletedTasks != null && _lastCompletedTasks != completedTasks;
    final reachedMinuteBoundary =
        _lastSecondsRemaining != null && secondsRemaining % 60 == 0;
    final periodicCheckpoint =
        _lastUpdateAt == null || now.difference(_lastUpdateAt!).inSeconds >= 30;

    if (!force &&
        !phaseChanged &&
        !completedChanged &&
        !reachedMinuteBoundary &&
        !periodicCheckpoint) {
      return;
    }

    await HomeWidget.saveWidgetData<int>('secondsRemaining', secondsRemaining);
    await HomeWidget.saveWidgetData<bool>('isWorking', isWorking);
    await HomeWidget.saveWidgetData<int>('completedTasks', completedTasks);
    await HomeWidget.updateWidget(name: 'CaledoroWidgetProvider');

    _lastUpdateAt = now;
    _lastSecondsRemaining = secondsRemaining;
    _lastIsWorking = isWorking;
    _lastCompletedTasks = completedTasks;
  }
}
