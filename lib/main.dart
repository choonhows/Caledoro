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
class _FocusShrineScreen extends StatelessWidget {
  const _FocusShrineScreen();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

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
            // Phase indicator chip
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(100),
              ),
              child: Text(
                'Phase: Deep Work',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
              ),
            ),
            const SizedBox(height: 32),
            const Center(child: PomodoroTimerWidget()),
            const SizedBox(height: 28),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Sanctuary Tasks',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: cs.onSurface,
                    ),
              ),
            ),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Check tasks while the timer runs. Tap a quest to open details.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
              ),
            ),
            const SizedBox(height: 12),
            const TaskChecklistWidget(
              showSubtasks: true,
              showSubtaskComposer: false,
              allowSubtaskReorder: false,
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
