import 'package:hive/hive.dart';

part 'pomodoro_phase.g.dart';

@HiveType(typeId: 7)
enum PomodoroPhase {
  @HiveField(0)
  work,
  @HiveField(1)
  shortBreak,
  @HiveField(2)
  longBreak,
}
