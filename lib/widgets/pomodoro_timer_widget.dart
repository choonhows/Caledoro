import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/settings_provider.dart';
import '../services/audio_service.dart';
import '../services/notification_service.dart';
import '../services/widget_service.dart';
import '../theme.dart';

enum PomodoroPhase { work, shortBreak, longBreak }

class PomodoroTimerWidget extends ConsumerStatefulWidget {
  const PomodoroTimerWidget({super.key});

  @override
  ConsumerState<PomodoroTimerWidget> createState() =>
      _PomodoroTimerWidgetState();
}

class _PomodoroTimerWidgetState extends ConsumerState<PomodoroTimerWidget>
    with TickerProviderStateMixin {
  PomodoroPhase phase = PomodoroPhase.work;
  Timer? _timer;
  int _remainingSeconds = 0;
  int _completedPomodoros = 0;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _remainingSeconds = _phaseDurationSeconds(phase);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  int _phaseDurationSeconds(PomodoroPhase phaseValue) {
    final settings = ref.read(settingsProvider);
    return switch (phaseValue) {
      PomodoroPhase.work => settings.workMinutes * 60,
      PomodoroPhase.shortBreak => settings.shortBreakMinutes * 60,
      PomodoroPhase.longBreak => settings.longBreakMinutes * 60,
    };
  }

  void _toggleTimer() {
    if (_timer?.isActive ?? false) {
      _timer?.cancel();
      _pulseController.stop();
      _pulseController.value = 0.0; // reset to 1.0 scale
      WidgetService.updateWidgets(
        secondsRemaining: _remainingSeconds,
        isWorking: phase == PomodoroPhase.work,
        completedTasks: _completedPomodoros,
        force: true,
      );
    } else {
      WidgetService.updateWidgets(
        secondsRemaining: _remainingSeconds,
        isWorking: phase == PomodoroPhase.work,
        completedTasks: _completedPomodoros,
        force: true,
      );
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          if (_remainingSeconds > 0) {
            _remainingSeconds--;
            WidgetService.updateWidgets(
              secondsRemaining: _remainingSeconds,
              isWorking: phase == PomodoroPhase.work,
              completedTasks: _completedPomodoros,
            );
          } else {
            timer.cancel();
            _pulseController.stop();
            _pulseController.value = 0.0;
            _handlePhaseCompletion();
            _remainingSeconds = _phaseDurationSeconds(phase);
            WidgetService.updateWidgets(
              secondsRemaining: _remainingSeconds,
              isWorking: phase == PomodoroPhase.work,
              completedTasks: _completedPomodoros,
              force: true,
            );
            if (ref.read(settingsProvider).autoStartNext) {
              _toggleTimer();
            }
          }
        });
      });
      if (!_pulseController.isAnimating) {
        _pulseController.repeat(reverse: true);
      }
    }
  }

  void _handlePhaseCompletion() {
    final settings = ref.read(settingsProvider);
    final finishedPhase = phase;

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

    if (finishedPhase == PomodoroPhase.work) {
      _completedPomodoros += 1;
      if (_completedPomodoros % settings.pomodorosUntilLongBreak == 0) {
        phase = PomodoroPhase.longBreak;
      } else {
        phase = PomodoroPhase.shortBreak;
      }
    } else {
      phase = PomodoroPhase.work;
    }
  }

  void _skipPhase() {
    _timer?.cancel();
    _pulseController.stop();
    _pulseController.value = 0.0;
    setState(() {
      if (phase == PomodoroPhase.work) {
        _completedPomodoros += 1;
        final settings = ref.read(settingsProvider);
        if (_completedPomodoros % settings.pomodorosUntilLongBreak == 0) {
          phase = PomodoroPhase.longBreak;
        } else {
          phase = PomodoroPhase.shortBreak;
        }
      } else {
        phase = PomodoroPhase.work;
      }
      _remainingSeconds = _phaseDurationSeconds(phase);
      WidgetService.updateWidgets(
        secondsRemaining: _remainingSeconds,
        isWorking: phase == PomodoroPhase.work,
        completedTasks: _completedPomodoros,
        force: true,
      );
    });
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    // Phase-specific colors from design tokens
    final phaseColor = switch (phase) {
      PomodoroPhase.work => cs.primary,
      PomodoroPhase.shortBreak => cs.secondary,
      PomodoroPhase.longBreak => cs.tertiary,
    };

    final phaseContainerColor = switch (phase) {
      PomodoroPhase.work => cs.primaryContainer,
      PomodoroPhase.shortBreak => cs.secondaryContainer,
      PomodoroPhase.longBreak => cs.tertiaryContainer,
    };

    final totalSeconds = phase == PomodoroPhase.work
        ? settings.workMinutes * 60
        : phase == PomodoroPhase.shortBreak
            ? settings.shortBreakMinutes * 60
            : settings.longBreakMinutes * 60;
    final ratio = totalSeconds == 0 ? 0.0 : _remainingSeconds / totalSeconds;

    final phaseLabel = switch (phase) {
      PomodoroPhase.work => 'Deep Work',
      PomodoroPhase.shortBreak => 'Short Break',
      PomodoroPhase.longBreak => 'Long Break',
    };

    final isRunning = _timer?.isActive ?? false;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Timer Ring — floating with ambient shadow ──
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: CozyColors.ambientShadow,
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _pulseAnimation.value,
                    child: SizedBox(
                      width: 220,
                      height: 220,
                      child: CircularProgressIndicator(
                        value: ratio,
                        strokeWidth: 14,
                        strokeCap: StrokeCap.round,
                        valueColor: AlwaysStoppedAnimation(phaseColor),
                        backgroundColor:
                            phaseContainerColor.withValues(alpha: 0.3),
                      ),
                    ),
                  );
                },
              ),
              GestureDetector(
                onTap: _toggleTimer,
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
                      // Timer countdown — monospace/pixel style
                      Text(
                        _formatTime(_remainingSeconds),
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
                        isRunning ? 'Tap to Pause' : 'Tap to Start',
                        style: tt.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 32),

        // ── Control Buttons — Pill shaped ──
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Start / Pause button
            _CozyPillButton(
              onPressed: _toggleTimer,
              label: isRunning ? 'Pause' : 'Start Quest',
              gradient: isRunning ? null : CozyColors.primaryGradient,
              backgroundColor: isRunning ? cs.secondaryContainer : null,
              textColor:
                  isRunning ? cs.onSecondaryContainer : CozyColors.onPrimary,
              icon: isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
            ),
            const SizedBox(width: 12),
            // Skip button
            _CozyPillButton(
              onPressed: _skipPhase,
              label: 'Skip',
              backgroundColor: cs.tertiaryContainer,
              textColor: cs.onTertiaryContainer,
              icon: Icons.skip_next_rounded,
            ),
          ],
        ),

        const SizedBox(height: 24),

        // ── Completed cycles ──
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: cs.surfaceContainerLow,
            borderRadius: BorderRadius.circular(100),
          ),
          child: Text(
            'Completed cycles: $_completedPomodoros',
            style: tt.labelMedium?.copyWith(color: cs.onSurfaceVariant),
          ),
        ),
      ],
    );
  }
}

/// A reusable pill-shaped button matching the Cozy Quests design system.
class _CozyPillButton extends StatelessWidget {
  final VoidCallback onPressed;
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
