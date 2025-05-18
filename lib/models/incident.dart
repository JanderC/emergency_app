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
    final coordinates = json['coordenadas']?['coordinates'];
    if (coordinates == null || coordinates.length != 2) {
      throw FormatException("Coordenadas no válidas");
    }

    return Incident(
      id: json['_id'] ?? json['id'],
      tipoEmergencia: json['tipo_emergencia'] ?? '',
      descripcion: json['descripcion'] ?? '',
      ubicacion: json['ubicacion'] ?? '',
      longitud: (coordinates[0] as num).toDouble(),
      latitud: (coordinates[1] as num).toDouble(),
      nivelUrgencia: json['nivel_urgencia'] ?? '',
      estado: json['estado'] ?? 'pendiente',
      fechaReporte: DateTime.parse(json['fecha_reporte']),
      fechaAtencion: json['fecha_atencion'] != null
          ? DateTime.parse(json['fecha_atencion'])
          : null,
      usuarioId: json['usuario_id'] ?? '',
      bomberoAsignadoId: json['bombero_asignado_id'],
      ambulanciaId: json['ambulancia_id'],
      imagenes: json['imagenes'] != null
          ? List<String>.from(json['imagenes'])
          : [],
    );
  }
}
