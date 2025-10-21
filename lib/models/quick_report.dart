// lib/models/quick_report.dart
class QuickReport {
  final String? id;
  final String tipoEmergencia;
  final String foto;
  final String nombreFoto;
  final String direccion;
  final double? lat;
  final double? lng;
  final String? usuarioId;
  final String estado;
  final DateTime fechaReporte;
  final String? bomberoAsignadoId;

  QuickReport({
    this.id,
    required this.tipoEmergencia,
    required this.foto,
    required this.nombreFoto,
    required this.direccion,
    this.lat,
    this.lng,
    this.usuarioId,
    this.estado = 'pendiente',
    required this.fechaReporte,
    this.bomberoAsignadoId,
  });

  factory QuickReport.fromJson(Map<String, dynamic> json) {
    return QuickReport(
      id: json['_id']?.toString(),
      tipoEmergencia: json['tipo_emergencia'] ?? '',
      foto: json['foto'] ?? '',
      nombreFoto: json['nombre_foto'] ?? '',
      direccion: json['direccion'] ?? '',
      lat: json['coordenadas']?['lat']?.toDouble(),
      lng: json['coordenadas']?['lng']?.toDouble(),
      usuarioId: json['usuario_id'],
      estado: json['estado'] ?? 'pendiente',
      fechaReporte: _parseFecha(json['fecha_reporte']),
      bomberoAsignadoId: json['bombero_asignado_id'],
    );
  }

  // Método mejorado para parsear diferentes formatos de fecha
  static DateTime _parseFecha(dynamic fecha) {
    if (fecha == null) return DateTime.now();
    
    try {
      // Si es un string
      if (fecha is String) {
        // Intentar formato HTTP (Mon, 06 Oct 2025 21:32:05 GMT)
        if (fecha.contains(',') && fecha.contains('GMT')) {
          return _parseHttpDate(fecha);
        }
        
        // Intentar formato ISO (2025-10-06T21:32:05.000Z)
        try {
          return DateTime.parse(fecha);
        } catch (e) {
          print('Error parseando fecha ISO: $e');
        }
      }
      
      // Si es un Map (formato MongoDB)
      if (fecha is Map) {
        if (fecha.containsKey('\$date')) {
          final dateValue = fecha['\$date'];
          if (dateValue is Map && dateValue.containsKey('\$numberLong')) {
            final timestamp = int.parse(dateValue['\$numberLong']);
            return DateTime.fromMillisecondsSinceEpoch(timestamp);
          } else if (dateValue is int) {
            return DateTime.fromMillisecondsSinceEpoch(dateValue);
          } else if (dateValue is String) {
            return DateTime.parse(dateValue);
          }
        }
      }
      
      // Si es un int (timestamp)
      if (fecha is int) {
        return DateTime.fromMillisecondsSinceEpoch(fecha);
      }
      
      return DateTime.now();
    } catch (e) {
      print('Error parseando fecha: $e, valor: $fecha');
      return DateTime.now();
    }
  }

  // Parsea fechas en formato HTTP (Mon, 06 Oct 2025 21:32:05 GMT)
  static DateTime _parseHttpDate(String dateStr) {
    try {
      // Mapa de meses
      final months = {
        'Jan': 1, 'Feb': 2, 'Mar': 3, 'Apr': 4,
        'May': 5, 'Jun': 6, 'Jul': 7, 'Aug': 8,
        'Sep': 9, 'Oct': 10, 'Nov': 11, 'Dec': 12,
      };
      
      // Ejemplo: "Mon, 06 Oct 2025 21:32:05 GMT"
      final parts = dateStr.split(' ');
      
      if (parts.length >= 5) {
        final day = int.parse(parts[1]);
        final month = months[parts[2]] ?? 1;
        final year = int.parse(parts[3]);
        
        final timeParts = parts[4].split(':');
        final hour = int.parse(timeParts[0]);
        final minute = int.parse(timeParts[1]);
        final second = int.parse(timeParts[2]);
        
        return DateTime.utc(year, month, day, hour, minute, second);
      }
      
      return DateTime.now();
    } catch (e) {
      print('Error parseando fecha HTTP: $e, fecha: $dateStr');
      return DateTime.now();
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'tipo_emergencia': tipoEmergencia,
      'foto': foto,
      'nombre_foto': nombreFoto,
      'direccion': direccion,
      if (lat != null) 'lat': lat,
      if (lng != null) 'lng': lng,
    };
  }
}