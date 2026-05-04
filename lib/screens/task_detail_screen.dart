import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/task_model.dart';
import '../providers/task_provider.dart';
import '../theme.dart';
import '../widgets/subtask_list_widget.dart';

class TaskDetailScreen extends ConsumerStatefulWidget {
  final String taskId;

  const TaskDetailScreen({super.key, required this.taskId});

  @override
  ConsumerState<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends ConsumerState<TaskDetailScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleCtrl;
  late final TextEditingController _descCtrl;
  DateTime? _dueDate;
  TimeOfDay? _dueTime;
  TaskPriority? _priority;
  bool _recurring = false;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController();
    _descCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tasks = ref.watch(taskListProvider);
    final task = tasks.firstWhere(
      (t) => t.id == widget.taskId,
      orElse: () => TaskModel(
        id: widget.taskId,
        title: 'Quest',
        description: '',
        dueDate: DateTime.now(),
      ),
    );
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    if (!_initialized) {
      _titleCtrl.text = task.title;
      _descCtrl.text = task.description;
      _dueDate = task.dueDate;
      _dueTime = TimeOfDay.fromDateTime(task.dueDate);
      _priority = task.priority;
      _recurring = task.recurringDaily;
      _initialized = true;
    }

    Future<void> saveTask() async {
      final form = _formKey.currentState;
      if (form == null || !form.validate()) return;
      final date = _dueDate ?? task.dueDate;
      final time = _dueTime ?? TimeOfDay.fromDateTime(task.dueDate);
      final nextDue = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );

      final updated = TaskModel(
        id: task.id,
        title: _titleCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        dueDate: nextDue,
        priority: _priority ?? task.priority,
        completed: task.completed,
        recurringDaily: _recurring,
        lastCompletedDate: task.lastCompletedDate,
        subtasks: task.subtasks,
        sortOrder: task.sortOrder,
      );

      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      await ref.read(taskListProvider.notifier).updateTask(updated);
      if (!mounted) return;
      messenger.showSnackBar(const SnackBar(content: Text('Quest updated')));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quest Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save_outlined),
            onPressed: saveTask,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
              TextFormField(
                controller: _descCtrl,
                decoration: const InputDecoration(labelText: 'Description'),
                style: tt.bodyLarge,
                maxLines: 3,
                maxLength: 500,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text('Due:', style: tt.labelLarge),
                  const SizedBox(width: 12),
                  TextButton.icon(
                    icon: Icon(Icons.calendar_today_rounded,
                        size: 16, color: cs.primary),
                    label: Text(
                      '${_dueDate!.year}-${_dueDate!.month.toString().padLeft(2, '0')}-${_dueDate!.day.toString().padLeft(2, '0')}',
                    ),
                    onPressed: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _dueDate!,
                        firstDate: DateTime.now()
                            .subtract(const Duration(days: 365)),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (date != null) {
                        setState(() {
                          _dueDate = DateTime(
                            date.year,
                            date.month,
                            date.day,
                            _dueTime?.hour ?? 0,
                            _dueTime?.minute ?? 0,
                          );
                        });
                      }
                    },
                  ),
                ],
              ),
              Row(
                children: [
                  Text('Time:', style: tt.labelLarge),
                  const SizedBox(width: 12),
                  TextButton.icon(
                    icon: Icon(Icons.access_time_rounded,
                        size: 16, color: cs.primary),
                    label: Text(
                      '${_dueTime!.hour.toString().padLeft(2, '0')}:${_dueTime!.minute.toString().padLeft(2, '0')}',
                    ),
                    onPressed: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: _dueTime!,
                      );
                      if (picked != null) {
                        setState(() => _dueTime = picked);
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
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
                    label: Text(p.name[0].toUpperCase() + p.name.substring(1)),
                    selected: isSelected,
                    selectedColor: chipColor,
                    backgroundColor: cs.surfaceContainerHigh,
                    checkmarkColor: cs.onSurface,
                    onSelected: (_) => setState(() => _priority = p),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  GestureDetector(
                    onTap: () => setState(() => _recurring = !_recurring),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color:
                            _recurring ? CozyColors.primary : Colors.transparent,
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
              const SizedBox(height: 20),
              SubtaskListWidget(task: task, dense: true),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: CozyColors.primaryGradient,
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: ElevatedButton(
                    onPressed: saveTask,
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
    );
  }
}
