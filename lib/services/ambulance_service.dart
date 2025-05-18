import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:app_emergency/models/ambulance.dart';
import 'package:app_emergency/utils/shared_prefs.dart';

class AmbulanceService {
  final String baseUrl = 'http://localhost:5000/api/ambulancias';
  final String? token = SharedPrefs.getToken();

  Future<List<Ambulance>> getAmbulances({Map<String, String>? filters}) async {
    try {
      Uri uri = Uri.parse(baseUrl);
      
      if (filters != null && filters.isNotEmpty) {
        uri = uri.replace(queryParameters: filters);
      }
      
      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Error al obtener ambulancias');
      }

      final List<dynamic> ambulancesJson = json.decode(response.body);
      return ambulancesJson.map((json) => Ambulance.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  Future<Map<String, dynamic>> registerAmbulance(Map<String, dynamic> ambulanceData) async {
    try {
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(ambulanceData),
      );

      final responseData = json.decode(response.body);
      
      if (response.statusCode != 201) {
        return {
          'success': false,
          'message': responseData['error'] ?? 'Error al registrar ambulancia',
        };
      }

      return {
        'success': true,
        'id': responseData['id'],
        'message': responseData['mensaje'],
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error de conexión: $e',
      };
    }
  }

  Future<Map<String, dynamic>> assignAmbulance(String ambulanceId) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/$ambulanceId/asignar'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final responseData = json.decode(response.body);
      
      if (response.statusCode != 200) {
        return {
          'success': false,
          'message': responseData['error'] ?? 'Error al asignar ambulancia',
        };
      }

      return {
        'success': true,
        'message': responseData['mensaje'],
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error de conexión: $e',
      };
    }
  }

  Future<Map<String, dynamic>> updateAmbulanceStatus(String ambulanceId, String newStatus) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/$ambulanceId/estado'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'estado': newStatus,
        }),
      );

      final responseData = json.decode(response.body);
      
      if (response.statusCode != 200) {
        return {
          'success': false,
          'message': responseData['error'] ?? 'Error al actualizar estado',
        };
      }

      return {
        'success': true,
        'message': responseData['mensaje'],
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error de conexión: $e',
      };
    }
  }
}
