import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/task_model.dart';
import '../services/connectivity_service.dart';
import '../services/subtask_generator_service.dart';

enum SubtaskGenerationStatus { idle, generating, success, error, offline }

class SubtaskGenerationState {
  final SubtaskGenerationStatus status;
  final List<SubtaskModel> subtasks;
  final String? errorMessage;

  const SubtaskGenerationState({
    this.status = SubtaskGenerationStatus.idle,
    this.subtasks = const [],
    this.errorMessage,
  });

  SubtaskGenerationState copyWith({
    SubtaskGenerationStatus? status,
    List<SubtaskModel>? subtasks,
    String? errorMessage,
  }) {
    return SubtaskGenerationState(
      status: status ?? this.status,
      subtasks: subtasks ?? this.subtasks,
      errorMessage: errorMessage,
    );
  }
}

class SubtaskGenerationNotifier extends Notifier<SubtaskGenerationState> {
  @override
  SubtaskGenerationState build() {
    return const SubtaskGenerationState();
  }

  Future<void> generate({
    required String taskTitle,
    required String taskDescription,
  }) async {
    state = state.copyWith(
      status: SubtaskGenerationStatus.generating,
      errorMessage: null,
    );

    final generator = ref.read(subtaskGeneratorProvider);
    final connectivity = ref.read(connectivityServiceProvider);

    try {
      if (!await connectivity.isConnected()) {
        state = state.copyWith(
          status: SubtaskGenerationStatus.offline,
          errorMessage: 'No internet connection. Please try again later.',
        );
        return;
      }

      final subtasks = await generator.generateSubtasks(
        taskTitle: taskTitle,
        taskDescription: taskDescription,
      );

      state = state.copyWith(
        status: SubtaskGenerationStatus.success,
        subtasks: subtasks,
      );
    } on OfflineException catch (e) {
      state = state.copyWith(
        status: SubtaskGenerationStatus.offline,
        errorMessage: e.message,
      );
    } on GeneratorException catch (e) {
      state = state.copyWith(
        status: SubtaskGenerationStatus.error,
        errorMessage: e.message,
      );
    } catch (e) {
      state = state.copyWith(
        status: SubtaskGenerationStatus.error,
        errorMessage: 'An unexpected error occurred',
      );
    }
  }

  void reset() {
    state = const SubtaskGenerationState();
  }
}

final subtaskGenerationProvider =
    NotifierProvider<SubtaskGenerationNotifier, SubtaskGenerationState>(
  SubtaskGenerationNotifier.new,
);
