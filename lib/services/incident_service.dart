// lib/services/incident_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:app_emergency/models/incident.dart';
import 'package:app_emergency/utils/shared_prefs.dart';
import 'package:app_emergency/models/quick_report.dart';
import 'package:app_emergency/services/quick_report_service.dart';

class IncidentService {
  final String baseUrl = 'https://emergencyapi-production.up.railway.app/api/incidentes';

  // Obtener el token cada vez que se necesite
  String? get token => SharedPrefs.getToken();
  final _quickReportService = QuickReportService();

  
  /// Convierte un archivo de imagen a base64
  Future<String> imageFileToBase64(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final base64String = base64Encode(bytes);
      
      // Determinar el tipo de imagen por la extensión
      String mimeType = 'image/png';
      final extension = imageFile.path.split('.').last.toLowerCase();
      
      if (extension == 'jpg' || extension == 'jpeg') {
        mimeType = 'image/jpeg';
      } else if (extension == 'png') {
        mimeType = 'image/png';
      } else if (extension == 'gif') {
        mimeType = 'image/gif';
      } else if (extension == 'webp') {
        mimeType = 'image/webp';
      }
      
      return 'data:$mimeType;base64,$base64String';
    } catch (e) {
      print('Error al convertir imagen a base64: $e');
      rethrow;
    }
  }

  

  /// Convierte una lista de archivos de imagen a base64
  Future<List<String>> imageFilesToBase64(List<File> imageFiles) async {
    List<String> base64Images = [];
    
    for (var imageFile in imageFiles) {
      try {
        final base64Image = await imageFileToBase64(imageFile);
        base64Images.add(base64Image);
        print('Imagen convertida: ${imageFile.path}');
      } catch (e) {
        print('Error procesando imagen ${imageFile.path}: $e');
        // Continuar con las demás imágenes
      }
    }
    
    return base64Images;
  }

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
        Uri.parse('$baseUrl/$id'),
        headers: {'Authorization': 'Bearer $token'},
      );

      print('Código de respuesta: ${response.statusCode}');

      if (response.statusCode != 200) {
        throw Exception('Error al obtener el incidente: ${response.body}');
      }

      final incidentData = json.decode(response.body);
      print('Incidente obtenido con ${incidentData['imagenes']?.length ?? 0} imágenes');

      return Incident.fromJson(incidentData);
    } catch (e) {
      print('Error en getIncidentById: $e');
      throw Exception('Error de conexión: $e');
    }
  }

  Future<Map<String, dynamic>> reportIncident(
    Map<String, dynamic> incidentData, {
    List<File>? imageFiles,
  }) async {
    try {
      print('Reportando incidente...');
      
      // Convertir imágenes a base64 si se proporcionaron
      if (imageFiles != null && imageFiles.isNotEmpty) {
        print('Convirtiendo ${imageFiles.length} imágenes a base64...');
        final base64Images = await imageFilesToBase64(imageFiles);
        incidentData['imagenes'] = base64Images;
        print('${base64Images.length} imágenes convertidas exitosamente');
      } else {
        incidentData['imagenes'] = [];
      }
      
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
        'imagenes_guardadas': responseData['imagenes_guardadas'] ?? 0,
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

final String baseUrl = 'https://emergencyapi-production.up.railway.app/api/incidentes';

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
