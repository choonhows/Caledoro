import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../models/pomodoro_phase.dart';
import '../models/pomodoro_timer_model.dart';
import '../services/hive_service.dart';
import '../services/foreground_timer_service.dart';
import '../services/notification_service.dart';
import '../services/widget_service.dart';
import 'settings_provider.dart';

final pomodoroTimerProvider =
    NotifierProvider<PomodoroTimerNotifier, PomodoroTimerModel>(
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

  void _updateWidgets({bool force = false}) {
    WidgetService.updateWidgets(
      secondsRemaining: state.remainingSeconds,
      isWorking: state.phase == PomodoroPhase.work,
      completedTasks: state.completedPomodoros,
      force: force,
    );
  }

  void toggleTimer() {
    if (state.isRunning) {
      _pauseTimer();
    } else {
      _startTimer();
    }
  }

  void _startTimer() {
    _timer?.cancel();
    state = state.copyWith(isRunning: true);
    _saveState();
    _updateWidgets(force: true);
    _ensureForegroundService();
    _updateOngoingNotification();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.remainingSeconds > 0) {
        state = state.copyWith(remainingSeconds: state.remainingSeconds - 1);
        _saveState();
        _updateWidgets();
        if (state.remainingSeconds % 1 == 0) {
          _updateOngoingNotification();
          _updateForegroundService();
        }
      } else {
        _handlePhaseCompletion();
      }
    });
  }

  void _pauseTimer() {
    _timer?.cancel();
    state = state.copyWith(isRunning: false);
    _saveState();
    _updateWidgets(force: true);
    NotificationService.cancelTimerNotification();
    ForegroundTimerService.stop();
  }

  void skipPhase() {
    _transitionToNextPhase(autoStart: false);
  }

  void _transitionToNextPhase({required bool autoStart}) {
    _timer?.cancel();
    final newPhase = _nextPhase();
    final completedPhase = state.phase;
    final newRemaining = _phaseDurationSeconds(newPhase);
    final completedPomodoros = newPhase == PomodoroPhase.work
        ? state.completedPomodoros
        : state.completedPomodoros + 1;
    state = state.copyWith(
      phase: newPhase,
      remainingSeconds: newRemaining,
      completedPomodoros: completedPomodoros,
      isRunning: false,
    );
    _saveState();
    _updateWidgets(force: true);

    final settings = ref.read(settingsProvider);
    if (settings.notificationsEnabled) {
      NotificationService.showPhaseNotification(
        title: 'Pomodoro Complete',
        body: _phaseCompletionBody(completedPhase),
      );
    }

    if (autoStart && ref.read(settingsProvider).autoStartNext) {
      _startTimer();
    } else {
      NotificationService.cancelTimerNotification();
      ForegroundTimerService.stop();
    }
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
    _transitionToNextPhase(autoStart: true);
  }

  void _saveState() {
    _box.put('timer', state);
  }

  void _updateOngoingNotification() {
    if (!state.isRunning) return;
    final settings = ref.read(settingsProvider);
    if (!settings.notificationsEnabled) {
      NotificationService.cancelTimerNotification();
      return;
    }

    NotificationService.showOngoingTimerNotification(
      title: _phaseTitle(state.phase),
      body:
          '${_formatTime(state.remainingSeconds)} left · ${_phaseSubtitle(state.phase)}',
    );
  }

  void _ensureForegroundService() {
    final settings = ref.read(settingsProvider);
    if (!settings.notificationsEnabled) return;
    ForegroundTimerService.start(
      title: _phaseTitle(state.phase),
      text:
          '${_formatTime(state.remainingSeconds)} left · ${_phaseSubtitle(state.phase)}',
    );
  }

  void _updateForegroundService() {
    final settings = ref.read(settingsProvider);
    if (!settings.notificationsEnabled) return;
    ForegroundTimerService.update(
      title: _phaseTitle(state.phase),
      text:
          '${_formatTime(state.remainingSeconds)} left · ${_phaseSubtitle(state.phase)}',
    );
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  String _phaseTitle(PomodoroPhase phase) {
    return switch (phase) {
      PomodoroPhase.work => 'Sanctuary Timer',
      PomodoroPhase.shortBreak => 'Short Break',
      PomodoroPhase.longBreak => 'Long Break',
    };
  }

  String _phaseSubtitle(PomodoroPhase phase) {
    return switch (phase) {
      PomodoroPhase.work => 'Focus session',
      PomodoroPhase.shortBreak => 'Rest moment',
      PomodoroPhase.longBreak => 'Recharge',
    };
  }

  String _phaseCompletionBody(PomodoroPhase phase) {
    return switch (phase) {
      PomodoroPhase.work => 'Work session complete. Time for a break.',
      PomodoroPhase.shortBreak => 'Break complete. Back to deep work.',
      PomodoroPhase.longBreak => 'Long break complete. Back to deep work.',
    };
  }

}
