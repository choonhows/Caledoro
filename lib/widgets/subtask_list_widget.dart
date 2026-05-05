import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/task_model.dart';
import '../providers/task_provider.dart';
import '../theme.dart';

class SubtaskListWidget extends ConsumerStatefulWidget {
  final TaskModel task;
  final bool dense;
  final bool compact;
  final bool showHeader;
  final bool allowReorder;
  final bool showComposer;

  const SubtaskListWidget({
    super.key,
    required this.task,
    this.dense = false,
    this.compact = false,
    this.showHeader = true,
    this.allowReorder = true,
    this.showComposer = true,
  });

  @override
  ConsumerState<SubtaskListWidget> createState() => _SubtaskListWidgetState();
}

class _SubtaskListWidgetState extends ConsumerState<SubtaskListWidget> {
  final TextEditingController _inputCtrl = TextEditingController();
  bool _showCompleted = false;

  @override
  void dispose() {
    _inputCtrl.dispose();
    super.dispose();
  }

  TaskModel _cloneTask(TaskModel task) {
    return TaskModel(
      id: task.id,
      title: task.title,
      description: task.description,
      dueDate: task.dueDate,
      priority: task.priority,
      completed: task.completed,
      recurringDaily: task.recurringDaily,
      lastCompletedDate: task.lastCompletedDate,
      sortOrder: task.sortOrder,
      subtasks: task.subtasks
          .map((s) => SubtaskModel(
                id: s.id,
                label: s.label,
                completed: s.completed,
                sortOrder: s.sortOrder,
                createdBy: s.createdBy,
                suggested: s.suggested,
                acceptedAt: s.acceptedAt,
              ))
          .toList(),
    );
  }

  Future<void> _addSubtask() async {
    final label = _inputCtrl.text.trim();
    if (label.isEmpty) return;
    _inputCtrl.clear();
    await ref.read(taskListProvider.notifier).addSubtask(widget.task.id, label);
  }

  Future<void> _clearCompleted() async {
    final snapshot = _cloneTask(widget.task);
    await ref
        .read(taskListProvider.notifier)
        .clearCompletedSubtasks(widget.task.id);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Completed subtasks cleared'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            ref.read(taskListProvider.notifier).updateTask(snapshot);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final task = widget.task;

    final subtasks = [...task.subtasks]
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    final completedSubtasks = subtasks.where((s) => s.completed).toList();
    final pendingSubtasks = subtasks.where((s) => !s.completed).toList();
    final visible = _showCompleted ? subtasks : pendingSubtasks;

    final rowPadding = EdgeInsets.symmetric(
      horizontal: widget.dense ? 10 : 12,
      vertical: widget.dense ? 8 : 10,
    );

    final inputRow = Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(widget.compact ? 14 : 18),
      ),
      padding: widget.compact
          ? const EdgeInsets.symmetric(horizontal: 10, vertical: 6)
          : rowPadding,
      child: Row(
        children: [
          Icon(Icons.add_rounded, color: cs.primary, size: widget.compact ? 18 : 22),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _inputCtrl,
              decoration: const InputDecoration(
                hintText: 'Add a subtask',
                border: InputBorder.none,
              ),
              style: widget.compact ? tt.bodySmall : tt.bodyMedium,
              onSubmitted: (_) => _addSubtask(),
            ),
          ),
          TextButton(
            onPressed: _addSubtask,
            style: TextButton.styleFrom(
              padding: widget.compact
                  ? const EdgeInsets.symmetric(horizontal: 10, vertical: 6)
                  : const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text('Add'),
          ),
        ],
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.showHeader)
          Row(
            children: [
              Text('Subtasks', style: tt.titleSmall?.copyWith(color: cs.onSurface)),
              const Spacer(),
              if (completedSubtasks.isNotEmpty)
                TextButton(
                  onPressed: _clearCompleted,
                  child: const Text('Clear completed'),
                ),
            ],
          ),
        if (widget.showHeader) const SizedBox(height: 8),
        if (!widget.showComposer && !widget.compact) inputRow,
        const SizedBox(height: 12),
        if (subtasks.isEmpty)
          Text(
            'No subtasks yet. Add a step to break it down.',
            style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
          )
        else
          widget.allowReorder
              ? ReorderableListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  buildDefaultDragHandles: false,
                  itemCount: visible.length,
                  onReorder: (oldIndex, newIndex) async {
                    var nextIndex = newIndex;
                    if (nextIndex > oldIndex) nextIndex -= 1;
                    final reordered = [...subtasks];
                    final moving = visible[oldIndex];
                    final visibleOrdered = [...visible]..removeAt(oldIndex);
                    visibleOrdered.insert(nextIndex, moving);

                    if (_showCompleted) {
                      reordered
                        ..clear()
                        ..addAll(visibleOrdered);
                    } else {
                      var pendingIndex = 0;
                      for (var i = 0; i < reordered.length; i++) {
                        if (!reordered[i].completed) {
                          reordered[i] = visibleOrdered[pendingIndex];
                          pendingIndex += 1;
                        }
                      }
                    }
                    await ref
                        .read(taskListProvider.notifier)
                        .reorderSubtasks(task.id, reordered);
                  },
                  itemBuilder: (context, index) {
                    final subtask = visible[index];
                    return Container(
                      key: ValueKey('subtask-${subtask.id}'),
                      margin: EdgeInsets.only(
                          bottom: index == visible.length - 1 ? 0 : 8),
                      padding: rowPadding,
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () => ref
                                .read(taskListProvider.notifier)
                                .toggleSubtask(task.id, subtask.id),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                color: subtask.completed
                                    ? CozyColors.primary
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(6),
                                border: subtask.completed
                                    ? null
                                    : Border.all(color: cs.outline, width: 1.5),
                              ),
                              child: subtask.completed
                                  ? const Icon(Icons.check_rounded,
                                      size: 14, color: CozyColors.onPrimary)
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              subtask.label,
                              style: tt.bodySmall?.copyWith(
                                color: subtask.completed
                                    ? cs.onSurfaceVariant.withValues(alpha: 0.6)
                                    : cs.onSurface,
                                decoration: subtask.completed
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                            ),
                          ),
                          ReorderableDragStartListener(
                            index: index,
                            child: Icon(
                              Icons.drag_handle_rounded,
                              color: cs.onSurfaceVariant.withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                )
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: visible.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final subtask = visible[index];
                    return Container(
                      key: ValueKey('subtask-${subtask.id}'),
                      padding: rowPadding,
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () => ref
                                .read(taskListProvider.notifier)
                                .toggleSubtask(task.id, subtask.id),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                color: subtask.completed
                                    ? CozyColors.primary
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(6),
                                border: subtask.completed
                                    ? null
                                    : Border.all(color: cs.outline, width: 1.5),
                              ),
                              child: subtask.completed
                                  ? const Icon(Icons.check_rounded,
                                      size: 14, color: CozyColors.onPrimary)
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              subtask.label,
                              style: tt.bodySmall?.copyWith(
                                color: subtask.completed
                                    ? cs.onSurfaceVariant.withValues(alpha: 0.6)
                                    : cs.onSurface,
                                decoration: subtask.completed
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        if (completedSubtasks.isNotEmpty)
          TextButton(
            onPressed: () => setState(() {
              _showCompleted = !_showCompleted;
            }),
            child: Text(
              _showCompleted
                  ? 'Hide completed'
                  : 'Show completed (${completedSubtasks.length})',
            ),
          ),
        if (widget.showComposer && widget.compact) ...[
          const SizedBox(height: 8),
          inputRow,
        ],
      ],
    );
  }
}
