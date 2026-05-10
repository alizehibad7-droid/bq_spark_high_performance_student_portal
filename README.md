<div align="center">

# BQ Spark — High Performance Student Portal

**A Flutter app for Bano Qabil’s HP Track students — tasks, progress, and learning in one place.**

[![Flutter](https://img.shields.io/badge/Flutter-3.11+-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.11+-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
[![Firebase](https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black)](https://firebase.google.com)
[![Platform](https://img.shields.io/badge/Platform-iOS%20%7C%20Android%20%7C%20Web-555555?style=for-the-badge)](https://flutter.dev/multi-platform)

</div>

---

## About :blue_book:

**BQ Spark** is the digital companion for **Bano Qabil’s High Performance (HP) Track** in Rawalpindi, Pakistan — a selective program that prepares top students for industry-ready skills in mobile development, Firebase-backed apps, and professional workflows. The portal gives **students** a focused workspace for tasks, rankings, and resources, while **admins** can manage cohorts, announcements, and progress — all backed by Firebase and modern Flutter UI.

---

## Screenshots :camera_flash:

> Add your screenshots to `docs/screenshots/` (or `.github/`) and embed them here.

```text
[placeholder for screenshots]

Example after you add images:
![Home](docs/screenshots/home.png)
![Tasks](docs/screenshots/tasks.png)
```

---

## Features :sparkles:

| Area | Highlights |
|------|------------|
| Access | Student & Admin **role-based** login |
| Learning | **Task** management with **points** system |
| Engagement | **Real-time leaderboard** |
| Content | **Resource library** with **PDF** support |
| Updates | **Tech news** feed |
| AI | **AI Study Assistant** (using **Groq**) |
| Alerts | **Push notifications** (FCM) |
| Ops | **Remote Config** for live feature flags & copy |
| Quality | **Crash reporting** (Crashlytics) |

---

## Tech Stack :hammer_and_wrench:

| Layer | Technologies |
|--------|--------------|
| **App** | Flutter & Dart (SDK `>=3.11.0 <4.0.0`) |
| **Backend** | **Firebase** — Auth, Firestore, FCM, Crashlytics, Remote Config, Storage |
| **AI** | **Groq** API key (study assistant) |
| **State** | **Provider** (ChangeNotifier pattern) |
| **News** | **NewsAPI** |
| **HTTP** | `http` package for REST integrations |

---

## Setup Instructions :rocket:

### Prerequisites

- **Flutter** stable channel (compatible with Dart **3.11+**)
- **Git**
- A **Firebase** project (for Auth, Firestore, Storage, FCM, Remote Config, Crashlytics)
- Optional: **Android Studio** / **Xcode** for device emulators

### 1. Clone the repository

```bash
git clone <your-repo-url>
cd bq_spark_high_performance_student_portal
```

### 2. Install dependencies

```bash
flutter pub get
```

### 3. Firebase configuration

1. Create a Firebase project in the [Firebase Console](https://console.firebase.google.com).
2. Register **Android**, **iOS**, and/or **Web** apps and download platform config files as needed.
3. Use [FlutterFire CLI](https://firebase.google.com/docs/flutter/setup) to generate `lib/firebase_options.dart`:

   ```bash
   dart pub global activate flutterfire_cli
   flutterfire configure
   ```

4. Place **`google-services.json`** under `android/app/` (Android) and **`GoogleService-Info.plist`** under `ios/Runner/` (iOS) if you configure manually.

### 4. API keys and secrets

| Integration | Where to configure |
|-------------|-------------------|
| **Groq** (AI assistant) | `lib/services/ai_service.dart` — set your API key / endpoint as implemented in the project |
| **NewsAPI** | `lib/services/news_service.dart` and/or `lib/screens/news_screen.dart` — replace `YOUR_NEWSAPI_KEY` |

> Never commit real keys to public repositories. Prefer `--dart-define`, environment files (gitignored), or CI secrets.

### 5. Run the app

```bash
# List devices
flutter devices

# Run (pick device or -d chrome for web)
flutter run
```

### 6. Release builds (optional)

```bash
flutter build apk    # Android
flutter build ios    # iOS (macOS only)
flutter build web    # Web
```

---

## Architecture :building_construction:

The app follows a **layered MVVM-style** structure common in Flutter:

- **View** - `lib/screens/` and widgets: UI only, reacts to state.
- **ViewModel** - `lib/providers/` (Provider + `ChangeNotifier`): exposes state, calls services, notifies listeners.
- **Model** - `lib/models/`: immutable or focused data types (e.g. user, task).
- **Services** - `lib/services/`: Firebase, HTTP (AI, news), notifications; no UI.

Data flows **View -> Provider -> Service -> Firebase/API**, then updates propagate back through **`notifyListeners()`** and **`context.watch`** / **`read`**. This keeps screens thin and testable.

---

## Team :busts_in_silhouette:

```text
[placeholder]

Add names, roles, and links (LinkedIn / GitHub) here.
```

---

## License :scroll:

Specify your license here (e.g. MIT, proprietary) once decided.

---

<div align="center">

Built with care for **Bano Qabil — BQ Spark HP Track**

</div>
