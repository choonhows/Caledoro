# 📱 Caledoro

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](./LICENSE)

**Caledoro** is a lightweight, offline‑first productivity app built with **Flutter (Dart)**. It combines a **To‑Do Playlist**, **customizable Pomodoro timer**, **calendar integration**, and **Android home screen widgets** — all designed for simplicity and smooth performance.

🚀 This application is ready for team collaboration, and optimized for offline use with persistent storage.

---

## 🔑 Features

### 🧠 Productivity Tools
- **To‑Do Playlist** — Organize daily tasks into ordered lists
- **Pomodoro Timer**  
  - Configurable work/break durations  
  - Short & long breaks  
  - Cycle persistence after app restarts  
  - Notifications for start/end and breaks  
  - Pause/Skip controls

### 📅 Calendar Integration
- Lightweight monthly & daily views
- Tasks optionally linked to calendar dates
- Task creation supports explicit due-time selection
- UI calendar navigation with events and task markers

### 🎨 Themes
- Minimal clean UI
- Light & Dark modes
- Customizable accent colors

### 🔁 Daily Progress
- Recurring daily tasks with automatic day rollover reset
- Completion streak tracking surfaced on the home screen
- Rotating daily motivational quotes

### 📲 Android Home Screen Widgets
- Pomodoro countdown widget
- Quick start/pause widget actions
- Today’s top task at a glance
- Checkpointed widget sync cadence (phase changes, minute boundaries, periodic checkpoints) to reduce battery/storage churn

---

## 🗃️ Data Storage (Hive)

Data is stored locally using **Hive**:

| Box Name       | Purpose |
|----------------|---------|
| `tasksBox`     | Stores TaskModel objects |
| `settingsBox`  | Pomodoro settings & theme preferences |
| `widgetBox`    | Home widget state |

### 📦 Data Models

- **TaskModel** – id, title, description, dueDate, priority (enum), completed, recurringDaily  
- **SettingsModel** – workDuration, shortBreakDuration, longBreakDuration, darkMode, accentColor  

---

## 🧠 State Management

State is managed using **Riverpod** with `NotifierProvider` pattern. All state changes persist to Hive automatically.

**Key Providers:**
- `taskListProvider` – Manages all tasks (add, update, delete, toggle completion)
  - Uses typed failures (`TaskOperationException`) for task operation error paths
- `settingsProvider` – Manages Pomodoro durations and theme settings
- `streakProvider` – Computes and exposes current recurring-task streak
- `quoteProvider` – Returns a deterministic quote-of-the-day

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

Uses `flutter_local_notifications` to notify:
- Pomodoro start
- Pomodoro end
- Break start/end

Permission behavior:
- Notification permission is requested during app initialization
- Settings screen shows notification authorization status with a re-check action

---

## 📂 Architecture

The app follows a **Riverpod-based Provider Pattern** with clear separation of concerns:

```text
lib/
├── main.dart                    # App initialization & navigation
├── theme.dart                   # Theme configuration
├── models/                      # Data models with Hive serialization
│   ├── task_model.dart
│   ├── task_model.g.dart
│   ├── settings_model.dart
│   └── settings_model.g.dart
├── providers/                   # Riverpod NotifierProviders (state management)
│   ├── task_provider.dart       # TaskListNotifier
│   ├── settings_provider.dart   # SettingsNotifier
│   ├── streak_provider.dart     # Streak derivation/state
│   └── quote_provider.dart      # Daily quote selection
├── screens/                     # Page-level widgets
│   ├── home_widget_screen.dart
│   ├── calendar_screen.dart
│   └── pomodoro_settings_screen.dart
├── services/                    # Data & external integrations
│   ├── hive_service.dart        # Hive storage initialization
│   ├── widget_service.dart      # Home widget updates
│   ├── notification_service.dart# Local notifications
│   └── audio_service.dart       # Timer completion sound
├── widgets/                     # Reusable UI components
│   ├── pomodoro_timer_widget.dart
│   ├── task_checklist_widget.dart
│   └── mini_calendar_widget.dart
└── utils/                       # Helper functions
    └── date_utils.dart
```

### State Management Flow
- **Providers** (`task_provider.dart`, `settings_provider.dart`) manage all app state
- **Widgets** use `ConsumerWidget` / `ConsumerStatefulWidget` to watch and mutate state
- **Hive** persists state through `HiveService`
- **Models** use code generation (`@HiveType`, `@HiveField`) for serialization

---

## 🚀 Run & Build

### ✅ Prerequisites
- Flutter SDK installed
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

- 23 passing tests (`unit`, `widget`, and `integration`)
- Serial execution required for Hive stability:

```bash
flutter test --concurrency=1
```

- Coverage generation:

```bash
flutter test --coverage --concurrency=1
```

- Latest measured line coverage: **65.10%** (`coverage/lcov.info`)

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
| flutter_local_notifications | Local alerts |
| table_calendar | Calendar UI |
| home_widget | Android home screen widgets |

---

## 🎯 Priorities

1. To‑Do Playlist + Pomodoro Timer  
2. Calendar integration  
3. Theme customization  
4. Home screen widget interactivity

---

## 📝 License

This project is licensed under the MIT License. See the [LICENSE](./LICENSE) file for details.
