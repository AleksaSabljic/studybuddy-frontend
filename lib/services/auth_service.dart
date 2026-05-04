import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';
import '../utils/app_config.dart';

class AuthService {
  static const _storage = FlutterSecureStorage();

  // ─── Token helpers ───────────────────────────────────────────────────────

  static Future<String?> getToken() async {
    return await _storage.read(key: AppConfig.tokenKey);
  }

  static Future<UserModel?> getUser() async {
    final data = await _storage.read(key: AppConfig.userKey);
    if (data == null) return null;
    return UserModel.fromJsonString(data);
  }

  static Future<void> saveSession(String token, UserModel user) async {
    await _storage.write(key: AppConfig.tokenKey, value: token);
    await _storage.write(key: AppConfig.userKey, value: user.toJsonString());
  }

  static Future<void> clearSession() async {
    await _storage.deleteAll();
  }

  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  // ─── Auth headers ────────────────────────────────────────────────────────

  static Future<Map<String, String>> authHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // ─── Register ────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String password,
    required String role,
  }) async {
    final response = await http.post(
      Uri.parse('${AppConfig.baseUrl}/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'email': email,
        'password': password,
        'role': role,
      }),
    );

    final body = jsonDecode(response.body);
    return {
      'success': response.statusCode == 201,
      'message': body['message'] ?? 'Unknown error',
      'data': body,
    };
  }

  // ─── Login ───────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('${AppConfig.baseUrl}/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    final body = jsonDecode(response.body);

    if (response.statusCode == 200) {
      final token = body['token'];
      final user = UserModel.fromJson(body['user']);
      await saveSession(token, user);
      return {'success': true, 'user': user, 'token': token};
    }

    return {'success': false, 'message': body['message'] ?? 'Login failed'};
  }

  // ─── Logout ──────────────────────────────────────────────────────────────

  static Future<void> logout() async {
    await clearSession();
  }
}
