import 'package:hive/hive.dart';
import 'pomodoro_phase.dart';

part 'pomodoro_timer_model.g.dart'; // Generated file for Hive

@HiveType(typeId: 6) // Use a unique typeId
class PomodoroTimerModel extends HiveObject {
  @HiveField(0)
  PomodoroPhase phase;

  @HiveField(1)
  int remainingSeconds;

  @HiveField(2)
  int completedPomodoros;

  @HiveField(3)
  bool isRunning;

  PomodoroTimerModel({
    this.phase = PomodoroPhase.work,
    this.remainingSeconds = 25 * 60, // Default to work duration
    this.completedPomodoros = 0,
    this.isRunning = false,
  });

  PomodoroTimerModel copyWith({
    PomodoroPhase? phase,
    int? remainingSeconds,
    int? completedPomodoros,
    bool? isRunning,
  }) {
    return PomodoroTimerModel(
      phase: phase ?? this.phase,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      completedPomodoros: completedPomodoros ?? this.completedPomodoros,
      isRunning: isRunning ?? this.isRunning,
    );
  }
}