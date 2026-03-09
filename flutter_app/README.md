# AZ Learner — Flutter Android App

Native Android application for the AZ Learner student platform, built with Flutter.

## Features

- 🎓 **Timetable** — Weekly class schedule with notifications
- 📚 **Assignments** — Task tracker with AI assistance powered by Gemini
- 📝 **Notes** — Rich note-taking with a beautiful dark grid interface
- 🍅 **Study Room** — Pomodoro timer + lofi radio + ambient sounds + focus goal
- 🤖 **AZ AI** — Conversational AI study buddy
- 🔔 **Push Notifications** — Works even when the app is closed (FCM)
- 🔥 **Streak & XP System** — Gamified daily engagement
- 👤 **Profile** — View stats, rank, and programme info

## Project Structure

```
flutter_app/
├── lib/
│   ├── main.dart                    # App entry point, Firebase init
│   ├── router.dart                  # GoRouter navigation setup
│   ├── firebase_options.dart        # Firebase configuration (replace with yours)
│   ├── theme/
│   │   └── app_theme.dart           # Dark theme, colors, typography
│   ├── models/
│   │   ├── user_model.dart
│   │   ├── assignment.dart
│   │   ├── course.dart
│   │   └── note.dart
│   ├── services/
│   │   ├── auth_service.dart        # Firebase Auth + FCM token management
│   │   ├── firestore_service.dart   # Firestore CRUD operations
│   │   ├── notification_service.dart # Local + push notifications (FCM)
│   │   └── ai_service.dart          # Gemini AI integration
│   ├── screens/
│   │   ├── splash_screen.dart
│   │   ├── auth/
│   │   │   ├── login_screen.dart
│   │   │   └── register_screen.dart
│   │   ├── main_screen.dart         # Bottom navigation shell
│   │   ├── home/
│   │   │   └── home_screen.dart
│   │   ├── timetable_screen.dart
│   │   ├── tasks_screen.dart
│   │   ├── notes_screen.dart
│   │   ├── chat_screen.dart
│   │   ├── study_room/
│   │   │   └── study_room_screen.dart  # Pomodoro + lofi radio
│   │   └── profile_screen.dart
│   └── widgets/
│       └── task_ai_sheet.dart       # AI chat sheet for task assistance
├── android/
│   ├── app/
│   │   ├── build.gradle
│   │   ├── google-services.json     # ⚠️ Replace with your Firebase config
│   │   └── src/main/
│   │       ├── AndroidManifest.xml
│   │       └── kotlin/com/azlearner/app/
│   │           └── MainActivity.kt
│   ├── build.gradle
│   └── settings.gradle
├── pubspec.yaml
├── PLAY_STORE_INSTRUCTIONS.md       # Step-by-step Play Store guide
└── README.md
```

## Quick Start

```bash
# 1. Install dependencies
flutter pub get

# 2. Replace firebase config
# Download google-services.json from Firebase Console
# Place at android/app/google-services.json
# Update lib/firebase_options.dart with your values

# 3. Run in debug mode
flutter run

# 4. Build release AAB for Play Store
flutter build appbundle --release --dart-define=GEMINI_API_KEY=YOUR_KEY
```

## Tech Stack

| Technology | Purpose |
|-----------|---------|
| Flutter 3.2+ | Cross-platform UI framework |
| Firebase Auth | Authentication |
| Cloud Firestore | Real-time database |
| Firebase Messaging (FCM) | Push notifications (background + foreground) |
| flutter_local_notifications | Scheduled local notifications |
| just_audio | Lofi radio streaming |
| google_generative_ai | Gemini AI for task assistance |
| go_router | Navigation |
| provider | State management |
| google_fonts (Poppins) | Typography |
| flutter_animate | UI animations |

## Push Notifications Architecture

Notifications work in 3 scenarios:

1. **App in foreground** — `FirebaseMessaging.onMessage` triggers local notification
2. **App in background** — FCM system tray notification, tap opens app
3. **App closed** — `@pragma('vm:entry-point')` background handler processes FCM message and shows local notification

See `PLAY_STORE_INSTRUCTIONS.md` for full setup guide.
