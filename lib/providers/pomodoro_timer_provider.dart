import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../models/pomodoro_phase.dart';
import '../models/pomodoro_timer_model.dart';
import '../services/hive_service.dart';
import '../services/widget_service.dart';
import 'settings_provider.dart';

final pomodoroTimerProvider = NotifierProvider<PomodoroTimerNotifier, PomodoroTimerModel>(
  PomodoroTimerNotifier.new,
);

class PomodoroTimerNotifier extends Notifier<PomodoroTimerModel> {
  Timer? _timer;
  late Box<PomodoroTimerModel> _box;

  @override
  PomodoroTimerModel build() {
    _box = HiveService.timerBox();
    ref.onDispose(() {
      _timer?.cancel();
    });
    final saved = _box.get('timer');
    if (saved != null) {
      // Restore and check if we need to auto-start or adjust based on time passed
      // For simplicity, just load it; you could add logic to handle elapsed time
      return saved;
    }
    return PomodoroTimerModel();
  }

  int _phaseDurationSeconds(PomodoroPhase phase) {
    final settings = ref.read(settingsProvider);
    return switch (phase) {
      PomodoroPhase.work => settings.workMinutes * 60,
      PomodoroPhase.shortBreak => settings.shortBreakMinutes * 60,
      PomodoroPhase.longBreak => settings.longBreakMinutes * 60,
    };
  }

  void toggleTimer() {
    if (state.isRunning) {
      _pauseTimer();
    } else {
      _startTimer();
    }
  }

  void _startTimer() {
    state = state.copyWith(isRunning: true);
    _saveState();
    WidgetService.updateWidgets(
      secondsRemaining: state.remainingSeconds,
      isWorking: state.phase == PomodoroPhase.work,
      completedTasks: state.completedPomodoros,
      force: true,
    );
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.remainingSeconds > 0) {
        state = state.copyWith(remainingSeconds: state.remainingSeconds - 1);
        _saveState();
        WidgetService.updateWidgets(
          secondsRemaining: state.remainingSeconds,
          isWorking: state.phase == PomodoroPhase.work,
          completedTasks: state.completedPomodoros,
        );
      } else {
        _handlePhaseCompletion();
      }
    });
  }

  void _pauseTimer() {
    _timer?.cancel();
    state = state.copyWith(isRunning: false);
    _saveState();
    WidgetService.updateWidgets(
      secondsRemaining: state.remainingSeconds,
      isWorking: state.phase == PomodoroPhase.work,
      completedTasks: state.completedPomodoros,
      force: true,
    );
  }

  void skipPhase() {
    _timer?.cancel();
    final newPhase = _nextPhase();
    final newRemaining = _phaseDurationSeconds(newPhase);
    state = state.copyWith(
      phase: newPhase,
      remainingSeconds: newRemaining,
      completedPomodoros: newPhase == PomodoroPhase.work ? state.completedPomodoros : state.completedPomodoros + 1,
      isRunning: false,
    );
    _saveState();
    WidgetService.updateWidgets(
      secondsRemaining: state.remainingSeconds,
      isWorking: state.phase == PomodoroPhase.work,
      completedTasks: state.completedPomodoros,
      force: true,
    );
  }

  PomodoroPhase _nextPhase() {
    final settings = ref.read(settingsProvider);
    if (state.phase == PomodoroPhase.work) {
      final newCompleted = state.completedPomodoros + 1;
      if (newCompleted % settings.pomodorosUntilLongBreak == 0) {
        return PomodoroPhase.longBreak;
      } else {
        return PomodoroPhase.shortBreak;
      }
    } else {
      return PomodoroPhase.work;
    }
  }

  void _handlePhaseCompletion() {
    _timer?.cancel();
    final newPhase = _nextPhase();
    final newRemaining = _phaseDurationSeconds(newPhase);
    state = state.copyWith(
      phase: newPhase,
      remainingSeconds: newRemaining,
      completedPomodoros: newPhase == PomodoroPhase.work ? state.completedPomodoros : state.completedPomodoros + 1,
      isRunning: false,
    );
    _saveState();
    WidgetService.updateWidgets(
      secondsRemaining: state.remainingSeconds,
      isWorking: state.phase == PomodoroPhase.work,
      completedTasks: state.completedPomodoros,
      force: true,
    );
    // Auto-start next if enabled
    if (ref.read(settingsProvider).autoStartNext) {
      _startTimer();
    }
  }

  void _saveState() {
    _box.put('timer', state);
  }

}
