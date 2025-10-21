// lib/models/ambulance.dart
class Ambulance {
  final String id;
  final String placa;
  final String? modelo;
  final String? tipo;
  final int? capacidad;
  final int? ano;
  final String estado;
  final String? estacionPertenencia;
  final String? bomberoAsignadoId;
  final Map<String, dynamic>? ubicacionActual;
  final DateTime fechaRegistro;
  final Map<String, dynamic>? bomberoInfo;

  Ambulance({
    required this.id,
    required this.placa,
    this.modelo,
    this.tipo,
    this.capacidad,
    this.ano,
    required this.estado,
    this.estacionPertenencia,
    this.bomberoAsignadoId,
    this.ubicacionActual,
    required this.fechaRegistro,
    this.bomberoInfo,
  });

  factory Ambulance.fromJson(Map<String, dynamic> json) {
    return Ambulance(
      id: json['_id']?.toString() ?? '',
      placa: json['placa'] ?? '',
      modelo: json['modelo'],
      tipo: json['tipo'],
      capacidad: json['capacidad'],
      ano: json['ano'],
      estado: json['estado'] ?? 'operativa',
      estacionPertenencia: json['estacion_pertenencia'],
      bomberoAsignadoId: json['bombero_asignado_id'],
      ubicacionActual: json['ubicacion_actual'],
      fechaRegistro: json['fecha_registro'] != null
          ? DateTime.parse(json['fecha_registro'].toString())
          : DateTime.now(),
      bomberoInfo: json['bombero_info'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'placa': placa,
      'modelo': modelo,
      'tipo': tipo,
      'capacidad': capacidad,
      'ano': ano,
      'estado': estado,
      'estacion_pertenencia': estacionPertenencia,
      'bombero_asignado_id': bomberoAsignadoId,
      'ubicacion_actual': ubicacionActual,
      'fecha_registro': fechaRegistro.toIso8601String(),
      'bombero_info': bomberoInfo,
    };
  }

  bool get isDisponible =>
      estado == 'operativa' && bomberoAsignadoId == null;

  String get displayName => '$placa${modelo != null ? " - $modelo" : ""}';
}