import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:caledoro/models/task_model.dart';
import 'package:caledoro/providers/task_provider.dart';
import 'package:caledoro/services/hive_service.dart';
import 'package:caledoro/utils/date_utils.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await HiveService.init();
  });

  setUp(() async {
    await HiveService.tasksBox().clear();
  });

  tearDownAll(() async {
    await Hive.close();
  });

  test('Reorder ignores tasks from other days and appends remaining', () async {
    final day = DateTime(2026, 5, 2, 9);
    final otherDay = DateTime(2026, 5, 3, 9);

    final first = TaskModel(
      id: 't1',
      title: 'Alpha',
      description: '',
      dueDate: day,
    );
    final second = TaskModel(
      id: 't2',
      title: 'Beta',
      description: '',
      dueDate: day,
    );
    final other = TaskModel(
      id: 't3',
      title: 'Gamma',
      description: '',
      dueDate: otherDay,
    );

    final box = HiveService.tasksBox();
    await box.put(first.id, first);
    await box.put(second.id, second);
    await box.put(other.id, other);

    final container = ProviderContainer();
    addTearDown(container.dispose);

    final notifier = container.read(taskListProvider.notifier);
    final state = container.read(taskListProvider);
    final orderedDayTask = state.firstWhere((task) => task.id == 't2');
    final orderedOtherDayTask = state.firstWhere((task) => task.id == 't3');

    await notifier.reorderTasksForDay(
      day,
      [orderedDayTask, orderedOtherDayTask],
    );

    final next = container.read(taskListProvider);
    final sameDayIds = next
        .where((task) => DateUtilsHelper.isSameDay(task.dueDate, day))
        .map((task) => task.id)
        .toList();
    expect(sameDayIds, ['t2', 't1']);

    final otherDayTasks = next
        .where((task) => DateUtilsHelper.isSameDay(task.dueDate, otherDay))
        .toList();
    expect(otherDayTasks.length, 1);
    expect(otherDayTasks.first.id, 't3');
    expect(next.length, 3);
  });

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
