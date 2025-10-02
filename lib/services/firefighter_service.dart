// lib/services/firefighter_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:app_emergency/utils/shared_prefs.dart';

class FirefighterService {
  final String baseUrl = 'http://192.168.123.41:5000/api/bomberos';

  // Obtener el token cada vez que se necesite
  String? get token => SharedPrefs.getToken();

  /// Registra un nuevo bombero
  Future<Map<String, dynamic>> registerFirefighter(
    Map<String, dynamic> firefighterData,
  ) async {
    try {
      print('Registrando bombero. Datos: $firefighterData');
      print('Token usado: $token');

      final response = await http.post(
        Uri.parse('$baseUrl/registro'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(firefighterData),
      );

      print('Código de respuesta: ${response.statusCode}');
      print('Cuerpo de respuesta: ${response.body}');

      final responseData = json.decode(response.body);

      if (response.statusCode != 201) {
        return {
          'success': false,
          'message': responseData['error'] ?? 'Error al registrar bombero',
        };
      }

      return {
        'success': true,
        'message': responseData['mensaje'] ?? 'Bombero registrado exitosamente',
      };
    } catch (e) {
      print('Error en registerFirefighter: $e');
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  /// Obtiene el perfil del bombero actual
  Future<Map<String, dynamic>> getFirefighterProfile() async {
    try {
      print('Obteniendo perfil del bombero actual');
      print('Token usado: $token');

      final response = await http.get(
        Uri.parse('$baseUrl/perfil'),
        headers: {'Authorization': 'Bearer $token'},
      );

      print('Código de respuesta: ${response.statusCode}');
      print('Cuerpo de respuesta: ${response.body}');

      if (response.statusCode != 200) {
        final responseData = json.decode(response.body);
        throw Exception(responseData['error'] ?? 'Error al obtener perfil');
      }

      return json.decode(response.body);
    } catch (e) {
      print('Error en getFirefighterProfile: $e');
      throw Exception('Error de conexión: $e');
    }
  }

  /// Actualiza el perfil del bombero actual
  Future<Map<String, dynamic>> updateFirefighterProfile(
    Map<String, dynamic> profileData,
  ) async {
    try {
      print('Actualizando perfil del bombero. Datos: $profileData');
      print('Token usado: $token');

      final response = await http.put(
        Uri.parse('$baseUrl/perfil'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(profileData),
      );

      print('Código de respuesta: ${response.statusCode}');
      print('Cuerpo de respuesta: ${response.body}');

      final responseData = json.decode(response.body);

      if (response.statusCode != 200) {
        return {
          'success': false,
          'message': responseData['error'] ?? 'Error al actualizar perfil',
        };
      }

      return {
        'success': true,
        'message': responseData['mensaje'] ?? 'Perfil actualizado exitosamente',
      };
    } catch (e) {
      print('Error en updateFirefighterProfile: $e');
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  /// Obtiene detalles de un bombero específico
  Future<Map<String, dynamic>> getFirefighterById(String userId) async {
    try {
      print('Obteniendo bombero por ID: $userId');
      print('Token usado: $token');

      final response = await http.get(
        Uri.parse('$baseUrl/$userId'),
        headers: {'Authorization': 'Bearer $token'},
      );

      print('Código de respuesta: ${response.statusCode}');
      print('Cuerpo de respuesta: ${response.body}');

      if (response.statusCode != 200) {
        final responseData = json.decode(response.body);
        throw Exception(responseData['error'] ?? 'Error al obtener bombero');
      }

      return json.decode(response.body);
    } catch (e) {
      print('Error en getFirefighterById: $e');
      throw Exception('Error de conexión: $e');
    }
  }

  /// Cambia el estado del bombero actual
  Future<Map<String, dynamic>> updateMyServiceStatus(String estado) async {
    try {
      print('Actualizando mi estado de servicio a: $estado');
      print('Token usado: $token');

      final response = await http.put(
        Uri.parse('$baseUrl/estado'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'estado_servicio': estado}),
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
      print('Error en updateMyServiceStatus: $e');
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  /// Cambia el estado de otro bombero
  Future<Map<String, dynamic>> updateFirefighterStatus(
    String userId,
    String estado,
  ) async {
    try {
      print('Actualizando estado del bombero $userId a: $estado');
      print('Token usado: $token');

      final response = await http.put(
        Uri.parse('$baseUrl/$userId/estado'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'estado_servicio': estado}),
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
      print('Error en updateFirefighterStatus: $e');
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  /// Lista bomberos disponibles
  Future<List<Map<String, dynamic>>> getAvailableFirefighters() async {
    try {
      print('Obteniendo bomberos disponibles');
      print('Token usado: $token');

      final response = await http.get(
        Uri.parse('$baseUrl/disponibles'),
        headers: {'Authorization': 'Bearer $token'},
      );

      print('Código de respuesta: ${response.statusCode}');
      print('Cuerpo de respuesta: ${response.body}');

      if (response.statusCode != 200) {
        throw Exception('Error al obtener bomberos disponibles');
      }

      final List<dynamic> firefightersJson = json.decode(response.body);
      return firefightersJson.cast<Map<String, dynamic>>();
    } catch (e) {
      print('Error en getAvailableFirefighters: $e');
      throw Exception('Error de conexión: $e');
    }
  }

  /// Lista todos los bomberos con filtros
  Future<List<Map<String, dynamic>>> getAllFirefighters({
    String? estadoServicio,
    String? estacionPertenencia,
    String? rango,
    bool? tieneAmbulancia,
  }) async {
    try {
      Uri uri = Uri.parse(baseUrl);

      Map<String, String> queryParams = {};
      if (estadoServicio != null)
        queryParams['estado_servicio'] = estadoServicio;
      if (estacionPertenencia != null)
        queryParams['estacion_pertenencia'] = estacionPertenencia;
      if (rango != null) queryParams['rango'] = rango;
      if (tieneAmbulancia != null)
        queryParams['tiene_ambulancia'] = tieneAmbulancia.toString();

      if (queryParams.isNotEmpty) {
        uri = uri.replace(queryParameters: queryParams);
      }

      print('Obteniendo todos los bomberos. URL: $uri');
      print('Token usado: $token');

      final response = await http.get(
        uri,
        headers: {'Authorization': 'Bearer $token'},
      );

      print('Código de respuesta: ${response.statusCode}');
      print('Cuerpo de respuesta: ${response.body}');

      if (response.statusCode != 200) {
        throw Exception('Error al obtener bomberos');
      }

      final List<dynamic> firefightersJson = json.decode(response.body);
      return firefightersJson.cast<Map<String, dynamic>>();
    } catch (e) {
      print('Error en getAllFirefighters: $e');
      throw Exception('Error de conexión: $e');
    }
  }

  /// Actualiza la ubicación del bombero
  Future<Map<String, dynamic>> updateLocation(double lat, double lng) async {
    try {
      print('Actualizando ubicación del bombero: lat=$lat, lng=$lng');
      print('Token usado: $token');

      final response = await http.put(
        Uri.parse('$baseUrl/ubicacion'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'lat': lat, 'lng': lng}),
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
        'message':
            responseData['mensaje'] ?? 'Ubicación actualizada exitosamente',
      };
    } catch (e) {
      print('Error en updateLocation: $e');
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }
  /// Marca un incidente como completado
  Future<Map<String, dynamic>> completeIncident(String incidentId) async {
    try {
      print('Marcando incidente como completado: $incidentId');
      print('Token usado: $token');

      final response = await http.put(
        Uri.parse(
          'http://192.168.123.41:5000/api/incidentes/$incidentId/completar',
        ), // Usar el endpoint de cambiar estado
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'estado': 'completado', // Enviar el nuevo estado
        }),
      );

      print('Código de respuesta: ${response.statusCode}');
      print('Cuerpo de respuesta: ${response.body}');

      final responseData = json.decode(response.body);

      if (response.statusCode != 200) {
        return {
          'success': false,
          'message': responseData['error'] ?? 'Error al completar incidente',
        };
      }

      return {
        'success': true,
        'message':
            responseData['mensaje'] ?? 'Incidente completado exitosamente',
      };
    } catch (e) {
      print('Error en completeIncident: $e');
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  /// Desactiva un bombero (Solo para administradores)
  Future<Map<String, dynamic>> deactivateFirefighter(String userId) async {
    try {
      print('Desactivando bombero: $userId');
      print('Token usado: $token');

      final response = await http.put(
        Uri.parse('$baseUrl/$userId/desactivar'),
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
          'message': responseData['error'] ?? 'Error al desactivar bombero',
        };
      }

      return {
        'success': true,
        'message':
            responseData['mensaje'] ?? 'Bombero desactivado exitosamente',
      };
    } catch (e) {
      print('Error en deactivateFirefighter: $e');
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }
}
