// lib/services/emergency_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:app_emergency/models/incident.dart';
import 'package:app_emergency/utils/shared_prefs.dart';

class EmergencyService {
  final String baseUrl = 'https://emergencyapi-production.up.railway.app/api/incidentes';

  String? get token => SharedPrefs.getToken();

  /// Obtiene emergencias disponibles (estado=reportado)
  Future<List<Incident>> getAvailableEmergencies({
    String? nivelUrgencia,
    String? tipoEmergencia,
  }) async {
    try {
      Map<String, String> queryParams = {'estado': 'reportado'};
      
      if (nivelUrgencia != null) queryParams['nivel_urgencia'] = nivelUrgencia;
      if (tipoEmergencia != null) queryParams['tipo_emergencia'] = tipoEmergencia;
      
      Uri uri = Uri.parse(baseUrl).replace(queryParameters: queryParams);

      print('📥 Obteniendo emergencias disponibles: $uri');

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('✅ Código: ${response.statusCode}');

      if (response.statusCode != 200) {
        throw Exception('Error al obtener emergencias: ${response.body}');
      }

      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => Incident.fromJson(json)).toList();
    } catch (e) {
      print('❌ Error en getAvailableEmergencies: $e');
      throw Exception('Error de conexión: $e');
    }
  }

  /// Obtiene mis emergencias
  Future<List<Incident>> getMyEmergencies({String? estado}) async {
    try {
      final userId = SharedPrefs.getUserId();
      
      Map<String, String> queryParams = {};
      if (estado != null) {
        queryParams['estado'] = estado;
      }
      
      Uri uri = Uri.parse(baseUrl);
      if (queryParams.isNotEmpty) {
        uri = uri.replace(queryParameters: queryParams);
      }

      print('📥 Obteniendo mis emergencias: $uri');
      print('🔍 Filtrando por bombero: $userId');

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('✅ Código: ${response.statusCode}');

      if (response.statusCode != 200) {
        throw Exception('Error al obtener mis emergencias: ${response.body}');
      }

      final List<dynamic> data = json.decode(response.body);
      final allIncidents = data.map((json) => Incident.fromJson(json)).toList();
      
      // Filtrar solo las asignadas a este bombero
      final myIncidents = allIncidents.where((incident) {
        return incident.bomberoAsignadoId == userId;
      }).toList();
      
      print('📊 Total incidentes: ${allIncidents.length}, Mis incidentes: ${myIncidents.length}');
      
      return myIncidents;
    } catch (e) {
      print('❌ Error en getMyEmergencies: $e');
      throw Exception('Error de conexión: $e');
    }
  }

  /// Toma una emergencia
  Future<Map<String, dynamic>> takeEmergency(String incidentId) async {
    try {
      final userId = SharedPrefs.getUserId();
      
      print('🚒 Tomando emergencia: $incidentId');
      print('👤 Bombero: $userId');

      final response = await http.put(
        Uri.parse('$baseUrl/$incidentId/estado'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'estado': 'en_proceso',
          'bombero_id': userId,
        }),
      );

      print('✅ Código: ${response.statusCode}');

      final responseData = json.decode(response.body);

      if (response.statusCode != 200) {
        return {
          'success': false,
          'message': responseData['error'] ?? 'Error al tomar emergencia',
        };
      }

      return {
        'success': true,
        'message': responseData['mensaje'] ?? 'Emergencia tomada exitosamente',
      };
    } catch (e) {
      print('❌ Error en takeEmergency: $e');
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  /// Libera una emergencia
  Future<Map<String, dynamic>> releaseEmergency(String incidentId, String reason) async {
    try {
      print('🔓 Liberando emergencia: $incidentId');

      final response = await http.put(
        Uri.parse('$baseUrl/$incidentId/estado'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'estado': 'reportado',
          'bombero_id': null,
        }),
      );

      print('✅ Código: ${response.statusCode}');

      final responseData = json.decode(response.body);

      if (response.statusCode != 200) {
        return {
          'success': false,
          'message': responseData['error'] ?? 'Error al liberar emergencia',
        };
      }

      return {
        'success': true,
        'message': responseData['mensaje'] ?? 'Emergencia liberada',
      };
    } catch (e) {
      print('❌ Error en releaseEmergency: $e');
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  /// Completa una emergencia
  Future<Map<String, dynamic>> completeEmergency(String incidentId) async {
    try {
      print('✅ Completando emergencia: $incidentId');

      final response = await http.put(
        Uri.parse('$baseUrl/$incidentId/estado'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'estado': 'completado',
        }),
      );

      print('✅ Código: ${response.statusCode}');

      final responseData = json.decode(response.body);

      if (response.statusCode != 200) {
        return {
          'success': false,
          'message': responseData['error'] ?? 'Error al completar emergencia',
        };
      }

      return {
        'success': true,
        'message': responseData['mensaje'] ?? 'Emergencia completada',
      };
    } catch (e) {
      print('❌ Error en completeEmergency: $e');
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }
}