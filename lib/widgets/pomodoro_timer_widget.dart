import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/pomodoro_phase.dart';
import '../providers/pomodoro_timer_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/task_provider.dart';
import '../services/audio_service.dart';
import '../services/notification_service.dart';
import '../theme.dart';
import '../utils/date_utils.dart';

class PomodoroTimerWidget extends ConsumerWidget {
  const PomodoroTimerWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timerState = ref.watch(pomodoroTimerProvider);
    final settings = ref.watch(settingsProvider);
    final tasks = ref.watch(taskListProvider);
    final selectedDate = ref.watch(selectedDateProvider);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final dayTasks = tasks
        .where((task) => DateUtilsHelper.isSameDay(task.dueDate, selectedDate))
        .toList();
    final canStartTimer = dayTasks.isNotEmpty;

    // Phase-specific colors
    final phaseColor = switch (timerState.phase) {
      PomodoroPhase.work => cs.primary,
      PomodoroPhase.shortBreak => cs.secondary,
      PomodoroPhase.longBreak => cs.tertiary,
    };

    final phaseContainerColor = switch (timerState.phase) {
      PomodoroPhase.work => cs.primaryContainer,
      PomodoroPhase.shortBreak => cs.secondaryContainer,
      PomodoroPhase.longBreak => cs.tertiaryContainer,
    };

    final totalSeconds = switch (timerState.phase) {
      PomodoroPhase.work => settings.workMinutes * 60,
      PomodoroPhase.shortBreak => settings.shortBreakMinutes * 60,
      PomodoroPhase.longBreak => settings.longBreakMinutes * 60,
    };
    final ratio = totalSeconds == 0 ? 0.0 : timerState.remainingSeconds / totalSeconds;

    final phaseLabel = switch (timerState.phase) {
      PomodoroPhase.work => 'Deep Work',
      PomodoroPhase.shortBreak => 'Short Break',
      PomodoroPhase.longBreak => 'Long Break',
    };

    // Handle phase completion effects (move to provider if preferred)
    ref.listen(pomodoroTimerProvider, (previous, next) {
      if (previous?.phase != next.phase && previous != null) {
        // Phase changed, trigger notifications/sounds
        final finishedPhase = previous.phase;
        if (settings.notificationsEnabled) {
          final body = switch (finishedPhase) {
            PomodoroPhase.work => 'Work session complete. Time for a break.',
            PomodoroPhase.shortBreak => 'Break complete. Back to deep work.',
            PomodoroPhase.longBreak => 'Long break complete. Back to deep work.',
          };
          NotificationService.showPhaseNotification(
            title: 'Pomodoro Complete',
            body: body,
          );
        }
        if (settings.soundEnabled) {
          if (finishedPhase == PomodoroPhase.work) {
            AudioService.playTimerComplete();
          } else if (finishedPhase == PomodoroPhase.shortBreak) {
            AudioService.playBreakStart();
          } else {
            AudioService.playSessionEnd();
          }
        }
      }
    });

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Timer Ring (same as before, but using timerState.remainingSeconds)
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: CozyColors.ambientShadow,
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 220,
                height: 220,
                child: CircularProgressIndicator(
                  value: ratio,
                  strokeWidth: 14,
                  strokeCap: StrokeCap.round,
                  valueColor: AlwaysStoppedAnimation(phaseColor),
                  backgroundColor: phaseContainerColor.withValues(alpha: 0.3),
                ),
              ),
              GestureDetector(
                onTap: () => _handleTimerTap(context, ref, canStartTimer),
                child: Container(
                  width: 190,
                  height: 190,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: cs.surfaceContainerLowest,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _formatTime(timerState.remainingSeconds),
                        style: tt.displayMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: cs.onSurface,
                          letterSpacing: 3,
                          fontFamily: 'monospace',
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        phaseLabel,
                        style: tt.labelLarge?.copyWith(color: phaseColor),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        timerState.isRunning ? 'Tap to Pause' : 'Tap to Start',
                        style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),
        if (!canStartTimer)
          Text(
            'Add a quest for today to start the timer.',
            style: tt.bodySmall?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
        const SizedBox(height: 20),

        // Control Buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _CozyPillButton(
              onPressed: canStartTimer
                ? () => ref.read(pomodoroTimerProvider.notifier).toggleTimer()
                : null,
              label: canStartTimer
                  ? timerState.isRunning
                      ? 'Pause'
                      : 'Start Quest'
                  : 'No quests available',
              gradient: canStartTimer && !timerState.isRunning
                  ? CozyColors.primaryGradient
                  : null,
              backgroundColor: !canStartTimer
                  ? cs.surfaceContainerLow
                  : timerState.isRunning
                      ? cs.secondaryContainer
                      : null,
              textColor: !canStartTimer
                  ? cs.onSurfaceVariant
                  : timerState.isRunning
                      ? cs.onSecondaryContainer
                      : CozyColors.onPrimary,
              icon: timerState.isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
            ),
            const SizedBox(width: 12),
            _CozyPillButton(
              onPressed: canStartTimer
                ? () => ref.read(pomodoroTimerProvider.notifier).skipPhase()
                : null,
              label: 'Skip',
              backgroundColor:
                  canStartTimer ? cs.tertiaryContainer : cs.surfaceContainerLow,
              textColor:
                  canStartTimer ? cs.onTertiaryContainer : cs.onSurfaceVariant,
              icon: Icons.skip_next_rounded,
            ),
          ],
        ),

        const SizedBox(height: 24),

        // Completed cycles
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: cs.surfaceContainerLow,
            borderRadius: BorderRadius.circular(100),
          ),
          child: Text(
            'Completed cycles: ${timerState.completedPomodoros}',
            style: tt.labelMedium?.copyWith(color: cs.onSurfaceVariant),
          ),
        ),
      ],
    );
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  void _handleTimerTap(BuildContext context, WidgetRef ref, bool canStartTimer) {
    if (!canStartTimer) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Add a quest before starting your focus session.'),
          duration: Duration(milliseconds: 1200),
        ),
      );
      return;
    }
    ref.read(pomodoroTimerProvider.notifier).toggleTimer();
  }
}

/// A reusable pill-shaped button matching the Cozy Quests design system.
class _CozyPillButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String label;
  final LinearGradient? gradient;
  final Color? backgroundColor;
  final Color textColor;
  final IconData? icon;

  const _CozyPillButton({
    required this.onPressed,
    required this.label,
    this.gradient,
    this.backgroundColor,
    required this.textColor,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(100),
        child: Ink(
          decoration: BoxDecoration(
            gradient: gradient,
            color: gradient == null ? backgroundColor : null,
            borderRadius: BorderRadius.circular(100),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, color: textColor, size: 20),
                const SizedBox(width: 8),
              ],
              Text(
                label,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: textColor,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
