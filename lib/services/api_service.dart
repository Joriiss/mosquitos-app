import 'dart:convert';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';

class ApiService {
  static const String baseUrl = ApiConfig.baseUrl;

  static Future<bool> login(String username, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'password': password,
      }),
    );

    return response.statusCode == 200;
  }

  static Future<List<dynamic>> getParcours() async {
    final response = await http.get(Uri.parse('$baseUrl/parcours/'));

    if (response.statusCode != 200) {
      throw Exception('Erreur chargement parcours');
    }

    return jsonDecode(response.body);
  }

  /// Full parcours payload including nested `parcours_points` → `point` (for map markers).
  static Future<Map<String, dynamic>> getParcoursById(String parcoursId) async {
    final response =
        await http.get(Uri.parse('$baseUrl/parcours/$parcoursId/'));

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
      headers: {'Content-Type': 'application/json'},
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
    final response = await http.get(Uri.parse('$baseUrl/points/'));

    if (response.statusCode != 200) {
      throw Exception('Erreur chargement points');
    }

    return jsonDecode(response.body);
  }

  static Future<List<dynamic>> getLabels() async {
    final response = await http.get(Uri.parse('$baseUrl/labels/'));

    if (response.statusCode != 200) {
      throw Exception('Erreur chargement labels');
    }

    return jsonDecode(response.body);
  }

  static Future<List<dynamic>> getPointHistory(String pointId) async {
    final response =
        await http.get(Uri.parse('$baseUrl/points/$pointId/history/'));

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
      headers: {'Content-Type': 'application/json'},
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

  static Future<void> markPointTreated(String pointId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/points/$pointId/mark_treated/'),
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
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'point_id': pointId,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Erreur ajout point au parcours');
    }
  }

  static Future<void> sendTrack({
    required String parcoursId,
    required double latitude,
    required double longitude,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/mission-tracks/'),
      headers: {'Content-Type': 'application/json'},
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
    );

    // DRF default is 204 No Content, but we accept 200 for safety.
    if (response.statusCode != 204 && response.statusCode != 200) {
      throw Exception('Erreur suppression parcours');
    }
  }
}
