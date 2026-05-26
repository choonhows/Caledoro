// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pomodoro_timer_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PomodoroTimerModelAdapter extends TypeAdapter<PomodoroTimerModel> {
  @override
  final int typeId = 6;

  @override
  PomodoroTimerModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PomodoroTimerModel(
      phase: fields[0] as PomodoroPhase,
      remainingSeconds: fields[1] as int,
      completedPomodoros: fields[2] as int,
      isRunning: fields[3] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, PomodoroTimerModel obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.phase)
      ..writeByte(1)
      ..write(obj.remainingSeconds)
      ..writeByte(2)
      ..write(obj.completedPomodoros)
      ..writeByte(3)
      ..write(obj.isRunning);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PomodoroTimerModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
