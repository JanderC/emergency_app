// lib/services/ambulance_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:app_emergency/utils/shared_prefs.dart';
import 'package:app_emergency/models/ambulance.dart';

class AmbulanceService {
  final String baseUrl = 'https://emergencyapi-production.up.railway.app/api/ambulancias';

  String? get token => SharedPrefs.getToken();

  /// Registra una nueva ambulancia
  Future<Map<String, dynamic>> registerAmbulance(
    Map<String, dynamic> ambulanceData,
  ) async {
    try {
      print('Registrando ambulancia. Datos: $ambulanceData');

      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(ambulanceData),
      );

      print('Código de respuesta: ${response.statusCode}');
      print('Cuerpo de respuesta: ${response.body}');

      final responseData = json.decode(response.body);

      if (response.statusCode != 201) {
        return {
          'success': false,
          'message': responseData['error'] ?? 'Error al registrar ambulancia',
        };
      }

      return {
        'success': true,
        'message': responseData['mensaje'] ?? 'Ambulancia registrada exitosamente',
        'ambulancia_id': responseData['ambulancia_id'],
      };
    } catch (e) {
      print('Error en registerAmbulance: $e');
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  /// Obtiene lista de ambulancias con filtros opcionales
  Future<List<Ambulance>> getAmbulances({
    Map<String, String>? filters,
  }) async {
    try {
      Uri uri = Uri.parse(baseUrl);

      if (filters != null && filters.isNotEmpty) {
        uri = uri.replace(queryParameters: filters);
      }

      print('Obteniendo ambulancias. URL: $uri');
      print('Filtros aplicados: $filters');

      final response = await http.get(
        uri,
        headers: {'Authorization': 'Bearer $token'},
      );

      print('Código de respuesta: ${response.statusCode}');
      print('Cuerpo de respuesta: ${response.body}');

      if (response.statusCode != 200) {
        throw Exception('Error al obtener ambulancias');
      }

      final List<dynamic> ambulancesJson = json.decode(response.body);
      print('Total de ambulancias recibidas: ${ambulancesJson.length}');
      
      return ambulancesJson.map((json) => Ambulance.fromJson(json)).toList();
    } catch (e) {
      print('Error en getAmbulances: $e');
      throw Exception('Error de conexión: $e');
    }
  }

  /// Obtiene detalles de una ambulancia específica
  Future<Ambulance> getAmbulanceById(String ambulanciaId) async {
    try {
      print('Obteniendo ambulancia por ID: $ambulanciaId');

      final response = await http.get(
        Uri.parse('$baseUrl/$ambulanciaId'),
        headers: {'Authorization': 'Bearer $token'},
      );

      print('Código de respuesta: ${response.statusCode}');
      print('Cuerpo de respuesta: ${response.body}');

      if (response.statusCode != 200) {
        final responseData = json.decode(response.body);
        throw Exception(responseData['error'] ?? 'Error al obtener ambulancia');
      }

      return Ambulance.fromJson(json.decode(response.body));
    } catch (e) {
      print('Error en getAmbulanceById: $e');
      throw Exception('Error de conexión: $e');
    }
  }

  /// Asigna una ambulancia al bombero actual
  Future<Map<String, dynamic>> assignAmbulance(String ambulanciaId) async {
    try {
      print('Asignando ambulancia: $ambulanciaId');
      print('Token usado: $token');

      final response = await http.put(
        Uri.parse('$baseUrl/$ambulanciaId/asignar'),
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
          'message': responseData['error'] ?? 'Error al asignar ambulancia',
        };
      }

      return {
        'success': true,
        'message': responseData['mensaje'] ?? 'Ambulancia asignada exitosamente',
      };
    } catch (e) {
      print('Error en assignAmbulance: $e');
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  /// Cambia el estado de una ambulancia
  Future<Map<String, dynamic>> updateAmbulanceStatus(
    String ambulanciaId,
    String estado,
  ) async {
    try {
      print('Actualizando estado de ambulancia $ambulanciaId a: $estado');

      final response = await http.put(
        Uri.parse('$baseUrl/$ambulanciaId/estado'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'estado': estado}),
      );

      print('Código de respuesta: ${response.statusCode}');
      print('Cuerpo de respuesta: ${response.body}');

      final responseData = json.decode(response.body);

      if (response.statusCode != 200) {
        return {
          'success': false,
          'message': responseData['error'] ?? 'Error al actualizar estado',
        };
      }

      return {
        'success': true,
        'message': responseData['mensaje'] ?? 'Estado actualizado exitosamente',
      };
    } catch (e) {
      print('Error en updateAmbulanceStatus: $e');
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  /// Libera una ambulancia (la desasigna del bombero)
  Future<Map<String, dynamic>> releaseAmbulance(String ambulanciaId) async {
    try {
      print('Liberando ambulancia: $ambulanciaId');

      final response = await http.put(
        Uri.parse('$baseUrl/$ambulanciaId/liberar'),
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
          'message': responseData['error'] ?? 'Error al liberar ambulancia',
        };
      }

      return {
        'success': true,
        'message': responseData['mensaje'] ?? 'Ambulancia liberada exitosamente',
      };
    } catch (e) {
      print('Error en releaseAmbulance: $e');
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }
}