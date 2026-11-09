import 'enums.dart';

class Perfil {
  final String id;
  final String cedula;
  final String nombre;
  final String correo;
  final RolUsuario rol;
  final String? restauranteId;
  final String? estacionPrincipal;
  final String? equipo;
  final DateTime? creadoEn;

  const Perfil({
    required this.id,
    required this.cedula,
    required this.nombre,
    required this.correo,
    this.rol = RolUsuario.colaborador,
    this.restauranteId,
    this.estacionPrincipal,
    this.equipo,
    this.creadoEn,
  });

  factory Perfil.fromJson(Map<String, dynamic> json) {
    return Perfil(
      id: json['id'] as String,
      cedula: json['cedula'] as String? ?? '',
      nombre: json['nombre'] as String? ?? '',
      correo: json['correo'] as String? ?? '',
      rol: RolUsuario.fromString(json['rol'] as String? ?? 'colaborador'),
      restauranteId: json['restaurante_id'] as String?,
      estacionPrincipal: json['estacion_principal'] as String?,
      equipo: json['equipo'] as String?,
      creadoEn: json['creado_en'] != null
          ? DateTime.tryParse(json['creado_en'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'cedula': cedula,
      'nombre': nombre,
      'correo': correo,
      'rol': rol.toDbValue(),
      'restaurante_id': restauranteId,
      'estacion_principal': estacionPrincipal,
      'equipo': equipo,
      if (creadoEn != null) 'creado_en': creadoEn!.toIso8601String(),
    };
  }

  Perfil copyWith({
    String? id,
    String? cedula,
    String? nombre,
    String? correo,
    RolUsuario? rol,
    String? restauranteId,
    String? estacionPrincipal,
    String? equipo,
    DateTime? creadoEn,
  }) {
    return Perfil(
      id: id ?? this.id,
      cedula: cedula ?? this.cedula,
      nombre: nombre ?? this.nombre,
      correo: correo ?? this.correo,
      rol: rol ?? this.rol,
      restauranteId: restauranteId ?? this.restauranteId,
      estacionPrincipal: estacionPrincipal ?? this.estacionPrincipal,
      equipo: equipo ?? this.equipo,
      creadoEn: creadoEn ?? this.creadoEn,
    );
  }
}

