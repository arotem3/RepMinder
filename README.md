# RepMinder

A personal iPhone app that reminds you to do bodyweight exercises throughout the day until you hit your daily rep goals.

## Features

- **Custom exercise goals** — add any exercise (push-ups, pull-ups, etc.) with a daily rep/time target
- **Weekly schedules** — choose training days and rest days for each exercise
- **Smart reminders** — frequent reminders when you're home (Wi-Fi based), less frequent when away
- **Log reps** — tap an exercise to log a set; the reminder cadence adjusts automatically
- **Quiet hours** — no reminders while you sleep
- **Streak tracking** — see how many consecutive days you've hit all goals
- **Bar chart** — 7/30/90-day completion history per exercise
- **Heatmap** — GitHub-style calendar view of the past 6 months

## Setup

### 1. Install xcodegen

```bash
brew install xcodegen
```

### 2. Generate the Xcode project

```bash
cd ~/RepMinder
make generate
```

This creates `RepMinder.xcodeproj`.

### 3. Open in Xcode

```bash
open RepMinder.xcodeproj
```

### 4. Sign the app

In Xcode → RepMinder target → Signing & Capabilities → select your Apple ID as the Team.

### 5. Run on your iPhone

Plug in your iPhone, select it as the destination, and press Run (⌘R).

---

## Wi-Fi Home Detection

The app reads your current Wi-Fi SSID to know whether you're home. This requires the **"Access WiFi Information"** entitlement, which needs a **paid Apple Developer account** ($99/yr).

**If you have a free account:** the Wi-Fi read will silently fail. Use the **"I'm home right now" toggle** in Settings as a manual override — it works identically.

---

## iOS Requirements

- iOS 17.0+
- Xcode 15+

## Project structure

```
RepMinder/
├── Models/
│   ├── Exercise.swift       SwiftData model for a goal
│   └── ExerciseLog.swift    SwiftData model for a logged set
├── Services/
│   ├── AppSettings.swift    UserDefaults-backed settings singleton
│   ├── NotificationService  Schedules/cancels UNNotifications
│   └── WiFiService.swift    NEHotspotNetwork SSID polling
└── Views/
    ├── TodayView            Daily progress + log-reps entry point
    ├── ExercisesView        Manage/reorder/delete goals
    ├── AddExerciseView      Add or edit a goal
    ├── LogRepsView          Stepper sheet for logging a set
    ├── HistoryView          Tab host for chart + heatmap
    ├── BarChartView         Swift Charts bar chart + streak
    ├── HeatmapView          Calendar heatmap + all-time totals
    └── SettingsView         Wi-Fi, intervals, quiet hours, notifications
```
