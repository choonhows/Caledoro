import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../widgets/mini_calendar_widget.dart';
import '../widgets/task_checklist_widget.dart';
import '../models/task_model.dart';
import '../models/settings_model.dart';
import '../providers/settings_provider.dart';
import '../providers/task_provider.dart';
import '../theme.dart';

class CalendarScreen extends ConsumerWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final selectedDate = ref.watch(selectedDateProvider);
    final settings = ref.watch(settingsProvider);

    String monthName(DateTime date) => DateFormat('MMMM').format(date);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),

              // ── Header (integrated into body, no AppBar) ──
              Text(
                'Cozy Calendar',
                style: tt.headlineMedium?.copyWith(
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${monthName(selectedDate)} ${selectedDate.year}',
                style: tt.bodyMedium?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),

              const SizedBox(height: 20),

              // ── Calendar Widget ──
              const MiniCalendarWidget(),

              const SizedBox(height: 24),

              // ── Selected day header ──
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${monthName(selectedDate)} ${selectedDate.day}',
                      style: tt.titleLarge?.copyWith(
                        color: cs.onSurface,
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
                        selected:
                            settings.taskSortMode == TaskSortMode.custom,
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

              // ── Tasks for selected day ──
              const TaskChecklistWidget(),

              const SizedBox(height: 100), // space for FAB
            ],
          ),
        ),
      ),

      // ── FAB — Pill-shaped add button ──
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) {
            return const _AddTaskPanel();
          },
        ),
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Quest'),
      ),
    );
  }
}

// ─── Add Task Bottom Sheet — Glassmorphism style ─────────────────────────────

class _AddTaskPanel extends ConsumerStatefulWidget {
  const _AddTaskPanel();

  @override
  ConsumerState<_AddTaskPanel> createState() => _AddTaskPanelState();
}

class _AddTaskPanelState extends ConsumerState<_AddTaskPanel> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  DateTime? _dueDate;
  TimeOfDay? _dueTime;
  TaskPriority _priority = TaskPriority.medium;
  bool _recurring = false;

  @override
  void initState() {
    super.initState();
    _dueDate = ref.read(selectedDateProvider);
    _dueTime = TimeOfDay.fromDateTime(_dueDate ?? DateTime.now());
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final dueDate = _dueDate ?? DateTime.now();

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            // Glassmorphism: surface_variant at 60% opacity + backdrop blur
            color: CozyColors.surfaceVariant.withValues(alpha: 0.85),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Handle bar ──
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: cs.onSurfaceVariant.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  Text(
                    'New Quest',
                    style: tt.headlineSmall?.copyWith(
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Title field ──
                  TextFormField(
                    controller: _titleCtrl,
                    decoration: const InputDecoration(labelText: 'Quest Title'),
                    style: tt.bodyLarge,
                    validator: (value) => (value == null || value.isEmpty)
                        ? 'Title is required'
                        : value.trim().length > 200
                            ? 'Title must be 200 characters or less'
                            : null,
                  ),
                  const SizedBox(height: 12),

                  // ── Description field ──
                  TextFormField(
                    controller: _descCtrl,
                    decoration: const InputDecoration(labelText: 'Description'),
                    style: tt.bodyLarge,
                    maxLines: 2,
                    maxLength: 500,
                    validator: (value) => (value != null && value.length > 500)
                        ? 'Description must be 500 characters or less'
                        : null,
                  ),
                  const SizedBox(height: 16),

                  // ── Due date ──
                  Row(
                    children: [
                      Text('Due:', style: tt.labelLarge),
                      const SizedBox(width: 12),
                      TextButton.icon(
                        icon: Icon(Icons.calendar_today_rounded,
                            size: 16, color: cs.primary),
                        label: Text(
                          '${dueDate.year}-${dueDate.month.toString().padLeft(2, '0')}-${dueDate.day.toString().padLeft(2, '0')}',
                        ),
                        onPressed: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: dueDate,
                            firstDate: DateTime.now()
                                .subtract(const Duration(days: 365)),
                            lastDate:
                                DateTime.now().add(const Duration(days: 365)),
                          );
                          if (date != null) {
                            setState(() {
                              _dueDate = DateTime(date.year, date.month,
                                  date.day, dueDate.hour, dueDate.minute);
                            });
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text('Time:', style: tt.labelLarge),
                      const SizedBox(width: 12),
                      TextButton.icon(
                        icon: Icon(Icons.access_time_rounded,
                            size: 16, color: cs.primary),
                        label: Text(
                          _dueTime == null
                              ? 'Set Time'
                              : '${_dueTime!.hour.toString().padLeft(2, '0')}:${_dueTime!.minute.toString().padLeft(2, '0')}',
                        ),
                        onPressed: () async {
                          final picked = await showTimePicker(
                            context: context,
                            initialTime: _dueTime ?? TimeOfDay.now(),
                          );
                          if (picked != null) {
                            setState(() {
                              _dueTime = picked;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // ── Priority — Chip selector ──
                  Text('Priority', style: tt.labelLarge),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: TaskPriority.values.map((p) {
                      final isSelected = _priority == p;
                      final chipColor = switch (p) {
                        TaskPriority.high => cs.tertiaryContainer,
                        TaskPriority.medium => cs.secondaryContainer,
                        TaskPriority.low => cs.primaryContainer,
                      };
                      return ChoiceChip(
                        label:
                            Text(p.name[0].toUpperCase() + p.name.substring(1)),
                        selected: isSelected,
                        selectedColor: chipColor,
                        backgroundColor: cs.surfaceContainerHigh,
                        checkmarkColor: cs.onSurface,
                        onSelected: (_) => setState(() => _priority = p),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),

                  // ── Recurring toggle ──
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => setState(() => _recurring = !_recurring),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: _recurring
                                ? CozyColors.primary
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            border: _recurring
                                ? null
                                : Border.all(color: cs.outline, width: 1.5),
                          ),
                          child: _recurring
                              ? const Icon(Icons.check_rounded,
                                  size: 18, color: CozyColors.onPrimary)
                              : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text('Recurring Daily', style: tt.bodyLarge),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // ── Save button — Primary gradient pill ──
                  SizedBox(
                    width: double.infinity,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: CozyColors.primaryGradient,
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: ElevatedButton(
                        onPressed: () async {
                          final state = _formKey.currentState;
                          if (state == null || !state.validate()) return;

                          final title = _titleCtrl.text.trim();
                          if (title.isEmpty) return;

                          final date = _dueDate ?? DateTime.now();
                          final time = _dueTime;
                          final dueDateTime = DateTime(
                            date.year,
                            date.month,
                            date.day,
                            time?.hour ?? 0,
                            time?.minute ?? 0,
                          );

                          try {
                            await ref.read(taskListProvider.notifier).addTask(
                                  title: title,
                                  description: _descCtrl.text.trim(),
                                  dueDate: dueDateTime,
                                  priority: _priority,
                                  recurringDaily: _recurring,
                                );
                            if (context.mounted) Navigator.pop(context);
                          } catch (e) {
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(e.toString())),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          foregroundColor: CozyColors.onPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text('Save Quest'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
