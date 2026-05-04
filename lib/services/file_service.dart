import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:http/http.dart' as http;
import '../models/file_model.dart';
import '../utils/app_config.dart';
import 'auth_service.dart';

class FileService {
  // ─── Upload file (bytes-based, works on web + mobile) ────────────────────

  static Future<Map<String, dynamic>> uploadFile({
    required Uint8List bytes,
    required String filename,
    required int taskId,
  }) async {
    try {
      final token = await AuthService.getToken();
      final dio = Dio();

      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(bytes, filename: filename),
        'task_id': taskId.toString(),
      });

      final response = await dio.post(
        '${AppConfig.baseUrl}/files/upload',
        data: formData,
        options: Options(headers: {
          'Authorization': 'Bearer $token',
        }),
      );

      if (response.statusCode == 201) {
        return {
          'success': true,
          'file': FileModel.fromJson(response.data['file']),
        };
      }
      return {'success': false, 'message': response.data['message']};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // ─── Get file download URL ────────────────────────────────────────────────

  static String getFileUrl(int fileId) {
    return '${AppConfig.baseUrl}/files/$fileId';
  }

  // ─── Delete file ─────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> deleteFile(int fileId) async {
    try {
      final headers = await AuthService.authHeaders();
      final response = await http
          .delete(
            Uri.parse('${AppConfig.baseUrl}/files/$fileId'),
            headers: headers,
          )
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        return {'success': true};
      }
      return {'success': false};
    } catch (_) {
      return {'success': false, 'message': 'Network error'};
    }
  }
}
