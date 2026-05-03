import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/task_model.dart';
import '../services/hive_service.dart';
import '../utils/date_utils.dart';

class TaskOperationException implements Exception {
  final String message;
  final Object? cause;

  const TaskOperationException(this.message, {this.cause});

  @override
  String toString() {
    if (cause == null) return message;
    return '$message (cause: $cause)';
  }
}

final taskListProvider = NotifierProvider<TaskListNotifier, List<TaskModel>>(
  TaskListNotifier.new,
);

final selectedDateProvider = NotifierProvider<SelectedDateNotifier, DateTime>(
  SelectedDateNotifier.new,
);

class SelectedDateNotifier extends Notifier<DateTime> {
  @override
  DateTime build() {
    return DateTime.now();
  }

  void setDate(DateTime date) {
    state = date;
  }
}

class TaskListNotifier extends Notifier<List<TaskModel>> {
  @override
  List<TaskModel> build() {
    return HiveService.tasksBox().values.toList();
  }

  Future<void> addTask({
    required String title,
    String description = '',
    required DateTime dueDate,
    TaskPriority priority = TaskPriority.medium,
    bool recurringDaily = false,
  }) async {
    final task = TaskModel(
      id: const Uuid().v4(),
      title: title.trim(),
      description: description.trim(),
      dueDate: dueDate,
      priority: priority,
      recurringDaily: recurringDaily,
    );
    final box = HiveService.tasksBox();
    try {
      await box.put(task.id, task);
      state = [...state, task];
    } catch (e, stackTrace) {
      debugPrint('Failed to add task: $e');
      Error.throwWithStackTrace(
        TaskOperationException('Failed to add task. Please try again.',
            cause: e),
        stackTrace,
      );
    }
  }

  Future<void> toggleComplete(String id) async {
    final index = state.indexWhere((task) => task.id == id);
    if (index == -1) return;
    final task = state[index];
    try {
      final nextCompleted = !task.completed;
      if (task.subtasks.isNotEmpty) {
        for (final subtask in task.subtasks) {
          subtask.completed = nextCompleted;
        }
      }
      task.completed = nextCompleted;
      task.lastCompletedDate = nextCompleted ? DateTime.now() : null;
      await task.save();
      state = [...state]..[index] = task;

      if (task.recurringDaily && task.completed) {
        await _updateStreakOnRecurringCompletion(DateTime.now());
      }
    } catch (e, stackTrace) {
      Error.throwWithStackTrace(
        TaskOperationException('Failed to update task completion.', cause: e),
        stackTrace,
      );
    }
  }

  Future<void> updateTask(TaskModel task) async {
    await task.save();
    state = state.map((t) => t.id == task.id ? task : t).toList();
  }

  Future<void> deleteTask(String id) async {
    await HiveService.tasksBox().delete(id);
    state = state.where((task) => task.id != id).toList();
  }

  Future<void> addSubtask(String taskId, String label) async {
    final index = state.indexWhere((task) => task.id == taskId);
    if (index == -1) return;
    final task = state[index];
    final trimmed = label.trim();
    if (trimmed.isEmpty) return;

    final subtask = SubtaskModel(
      id: const Uuid().v4(),
      label: trimmed,
      sortOrder: task.subtasks.length,
    );

    try {
      task.subtasks = [...task.subtasks, subtask];
      task.completed = false;
      task.lastCompletedDate = null;
      await task.save();
      state = [...state]..[index] = task;
    } catch (e, stackTrace) {
      Error.throwWithStackTrace(
        TaskOperationException('Failed to add subtask.', cause: e),
        stackTrace,
      );
    }
  }

  Future<void> toggleSubtask(String taskId, String subtaskId) async {
    final index = state.indexWhere((task) => task.id == taskId);
    if (index == -1) return;
    final task = state[index];
    final subtaskIndex =
        task.subtasks.indexWhere((subtask) => subtask.id == subtaskId);
    if (subtaskIndex == -1) return;

    try {
      final subtask = task.subtasks[subtaskIndex];
      subtask.completed = !subtask.completed;
      task.subtasks = [...task.subtasks]..[subtaskIndex] = subtask;

      if (task.subtasks.isNotEmpty) {
        final allCompleted = task.subtasks.every((s) => s.completed);
        task.completed = allCompleted;
        task.lastCompletedDate = allCompleted ? DateTime.now() : null;
      }

      await task.save();
      state = [...state]..[index] = task;

      if (task.recurringDaily && task.completed) {
        await _updateStreakOnRecurringCompletion(DateTime.now());
      }
    } catch (e, stackTrace) {
      Error.throwWithStackTrace(
        TaskOperationException('Failed to update subtask.', cause: e),
        stackTrace,
      );
    }
  }

