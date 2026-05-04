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
| Figma Prototype | https://www.figma.com/design/du2em5iANF6pbEDInkOThA/ |

---

## Features Implemented

### Required Features
- JWT authentication with persistent login (flutter_secure_storage)
- Two user roles with different rights enforced on both frontend and backend
- Full CRUD for tasks (create, edit, delete, view)
- Binary file upload and download (camera, gallery, file picker)
- Real-time group chat via WebSockets with persistent DB-backed history
- Offline task creation with automatic sync on reconnect (SQLite queue)
- Dark mode (persisted across sessions)
- Push notifications via Firebase Cloud Messaging
- Permission handling (camera, storage, location, notifications)

### Optional Requirements (PVP)
- **PVP4** — Google SSO authentication (google_sign_in)
- **PVP5** — Firebase Analytics + Crashlytics
- **PVP6** — Real-time GPS study location sharing with group map

### Screens (9 total)
1. Splash Screen
2. Login Screen
3. Register Screen
4. Home Screen (task list with role-based UI and unread chat badge)
5. Task Detail Screen (files, upload, download)
6. Create / Edit Task Screen
7. Group Chat Screen (WebSocket, persistent history)
8. Location Screen (GPS sharing, group member list)
9. Profile Screen (dark mode toggle, logout)

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

# 3. Run on Android device/emulator
flutter run
```

> **Note:** The app connects to `localhost:3000` on web and `10.0.2.2:3000` on Android emulator automatically.

### Optional Setup
- **Google Maps** — add your API key to `android/app/src/main/AndroidManifest.xml` to enable the map view on Android. Coordinates and group sharing work without a key.
- **Firebase** — place `google-services.json` in `android/app/` to enable push notifications, Analytics, and Crashlytics. The app runs normally without this file.

---

## Project Structure

```
lib/
├── main.dart                         # Entry point, routing, theme
├── models/                           # Data models (User, Task, File, ChatMessage)
├── services/                         # API, file upload, local DB, location
├── providers/                        # AuthProvider, ChatProvider, ThemeProvider
└── screens/
    ├── auth/                         # Login, Register
    ├── tasks/                        # Home, Task Detail, Create/Edit
    ├── chat/                         # Group Chat (WebSocket)
    └── profile/                      # Profile, Location (GPS)
```
