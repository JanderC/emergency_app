class User {
  final String id;
  final String nombre;
  final String apellido;
  final String email;
  final String? telefono;
  final bool esBombero;
  final String? fotoPerfil;
  final String? fechaRegistro;

  User({
    required this.id,
    required this.nombre,
    required this.apellido,
    required this.email,
    this.telefono,
    required this.esBombero,
    this.fotoPerfil,
    this.fechaRegistro,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'].toString(),
      nombre: json['nombre'],
      apellido: json['apellido'],
      email: json['email'],
      telefono: json['telefono'],
      esBombero: json['es_bombero'] ?? false,
      fotoPerfil: json['foto_perfil'],
      fechaRegistro: json['fecha_registro'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'apellido': apellido,
      'email': email,
      'telefono': telefono,
      'es_bombero': esBombero,
      'foto_perfil': fotoPerfil,
      'fecha_registro': fechaRegistro,
    };
  }

  String get nombreCompleto => '$nombre $apellido';
}
