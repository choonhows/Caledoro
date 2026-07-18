// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pomodoro_phase.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PomodoroPhaseAdapter extends TypeAdapter<PomodoroPhase> {
  @override
  final int typeId = 7;

  @override
  PomodoroPhase read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return PomodoroPhase.work;
      case 1:
        return PomodoroPhase.shortBreak;
      case 2:
        return PomodoroPhase.longBreak;
      default:
        return PomodoroPhase.work;
    }
  }

  @override
  void write(BinaryWriter writer, PomodoroPhase obj) {
    switch (obj) {
      case PomodoroPhase.work:
        writer.writeByte(0);
        break;
      case PomodoroPhase.shortBreak:
        writer.writeByte(1);
        break;
      case PomodoroPhase.longBreak:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PomodoroPhaseAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
