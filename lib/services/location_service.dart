import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/app_config.dart';
import 'auth_service.dart';

class GroupLocation {
  final int userId;
  final String username;
  final double lat;
  final double lng;

  GroupLocation({
    required this.userId,
    required this.username,
    required this.lat,
    required this.lng,
  });

  factory GroupLocation.fromJson(Map<String, dynamic> j) => GroupLocation(
        userId: j['user_id'] as int,
        username: j['username'] as String,
        lat: (j['lat'] as num).toDouble(),
        lng: (j['lng'] as num).toDouble(),
      );
}

class LocationService {
  static Future<bool> postLocation(double lat, double lng) async {
    try {
      final headers = await AuthService.authHeaders();
      headers['Content-Type'] = 'application/json';
      final res = await http.post(
        Uri.parse('${AppConfig.baseUrl}/location'),
        headers: headers,
        body: jsonEncode({'lat': lat, 'lng': lng}),
      );
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  static Future<void> deleteLocation() async {
    try {
      final headers = await AuthService.authHeaders();
      await http.delete(
        Uri.parse('${AppConfig.baseUrl}/location'),
        headers: headers,
      );
    } catch (_) {}
  }

  static Future<List<GroupLocation>> getGroupLocations() async {
    try {
      final headers = await AuthService.authHeaders();
      final res = await http.get(
        Uri.parse('${AppConfig.baseUrl}/location/group'),
        headers: headers,
      );
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        return (body['locations'] as List)
            .map((l) => GroupLocation.fromJson(l))
            .toList();
      }
    } catch (_) {}
    return [];
  }
}
