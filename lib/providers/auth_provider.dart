import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/task_service.dart';

class AuthProvider extends ChangeNotifier {
  UserModel? _user;
  String? _token;
  bool _isLoading = false;
  String? _error;

  UserModel? get user => _user;
  String? get token => _token;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _user != null;
  bool get isGroupLeader => _user?.isGroupLeader ?? false;

  Future<void> init() async {
    if (await AuthService.isLoggedIn()) {
      _user = await AuthService.getUser();
      _token = await AuthService.getToken();
      notifyListeners();
      TaskService.syncPendingTasks();
    }
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await AuthService.login(email: email, password: password);
    _isLoading = false;

    if (result['success']) {
      _user = result['user'];
      _token = result['token'];
      TaskService.syncPendingTasks();
      notifyListeners();
      return true;
    } else {
      _error = result['message'];
      notifyListeners();
      return false;
    }
  }

  Future<bool> register({
    required String username,
    required String email,
    required String password,
    required String role,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await AuthService.register(
      username: username,
      email: email,
      password: password,
      role: role,
    );

    _isLoading = false;
    if (!result['success']) {
      _error = result['message'];
    }
    notifyListeners();
    return result['success'];
  }

  Future<void> logout() async {
    await AuthService.logout();
    _user = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
