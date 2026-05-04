import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/chat_provider.dart';
import 'providers/theme_provider.dart';
import 'utils/app_config.dart';

// Screens
import 'screens/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/tasks/home_screen.dart';
import 'screens/tasks/task_detail_screen.dart';
import 'screens/tasks/create_edit_task_screen.dart';
import 'screens/chat/chat_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/profile/location_screen.dart';

// Background message handler — must be top-level
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

final FlutterLocalNotificationsPlugin localNotifications =
    FlutterLocalNotificationsPlugin();

Future<void> _initLocalNotifications() async {
  const android = AndroidInitializationSettings('@mipmap/ic_launcher');
  const ios = DarwinInitializationSettings();
  const settings = InitializationSettings(android: android, iOS: ios);
  await localNotifications.initialize(
    settings,
    onDidReceiveNotificationResponse: (details) {
      // TODO: navigate to relevant content based on payload
    },
  );
}

Future<void> _initFirebase() async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Crashlytics
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

  // FCM
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  await FirebaseMessaging.instance.requestPermission();

  // Foreground notifications
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    final n = message.notification;
    if (n == null) return;
    localNotifications.show(
      0,
      n.title,
      n.body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'studybuddy_channel',
          'StudyBuddy',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      payload: message.data.toString(),
    );
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase — wrap in try/catch so app runs without google-services.json during dev
  try {
    await _initFirebase();
    await _initLocalNotifications();
  } catch (e) {
    debugPrint('Firebase init skipped (no config): $e');
  }

  runApp(const StudyBuddyApp());
}

class StudyBuddyApp extends StatelessWidget {
  const StudyBuddyApp({super.key});

  static final _analytics = FirebaseAnalytics.instanceFor(
    app: Firebase.apps.isNotEmpty
        ? Firebase.app()
        : throw Exception('No Firebase app'),
  );

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()..init()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (_, themeProvider, __) {
          return MaterialApp(
            title: 'StudyBuddy',
            debugShowCheckedModeBanner: false,
            themeMode: themeProvider.themeMode,
            theme: _buildTheme(Brightness.light),
            darkTheme: _buildTheme(Brightness.dark),
            initialRoute: AppRoutes.splash,
            routes: {
              AppRoutes.splash: (_) => const SplashScreen(),
              AppRoutes.login: (_) => const LoginScreen(),
              AppRoutes.register: (_) => const RegisterScreen(),
              AppRoutes.home: (_) => const HomeScreen(),
              AppRoutes.taskDetail: (_) => const TaskDetailScreen(),
              AppRoutes.createTask: (_) => const CreateEditTaskScreen(),
              AppRoutes.editTask: (_) => const CreateEditTaskScreen(),
              AppRoutes.chat: (_) => const ChatScreen(),
              AppRoutes.profile: (_) => const ProfileScreen(),
              AppRoutes.location: (_) => const LocationScreen(),
            },
          );
        },
      ),
    );
  }

  ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final seed = const Color(0xFF3B5BDB); // Indigo-blue

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorSchemeSeed: seed,
      fontFamily: 'Roboto',
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        filled: true,
        fillColor: isDark ? Colors.grey[900] : Colors.grey[50],
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
      ),
    );
  }
}
