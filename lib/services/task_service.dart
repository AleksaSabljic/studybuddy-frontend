import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/task_model.dart';
import '../models/user_model.dart';
import '../utils/app_config.dart';
import 'auth_service.dart';
import 'local_db_service.dart';

class TaskService {
  // ─── Fetch all tasks (with offline fallback) ─────────────────────────────

  static Future<List<TaskModel>> getTasks() async {
    try {
      final headers = await AuthService.authHeaders();
      final response = await http
          .get(Uri.parse('${AppConfig.baseUrl}/tasks'), headers: headers)
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final tasks = (body['tasks'] as List)
            .map((t) => TaskModel.fromJson(t))
            .toList();
        try {
          await LocalDbService.clearTasks();
          await LocalDbService.insertOrUpdateTasks(tasks);
        } catch (_) {}
        return tasks;
      }
    } catch (_) {}
    try {
      return await LocalDbService.getAllTasks();
    } catch (_) {
      return [];
    }
  }

  // ─── Get single task ─────────────────────────────────────────────────────

  static Future<Map<String, dynamic>?> getTaskDetail(int id) async {
    try {
      final headers = await AuthService.authHeaders();
      final response = await http
          .get(Uri.parse('${AppConfig.baseUrl}/tasks/$id'), headers: headers)
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (_) {}
    return null;
  }

  // ─── Create task (with offline queue) ────────────────────────────────────

  static Future<Map<String, dynamic>> createTask({
    required String title,
    String? description,
    int? assignedTo,
  }) async {
    try {
      final headers = await AuthService.authHeaders();
      final response = await http
          .post(
            Uri.parse('${AppConfig.baseUrl}/tasks'),
            headers: headers,
            body: jsonEncode({
              'title': title,
              'description': description,
              'assigned_to': assignedTo,
            }),
          )
          .timeout(const Duration(seconds: 8));

      final body = jsonDecode(response.body);
      if (response.statusCode == 201) {
        final task = TaskModel.fromJson(body['task']);
        await LocalDbService.insertOrUpdateTask(task);
        return {'success': true, 'task': task};
      }
      return {'success': false, 'message': body['message']};
    } catch (_) {
      // Offline – queue locally
      final user = await AuthService.getUser();
      final localId = DateTime.now().millisecondsSinceEpoch.toString();
      final offlineTask = TaskModel(
        id: -int.parse(localId.substring(localId.length - 6)),
        title: title,
        description: description,
        createdBy: user?.id,
        assignedTo: assignedTo,
        isPendingSync: true,
        localId: localId,
        createdAt: DateTime.now(),
      );
      await LocalDbService.insertOrUpdateTask(offlineTask);
      return {'success': true, 'task': offlineTask, 'offline': true};
    }
  }

  // ─── Update task ─────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> updateTask({
    required int id,
    String? title,
    String? description,
    int? assignedTo,
  }) async {
    try {
      final headers = await AuthService.authHeaders();
      final response = await http
          .put(
            Uri.parse('${AppConfig.baseUrl}/tasks/$id'),
            headers: headers,
            body: jsonEncode({
              if (title != null) 'title': title,
              if (description != null) 'description': description,
              if (assignedTo != null) 'assigned_to': assignedTo,
            }),
          )
          .timeout(const Duration(seconds: 8));

      final body = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'task': TaskModel.fromJson(body['task'])};
      }
      return {'success': false, 'message': body['message']};
    } catch (_) {
      return {'success': false, 'message': 'Network error'};
    }
  }

  // ─── Delete task ─────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> deleteTask(int id) async {
    try {
      final headers = await AuthService.authHeaders();
      final response = await http
          .delete(Uri.parse('${AppConfig.baseUrl}/tasks/$id'), headers: headers)
          .timeout(const Duration(seconds: 8));

      final body = jsonDecode(response.body);
      if (response.statusCode == 200) {
        await LocalDbService.deleteTask(id);
        return {'success': true};
      }
      return {'success': false, 'message': body['message']};
    } catch (_) {
      return {'success': false, 'message': 'Network error'};
    }
  }

  // ─── Get users (for assignment dropdown) ────────────────────────────────

  static Future<List<UserModel>> getStudents() async {
    try {
      final headers = await AuthService.authHeaders();
      final response = await http
          .get(Uri.parse('${AppConfig.baseUrl}/auth/users'), headers: headers)
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final users = (body['users'] as List)
            .map((u) => UserModel.fromJson(u))
            .where((u) => u.role == 'student')
            .toList();
        return users;
      }
    } catch (_) {}
    return [];
  }

  // ─── Sync pending offline tasks ──────────────────────────────────────────

  static Future<void> syncPendingTasks() async {
    final pending = await LocalDbService.getPendingTasks();
    for (final task in pending) {
      try {
        final result = await createTask(
          title: task.title,
          description: task.description,
          assignedTo: task.assignedTo,
        );
        if (result['success'] == true && result['offline'] != true) {
          // Remove old local entry and add server one
          await LocalDbService.deleteTask(task.id);
        }
      } catch (_) {}
    }
  }
}
