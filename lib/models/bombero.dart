class Bombero {
  final String id;
  final String usuarioId;
  final String codigoBombero;
  final String estacionPertenencia;
  final String rango;
  final List<String> especialidades;
  final List<String> certificaciones;
  final String estadoServicio;
  final DateTime fechaRegistro;
  final int experienciaAnos;
  final Map<String, dynamic>? contactoEmergencia;
  final String? ambulanciaId;
  final Map<String, dynamic>? ubicacionActual;
  final int turnosCompletados;
  final int incidentesAtendidos;

  Bombero({
    required this.id,
    required this.usuarioId,
    required this.codigoBombero,
    required this.estacionPertenencia,
    required this.rango,
    required this.especialidades,
    required this.certificaciones,
    required this.estadoServicio,
    required this.fechaRegistro,
    required this.experienciaAnos,
    this.contactoEmergencia,
    this.ambulanciaId,
    this.ubicacionActual,
    this.turnosCompletados = 0,
    this.incidentesAtendidos = 0,
  });

  factory Bombero.fromJson(Map<String, dynamic> json) {
    return Bombero(
      id: json['_id']?.toString() ?? '',
      usuarioId: json['usuario_id']?.toString() ?? '',
      codigoBombero: json['codigo_bombero'] ?? '',
      estacionPertenencia: json['estacion_pertenencia'] ?? '',
      rango: json['rango'] ?? 'bombero',
      especialidades: List<String>.from(json['especialidades'] ?? []),
      certificaciones: List<String>.from(json['certificaciones'] ?? []),
      estadoServicio: json['estado_servicio'] ?? 'disponible',
      fechaRegistro: json['fecha_registro'] != null 
          ? DateTime.parse(json['fecha_registro'].toString())
          : DateTime.now(),
      experienciaAnos: json['experiencia_anos'] ?? 0,
      contactoEmergencia: json['contacto_emergencia'],
      ambulanciaId: json['ambulancia_id'],
      ubicacionActual: json['ubicacion_actual'],
      turnosCompletados: json['turnos_completados'] ?? 0,
      incidentesAtendidos: json['incidentes_atendidos'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'usuario_id': usuarioId,
      'codigo_bombero': codigoBombero,
      'estacion_pertenencia': estacionPertenencia,
      'rango': rango,
      'especialidades': especialidades,
      'certificaciones': certificaciones,
      'estado_servicio': estadoServicio,
      'fecha_registro': fechaRegistro.toIso8601String(),
      'experiencia_anos': experienciaAnos,
      'contacto_emergencia': contactoEmergencia,
      'ambulancia_id': ambulanciaId,
      'ubicacion_actual': ubicacionActual,
      'turnos_completados': turnosCompletados,
      'incidentes_atendidos': incidentesAtendidos,
    };
  }
}