  Future<void> deleteSubtask(String taskId, String subtaskId) async {
    final index = state.indexWhere((task) => task.id == taskId);
    if (index == -1) return;
    final task = state[index];
    final nextSubtasks =
        task.subtasks.where((subtask) => subtask.id != subtaskId).toList();
    if (nextSubtasks.length == task.subtasks.length) return;

    try {
      for (var i = 0; i < nextSubtasks.length; i++) {
        nextSubtasks[i].sortOrder = i;
      }
      task.subtasks = nextSubtasks;
      if (task.subtasks.isNotEmpty) {
        final allCompleted = task.subtasks.every((s) => s.completed);
        task.completed = allCompleted;
        task.lastCompletedDate = allCompleted ? DateTime.now() : null;
      }
      await task.save();
      state = [...state]..[index] = task;
    } catch (e, stackTrace) {
      Error.throwWithStackTrace(
        TaskOperationException('Failed to delete subtask.', cause: e),
        stackTrace,
      );
    }
  }

  Future<void> reorderSubtasks(String taskId, List<SubtaskModel> ordered) async {
    final index = state.indexWhere((task) => task.id == taskId);
    if (index == -1) return;
    final task = state[index];

    try {
      final next = <SubtaskModel>[];
      for (var i = 0; i < ordered.length; i++) {
        final subtask = ordered[i];
        subtask.sortOrder = i;
        next.add(subtask);
      }
      task.subtasks = next;
      if (task.subtasks.isNotEmpty) {
        final allCompleted = task.subtasks.every((s) => s.completed);
        task.completed = allCompleted;
        task.lastCompletedDate = allCompleted ? DateTime.now() : null;
      }
      await task.save();
      state = [...state]..[index] = task;
    } catch (e, stackTrace) {
      Error.throwWithStackTrace(
        TaskOperationException('Failed to reorder subtasks.', cause: e),
        stackTrace,
      );
    }
  }

  Future<void> reorderTasksForDay(
    DateTime day,
    List<TaskModel> ordered,
  ) async {
    try {
      final dayTasks = <TaskModel>[];
      final remaining = <TaskModel>[];
      for (final task in state) {
        if (DateUtilsHelper.isSameDay(task.dueDate, day)) {
          dayTasks.add(task);
        } else {
          remaining.add(task);
        }
      }

      final orderedDayTasks = ordered
          .where((task) => DateUtilsHelper.isSameDay(task.dueDate, day))
          .toList();
      final orderedIds = orderedDayTasks.map((task) => task.id).toSet();
      final remainingDayTasks = <TaskModel>[];
      for (final task in dayTasks) {
        if (!orderedIds.contains(task.id)) {
          remainingDayTasks.add(task);
        }
      }

      final nextDayTasks = [...orderedDayTasks, ...remainingDayTasks];
      for (var i = 0; i < nextDayTasks.length; i++) {
        final task = nextDayTasks[i];
        task.sortOrder = i;
        await task.save();
      }

      state = [...remaining, ...nextDayTasks];
    } catch (e, stackTrace) {
      Error.throwWithStackTrace(
        TaskOperationException('Failed to reorder tasks.', cause: e),
        stackTrace,
      );
    }
  }

  Future<void> dailyResetRecurring(DateTime today) async {
    final meta = HiveService.widgetBox().get('meta') ?? <String, dynamic>{};
    final lastResetRaw = meta['lastResetDate'] as String?;
    final lastReset =
        lastResetRaw == null ? null : DateTime.tryParse(lastResetRaw);
    if (DateUtilsHelper.isSameDay(lastReset, today)) return;

    var hasReset = false;
    for (final task in state) {
      if (task.recurringDaily && task.completed) {
        task.completed = false;
        await task.save();
        hasReset = true;
      }
    }

    if (hasReset) {
      state = [...state];
    }

    await HiveService.widgetBox().put('meta', {
      ...meta,
      'lastResetDate': today.toIso8601String(),
    });
  }

  Future<void> _updateStreakOnRecurringCompletion(DateTime today) async {
    final dailyTasks = state.where((t) => t.recurringDaily).toList();
    if (dailyTasks.isEmpty) return;

    final allCompletedToday = dailyTasks.every(
      (task) =>
          task.completed &&
          DateUtilsHelper.isSameDay(task.lastCompletedDate, today),
    );
    if (!allCompletedToday) return;

    final meta = HiveService.widgetBox().get('meta') ?? <String, dynamic>{};
    final lastStreakDateRaw = meta['lastStreakDate'] as String?;
    final lastStreakDate =
        lastStreakDateRaw == null ? null : DateTime.tryParse(lastStreakDateRaw);

    if (DateUtilsHelper.isSameDay(lastStreakDate, today)) {
      return;
    }

    final wasYesterday = DateUtilsHelper.isSameDay(
      lastStreakDate,
      today.subtract(const Duration(days: 1)),
    );

    final prevCurrent = (meta['currentStreak'] as int?) ?? 0;
    final prevLongest = (meta['longestStreak'] as int?) ?? 0;
    final current = wasYesterday ? prevCurrent + 1 : 1;
    final longest = math.max(prevLongest, current);

    await HiveService.widgetBox().put('meta', {
      ...meta,
      'currentStreak': current,
      'longestStreak': longest,
      'lastStreakDate': today.toIso8601String(),
    });
  }
}
