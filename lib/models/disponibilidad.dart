import 'enums.dart';

class Disponibilidad {
  final String id;
  final String colaboradorId;
  final DateTime fecha;
  final TipoNovedad motivo;
  final String? detalles;
  final EstadoSolicitud estado;
  final DateTime? creadoEn;

  // Joined metadata
  final String? colaboradorNombre;
  final String? colaboradorCedula;

  const Disponibilidad({
    required this.id,
    required this.colaboradorId,
    required this.fecha,
    required this.motivo,
    this.detalles,
    this.estado = EstadoSolicitud.pendiente,
    this.creadoEn,
    this.colaboradorNombre,
    this.colaboradorCedula,
  });

  factory Disponibilidad.fromJson(Map<String, dynamic> json) {
    String? cNombre;
    String? cCedula;
    if (json['perfiles'] is Map) {
      cNombre = json['perfiles']['nombre'] as String?;
      cCedula = json['perfiles']['cedula'] as String?;
    }

    return Disponibilidad(
      id: json['id'] as String,
      colaboradorId: json['colaborador_id'] as String,
      fecha: json['fecha'] is String
          ? DateTime.parse(json['fecha'] as String)
          : (json['fecha'] as DateTime? ?? DateTime.now()),
      motivo: TipoNovedad.fromString(json['motivo'] as String? ?? 'descanso'),
      detalles: json['detalles'] as String?,
      estado: EstadoSolicitud.fromString(
        json['estado'] as String? ?? 'pendiente',
      ),
      creadoEn: json['creado_en'] != null
          ? DateTime.tryParse(json['creado_en'] as String)
          : null,
      colaboradorNombre: cNombre,
      colaboradorCedula: cCedula,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'colaborador_id': colaboradorId,
      'fecha':
          "${fecha.year.toString().padLeft(4, '0')}-${fecha.month.toString().padLeft(2, '0')}-${fecha.day.toString().padLeft(2, '0')}",
      'motivo': motivo.toDbValue(),
      'detalles': detalles,
      'estado': estado.toDbValue(),
      if (creadoEn != null) 'creado_en': creadoEn!.toIso8601String(),
    };
  }

  Disponibilidad copyWith({
    String? id,
    String? colaboradorId,
    DateTime? fecha,
    TipoNovedad? motivo,
    String? detalles,
    EstadoSolicitud? estado,
    DateTime? creadoEn,
    String? colaboradorNombre,
    String? colaboradorCedula,
  }) {
    return Disponibilidad(
      id: id ?? this.id,
      colaboradorId: colaboradorId ?? this.colaboradorId,
      fecha: fecha ?? this.fecha,
      motivo: motivo ?? this.motivo,
      detalles: detalles ?? this.detalles,
      estado: estado ?? this.estado,
      creadoEn: creadoEn ?? this.creadoEn,
      colaboradorNombre: colaboradorNombre ?? this.colaboradorNombre,
      colaboradorCedula: colaboradorCedula ?? this.colaboradorCedula,
    );
  }
}
