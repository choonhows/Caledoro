import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/settings_model.dart';
import '../models/task_model.dart';
import '../providers/settings_provider.dart';
import '../providers/task_provider.dart';
import '../screens/task_detail_screen.dart';
import '../theme.dart';
import '../widgets/subtask_list_widget.dart';
import '../utils/date_utils.dart';

class TaskChecklistWidget extends ConsumerWidget {
  final bool showSubtasks;
  final bool showSubtaskComposer;
  final bool allowSubtaskReorder;
  final bool allowTaskReorder;

  const TaskChecklistWidget({
    super.key,
    this.showSubtasks = false,
    this.showSubtaskComposer = false,
    this.allowSubtaskReorder = true,
    this.allowTaskReorder = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = ref.watch(taskListProvider);
    final today = ref.watch(selectedDateProvider);
    final settings = ref.watch(settingsProvider);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final dayTasks = tasks
        .where((task) => DateUtilsHelper.isSameDay(task.dueDate, today))
        .toList();

    if (settings.taskSortMode == TaskSortMode.smart) {
      dayTasks.sort((a, b) {
        final priority = b.priority.index.compareTo(a.priority.index);
        if (priority != 0) return priority;
        return a.dueDate.compareTo(b.dueDate);
      });
    } else {
      dayTasks.sort((a, b) {
        final order = a.sortOrder.compareTo(b.sortOrder);
        if (order != 0) return order;
        return a.dueDate.compareTo(b.dueDate);
      });
    }

    if (dayTasks.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: cs.surfaceContainerLow,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          children: [
            Icon(
              Icons.check_circle_outline_rounded,
              size: 48,
              color: cs.onSurfaceVariant.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 12),
            Text(
              'No quests for today',
              style: tt.bodyLarge?.copyWith(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 4),
            Text(
              'Enjoy the calm 🌿',
              style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            ),
          ],
        ),
      );
    }

    final isDense = dayTasks.length > 6;

    if (settings.taskSortMode == TaskSortMode.custom && allowTaskReorder) {
      return ReorderableListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        buildDefaultDragHandles: false,
        itemCount: dayTasks.length,
        onReorder: (oldIndex, newIndex) async {
          var nextIndex = newIndex;
          if (nextIndex > oldIndex) {
            nextIndex -= 1;
          }
          final reordered = [...dayTasks];
          final task = reordered.removeAt(oldIndex);
          reordered.insert(nextIndex, task);
          await ref
              .read(taskListProvider.notifier)
              .reorderTasksForDay(today, reordered);
        },
        itemBuilder: (context, index) {
          final task = dayTasks[index];
            return Padding(
              key: ValueKey(task.id),
              padding: EdgeInsets.only(bottom: index == dayTasks.length - 1 ? 0 : 12),
              child: _QuestCard(
                key: ValueKey('task-${task.id}'),
                task: task,
                showDragHandle: true,
                dragIndex: index,
                dense: isDense,
                showSubtasks: showSubtasks,
                showSubtaskComposer: showSubtaskComposer,
                allowSubtaskReorder: allowSubtaskReorder,
              ),
            );
          },
        );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: dayTasks.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final task = dayTasks[index];
        return _QuestCard(
          key: ValueKey('task-${task.id}'),
          task: task,
          dense: isDense,
          showSubtasks: showSubtasks,
          showSubtaskComposer: showSubtaskComposer,
          allowSubtaskReorder: allowSubtaskReorder,
        );
      },
    );
  }
}

/// A single quest/task card following "No-Line Rule" — tonal layering, no borders.
class _QuestCard extends ConsumerStatefulWidget {
  final TaskModel task;
  final bool showDragHandle;
  final int? dragIndex;
  final bool dense;
  final bool showSubtasks;
  final bool showSubtaskComposer;
  final bool allowSubtaskReorder;

  const _QuestCard({
    super.key,
    required this.task,
    this.showDragHandle = false,
    this.dragIndex,
    this.dense = false,
    this.showSubtasks = false,
    this.showSubtaskComposer = false,
    this.allowSubtaskReorder = true,
  });

  @override
  ConsumerState<_QuestCard> createState() => _QuestCardState();
}

class _QuestCardState extends ConsumerState<_QuestCard> {
  bool _showCompletedSubtasks = false;

