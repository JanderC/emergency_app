// lib/services/emergency_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:app_emergency/models/incident.dart';
import 'package:app_emergency/utils/shared_prefs.dart';

class EmergencyService {
  final String baseUrl = 'http://192.168.1.116:5000/api/emergencias';

  // Obtener el token cada vez que se necesite
  String? get token => SharedPrefs.getToken();

  /// Obtiene lista de emergencias disponibles para tomar (Solo bomberos)
  Future<List<Incident>> getAvailableEmergencies({
    String? nivelUrgencia,
    String? tipoEmergencia,
  }) async {
    try {
      Uri uri = Uri.parse('$baseUrl/disponibles');
      
      Map<String, String> queryParams = {};
      if (nivelUrgencia != null) queryParams['nivel_urgencia'] = nivelUrgencia;
      if (tipoEmergencia != null) queryParams['tipo_emergencia'] = tipoEmergencia;
      
      if (queryParams.isNotEmpty) {
        uri = uri.replace(queryParameters: queryParams);  
      }

      print('Obteniendo emergencias disponibles. URL: $uri');
      print('Token usado: $token');

      final response = await http.get(
        uri,
        headers: {'Authorization': 'Bearer $token'},
      );

      print('Código de respuesta: ${response.statusCode}');
      print('Cuerpo de respuesta: ${response.body}');

      if (response.statusCode != 200) {
        throw Exception('Error al obtener emergencias disponibles: ${response.body}');
      }

      final List<dynamic> emergenciesJson = json.decode(response.body);
      return emergenciesJson.map((json) => Incident.fromJson(json)).toList();
    } catch (e) {
      print('Error en getAvailableEmergencies: $e');
      throw Exception('Error de conexión: $e');
    }
  }

  /// Toma una emergencia asignándola al bombero actual
  Future<Map<String, dynamic>> takeEmergency(String incidentId) async {
    try {
      print('Tomando emergencia con ID: $incidentId');
      print('Token usado: $token');

      final response = await http.post(
        Uri.parse('$baseUrl/$incidentId/tomar'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('Código de respuesta: ${response.statusCode}');
      print('Cuerpo de respuesta: ${response.body}');

      final responseData = json.decode(response.body);

      if (response.statusCode != 200) {
        return {
          'success': false,
          'message': responseData['error'] ?? 'Error al tomar la emergencia',
        };
      }

      return {
        'success': true,
        'message': responseData['mensaje'] ?? 'Emergencia tomada exitosamente',
      };
    } catch (e) {
      print('Error en takeEmergency: $e');
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  /// Libera una emergencia asignada al bombero actual
  Future<Map<String, dynamic>> releaseEmergency(
    String incidentId,
    String reason,
  ) async {
    try {
      print('Liberando emergencia con ID: $incidentId');
      print('Razón: $reason');
      print('Token usado: $token');

      final response = await http.post(
        Uri.parse('$baseUrl/$incidentId/liberar'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'razon': reason}),
      );

      print('Código de respuesta: ${response.statusCode}');
      print('Cuerpo de respuesta: ${response.body}');

      final responseData = json.decode(response.body);

      if (response.statusCode != 200) {
        return {
          'success': false,
          'message': responseData['error'] ?? 'Error al liberar la emergencia',
        };
      }

      return {
        'success': true,
        'message': responseData['mensaje'] ?? 'Emergencia liberada exitosamente',
      };
    } catch (e) {
      print('Error en releaseEmergency: $e');
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  /// Obtiene las emergencias asignadas al bombero actual
  Future<List<Incident>> getMyEmergencies({String? estado}) async {
    try {
      Uri uri = Uri.parse('$baseUrl/mis-emergencias');
      
      if (estado != null) {
        uri = uri.replace(queryParameters: {'estado': estado});
      }

      print('Obteniendo mis emergencias. URL: $uri');
      print('Token usado: $token');

      final response = await http.get(
        uri,
        headers: {'Authorization': 'Bearer $token'},
      );

      print('Código de respuesta: ${response.statusCode}');
      print('Cuerpo de respuesta: ${response.body}');

      if (response.statusCode != 200) {
        throw Exception('Error al obtener mis emergencias: ${response.body}');
      }

      final List<dynamic> emergenciesJson = json.decode(response.body);
      return emergenciesJson.map((json) => Incident.fromJson(json)).toList();
    } catch (e) {
      print('Error en getMyEmergencies: $e');
      throw Exception('Error de conexión: $e');
    }
  }

  /// Actualiza la ubicación del bombero
  Future<Map<String, dynamic>> updateFirefighterLocation(
    double lat,
    double lng,
  ) async {
    try {
      print('Actualizando ubicación del bombero: lat=$lat, lng=$lng');
      print('Token usado: $token');

      final response = await http.put(
        Uri.parse('$baseUrl/ubicacion'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'lat': lat,
          'lng': lng,
        }),
      );

      print('Código de respuesta: ${response.statusCode}');
      print('Cuerpo de respuesta: ${response.body}');

      final responseData = json.decode(response.body);

      if (response.statusCode != 200) {
        return {
          'success': false,
          'message': responseData['error'] ?? 'Error al actualizar ubicación',
        };
      }

      return {
        'success': true,
        'message': responseData['mensaje'] ?? 'Ubicación actualizada exitosamente',
      };
    } catch (e) {
      print('Error en updateFirefighterLocation: $e');
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }
}