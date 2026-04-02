import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

class ApiService {
  static const String baseUrl = ApiConfig.baseUrl;

  /// Set by [login]; sent as `Authorization: Token <key>` on subsequent API calls.
  static String? _authToken;

  static String? get authToken => _authToken;

  static void setAuthToken(String? token) {
    _authToken = token;
  }

  static void clearAuthToken() {
    _authToken = null;
  }
  static Future<void> _saveToken(String token) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('auth_token', token);
  _authToken = token;
  }

  static Future<bool> restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token != null && token.isNotEmpty) {
      _authToken = token;
      return true;
    }
    return false;
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    _authToken = null;
  }

  static Map<String, String> _headers({bool jsonBody = false}) {
    final h = <String, String>{};
    if (jsonBody) {
      h['Content-Type'] = 'application/json';
    }
    final t = _authToken;
    if (t != null && t.isNotEmpty) {
      h['Authorization'] = 'Token $t';
    }
    return h;
  }

  static Future<bool> login(String username, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'password': password,
      }),
    );

    if (response.statusCode != 200) {
      return false;
    }

    try {
      final data = jsonDecode(response.body);
      if (data is Map<String, dynamic> && data['token'] != null) {
        await _saveToken(data['token'].toString());
        return true;
      }
    } catch (_) {}
    return false;
  }

  static Future<List<dynamic>> getParcours() async {
    final response = await http.get(
      Uri.parse('$baseUrl/parcours/'),
      headers: _headers(),
    );

    if (response.statusCode != 200) {
      throw Exception('Erreur chargement parcours');
    }

    return jsonDecode(response.body);
  }

  /// Full parcours payload including nested `parcours_points` → `point` (for map markers).
  static Future<Map<String, dynamic>> getParcoursById(String parcoursId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/parcours/$parcoursId/'),
      headers: _headers(),
    );

    if (response.statusCode != 200) {
      throw Exception('Erreur chargement parcours');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Réponse parcours invalide');
    }
    return decoded;
  }

  static Future<Map<String, dynamic>> createParcours(String name) async {
    final response = await http.post(
      Uri.parse('$baseUrl/parcours/'),
      headers: _headers(jsonBody: true),
      body: jsonEncode({
        'name': name,
        'description': '',
        'distance_km': 0,
        'duration_min': 0,
        'planned_path': [],
      }),
    );

    if (response.statusCode != 201) {
      throw Exception('Erreur création parcours');
    }

    return jsonDecode(response.body);
  }

  static Future<List<dynamic>> getPoints() async {
    final response = await http.get(
      Uri.parse('$baseUrl/points/'),
      headers: _headers(),
    );

    if (response.statusCode != 200) {
      throw Exception('Erreur chargement points');
    }

    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> getPointById(String pointId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/points/$pointId/'),
      headers: _headers(),
    );

    if (response.statusCode != 200) {
      throw Exception('Erreur chargement point');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Réponse point invalide');
    }
    return decoded;
  }

  static Future<List<dynamic>> getLabels() async {
    final response = await http.get(
      Uri.parse('$baseUrl/labels/'),
      headers: _headers(),
    );

    if (response.statusCode != 200) {
      throw Exception('Erreur chargement labels');
    }

    return jsonDecode(response.body);
  }

  static Future<List<dynamic>> getPointHistory(String pointId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/points/$pointId/history/'),
      headers: _headers(),
    );

    if (response.statusCode != 200) {
      throw Exception('Erreur chargement historique');
    }

    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> createPoint({
    required String name,
    required String description,
    required double latitude,
    required double longitude,
    required String labelId,
    required String comment,
    required bool isTreated,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/points/'),
      headers: _headers(jsonBody: true),
      body: jsonEncode({
        'name': name,
        'description': description,
        'latitude': latitude,
        'longitude': longitude,
        'label_id': labelId,
        'comment': comment,
        'is_treated': isTreated,
      }),
    );

    if (response.statusCode != 201) {
      throw Exception('Erreur création point: ${response.body}');
    }

    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> updatePoint({
    required String pointId,
    required String name,
    required String description,
    required double latitude,
    required double longitude,
    required String labelId,
    required String comment,
    required bool isTreated,
  }) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/points/$pointId/'),
      headers: _headers(jsonBody: true),
      body: jsonEncode({
        'name': name,
        'description': description,
        'latitude': latitude,
        'longitude': longitude,
        'label_id': labelId,
        'comment': comment,
        'is_treated': isTreated,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Erreur mise à jour point: ${response.body}');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Réponse point invalide');
    }
    return decoded;
  }

  static Future<void> deletePoint(String pointId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/points/$pointId/'),
      headers: _headers(),
    );

    if (response.statusCode != 204 && response.statusCode != 200) {
      throw Exception('Erreur suppression point: ${response.body}');
    }
  }

  static Future<void> markPointTreated(String pointId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/points/$pointId/mark_treated/'),
      headers: _headers(),
    );

    if (response.statusCode != 200) {
      throw Exception('Erreur traitement point');
    }
  }

  static Future<void> addPointToParcours({
    required String parcoursId,
    required String pointId,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/parcours/$parcoursId/add_point/'),
      headers: _headers(jsonBody: true),
      body: jsonEncode({
        'point_id': pointId,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Erreur ajout point au parcours');
    }
  }

  static Future<Map<String, dynamic>> optimizeParcours(
        double startLat, 
        double startLng,
        String parcoursId) async {
      final uri = Uri.parse('$baseUrl/parcours/$parcoursId/optimize/').replace(
        queryParameters: <String, String>{
          'start_lat': startLat.toString(),
          'start_lng': startLng.toString(),
        },
      );
      final response = await http.get(
        uri,
        headers: _headers(),
      );

      if (response.statusCode != 200) {
        throw Exception('Erreur optimisation parcours: ${response.body}');
      }

      return jsonDecode(response.body);
    }

  static Future<void> sendTrack({
    required String parcoursId,
    required double latitude,
    required double longitude,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/mission-tracks/'),
      headers: _headers(jsonBody: true),
      body: jsonEncode({
        'parcours': parcoursId,
        'latitude': latitude,
        'longitude': longitude,
      }),
    );

    if (response.statusCode != 201) {
      throw Exception('Erreur envoi GPS');
    }
  }

  static Future<void> deleteParcours(String parcoursId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/parcours/$parcoursId/'),
      headers: _headers(),
    );

    // DRF default is 204 No Content, but we accept 200 for safety.
    if (response.statusCode != 204 && response.statusCode != 200) {
      throw Exception('Erreur suppression parcours');
    }
  }

 static Future<void> uploadPointPhotos({
  required String pointId,
  required List<File> images,
}) async {
  final request = http.MultipartRequest(
    'POST',
    Uri.parse('$baseUrl/points/$pointId/photos/'),
  );

  request.headers.addAll(_headers());

  for (final img in images) {
    request.files.add(
      await http.MultipartFile.fromPath(
        'images',     
        img.path,
        filename: img.path.split('/').last,  
      ),
    );
  }

  final response = await request.send();
  final body = await response.stream.bytesToString();

  if (response.statusCode != 201) {
    throw Exception('Erreur upload photos: $body');
  }
}}
