// lib/services/firefighter_approval_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:app_emergency/models/pending_firefighter.dart';
import 'package:app_emergency/utils/shared_prefs.dart';

class FirefighterApprovalService {
  static const String baseUrl = 'https://emergencyapi-production.up.railway.app/api/bomberos';

  Future<List<PendingFirefighter>> getPendingFirefighters() async {
    try {
      final token = SharedPrefs.getToken();

      final response = await http.get(
        Uri.parse('$baseUrl/pendientes'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('Status: ${response.statusCode}');
      print('Response: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data
            .map((json) => PendingFirefighter.fromJson(json))
            .toList();
      } else {
        throw Exception('Error al obtener bomberos pendientes');
      }
    } catch (e) {
      print('Error en getPendingFirefighters: $e');
      throw Exception('Error: $e');
    }
  }

  Future<Map<String, dynamic>> approveFirefighter({
    required String bomberoId,
    required String codigoJefe,
    required String passwordJefe,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/$bomberoId/aprobar'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'accion': 'aprobar',
          'codigo_jefe': codigoJefe,
          'password_jefe': passwordJefe,
        }),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': responseData['mensaje'] ?? 'Bombero aprobado exitosamente',
        };
      } else {
        return {
          'success': false,
          'message': responseData['error'] ?? 'Error al aprobar bombero',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }

  Future<Map<String, dynamic>> rejectFirefighter({
    required String bomberoId,
    required String codigoJefe,
    required String passwordJefe,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/$bomberoId/rechazar'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'accion': 'rechazar',
          'codigo_jefe': codigoJefe,
          'password_jefe': passwordJefe,
        }),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': responseData['mensaje'] ?? 'Solicitud rechazada',
        };
      } else {
        return {
          'success': false,
          'message': responseData['error'] ?? 'Error al rechazar solicitud',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }
}