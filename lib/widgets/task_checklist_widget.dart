import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/task_model.dart';
import '../providers/task_provider.dart';
import '../theme.dart';
import '../utils/date_utils.dart';

class TaskChecklistWidget extends ConsumerWidget {
  const TaskChecklistWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = ref.watch(taskListProvider);
    final today = ref.watch(selectedDateProvider);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final dayTasks = tasks
        .where((task) => DateUtilsHelper.isSameDay(task.dueDate, today))
        .toList()
      ..sort((a, b) {
        final priority = b.priority.index.compareTo(a.priority.index);
        if (priority != 0) return priority;
        return a.dueDate.compareTo(b.dueDate);
      });

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

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: dayTasks.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final task = dayTasks[index];
        return _QuestCard(task: task);
      },
    );
  }
}

/// A single quest/task card following "No-Line Rule" — tonal layering, no borders.
class _QuestCard extends ConsumerWidget {
  final TaskModel task;
  const _QuestCard({required this.task});

  Future<void> _toggleTask(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(taskListProvider.notifier).toggleComplete(task.id);
    } on TaskOperationException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    // Priority dot color from design tokens
    final priorityColor = switch (task.priority) {
      TaskPriority.high => cs.tertiary,
      TaskPriority.medium => cs.secondary,
      TaskPriority.low => cs.primary,
    };

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
          onTap: () => _toggleTask(context, ref),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // ── Oversized Checkbox (28x28, 10px radius) ──
                GestureDetector(
                  onTap: () => _toggleTask(context, ref),
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
                      Text(
                        task.title,
                        style: tt.bodyLarge?.copyWith(
                          color: task.completed
                              ? cs.onSurface.withValues(alpha: 0.45)
                              : cs.onSurface,
                          decoration: task.completed
                              ? TextDecoration.lineThrough
                              : null,
                          decorationColor: cs.onSurface.withValues(alpha: 0.45),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (task.description.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          task.description,
                          style: tt.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant.withValues(alpha: 0.7),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
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
                        ],
                      ),
                    ],
                  ),
                ),

                // ── Play/action icon ──
                if (!task.completed)
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
