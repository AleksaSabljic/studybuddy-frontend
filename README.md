# StudyBuddy Flutter Frontend

Mobile app for the Mobile and Wireless Technologies course.

## Quick Setup (do this in order)

### 1. Backend — WebSocket Support
Before running Flutter, patch your backend to support WebSocket chat:

```bash
cd studybuddy-backend
npm install ws
```

Then open `server.js`, find `app.listen(PORT, ...)` and replace it with the
code inside `BACKEND_WEBSOCKET_PATCH.txt`.

Also add a GET /auth/users endpoint to auth.js for student assignment:
```js
router.get('/users', authenticate, async (req, res) => {
  const result = await pool.query('SELECT id, username, email, role FROM users ORDER BY username');
  res.json({ users: result.rows });
});
```

### 2. Flutter — Network Config

**For Android Emulator:** The default `AppConfig.baseUrl = 'http://10.0.2.2:3000'` works.

**For Physical Device:** Change `10.0.2.2` to your PC's local IP in:
`lib/utils/app_config.dart`

Find your IP: `ipconfig` (Windows) → look for IPv4 under your WiFi adapter.

### 3. Firebase Setup (PVP4, PVP5)

1. Create a Firebase project at console.firebase.google.com
2. Add Android app with package name: `com.example.studybuddy`
3. Download `google-services.json` → place in `android/app/`
4. Enable:
   - **Authentication** → Google Sign-In
   - **Analytics**
   - **Crashlytics**
   - **Cloud Messaging** (for push notifications)

> Without google-services.json the app still runs — Firebase init is wrapped in try/catch.

### 4. Google Maps API Key (PVP6)

1. Get a key from Google Cloud Console (Maps SDK for Android)
2. Open `android/app/src/main/AndroidManifest.xml`
3. Replace `YOUR_GOOGLE_MAPS_API_KEY` with your actual key

### 5. Run the app

```bash
# Install dependencies
flutter pub get

# Check connected devices
flutter devices

# Run on device/emulator
flutter run

# Build APK for testing
flutter build apk --debug
```

---

## Project Structure

```
lib/
├── main.dart                    # App entry, routing, Firebase, theme
├── utils/
│   └── app_config.dart          # API URL, routes
├── models/
│   ├── user_model.dart
│   ├── task_model.dart          # Supports offline flag
│   ├── file_model.dart
│   └── chat_message.dart
├── services/
│   ├── auth_service.dart        # JWT login/register/storage
│   ├── task_service.dart        # API + offline queue
│   ├── file_service.dart        # Multipart upload/download
│   └── local_db_service.dart    # SQLite offline cache
├── providers/
│   ├── auth_provider.dart       # Auth state
│   └── theme_provider.dart      # Dark mode
└── screens/
    ├── splash_screen.dart
    ├── auth/
    │   ├── login_screen.dart
    │   └── register_screen.dart
    ├── tasks/
    │   ├── home_screen.dart          # Task list, role-based FAB
    │   ├── task_detail_screen.dart   # Files, upload, role guard
    │   └── create_edit_task_screen.dart
    ├── chat/
    │   └── chat_screen.dart          # WebSocket real-time chat
    └── profile/
        ├── profile_screen.dart
        └── location_screen.dart      # GPS + Google Maps (PVP6)
```

---

## Features Implemented

| Feature | Status |
|---------|--------|
| JWT Authentication (login/register/logout) | ✅ |
| Role-based UI (leader vs student) | ✅ |
| Task CRUD (full) | ✅ |
| File upload (camera/gallery/files) | ✅ |
| Permission handling | ✅ |
| Dark mode | ✅ |
| WebSocket chat | ✅ |
| Offline mode + sync queue | ✅ |
| Firebase Push Notifications | ✅ (needs google-services.json) |
| Firebase Analytics + Crashlytics (PVP5) | ✅ (needs google-services.json) |
| Google SSO (PVP4) | ⚙️ (needs Firebase Auth setup) |
| GPS Location sharing (PVP6) | ✅ (needs Maps API key) |

---

## Screens (for UAT demo)

1. **Splash** → auto-login check
2. **Login / Register** → with role selection
3. **Home** → task list, role-based edit/delete/FAB
4. **Task Detail** → description, file list, upload button
5. **Create/Edit Task** → form with student dropdown
6. **Chat** → real-time WebSocket group chat
7. **Location** → GPS map, share location button
8. **Profile** → user info, dark mode toggle, logout

---

## Troubleshooting

**"Connection refused" / tasks not loading:**
- Make sure backend is running: `node server.js`
- Check IP in `app_config.dart` matches your machine

**"Cleartext not permitted":**
- `android:usesCleartextTraffic="true"` is already set in AndroidManifest.xml

**Firebase errors on startup:**
- Normal without `google-services.json` — the app catches the error and continues

**WebSocket not connecting:**
- Make sure you applied the WebSocket patch to server.js
- Check that `ws` package is installed in backend
