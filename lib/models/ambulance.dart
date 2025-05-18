class Ambulance {
  final String id;
  final String placa;
  final String modelo;
  final String tipo;
  final int capacidad;
  final String estado;
  final String? bomberoAsignadoId;
  final String estacionPertenencia;

  Ambulance({
    required this.id,
    required this.placa,
    required this.modelo,
    required this.tipo,
    required this.capacidad,
    required this.estado,
    this.bomberoAsignadoId,
    required this.estacionPertenencia,
  });

  factory Ambulance.fromJson(Map<String, dynamic> json) {
    return Ambulance(
      id: json['id'].toString(),
      placa: json['placa'],
      modelo: json['modelo'],
      tipo: json['tipo'],
      capacidad: json['capacidad'],
      estado: json['estado'],
      bomberoAsignadoId: json['bombero_asignado_id']?.toString(),
      estacionPertenencia: json['estacion_pertenencia'],
    );
  }
}
