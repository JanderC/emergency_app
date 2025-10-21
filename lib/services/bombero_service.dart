
// lib/services/bombero_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:app_emergency/utils/shared_prefs.dart';

class BomberoService {
  static const String baseUrl = 'https://emergencyapi-production.up.railway.app/api/bomberos';

  Future<Map<String, dynamic>> getBomberoByUserId(String userId) async {
    try {
      final token = SharedPrefs.getToken();
      
      final response = await http.get(
        Uri.parse('$baseUrl/usuario/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'bombero': json.decode(response.body),
        };
      } else {
        return {'success': false};
      }
    } catch (e) {
      print('Error en getBomberoByUserId: $e');
      return {'success': false};
    }
  }
}