# Streak — Habit Tracker

A premium-feeling monochrome habit tracker built with Flutter. Track daily habits, maintain streaks, and complete a 90-day challenge.

## Features

- 🔥 Streak tracking with auto-reset on missed days
- ✅ Buttery-smooth check/uncheck animations (custom `CustomPainter`)
- 📊 GitHub-style contribution grid (last 3 days editable)
- 🎯 90-day challenge progress
- 🌙 Monochrome design system with Plus Jakarta Sans

## Architecture

```
lib/
├── core/           # Theme, utils, router, providers, services
├── features/
│   ├── auth/       # (placeholder — Firebase Auth later)
│   ├── onboarding/ # 2-page onboarding flow
│   ├── habit/      # Main feature — CRUD, animations
│   └── target/     # 90-day challenge model
└── main.dart
```

## Quick Start

```bash
# Install dependencies
flutter pub get

# Run on connected device / emulator
flutter run

# Analyze
flutter analyze
```

## Firebase Integration (TODO)

1. Create a Firebase project at [console.firebase.google.com](https://console.firebase.google.com)
2. Enable **Firestore** and **Google Sign-In** under Authentication
3. Install FlutterFire CLI:
   ```bash
   dart pub global activate flutterfire_cli
   flutterfire configure
   ```
4. Add Firebase packages to `pubspec.yaml`:
   ```yaml
   firebase_core: ^3.0.0
   cloud_firestore: ^5.0.0
   firebase_auth: ^5.0.0
   google_sign_in: ^6.0.0
   ```
5. Replace `MockAuthService` with `FirebaseAuth`
6. Replace `HabitRepository` / `TargetRepository` with Firestore implementations
7. Deploy Firestore rules from `firestore.rules`

## Riverpod Code-Gen (TODO)

To convert to `@riverpod` code-gen:

1. Add to `pubspec.yaml`:
   ```yaml
   dependencies:
     riverpod_annotation: ^2.6.0
   dev_dependencies:
     riverpod_generator: ^2.6.0
     build_runner: ^2.4.0
   ```
2. Add `@riverpod` annotations and `part` directives to provider files
3. Run: `dart run build_runner build --delete-conflicting-outputs`

## Stack

| Layer | Technology |
|-------|-----------|
| UI | Flutter (Material 3) |
| State | Riverpod |
| Router | go_router |
| Fonts | Google Fonts (Plus Jakarta Sans) |
| Backend | Mock (Firebase-ready) |
