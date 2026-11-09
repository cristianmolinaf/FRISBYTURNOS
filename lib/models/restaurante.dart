class Restaurante {
  final String id;
  final String nombre;
  final String? zonaId;
  final String? direccion;

  const Restaurante({
    required this.id,
    required this.nombre,
    this.zonaId,
    this.direccion,
  });

  factory Restaurante.fromJson(Map<String, dynamic> json) {
    return Restaurante(
      id: json['id'] as String,
      nombre: json['nombre'] as String? ?? 'Frisby',
      zonaId: json['zona_id'] as String?,
      direccion: json['direccion'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'zona_id': zonaId,
      'direccion': direccion,
    };
  }
}

class Zona {
  final String id;
  final String nombre;
  final String? jefeZonaId;

  const Zona({required this.id, required this.nombre, this.jefeZonaId});

  factory Zona.fromJson(Map<String, dynamic> json) {
    return Zona(
      id: json['id'] as String,
      nombre: json['nombre'] as String? ?? 'Zona',
      jefeZonaId: json['jefe_zona_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'nombre': nombre, 'jefe_zona_id': jefeZonaId};
  }
}

class NotificacionUsuario {
  final String id;
  final String usuarioId;
  final String titulo;
  final String mensaje;
  final bool leido;
  final DateTime? creadoEn;

  const NotificacionUsuario({
    required this.id,
    required this.usuarioId,
    required this.titulo,
    required this.mensaje,
    this.leido = false,
    this.creadoEn,
  });

  factory NotificacionUsuario.fromJson(Map<String, dynamic> json) {
    return NotificacionUsuario(
      id: json['id'] as String,
      usuarioId: json['usuario_id'] as String,
      titulo: json['titulo'] as String? ?? '',
      mensaje: json['mensaje'] as String? ?? '',
      leido: json['leido'] as bool? ?? false,
      creadoEn: json['creado_en'] != null
          ? DateTime.tryParse(json['creado_en'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'usuario_id': usuarioId,
      'titulo': titulo,
      'mensaje': mensaje,
      'leido': leido,
      if (creadoEn != null) 'creado_en': creadoEn!.toIso8601String(),
    };
  }
}
