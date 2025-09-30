// lib/services/user_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:app_emergency/utils/shared_prefs.dart';

class UserService {
  final String baseUrl = 'http://192.168.1.116:5000/api/usuarios';

  // Obtener el token cada vez que se necesite
  String? get token => SharedPrefs.getToken();

  /// Obtiene el perfil del usuario actual
  Future<Map<String, dynamic>> getUserProfile() async {
    try {
      print('Obteniendo perfil del usuario actual');
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
      print('Error en getUserProfile: $e');
      throw Exception('Error de conexión: $e');
    }
  }

  /// Actualiza el perfil del usuario actual
  Future<Map<String, dynamic>> updateUserProfile(
    Map<String, dynamic> profileData,
  ) async {
    try {
      print('Actualizando perfil del usuario. Datos: $profileData');
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
        'usuario': responseData['usuario'],
      };
    } catch (e) {
      print('Error en updateUserProfile: $e');
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  /// Cambia la contraseña del usuario
  Future<Map<String, dynamic>> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    try {
      print('Cambiando contraseña del usuario');
      print('Token usado: $token');

      final response = await http.post(
        Uri.parse('$baseUrl/cambiar-password'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'password_actual': currentPassword,
          'password_nueva': newPassword,
        }),
      );

      print('Código de respuesta: ${response.statusCode}');
      print('Cuerpo de respuesta: ${response.body}');

      final responseData = json.decode(response.body);

      if (response.statusCode != 200) {
        return {
          'success': false,
          'message': responseData['error'] ?? 'Error al cambiar contraseña',
        };
      }

      return {
        'success': true,
        'message': responseData['mensaje'] ?? 'Contraseña cambiada exitosamente',
      };
    } catch (e) {
      print('Error en changePassword: $e');
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  /// Obtiene el historial de incidentes del usuario
  Future<List<Map<String, dynamic>>> getUserIncidentHistory({
    String? estado,
    String? fechaDesde,
    String? fechaHasta,
  }) async {
    try {
      Uri uri = Uri.parse('$baseUrl/historial-incidentes');
      
      Map<String, String> queryParams = {};
      if (estado != null) queryParams['estado'] = estado;
      if (fechaDesde != null) queryParams['fecha_desde'] = fechaDesde;
      if (fechaHasta != null) queryParams['fecha_hasta'] = fechaHasta;
      
      if (queryParams.isNotEmpty) {
        uri = uri.replace(queryParameters: queryParams);
      }

      print('Obteniendo historial de incidentes. URL: $uri');
      print('Token usado: $token');

      final response = await http.get(
        uri,
        headers: {'Authorization': 'Bearer $token'},
      );

      print('Código de respuesta: ${response.statusCode}');
      print('Cuerpo de respuesta: ${response.body}');

      if (response.statusCode != 200) {
        throw Exception('Error al obtener historial de incidentes');
      }

      final List<dynamic> incidentsJson = json.decode(response.body);
      return incidentsJson.cast<Map<String, dynamic>>();
    } catch (e) {
      print('Error en getUserIncidentHistory: $e');
      throw Exception('Error de conexión: $e');
    }
  }

  /// Obtiene las notificaciones del usuario
  Future<List<Map<String, dynamic>>> getUserNotifications({
    bool? soloNoLeidas,
  }) async {
    try {
      Uri uri = Uri.parse('$baseUrl/notificaciones');
      
      if (soloNoLeidas != null) {
        uri = uri.replace(queryParameters: {
          'solo_no_leidas': soloNoLeidas.toString()
        });
      }

      print('Obteniendo notificaciones del usuario. URL: $uri');
      print('Token usado: $token');

      final response = await http.get(
        uri,
        headers: {'Authorization': 'Bearer $token'},
      );

      print('Código de respuesta: ${response.statusCode}');
      print('Cuerpo de respuesta: ${response.body}');

      if (response.statusCode != 200) {
        throw Exception('Error al obtener notificaciones');
      }

      final List<dynamic> notificationsJson = json.decode(response.body);
      return notificationsJson.cast<Map<String, dynamic>>();
    } catch (e) {
      print('Error en getUserNotifications: $e');
      throw Exception('Error de conexión: $e');
    }
  }

  /// Marca una notificación como leída
  Future<Map<String, dynamic>> markNotificationAsRead(
    String notificationId,
  ) async {
    try {
      print('Marcando notificación como leída: $notificationId');
      print('Token usado: $token');

      final response = await http.post(
        Uri.parse('$baseUrl/notificaciones/$notificationId/marcar-leida'),
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
          'message': responseData['error'] ?? 'Error al marcar notificación',
        };
      }

      return {
        'success': true,
        'message': responseData['mensaje'] ?? 'Notificación marcada como leída',
      };
    } catch (e) {
      print('Error en markNotificationAsRead: $e');
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  /// Lista todos los usuarios del sistema (Solo para bomberos)
  Future<List<Map<String, dynamic>>> getAllSystemUsers({
    bool? esBombero,
    String? nombre,
  }) async {
    try {
      Uri uri = Uri.parse('$baseUrl/sistema');
      
      Map<String, String> queryParams = {};
      if (esBombero != null) queryParams['es_bombero'] = esBombero.toString();
      if (nombre != null) queryParams['nombre'] = nombre;
      
      if (queryParams.isNotEmpty) {
        uri = uri.replace(queryParameters: queryParams);
      }

      print('Obteniendo usuarios del sistema. URL: $uri');
      print('Token usado: $token');

      final response = await http.get(
        uri,
        headers: {'Authorization': 'Bearer $token'},
      );

      print('Código de respuesta: ${response.statusCode}');
      print('Cuerpo de respuesta: ${response.body}');

      if (response.statusCode != 200) {
        throw Exception('Error al obtener usuarios del sistema');
      }

      final List<dynamic> usersJson = json.decode(response.body);
      return usersJson.cast<Map<String, dynamic>>();
    } catch (e) {
      print('Error en getAllSystemUsers: $e');
      throw Exception('Error de conexión: $e');
    }
  }

  /// Elimina un usuario (Solo para bomberos)
  Future<Map<String, dynamic>> deleteUser(String userId) async {
    try {
      print('Eliminando usuario: $userId');
      print('Token usado: $token');

      final response = await http.delete(
        Uri.parse('$baseUrl/$userId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      print('Código de respuesta: ${response.statusCode}');
      print('Cuerpo de respuesta: ${response.body}');

      final responseData = json.decode(response.body);

      if (response.statusCode != 200) {
        return {
          'success': false,
          'message': responseData['error'] ?? 'Error al eliminar usuario',
        };
      }

      return {
        'success': true,
        'message': responseData['mensaje'] ?? 'Usuario eliminado exitosamente',
      };
    } catch (e) {
      print('Error en deleteUser: $e');
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }
}