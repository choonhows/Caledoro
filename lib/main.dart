import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'services/hive_service.dart';
import 'screens/home_widget_screen.dart';
import 'screens/calendar_screen.dart';
import 'screens/pomodoro_settings_screen.dart';
import 'providers/settings_provider.dart';
import 'providers/task_provider.dart';
import 'theme.dart';
import 'services/notification_service.dart';
import 'widgets/pomodoro_timer_widget.dart';
import 'widgets/task_checklist_widget.dart';
import 'utils/date_utils.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await HiveService.init();
  await NotificationService.init();

  final container = ProviderContainer();
  await container
      .read(taskListProvider.notifier)
      .dailyResetRecurring(DateTime.now());

  runApp(UncontrolledProviderScope(
    container: container,
    child: const CaledoroApp(),
  ));
}

class CaledoroApp extends ConsumerStatefulWidget {
  const CaledoroApp({super.key});

  @override
  ConsumerState<CaledoroApp> createState() => _CaledoroAppState();
}

class _CaledoroAppState extends ConsumerState<CaledoroApp> {
  int _selectedIndex = 0;

  static const List<Widget> _pages = <Widget>[
    HomeWidgetScreen(),
    _FocusShrineScreen(),
    CalendarScreen(),
  ];

  void _onNavSelected(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);

    return MaterialApp(
      title: 'Caledoro',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: settings.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: Scaffold(
        body: _pages.elementAt(_selectedIndex),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: _onNavSelected,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.assignment_outlined),
              selectedIcon: Icon(Icons.assignment),
              label: 'Quests',
            ),
            NavigationDestination(
              icon: Icon(Icons.temple_buddhist_outlined),
              selectedIcon: Icon(Icons.temple_buddhist),
              label: 'Shrine',
            ),
            NavigationDestination(
              icon: Icon(Icons.calendar_today_outlined),
              selectedIcon: Icon(Icons.calendar_today),
              label: 'Calendar',
            ),
          ],
        ),
      ),
    );
  }
}

/// The Focus Shrine tab wraps the PomodoroTimerWidget in a full-screen layout
/// with a settings gear icon and the cozy design system styling.
class _FocusShrineScreen extends ConsumerWidget {
  const _FocusShrineScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final tasks = ref.watch(taskListProvider);
    final selectedDate = ref.watch(selectedDateProvider);
    final settings = ref.watch(settingsProvider);

    final dayTasks = tasks
        .where((task) => DateUtilsHelper.isSameDay(task.dueDate, selectedDate))
        .toList();
    final remaining = dayTasks.where((t) => !t.completed).length;
    final remainingLabel =
        '$remaining task${remaining == 1 ? '' : 's'} left';
    final focusMinutes = settings.workMinutes;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Focus Shrine'),
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
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.04),
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.wb_sunny_outlined,
                      size: 16,
                      color: cs.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Focus Session',
                      style: tt.labelLarge?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        'Pomodoro',
                        style: tt.labelSmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),
            const Center(child: PomodoroTimerWidget()),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.timer_outlined,
                      size: 16,
                      color: cs.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Focus · $focusMinutes min · $remainingLabel',
                      style: tt.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Sanctuary Tasks',
                style: tt.titleLarge?.copyWith(
                      color: cs.onSurface,
                    ),
              ),
            ),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Stay grounded, check your quests, then return to focus.',
                style: tt.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.only(left: 6),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const TaskChecklistWidget(
                  showSubtasks: true,
                  showSubtaskComposer: false,
                  allowSubtaskReorder: false,
                  allowTaskReorder: false,
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