  Future<void> _toggleTask(
    BuildContext context,
    WidgetRef ref,
    TaskModel task,
  ) async {
    try {
      await ref.read(taskListProvider.notifier).toggleComplete(task.id);
    } on TaskOperationException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    }
  }

  void _openTaskDetail(BuildContext context, TaskModel task) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TaskDetailScreen(taskId: task.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final task = widget.task;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final isShrine = widget.showSubtasks && !widget.showSubtaskComposer;

    // Priority dot color from design tokens
    final priorityColor = switch (task.priority) {
      TaskPriority.high => cs.tertiary,
      TaskPriority.medium => cs.secondary,
      TaskPriority.low => cs.primary,
    };

    final subtasks = [...task.subtasks]
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    final completedSubtasks = subtasks.where((s) => s.completed).toList();
    final pendingSubtasks = subtasks.where((s) => !s.completed).toList();
    final previewSource =
        _showCompletedSubtasks ? subtasks : pendingSubtasks;
    final preview = previewSource.take(2).toList();
    final completedCount = completedSubtasks.length;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: task.completed
            ? cs.surfaceContainerHigh
            : cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(24),
        boxShadow: task.completed ? null : CozyColors.cardHoverShadow,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onLongPress: () => _showDeleteConfirmation(context, ref, task),
          onTap: () => _openTaskDetail(context, task),
          child: Padding(
            padding: EdgeInsets.all(widget.dense ? 12 : 14),
            child: Row(
              children: [
                // ── Oversized Checkbox (28x28, 10px radius) ──
                GestureDetector(
                  onTap: () => _toggleTask(context, ref, task),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOut,
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: task.completed
                          ? CozyColors.primary
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      border: task.completed
                          ? null
                          : Border.all(
                              color: cs.outline,
                              width: 1.5,
                            ),
                    ),
                    child: task.completed
                        ? const Icon(Icons.check_rounded,
                            size: 18, color: CozyColors.onPrimary)
                        : null,
                  ),
                ),

                const SizedBox(width: 16),

                // ── Task Content ──
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.local_florist_rounded,
                            size: 14,
                            color: cs.primary.withValues(alpha: 0.8),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              task.title,
                              style: tt.bodyLarge?.copyWith(
                                color: task.completed
                                    ? cs.onSurface.withValues(alpha: 0.45)
                                    : cs.onSurface,
                                decoration: task.completed
                                    ? TextDecoration.lineThrough
                                    : null,
                                decorationColor:
                                    cs.onSurface.withValues(alpha: 0.45),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            // Priority dot
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: priorityColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${task.dueDate.hour.toString().padLeft(2, '0')}:${task.dueDate.minute.toString().padLeft(2, '0')}',
                              style: tt.labelSmall?.copyWith(
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                            if (task.recurringDaily) ...[
                              const SizedBox(width: 8),
                              Icon(Icons.replay_rounded,
                                  size: 14, color: cs.onSurfaceVariant),
                            ],
                            if (subtasks.isNotEmpty) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: cs.surfaceContainerHigh,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  '$completedCount/${subtasks.length}',
                                  style: tt.labelSmall?.copyWith(
                                    color: cs.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        if (subtasks.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          widget.showSubtasks
                              ? Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: cs.surfaceContainerLow,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: SubtaskListWidget(
                                    task: task,
                                    dense: true,
                                    compact: !widget.showSubtaskComposer,
                                    showHeader: false,
                                    allowReorder: widget.allowSubtaskReorder,
                                    showComposer: widget.showSubtaskComposer,
                                  ),
                                )
                              : Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    for (final subtask in preview)
                                      Padding(
                                        padding: const EdgeInsets.only(bottom: 4),
                                        child: Row(
                                          children: [
                                            Icon(
                                              subtask.completed
                                                  ? Icons.check_circle_rounded
                                                  : Icons.radio_button_unchecked,
                                              size: 14,
                                              color: subtask.completed
                                                  ? cs.primary
                                                  : cs.onSurfaceVariant,
                                            ),
                                            const SizedBox(width: 6),
                                            Expanded(
                                              child: Text(
                                                subtask.label,
                                                style: tt.bodySmall?.copyWith(
                                                  color: subtask.completed
                                                      ? cs.onSurfaceVariant
                                                          .withValues(alpha: 0.6)
                                                      : cs.onSurfaceVariant,
                                                  decoration: subtask.completed
                                                      ? TextDecoration.lineThrough
                                                      : null,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    if (!_showCompletedSubtasks &&
                                        completedSubtasks.isNotEmpty)
                                      GestureDetector(
                                        onTap: () => setState(() {
                                          _showCompletedSubtasks = true;
                                        }),
                                        child: Text(
                                          'Show completed (${completedSubtasks.length})',
                                          style: tt.labelSmall?.copyWith(
                                            color: cs.primary,
                                          ),
                                        ),
                                      ),
                                    if (_showCompletedSubtasks &&
                                        completedSubtasks.isNotEmpty)
                                      GestureDetector(
                                        onTap: () => setState(() {
                                          _showCompletedSubtasks = false;
                                        }),
                                        child: Text(
                                          'Hide completed',
                                          style: tt.labelSmall?.copyWith(
                                            color: cs.primary,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                        ],
                      ],
                    ),
                  ),

                  // ── Play/action icon ──
                  if (widget.showDragHandle && widget.dragIndex != null)
                    ReorderableDragStartListener(
                      index: widget.dragIndex!,
                      child: Icon(
                        Icons.drag_handle_rounded,
                        color: cs.onSurfaceVariant.withValues(alpha: 0.5),
                        size: 24,
                      ),
                    )
                  else if (isShrine && subtasks.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '$completedCount/${subtasks.length}',
                        style: tt.labelSmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    )
                  else if (!task.completed)
                    Icon(
                      Icons.play_arrow_rounded,
                      color: cs.onSurfaceVariant.withValues(alpha: 0.4),
                      size: 24,
                    ),
                ],
              ),
            ),
          ),
        ),
    );
  }
}

void _showDeleteConfirmation(
    BuildContext context, WidgetRef ref, TaskModel task) {
  showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Delete Quest?'),
      content: const Text('This action cannot be undone.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () async {
            await ref.read(taskListProvider.notifier).deleteTask(task.id);
            if (!context.mounted) return;
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Quest deleted')),
            );
          },
          child: const Text('Delete'),
        ),
      ],
    ),
  );
}
