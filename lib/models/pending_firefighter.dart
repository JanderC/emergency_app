// lib/models/pending_firefighter.dart
class PendingFirefighter {
  final String id;
  final String usuarioId;
  final String nombre;
  final String email;
  final String cedula;
  final String telefono;
  final String codigoBombero;
  final String estacionPertenencia;
  final String rango;
  final List<String> especialidades;
  final int experienciaAnos;
  final DateTime fechaRegistro;
  final String estadoAprobacion;

  PendingFirefighter({
    required this.id,
    required this.usuarioId,
    required this.nombre,
    required this.email,
    required this.cedula,
    required this.telefono,
    required this.codigoBombero,
    required this.estacionPertenencia,
    required this.rango,
    required this.especialidades,
    required this.experienciaAnos,
    required this.fechaRegistro,
    required this.estadoAprobacion,
  });

  factory PendingFirefighter.fromJson(Map<String, dynamic> json) {
    return PendingFirefighter(
      id: json['_id']?.toString() ?? '',
      usuarioId: json['usuario_id']?.toString() ?? '',
      nombre: json['nombre'] ?? '',
      email: json['email'] ?? '',
      cedula: json['cedula'] ?? '',
      telefono: json['telefono'] ?? '',
      codigoBombero: json['codigo_bombero'] ?? '',
      estacionPertenencia: json['estacion_pertenencia'] ?? '',
      rango: json['rango'] ?? 'bombero',
      especialidades: List<String>.from(json['especialidades'] ?? []),
      experienciaAnos: json['experiencia_anos'] ?? 0,
      fechaRegistro: _parseFecha(json['fecha_registro']), // CAMBIO AQUÍ
      estadoAprobacion: json['estado_aprobacion'] ?? 'pendiente',
    );
  }

  // NUEVO: Método para parsear fechas de diferentes formatos
  static DateTime _parseFecha(dynamic fecha) {
    if (fecha == null) return DateTime.now();
    
    try {
      // Si es un string
      if (fecha is String) {
        // Intentar formato ISO
        return DateTime.parse(fecha);
      }
      
      // Si es un Map (formato MongoDB)
      if (fecha is Map) {
        if (fecha.containsKey('\$date')) {
          final dateValue = fecha['\$date'];
          if (dateValue is Map && dateValue.containsKey('\$numberLong')) {
            // Formato: {"$date": {"$numberLong": "1744578508614"}}
            final timestamp = int.parse(dateValue['\$numberLong']);
            return DateTime.fromMillisecondsSinceEpoch(timestamp);
          } else if (dateValue is int) {
            // Formato: {"$date": 1744578508614}
            return DateTime.fromMillisecondsSinceEpoch(dateValue);
          } else if (dateValue is String) {
            // Formato: {"$date": "2025-10-06T21:13:47.000Z"}
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
}