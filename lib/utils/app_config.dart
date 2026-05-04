import 'package:flutter/foundation.dart' show kIsWeb;

class AppConfig {
  // Web uses localhost; Android emulator uses 10.0.2.2 (maps to host machine).
  // Physical device: replace 10.0.2.2 with your computer's local IP (e.g. 192.168.x.x).
  static String get baseUrl =>
      kIsWeb ? 'http://localhost:3000' : 'http://10.0.2.2:3000';

  static String get wsUrl =>
      kIsWeb ? 'ws://localhost:3000' : 'ws://10.0.2.2:3000';

  // Token storage key
  static const String tokenKey = 'jwt_token';
  static const String userKey = 'user_data';
}

class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
  static const String taskDetail = '/task-detail';
  static const String createTask = '/create-task';
  static const String editTask = '/edit-task';
  static const String chat = '/chat';
  static const String profile = '/profile';
  static const String location = '/location';
}
