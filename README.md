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
- UI calendar navigation with events and task markers

### 🎨 Themes
- Minimal clean UI
- Light & Dark modes
- Customizable accent colors

### 📲 Android Home Screen Widgets
- Pomodoro countdown widget
- Quick start/pause widget actions
- Today’s top task at a glance

---

## 🗃️ Data Storage (Hive)

Data is stored locally using **Hive**:

| Box Name       | Purpose |
|----------------|---------|
| `tasksBox`     | Stores Task objects |
| `pomodoroBox`  | Stores timer settings |
| `calendarBox`  | Stores calendar events |
| `settingsBox`  | Theme & preferences |

### 📦 Data Models

- **Task** – id, title, description, status, priority, linked Pomodoro, optional date  
- **Pomodoro** – work duration, short/long break, cycles completed, total cycles  
- **CalendarEvent** – id, title, start/end, optional task link  

---

## 🧠 State Management

State is managed using **Riverpod** (or Provider). Timer and task state is preserved when the app is minimized or restarted.

---

## 🔔 Notifications

Uses `flutter_local_notifications` to notify:
- Pomodoro start
- Pomodoro end
- Break start/end

---

## 📂 Architecture

```text
lib/
├── core/
│   ├── timer/
│   ├── calendar/
│   └── storage/
├── features/
│   ├── pomodoro/
│   ├── todo/
│   └── theme/
├── widgets/
└── main.dart
```

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

(Add integration & unit tests here when available)

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
