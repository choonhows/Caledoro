# 📱 Caledoro

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](./LICENSE)

**Caledoro** is a lightweight, offline‑first productivity app built with **Flutter (Dart)**. It combines a **To‑Do Playlist**, **AI-powered subtask generation**, **customizable Pomodoro timer**, **calendar integration**, and **Android home screen widgets** — all designed for simplicity and smooth performance.

🚀 This application is ready for team collaboration, and optimized for offline use with persistent storage.

---

## 🔑 Features

### 🧠 Productivity Tools
- **To‑Do Playlist** — Organize daily tasks into ordered lists with priority-first or custom drag-reorder sorting
- **Subtasks** — Break tasks into ordered checklists with progress tracking, drag-reorder, and inline composer
- **AI Subtask Generator** — Gemini-powered task decomposition with accept/reject flow
  - Generates 3–7 actionable subtasks from a task title and description
  - Individual accept/reject per suggestion, or accept/reject all at once
  - Manual subtask entry as fallback when offline or API is unavailable
  - Connectivity check before API calls; offline state surfaced in UI
  - Atomic tasks return an empty array (no unnecessary subtasks)
- **Pomodoro Timer**
  - Configurable work/break durations
  - Short & long breaks with automatic cycle progression
  - Cycle persistence after app restarts
  - Notifications for start/end and breaks
  - Pause/Skip controls
  - Foreground service for background timer on Android

### 📅 Calendar Integration
- Lightweight monthly & daily views via `table_calendar`
- Tasks linked to calendar dates with priority-colored marker dots
- Task creation supports explicit due-time selection
- Bottom-sheet task creation with subtasks, priority, and recurring toggle
- Smart vs Custom task ordering per day

### 🎨 Themes
- Material 3 design system with custom color tokens (`CozyColors`)
- Light & Dark modes (auto-generated from seed color)
- Plus Jakarta Sans / Be Vietnam Pro / Space Grotesk typography

### 📊 Smart Home Dashboard
The Quests tab is a unified dashboard replacing the original home screen. It shows:
- **Date header** with day-of-week and motivational prompt
- **Priority Quests** — top 3 tasks for today sorted by priority, with "+N more" overflow
- **Focus Session** — live Pomodoro status with one-tap jump to the Shrine tab
- **Subtask Progress** — per-task subtask completion counts across today's tasks
- **Coming Up** — preview of tasks due in the next 7 days

### 🔁 Daily Progress
- Recurring daily tasks with automatic day rollover reset
- Completion streak tracking surfaced on the home screen
- Rotating daily motivational quotes

### 📲 Android Home Screen Widgets
- Pomodoro countdown widget with focus/break status and quest count
- Checkpointed widget sync cadence (phase changes, minute boundaries, periodic checkpoints)
- Native `AppWidgetProvider` with `RemoteViews` layout

### 📱 iOS Support (In Progress)
- Cupertino-conditional UI: `CupertinoTabBar`, `CupertinoNavigationBar`, `CupertinoSwitch`, `CupertinoAlertDialog`
- Platform detection via `dart:io Platform.isIOS`
- iOS-specific AppDelegate registration for `flutter_foreground_task` and `flutter_local_notifications`
- **Not yet complete:** iOS home screen widget (WidgetKit extension not implemented), simulator/build testing pending macOS access

---

## 🗃️ Data Storage (Hive)

Data is stored locally using **Hive**:

| Box Name       | Purpose |
|----------------|---------|
| `tasksBox`     | Stores `TaskModel` objects (including embedded subtasks) |
| `settingsBox`  | Pomodoro settings & theme preferences (`SettingsModel`) |
| `widgetBox`    | App metadata (streak counters, reset timestamps) |
| `timerBox`     | Pomodoro timer state (`PomodoroTimerModel`) |

### 📦 Data Models

