import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/settings_provider.dart';
import '../services/notification_service.dart';

final notificationAuthorizationProvider = FutureProvider<bool>((ref) async {
  return NotificationService.isAuthorized();
});

class PomodoroSettingsScreen extends ConsumerWidget {
  const PomodoroSettingsScreen({super.key});

  Future<void> _update(
    BuildContext context,
    WidgetRef ref, {
    int? workMinutes,
    int? shortBreakMinutes,
    int? longBreakMinutes,
    int? pomodorosUntilLongBreak,
    bool? autoStartNext,
    bool? notificationsEnabled,
    bool? soundEnabled,
    bool? isDarkMode,
  }) async {
    await ref.read(settingsProvider.notifier).update(
          workMinutes: workMinutes,
          shortBreakMinutes: shortBreakMinutes,
          longBreakMinutes: longBreakMinutes,
          pomodorosUntilLongBreak: pomodorosUntilLongBreak,
          autoStartNext: autoStartNext,
          notificationsEnabled: notificationsEnabled,
          soundEnabled: soundEnabled,
          isDarkMode: isDarkMode,
        );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Settings saved'),
        duration: Duration(milliseconds: 900),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Timer Settings Section ──
            Text('Timer', style: tt.titleLarge),
            const SizedBox(height: 16),

            _CozySettingControl(
              label: 'Work (minutes)',
              value: settings.workMinutes,
              onUpdate: (n) => _update(context, ref, workMinutes: n),
            ),
            _CozySettingControl(
              label: 'Short Break (minutes)',
              value: settings.shortBreakMinutes,
              onUpdate: (n) => _update(context, ref, shortBreakMinutes: n),
            ),
            _CozySettingControl(
              label: 'Long Break (minutes)',
              value: settings.longBreakMinutes,
              onUpdate: (n) => _update(context, ref, longBreakMinutes: n),
            ),
            _CozySettingControl(
              label: 'Long Break every (pomodoros)',
              value: settings.pomodorosUntilLongBreak,
              onUpdate: (n) =>
                  _update(context, ref, pomodorosUntilLongBreak: n),
            ),

            const SizedBox(height: 32),

            // ── Toggles Section ──
            Text('Preferences', style: tt.titleLarge),
            const SizedBox(height: 16),

            _CozyToggle(
              label: 'Auto-start next',
              value: settings.autoStartNext,
              onChanged: (v) => _update(context, ref, autoStartNext: v),
            ),
            _CozyToggle(
              label: 'Notifications',
              value: settings.notificationsEnabled,
              onChanged: (v) async {
                await _update(context, ref, notificationsEnabled: v);
                ref.invalidate(notificationAuthorizationProvider);
              },
            ),
            _NotificationStatusCard(
              onRefresh: () =>
                  ref.invalidate(notificationAuthorizationProvider),
            ),
            _CozyToggle(
              label: 'Sound',
              value: settings.soundEnabled,
              onChanged: (v) => _update(context, ref, soundEnabled: v),
            ),

            const SizedBox(height: 32),

            // ── Appearance Section ──
            Text('Appearance', style: tt.titleLarge),
            const SizedBox(height: 16),

            _CozyToggle(
              label: 'Dark Mode',
              value: settings.isDarkMode,
              onChanged: (v) => _update(context, ref, isDarkMode: v),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _NotificationStatusCard extends ConsumerWidget {
  final VoidCallback onRefresh;

  const _NotificationStatusCard({required this.onRefresh});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final status = ref.watch(notificationAuthorizationProvider);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(24),
      ),
      child: status.when(
        data: (authorized) {
          final title = authorized
              ? 'Notification permission is enabled.'
              : 'Notification permission is disabled.';
          final subtitle = authorized
              ? 'Pomodoro alerts can appear when enabled in preferences.'
              : 'Enable OS notification permission to receive timer alerts.';
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                authorized
                    ? Icons.notifications_active_rounded
                    : Icons.notifications_off_rounded,
                color: authorized ? cs.primary : cs.tertiary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: tt.bodyMedium?.copyWith(
                        color: cs.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: tt.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    if (!authorized) ...[
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: () async {
                          await NotificationService.requestPermissions();
                          onRefresh();
                        },
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Check permission again'),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          );
        },
        loading: () => Row(
          children: [
            SizedBox(
              height: 16,
              width: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: cs.primary,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Checking notification permission...',
              style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            ),
          ],
        ),
        error: (_, __) => Text(
          'Unable to verify notification permission right now.',
          style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
        ),
      ),
    );
  }
}

// ─── Cozy Numeric Setting Control ────────────────────────────────────────────

class _CozySettingControl extends StatelessWidget {
  final String label;
  final int value;
  final void Function(int) onUpdate;

  const _CozySettingControl({
    required this.label,
    required this.value,
    required this.onUpdate,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: tt.bodyLarge?.copyWith(color: cs.onSurface),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _RoundButton(
                icon: Icons.remove_rounded,
                onTap: () => onUpdate(value > 1 ? value - 1 : 1),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  value.toString(),
                  style: tt.titleMedium?.copyWith(
                    color: cs.onSurface,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
              _RoundButton(
                icon: Icons.add_rounded,
                onTap: () => onUpdate(value + 1),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Cozy Toggle Switch ──────────────────────────────────────────────────────

class _CozyToggle extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _CozyToggle({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: tt.bodyLarge?.copyWith(color: cs.onSurface)),
          Switch(
            value: value,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

// ─── Round increment/decrement button ────────────────────────────────────────

class _RoundButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _RoundButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Material(
      color: cs.surfaceContainerHigh,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, size: 20, color: cs.onSurfaceVariant),
        ),
      ),
    );
  }
}
