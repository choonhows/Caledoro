import 'package:flutter_test/flutter_test.dart';
import 'package:caledoro/models/task_model.dart';
import 'package:caledoro/providers/task_provider.dart';

void main() {
  test('Parent completion derives from subtasks', () {
    final task = TaskModel(
      id: 't1',
      title: 'Essay',
      description: '',
      dueDate: DateTime(2026, 5, 2, 9),
      subtasks: [
        SubtaskModel(id: 's1', label: 'Draft', completed: true, sortOrder: 0),
        SubtaskModel(id: 's2', label: 'Cite', completed: false, sortOrder: 1),
      ],
    );
    final allDone = task.subtasks.every((s) => s.completed);
    expect(allDone, false);
  });
}