| Model | typeId | Fields |
|-------|--------|--------|
| `TaskPriority` | 0 | `low`, `medium`, `high` |
| `TaskModel` | 1 | id, title, description, dueDate, priority, completed, recurringDaily, lastCompletedDate, subtasks, sortOrder |
| `SettingsModel` | 2 | workMinutes, shortBreakMinutes, longBreakMinutes, pomodorosUntilLongBreak, isDarkMode, notificationsEnabled, autoStartNext, taskSortMode |
| `SubtaskCreator` | 3 | `user`, `ai` |
| `SubtaskModel` | 4 | id, label, completed, sortOrder, createdBy, suggested, acceptedAt |
| `TaskSortMode` | 5 | `smart`, `custom` |
| `PomodoroTimerModel` | 6 | phase, remainingSeconds, completedPomodoros, isRunning |
| `PomodoroPhase` | 7 | `work`, `shortBreak`, `longBreak` |

> **Codegen required:** After editing any `@HiveType`/`@HiveField` annotations, run `flutter pub run build_runner build` to regenerate adapters.

---

## 🧠 State Management

State is managed using **Riverpod** with `NotifierProvider` pattern. All state changes persist to Hive automatically.

**Key Providers:**
- `taskListProvider` — Manages all tasks (CRUD, completion toggle, daily reset, streak)
  - Uses typed failures (`TaskOperationException`) for task operation error paths
- `settingsProvider` — Manages Pomodoro durations and theme settings
- `pomodoroTimerProvider` — Timer lifecycle, phase transitions, widget sync
- `selectedDateProvider` — Currently selected date for calendar/dashboard views
- `selectedTabProvider` — Bottom navigation tab index
- `subtaskGenerationProvider` — AI subtask generation state machine (`idle → generating → success/error/offline`)
- `streakProvider` — Computes and exposes current recurring-task streak from `widgetBox` metadata
- `quoteProvider` — Returns a deterministic quote-of-the-day (7 quotes, rotating by day-of-year)

Widgets access state via:
```dart
// Read current state
final tasks = ref.watch(taskListProvider);

// Mutate state
await ref.read(taskListProvider.notifier).addTask(
  title: 'Write docs',
  dueDate: DateTime.now(),
);
```

---

## 🔔 Notifications

Uses `flutter_local_notifications` with two Android channels:
- Ongoing timer notification (shows current phase and remaining time)
- Phase completion notification (work/break finished)

Permission behavior:
- Notification permission is requested during app initialization
- Settings screen shows notification authorization status with a re-check action

---

## 📂 Architecture

The app follows a **Riverpod-based Provider Pattern** with clear separation of concerns:

