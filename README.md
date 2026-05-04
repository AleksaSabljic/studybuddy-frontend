# StudyBuddy — Flutter Frontend

**Course:** Základy mobilných a bezdrôtových technológií | LS 2026  
**Student:** Aleksa Sabljic  
**Platform:** Android (Flutter) — also runs on Chrome for demonstration

---

## What is StudyBuddy?

StudyBuddy is a mobile study group management application. It allows students to organize study tasks, upload study materials, communicate via real-time group chat, and share their study location with group members.

Two user roles are supported:
- **Group Leader** — creates and manages tasks, assigns students, uploads files
- **Student** — views assigned tasks, uploads files, participates in chat

---

## Links

| Resource | Link |
|----------|------|
| Backend GitHub | https://github.com/AleksaSabljic/studybuddy-backend |
| Frontend GitHub | https://github.com/AleksaSabljic/studybuddy-frontend |
| API Documentation (Swagger) | http://localhost:3000/api-docs |

---

## Features Implemented

### Required Features
- JWT authentication with persistent login (flutter_secure_storage)
- Two user roles with different rights enforced on both frontend and backend
- Full CRUD for tasks (create, edit, delete, view)
- Binary file upload and download (camera, gallery, file picker)
- Real-time group chat via WebSockets with persistent DB-backed history
- Unread message badge with accurate count (own messages excluded)
- Offline task caching via SQLite with fallback on reconnect
- Dark mode (persisted across sessions)
- Permission handling (camera, storage, location, notifications)

### Optional Requirements (PVP)
- **PVP1** — Cross-Platform Support: built with Flutter, runs fully on Android and web browsers (Chrome). The complete application was demonstrated and verified running on Chrome, making it accessible on any device with a browser.
- **PVP5** — Firebase Services: Analytics and Crashlytics fully configured for both Android (`google-services.json`) and web (`firebase_options.dart`). Analytics tracks user interactions. Crashlytics provides automatic crash reporting. Firebase Cloud Messaging handles push notifications in both foreground and background.
- **PVP6** — Location Based Service: students share their GPS coordinates with the group via the `geolocator` package. `POST /location` saves coordinates to the database. `GET /location/group` returns all active members (updated within last 5 minutes). The group list updates in real time. On Android, Google Maps displays member pins (API key required — see Known Limitations). On web, coordinates are listed in the info card.

### Screens (9 total)
1. Splash Screen
2. Login Screen
3. Register Screen
4. Home Screen (task list with role-based UI and unread chat badge)
5. Task Detail Screen (files, upload, download)
6. Create / Edit Task Screen
7. Group Chat Screen (WebSocket, persistent history)
8. Location Screen (GPS sharing, group member list)
9. Profile Screen (user info, logout)

---

## How to Run

### Prerequisites
- Flutter 3.x installed
- Backend running at `http://localhost:3000` (see backend README)

### Steps

```bash
# 1. Install dependencies
flutter pub get

# 2. Run on Chrome (for demonstration)
flutter run -d chrome

# 3. Run on Android emulator
flutter run
```

> **Note:** The app connects to `localhost:3000` on web and `10.0.2.2:3000` on Android emulator automatically. For a physical Android device, update `baseUrl` in `lib/utils/app_config.dart` to your machine's local IP address.

### Known Limitations
- **Google Maps on web** — the map view is replaced with a placeholder on Chrome (Google Maps requires a native API key). GPS coordinates and group location sharing work correctly on both platforms. To enable the map on Android, add your Google Maps API key to `android/app/src/main/AndroidManifest.xml`.

---

## Project Structure

```
lib/
├── main.dart                         # Entry point, routing, theme, Firebase init
├── firebase_options.dart             # Firebase configuration (web + Android)
├── models/                           # Data models (User, Task, File, ChatMessage)
├── services/                         # API, file upload, local DB, location
├── providers/                        # AuthProvider, ChatProvider, ThemeProvider
└── screens/
    ├── auth/                         # Login, Register
    ├── tasks/                        # Home, Task Detail, Create/Edit
    ├── chat/                         # Group Chat (WebSocket)
    └── profile/                      # Profile, Location (GPS)
```
