// lib/services/incident_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:app_emergency/models/incident.dart';
import 'package:app_emergency/utils/shared_prefs.dart';

class IncidentService {
  final String baseUrl = 'http://127.0.0.1:5000/api/incidentes';

  // Obtener el token cada vez que se necesite, no al inicializar el servicio
  String? get token => SharedPrefs.getToken();

  Future<List<Incident>> getIncidents({Map<String, String>? filters}) async {
    try {
      Uri uri = Uri.parse(baseUrl);

      if (filters != null && filters.isNotEmpty) {
        uri = uri.replace(queryParameters: filters);
      }

      print('Obteniendo incidentes. URL: $uri');
      print('Token usado: $token');

      final response = await http.get(
        uri,
        headers: {'Authorization': 'Bearer $token'},
      );

      print('Código de respuesta: ${response.statusCode}');
      print('Cuerpo de respuesta: ${response.body}');

      if (response.statusCode != 200) {
        throw Exception('Error al obtener incidentes: ${response.body}');
      }

      final List<dynamic> incidentsJson = json.decode(response.body);
      return incidentsJson.map((json) => Incident.fromJson(json)).toList();
    } catch (e) {
      print('Error en getIncidents: $e');
      throw Exception('Error de conexión: $e');
    }
  }

  Future<Incident> getIncidentById(String id) async {
    try {
      print('Obteniendo incidente por ID: $id');
      print('Token usado: $token');

      final response = await http.get(
        Uri.parse('$baseUrl/mongodb/$id'), 
        headers: {'Authorization': 'Bearer $token'},
      );

      print('Código de respuesta: ${response.statusCode}');
      print('Cuerpo de respuesta: ${response.body}');

      if (response.statusCode != 200) {
        throw Exception('Error al obtener el incidente: ${response.body}');
      }

      return Incident.fromJson(json.decode(response.body));
    } catch (e) {
      print('Error en getIncidentById: $e');
      throw Exception('Error de conexión: $e');
    }
  }

  Future<Map<String, dynamic>> reportIncident(
    Map<String, dynamic> incidentData,
  ) async {
    try {
      print('Reportando incidente. Datos: $incidentData');
      print('Token usado: $token');

      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(incidentData),
      );

      print('Código de respuesta: ${response.statusCode}');
      print('Cuerpo de respuesta: ${response.body}');

      final responseData = json.decode(response.body);

      if (response.statusCode != 201) {
        return {
          'success': false,
          'message': responseData['error'] ?? 'Error al reportar incidente',
        };
      }

      return {
        'success': true,
        'id': responseData['id'],
        'message': responseData['mensaje'] ?? 'Incidente reportado con éxito',
      };
    } catch (e) {
      print('Error en reportIncident: $e');
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  Future<Map<String, dynamic>> updateIncidentStatus(
    String incidentId,
    String newStatus, {
    String? bomberoId,
    String? ambulanciaId,
  }) async {
    try {
      print('Actualizando estado del incidente $incidentId a $newStatus');
      print('Bombero ID: $bomberoId, Ambulancia ID: $ambulanciaId');
      print('Token usado: $token');

      final Map<String, dynamic> requestData = {'estado': newStatus};

      // Solo incluir estos campos si no son nulos
      if (bomberoId != null) {
        requestData['bombero_id'] = bomberoId;
      }

      if (ambulanciaId != null) {
        requestData['ambulancia_id'] = ambulanciaId;
      }

      final response = await http.put(
        Uri.parse('$baseUrl/$incidentId/estado'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(requestData),
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
        'message': responseData['mensaje'] ?? 'Estado actualizado con éxito',
      };
    } catch (e) {
      print('Error en updateIncidentStatus: $e');
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }
}

final String baseUrl = 'http://127.0.0.1:5000/api/incidentes';

// Obtener el token cada vez que se necesite, no al inicializar el servicio
String? get token => SharedPrefs.getToken();

Future<List<Incident>> getIncidents({Map<String, String>? filters}) async {
  try {
    Uri uri = Uri.parse(baseUrl);

    if (filters != null && filters.isNotEmpty) {
      uri = uri.replace(queryParameters: filters);
    }

    print('Obteniendo incidentes. URL: $uri');
    print('Token usado: $token');

    final response = await http.get(
      uri,
      headers: {'Authorization': 'Bearer $token'},
    );

    print('Código de respuesta: ${response.statusCode}');
    print('Cuerpo de respuesta: ${response.body}');

    if (response.statusCode != 200) {
      throw Exception('Error al obtener incidentes: ${response.body}');
    }

    final List<dynamic> incidentsJson = json.decode(response.body);
    return incidentsJson.map((json) => Incident.fromJson(json)).toList();
  } catch (e) {
    print('Error en getIncidents: $e');
    throw Exception('Error de conexión: $e');
  }
}

Future<Incident> getIncidentById(String id) async {
  try {
    print('Obteniendo incidente por ID: $id');
    print('Token usado: $token');

    final response = await http.get(
      Uri.parse('$baseUrl/mongodb/$id'), // ✅ Corregido aquí
      headers: {'Authorization': 'Bearer $token'},
    );

    print('Código de respuesta: ${response.statusCode}');
    print('Cuerpo de respuesta: ${response.body}');

    if (response.statusCode != 200) {
      throw Exception('Error al obtener el incidente: ${response.body}');
    }

    return Incident.fromJson(json.decode(response.body));
  } catch (e) {
    print('Error en getIncidentById: $e');
    throw Exception('Error de conexión: $e');
  }
}

Future<Map<String, dynamic>> reportIncident(
  Map<String, dynamic> incidentData,
) async {
  try {
    print('Reportando incidente. Datos: $incidentData');
    print('Token usado: $token');

    final response = await http.post(
      Uri.parse(baseUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode(incidentData),
    );

    print('Código de respuesta: ${response.statusCode}');
    print('Cuerpo de respuesta: ${response.body}');

    final responseData = json.decode(response.body);

    if (response.statusCode != 201) {
      return {
        'success': false,
        'message': responseData['error'] ?? 'Error al reportar incidente',
      };
    }

    return {
      'success': true,
      'id': responseData['id'],
      'message': responseData['mensaje'] ?? 'Incidente reportado con éxito',
    };
  } catch (e) {
    print('Error en reportIncident: $e');
    return {'success': false, 'message': 'Error de conexión: $e'};
  }
}
