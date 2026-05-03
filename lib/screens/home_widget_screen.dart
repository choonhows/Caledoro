import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/settings_model.dart';
import '../providers/settings_provider.dart';
import '../providers/task_provider.dart';
import '../providers/streak_provider.dart';
import '../providers/quote_provider.dart';
import '../screens/pomodoro_settings_screen.dart';
import '../theme.dart';
import '../utils/date_utils.dart';
import '../widgets/task_checklist_widget.dart';

class HomeWidgetScreen extends ConsumerWidget {
  const HomeWidgetScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = ref.watch(taskListProvider);
    final today = ref.watch(selectedDateProvider);
    final streak = ref.watch(streakProvider);
    final quote = ref.watch(quoteProvider);
    final settings = ref.watch(settingsProvider);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    // Count tasks remaining for today
    final dayTasks =
        tasks.where((task) => DateUtilsHelper.isSameDay(task.dueDate, today));
    final remaining = dayTasks.where((t) => !t.completed).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Caledoro'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PomodoroSettingsScreen()),
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

            // ── Streak Card (floating island) ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: CozyColors.primaryGradient,
                borderRadius: BorderRadius.circular(24),
                boxShadow: CozyColors.ambientShadow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Current Streak',
                    style: tt.labelLarge?.copyWith(
                      color: CozyColors.onPrimary.withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${streak.toString().padLeft(2, '0')} DAYS',
                    style: tt.displaySmall?.copyWith(
                      color: CozyColors.onPrimary,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── Daily Focus Quote ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cs.surfaceContainerLow,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Daily Focus',
                    style: tt.titleSmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '"$quote"',
                    style: tt.bodyLarge?.copyWith(
                      color: cs.onSurface,
                      fontStyle: FontStyle.italic,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // ── The Playlist Header ──
            Text(
              'The Playlist',
              style: tt.headlineMedium?.copyWith(
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '$remaining Quest${remaining == 1 ? '' : 's'} remaining for today',
                    style: tt.bodyMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ),
                Wrap(
                  spacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text('Smart'),
                      selected: settings.taskSortMode == TaskSortMode.smart,
                      selectedColor: cs.primaryContainer,
                      backgroundColor: cs.surfaceContainerHigh,
                      checkmarkColor: cs.onSurface,
                      onSelected: (_) => ref
                          .read(settingsProvider.notifier)
                          .update(taskSortMode: TaskSortMode.smart),
                    ),
                    ChoiceChip(
                      label: const Text('Custom'),
                      selected: settings.taskSortMode == TaskSortMode.custom,
                      selectedColor: cs.secondaryContainer,
                      backgroundColor: cs.surfaceContainerHigh,
                      checkmarkColor: cs.onSurface,
                      onSelected: (_) => ref
                          .read(settingsProvider.notifier)
                          .update(taskSortMode: TaskSortMode.custom),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 16),

            // ── Task Checklist ──
            const TaskChecklistWidget(),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
