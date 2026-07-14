import 'dart:io' show Platform;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/pomodoro_phase.dart';
import '../models/pomodoro_timer_model.dart';
import '../models/settings_model.dart';
import '../models/task_model.dart';
import '../providers/pomodoro_timer_provider.dart';
import '../providers/selected_tab_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/task_provider.dart';
import '../screens/pomodoro_settings_screen.dart';
import '../screens/task_detail_screen.dart';
import '../theme.dart';
import '../utils/date_utils.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = ref.watch(taskListProvider);
    final today = ref.watch(selectedDateProvider);
    final timerState = ref.watch(pomodoroTimerProvider);
    final settings = ref.watch(settingsProvider);
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

    final visibleTasks = dayTasks.take(3).toList();
    final remainingCount = dayTasks.length - visibleTasks.length;

    final isIOS = Platform.isIOS;

    return Scaffold(
      appBar: isIOS
          ? PreferredSize(
              preferredSize: const Size.fromHeight(44),
              child: CupertinoNavigationBar(
                middle: const Text('Caledoro'),
                trailing: GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const PomodoroSettingsScreen()),
                  ),
                  child: const Icon(CupertinoIcons.gear, size: 22),
                ),
              ),
            )
          : AppBar(
              title: const Text('Caledoro'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.settings_outlined),
                  tooltip: 'Settings',
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const PomodoroSettingsScreen()),
                  ),
                ),
              ],
            ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),

            // ── Date Header ──
            Text(
              DateFormat('EEEE, MMMM d').format(today),
              style: tt.headlineMedium?.copyWith(
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "What's on your plate today?",
              style: tt.bodyMedium?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),

            const SizedBox(height: 28),

            // ── Priority Tasks Section ──
            Text(
              'Priority Quests',
              style: tt.titleLarge?.copyWith(
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Top ${dayTasks.length == 1 ? 'quest' : 'quests'} by priority',
              style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 12),

            if (dayTasks.isEmpty)
              _buildEmptyState(cs, tt)
            else ...[
              for (final task in visibleTasks)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _DashboardTaskCard(task: task),
                ),
              if (remainingCount > 0)
                Center(
                  child: Text(
                    '+$remainingCount more quest${remainingCount == 1 ? '' : 's'}',
                    style: tt.labelLarge?.copyWith(color: cs.primary),
                  ),
                ),
            ],

            // ── Focus Session Section ──
            const SizedBox(height: 32),
            Text(
              'Focus Session',
              style: tt.titleLarge?.copyWith(
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            _buildFocusSessionSection(
              context: context,
              ref: ref,
              timerState: timerState,
              settings: settings,
              cs: cs,
              tt: tt,
            ),
            // ── Subtask Progress Section ──
            const SizedBox(height: 32),
            Text(
              'Subtask Progress',
              style: tt.titleLarge?.copyWith(
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            ..._buildSubtaskRows(dayTasks, cs, tt),
            // ── Coming Up Section ──
            const SizedBox(height: 32),
            Text(
              'Coming Up',
              style: tt.titleLarge?.copyWith(
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            ..._buildUpcomingSection(tasks, today, cs, tt),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ColorScheme cs, TextTheme tt) {
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
            'Enjoy the calm',
            style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _buildFocusSessionSection({
    required BuildContext context,
    required WidgetRef ref,
    required PomodoroTimerModel timerState,
    required SettingsModel settings,
    required ColorScheme cs,
    required TextTheme tt,
  }) {
    final isIdle = !timerState.isRunning && timerState.completedPomodoros == 0;

    if (isIdle) {
      return GestureDetector(
        onTap: () =>
            ref.read(selectedTabProvider.notifier).setTab(1),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: cs.surfaceContainerLow,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            children: [
              Icon(
                Icons.play_circle_outline_rounded,
                size: 48,
                color: cs.onSurfaceVariant.withValues(alpha: 0.4),
              ),
              const SizedBox(height: 12),
              Text(
                'No active session',
                style: tt.bodyLarge?.copyWith(color: cs.onSurfaceVariant),
              ),
              const SizedBox(height: 4),
              Text(
                'Tap to start focusing',
                style: tt.bodySmall?.copyWith(color: cs.primary),
              ),
            ],
          ),
        ),
      );
    }

    final phaseLabel = switch (timerState.phase) {
      PomodoroPhase.work => 'Focus',
      PomodoroPhase.shortBreak => 'Short Break',
      PomodoroPhase.longBreak => 'Long Break',
    };

    final phaseColor = switch (timerState.phase) {
      PomodoroPhase.work => cs.primary,
      PomodoroPhase.shortBreak => cs.secondary,
      PomodoroPhase.longBreak => cs.tertiary,
    };

    final totalSeconds = switch (timerState.phase) {
      PomodoroPhase.work => settings.workMinutes * 60,
      PomodoroPhase.shortBreak => settings.shortBreakMinutes * 60,
      PomodoroPhase.longBreak => settings.longBreakMinutes * 60,
    };

    final progress = totalSeconds > 0
        ? 1.0 - (timerState.remainingSeconds / totalSeconds)
        : 0.0;

    final minutes = timerState.remainingSeconds ~/ 60;
    final seconds = timerState.remainingSeconds % 60;
    final timeLabel =
        '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

    return GestureDetector(
      onTap: () =>
          ref.read(selectedTabProvider.notifier).setTab(1),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: cs.surfaceContainerLow,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: phaseColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    phaseLabel,
                    style: tt.labelSmall?.copyWith(
                      color: phaseColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (timerState.isRunning)
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: phaseColor,
                      shape: BoxShape.circle,
                    ),
                  )
                else
                  Icon(
                    Icons.pause_rounded,
                    size: 14,
                    color: cs.onSurfaceVariant,
                  ),
                const Spacer(),
                Text(
                  timeLabel,
                  style: tt.headlineSmall?.copyWith(
                    color: cs.onSurface,
                    fontWeight: FontWeight.w600,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: cs.surfaceContainerHigh,
                valueColor: AlwaysStoppedAnimation<Color>(phaseColor),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '${timerState.completedPomodoros} pomodoro${timerState.completedPomodoros == 1 ? '' : 's'} completed today',
              style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildSubtaskRows(
    List<TaskModel> dayTasks,
    ColorScheme cs,
    TextTheme tt,
  ) {
    final tasksWithSubtasks =
        dayTasks.where((t) => t.subtasks.isNotEmpty).toList();

    if (tasksWithSubtasks.isEmpty) {
      return [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: cs.surfaceContainerLow,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            children: [
              Icon(
                Icons.auto_awesome_rounded,
                size: 48,
                color: cs.onSurfaceVariant.withValues(alpha: 0.4),
              ),
              const SizedBox(height: 12),
              Text(
                'No subtasks yet',
                style: tt.bodyLarge?.copyWith(color: cs.onSurfaceVariant),
              ),
              const SizedBox(height: 4),
              Text(
                'Break down your quests with AI subtasks',
                style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ];
    }

    return [
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: cs.surfaceContainerLow,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          children: [
            for (var i = 0; i < tasksWithSubtasks.length; i++) ...[
              if (i > 0) const SizedBox(height: 12),
              _SubtaskProgressRow(task: tasksWithSubtasks[i]),
            ],
          ],
        ),
      ),
    ];
  }

  List<Widget> _buildUpcomingSection(
    List<TaskModel> allTasks,
    DateTime today,
    ColorScheme cs,
    TextTheme tt,
  ) {
    final upcoming = <DateTime, List<TaskModel>>{};
    for (var i = 1; i <= 5; i++) {
      final day = DateTime(today.year, today.month, today.day + i);
      final dayTasks = allTasks
          .where((t) => DateUtilsHelper.isSameDay(t.dueDate, day))
          .toList();
      if (dayTasks.isNotEmpty) {
        upcoming[day] = dayTasks;
      }
    }

    if (upcoming.isEmpty) {
      return [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: cs.surfaceContainerLow,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            children: [
              Icon(
                Icons.event_available_rounded,
                size: 48,
                color: cs.onSurfaceVariant.withValues(alpha: 0.4),
              ),
              const SizedBox(height: 12),
              Text(
                'Nothing on the horizon',
                style: tt.bodyLarge?.copyWith(color: cs.onSurfaceVariant),
              ),
              const SizedBox(height: 4),
              Text(
                'Enjoy the calm',
                style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ];
    }

    return [
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: cs.surfaceContainerLow,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          children: [
            for (final entry in upcoming.entries) ...[
              _UpcomingDayRow(day: entry.key, taskCount: entry.value.length),
              if (entry.key != upcoming.keys.last)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Divider(
                    height: 1,
                    color: cs.outlineVariant.withValues(alpha: 0.3),
                  ),
                ),
            ],
          ],
        ),
      ),
    ];
  }
}

/// Compact task card for the dashboard — single row, no subtask preview.
class _DashboardTaskCard extends ConsumerWidget {
  final TaskModel task;

  const _DashboardTaskCard({required this.task});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final priorityColor = switch (task.priority) {
      TaskPriority.high => cs.tertiary,
      TaskPriority.medium => cs.secondary,
      TaskPriority.low => cs.primary,
    };

    final completedSubtasks =
        task.subtasks.where((s) => s.completed).length;
    final totalSubtasks = task.subtasks.length;

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
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => TaskDetailScreen(taskId: task.id),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Row(
              children: [
                // Priority dot
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: priorityColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 14),

                // Title
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
                      decorationColor: cs.onSurface.withValues(alpha: 0.45),
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 12),

                // Time
                Text(
                  '${task.dueDate.hour.toString().padLeft(2, '0')}:${task.dueDate.minute.toString().padLeft(2, '0')}',
                  style: tt.labelSmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),

                // Subtask count (if any)
                if (totalSubtasks > 0) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '$completedSubtasks/$totalSubtasks',
                      style: tt.labelSmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],

                // Chevron
                const SizedBox(width: 8),
                Icon(
                  Icons.chevron_right_rounded,
                  color: cs.onSurfaceVariant.withValues(alpha: 0.4),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Single row showing task name and subtask completion progress.
class _SubtaskProgressRow extends StatelessWidget {
  final TaskModel task;

  const _SubtaskProgressRow({required this.task});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final completed = task.subtasks.where((s) => s.completed).length;
    final total = task.subtasks.length;
    final progress = total > 0 ? completed / total : 0.0;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                task.title,
                style: tt.bodyMedium?.copyWith(
                  color: cs.onSurface,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 5,
                  backgroundColor: cs.surfaceContainerHigh,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    completed == total ? cs.primary : cs.secondary,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            '$completed/$total',
            style: tt.labelSmall?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}

/// Single row showing an upcoming day and its task count.
class _UpcomingDayRow extends StatelessWidget {
  final DateTime day;
  final int taskCount;

  const _UpcomingDayRow({required this.day, required this.taskCount});

  String _formatDay(DateTime day) {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final dayNormalized = DateTime(day.year, day.month, day.day);

    if (dayNormalized == tomorrow) return 'Tomorrow';
    return DateFormat('EEEE').format(day);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Row(
      children: [
        Icon(
          Icons.calendar_today_rounded,
          size: 16,
          color: cs.onSurfaceVariant,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            _formatDay(day),
            style: tt.bodyMedium?.copyWith(
              color: cs.onSurface,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            '$taskCount task${taskCount == 1 ? '' : 's'}',
            style: tt.labelSmall?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}
