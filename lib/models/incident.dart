// lib/models/incident.dart
class Incident {
  final String id;
  final String tipoEmergencia;
  final String descripcion;
  final String ubicacion;
  final double latitud;
  final double longitud;
  final String nivelUrgencia;
  final String estado;
  final DateTime fechaReporte;
  final DateTime? fechaAtencion;
  final String usuarioId;
  final String? bomberoAsignadoId;
  final String? ambulanciaId;
  final List<String> imagenes;

  Incident({
    required this.id,
    required this.tipoEmergencia,
    required this.descripcion,
    required this.ubicacion,
    required this.latitud,
    required this.longitud,
    required this.nivelUrgencia,
    required this.estado,
    required this.fechaReporte,
    this.fechaAtencion,
    required this.usuarioId,
    this.bomberoAsignadoId,
    this.ambulanciaId,
    required this.imagenes,
  });

  factory Incident.fromJson(Map<String, dynamic> json) {
    double lat = 0.0;
    double lng = 0.0;

    // Intentar obtener coordenadas de diferentes formatos
    if (json['coordenadas'] != null) {
      final coordinates = json['coordenadas']['coordinates'];
      if (coordinates != null && coordinates.length >= 2) {
        lng = (coordinates[0] as num).toDouble();
        lat = (coordinates[1] as num).toDouble();
      }
    } else if (json['lat'] != null && json['lng'] != null) {
      lat = (json['lat'] as num).toDouble();
      lng = (json['lng'] as num).toDouble();
    } else if (json['coordenadas_lat'] != null && json['coordenadas_lng'] != null) {
      lat = (json['coordenadas_lat'] as num).toDouble();
      lng = (json['coordenadas_lng'] as num).toDouble();
    }

    return Incident(
      id: json['_id'] ?? json['id'] ?? '',
      tipoEmergencia: json['tipo_emergencia'] ?? '',
      descripcion: json['descripcion'] ?? '',
      ubicacion: json['ubicacion'] ?? json['direccion'] ?? '',
      longitud: lng,
      latitud: lat,
      nivelUrgencia: json['nivel_urgencia'] ?? 'media',
      estado: json['estado'] ?? 'pendiente',
      fechaReporte: json['fecha_reporte'] != null
          ? DateTime.parse(json['fecha_reporte'])
          : DateTime.now(),
      fechaAtencion: json['fecha_atencion'] != null
          ? DateTime.parse(json['fecha_atencion'])
          : null,
      usuarioId: json['usuario_id'] ?? '',
      bomberoAsignadoId: json['bombero_asignado_id'],
      ambulanciaId: json['ambulancia_id'],
      imagenes: json['imagenes'] != null
          ? List<String>.from(json['imagenes'])
          : json['foto'] != null
              ? [json['foto']]
              : [],
    );
  }
}