```text
lib/
├── main.dart                       # App bootstrap, 3-tab navigation (Quests, Shrine, Calendar)
├── theme.dart                      # CozyColors tokens, light/dark ThemeData
├── data/
│   └── quotes.dart                 # 7 daily motivational quotes
├── models/                         # Hive-backed data models with adapters
│   ├── task_model.dart             # TaskModel, SubtaskModel, TaskPriority, SubtaskCreator, TaskSortMode
│   ├── task_model.g.dart
│   ├── settings_model.dart         # SettingsModel
│   ├── settings_model.g.dart
│   ├── pomodoro_phase.dart         # PomodoroPhase enum
│   ├── pomodoro_phase.g.dart
│   ├── pomodoro_timer_model.dart   # PomodoroTimerModel
│   └── pomodoro_timer_model.g.dart
├── providers/                      # Riverpod NotifierProviders (state + Hive persistence)
│   ├── task_provider.dart          # TaskListNotifier, SelectedDateNotifier
│   ├── settings_provider.dart      # SettingsNotifier
│   ├── pomodoro_timer_provider.dart# PomodoroTimerNotifier (timer lifecycle)
│   ├── subtask_generation_provider.dart # SubtaskGenerationNotifier (AI state machine)
│   ├── selected_tab_provider.dart  # Bottom nav index
│   ├── streak_provider.dart        # Streak derivation from widgetBox
│   └── quote_provider.dart         # Daily quote selection
├── screens/                        # Page-level widgets
│   ├── dashboard_screen.dart       # Quests tab (date header, priority tasks, focus session, subtask progress, upcoming)
│   ├── calendar_screen.dart        # Calendar tab (table_calendar, task list, bottom-sheet creation)
│   ├── task_detail_screen.dart     # Task detail/edit with AI subtask generation
│   └── pomodoro_settings_screen.dart # Timer durations, notification status, appearance
├── services/                       # Platform & API integrations
│   ├── hive_service.dart           # Hive init, adapter registration (typeIds 0–7), 4 boxes
│   ├── subtask_generator_service.dart # Gemini 3.5 Flash API + connectivity wrapper + NoOp fallback
│   ├── subtask_prompt_template.dart # buildSubtaskPrompt() pure function
│   ├── connectivity_service.dart   # connectivity_plus wrapper, OfflineException
│   ├── widget_service.dart         # home_widget bridge, throttled updates
│   ├── notification_service.dart   # flutter_local_notifications wrapper, 2 channels
│   ├── foreground_timer_service.dart # flutter_foreground_task wrapper (Android background)
│   └── audio_service.dart          # SystemSound playback for phase transitions
├── widgets/                        # Reusable UI components
│   ├── task_checklist_widget.dart  # Configurable task list with smart/custom sort modes
│   ├── subtask_list_widget.dart    # Subtask management with drag-reorder, inline composer
│   ├── ai_subtask_generator_widget.dart # AI suggestion UI (generate, accept/reject per item)
│   ├── pomodoro_timer_widget.dart  # Circular timer ring (220px) with controls
│   └── mini_calendar_widget.dart   # table_calendar wrapper with priority dot markers
└── utils/
    └── date_utils.dart             # DateUtilsHelper.isSameDay() static helper
```

### State Management Flow
- **Providers** manage all app state and persist changes through Hive-backed models
- **Widgets** use `ConsumerWidget` / `ConsumerStatefulWidget` to watch and mutate state
- **Services** handle platform integrations (Hive, notifications, widgets, foreground tasks, API calls)
- **Models** use code generation (`@HiveType`, `@HiveField`) for Hive serialization

---

## 🚀 Run & Build

### ✅ Prerequisites
- Flutter SDK (3.44.6+ / Dart 3.12.2+)
- Android toolchain (SDK 36+)
- Android device or emulator (optional)
- VS Code or other editor

### 📦 Install Dependencies

```bash
flutter pub get
```

### 🏃 Run Dev Builds

```bash
flutter run -d linux       # Linux desktop
flutter run -d chrome      # Web (Chrome/Chromium)
flutter run -d <device_id> # Android device/emulator
```

### 📱 Build APK

```bash
flutter build apk --split-per-abi
```

Output will be under `build/app/outputs/flutter-apk/`.

---

## 🧪 Testing

Current local test suite:

- **73 passing tests** (`unit`, `widget`, and `integration`)
- Serial execution required for Hive stability:

```bash
flutter test --concurrency=1
```

- Coverage generation:

```bash
flutter test --coverage --concurrency=1
```

- Latest measured line coverage: **42.57%** (`coverage/lcov.info`)

---

## 🤝 Collaboration

We use a feature‑branch workflow:

```bash
git checkout -b feature/<feature-name>
git add .
git commit -m "Add <feature>"
git push origin feature/<feature-name>
```

Then open a Pull Request on GitHub for review.

---

## 🛠 Tech Stack

| Technology | Purpose |
|------------|---------|
| Flutter / Dart | Cross-platform UI |
| Hive | Offline persistence |
| Riverpod | State management |
| http | Gemini API client |
| connectivity_plus | Network detection |
| flutter_local_notifications | Local alerts |
| flutter_foreground_task | Android background timer |
| table_calendar | Calendar UI |
| home_widget | Android home screen widgets |
| google_fonts | Custom typography |

---

## 📝 License

This project is licensed under the MIT License. See the [LICENSE](./LICENSE) file for details.
