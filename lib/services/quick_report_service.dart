// lib/services/quick_report_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:app_emergency/models/quick_report.dart';
import 'package:app_emergency/utils/shared_prefs.dart';

class QuickReportService {
  static const String baseUrl = 'https://emergencyapi-production.up.railway.app/api/reportes-rapidos';

  Future<Map<String, dynamic>> createQuickReport(QuickReport report) async {
    try {
      // Este endpoint NO requiere autenticación
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(report.toJson()),
      );

      print('Status: ${response.statusCode}');
      print('Body: ${response.body}');

      final responseData = json.decode(response.body);

      if (response.statusCode == 201) {
        return {
          'success': true,
          'message': responseData['mensaje'] ?? 'Reporte enviado exitosamente',
          'reporte_id': responseData['reporte_id'],
        };
      } else {
        return {
          'success': false,
          'message': responseData['error'] ?? 'Error al enviar el reporte',
        };
      }
    } catch (e) {
      print('Error en createQuickReport: $e');
      return {
        'success': false,
        'message': 'Error de conexión: $e',
      };
    }
  }

  Future<List<QuickReport>> getPendingReports() async {
    try {
      final token = SharedPrefs.getToken();
      
      final response = await http.get(
        Uri.parse('$baseUrl/pendientes'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => QuickReport.fromJson(json)).toList();
      } else {
        throw Exception('Error al obtener reportes pendientes');
      }
    } catch (e) {
      print('Error en getPendingReports: $e');
      throw Exception('Error al obtener reportes: $e');
    }
  }

  // NUEVO: Obtener un reporte específico por ID
  Future<QuickReport> getReportById(String reportId) async {
    try {
      final token = SharedPrefs.getToken();

      final response = await http.get(
        Uri.parse('$baseUrl/$reportId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('Status getReportById: ${response.statusCode}');
      print('Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return QuickReport.fromJson(data);
      } else {
        throw Exception('Error al obtener el reporte');
      }
    } catch (e) {
      print('Error en getReportById: $e');
      throw Exception('Error: $e');
    }
  }

  Future<Map<String, dynamic>> assignFirefighter(
    String reporteId,
    String bomberoId,
  ) async {
    try {
      final token = SharedPrefs.getToken();

      final response = await http.post(
        Uri.parse('$baseUrl/$reporteId/asignar'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'bombero_id': bomberoId}),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': responseData['mensaje'],
        };
      } else {
        return {
          'success': false,
          'message': responseData['error'] ?? 'Error al asignar bombero',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }

  Future<Map<String, dynamic>> completeReport(
    String reporteId, {
    String? notas,
  }) async {
    try {
      final token = SharedPrefs.getToken();

      final response = await http.post(
        Uri.parse('$baseUrl/$reporteId/completar'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'notas': notas}),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': responseData['mensaje'],
        };
      } else {
        return {
          'success': false,
          'message': responseData['error'] ?? 'Error al completar reporte',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }

  Future<List<QuickReport>> getMyReports() async {
    try {
      final token = SharedPrefs.getToken();

      final response = await http.get(
        Uri.parse('$baseUrl/mis-reportes'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => QuickReport.fromJson(json)).toList();
      } else {
        throw Exception('Error al obtener mis reportes');
      }
    } catch (e) {
      print('Error en getMyReports: $e');
      throw Exception('Error: $e');
    }
  }
}