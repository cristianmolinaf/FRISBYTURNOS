import 'enums.dart';
import 'turno.dart';

class MercadoTurno {
  final String id;
  final String turnoId;
  final String solicitanteId;
  final String? receptorId;
  final EstadoSolicitud estado;
  final DateTime? creadoEn;

  // Joined metadata
  final Turno? turno;
  final String? solicitanteNombre;
  final String? receptorNombre;

  const MercadoTurno({
    required this.id,
    required this.turnoId,
    required this.solicitanteId,
    this.receptorId,
    this.estado = EstadoSolicitud.pendiente,
    this.creadoEn,
    this.turno,
    this.solicitanteNombre,
    this.receptorNombre,
  });

  factory MercadoTurno.fromJson(Map<String, dynamic> json) {
    Turno? t;
    if (json['turnos'] is Map<String, dynamic>) {
      t = Turno.fromJson(json['turnos'] as Map<String, dynamic>);
    }

    String? sNombre;
    if (json['solicitante'] is Map) {
      sNombre = json['solicitante']['nombre'] as String?;
    }

    String? rNombre;
    if (json['receptor'] is Map) {
      rNombre = json['receptor']['nombre'] as String?;
    }

    return MercadoTurno(
      id: json['id'] as String,
      turnoId: json['turno_id'] as String,
      solicitanteId: json['solicitante_id'] as String,
      receptorId: json['receptor_id'] as String?,
      estado: EstadoSolicitud.fromString(
        json['estado'] as String? ?? 'pendiente',
      ),
      creadoEn: json['creado_en'] != null
          ? DateTime.tryParse(json['creado_en'] as String)
          : null,
      turno: t,
      solicitanteNombre: sNombre,
      receptorNombre: rNombre,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'turno_id': turnoId,
      'solicitante_id': solicitanteId,
      'receptor_id': receptorId,
      'estado': estado.toDbValue(),
      if (creadoEn != null) 'creado_en': creadoEn!.toIso8601String(),
    };
  }

  bool get estaDisponible =>
      receptorId == null && estado == EstadoSolicitud.pendiente;

  MercadoTurno copyWith({
    String? id,
    String? turnoId,
    String? solicitanteId,
    String? receptorId,
    EstadoSolicitud? estado,
    DateTime? creadoEn,
    Turno? turno,
    String? solicitanteNombre,
    String? receptorNombre,
  }) {
    return MercadoTurno(
      id: id ?? this.id,
      turnoId: turnoId ?? this.turnoId,
      solicitanteId: solicitanteId ?? this.solicitanteId,
      receptorId: receptorId ?? this.receptorId,
      estado: estado ?? this.estado,
      creadoEn: creadoEn ?? this.creadoEn,
      turno: turno ?? this.turno,
      solicitanteNombre: solicitanteNombre ?? this.solicitanteNombre,
      receptorNombre: receptorNombre ?? this.receptorNombre,
    );
  }
}
