class Turno {
  final String id;
  final String colaboradorId;
  final String supervisorId;
  final String restauranteId;
  final DateTime fecha;
  final String horaInicio;
  final String horaFin;
  final String? pausaInicio;
  final String? pausaFin;
  final String estacion;
  final String estado;
  final DateTime? creadoEn;

  // Joined metadata from Supabase queries
  final String? colaboradorNombre;
  final String? colaboradorCedula;

  const Turno({
    required this.id,
    required this.colaboradorId,
    required this.supervisorId,
    required this.restauranteId,
    required this.fecha,
    required this.horaInicio,
    required this.horaFin,
    this.pausaInicio,
    this.pausaFin,
    required this.estacion,
    this.estado = 'programado',
    this.creadoEn,
    this.colaboradorNombre,
    this.colaboradorCedula,
  });

  factory Turno.fromJson(Map<String, dynamic> json) {
    String? cNombre;
    String? cCedula;
    if (json['perfiles'] is Map) {
      cNombre = json['perfiles']['nombre'] as String?;
      cCedula = json['perfiles']['cedula'] as String?;
    }

    return Turno(
      id: json['id'] as String,
      colaboradorId: json['colaborador_id'] as String,
      supervisorId: json['supervisor_id'] as String? ?? '',
      restauranteId: json['restaurante_id'] as String? ?? '',
      fecha: json['fecha'] is String
          ? DateTime.parse(json['fecha'] as String)
          : (json['fecha'] as DateTime? ?? DateTime.now()),
      horaInicio: json['hora_inicio'] as String? ?? '08:00',
      horaFin: json['hora_fin'] as String? ?? '16:00',
      pausaInicio: json['pausa_inicio'] as String?,
      pausaFin: json['pausa_fin'] as String?,
      estacion: json['estacion'] as String? ?? 'Polivalente',
      estado: json['estado'] as String? ?? 'programado',
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
      'supervisor_id': supervisorId,
      'restaurante_id': restauranteId,
      'fecha':
          "${fecha.year.toString().padLeft(4, '0')}-${fecha.month.toString().padLeft(2, '0')}-${fecha.day.toString().padLeft(2, '0')}",
      'hora_inicio': horaInicio,
      'hora_fin': horaFin,
      'pausa_inicio': pausaInicio,
      'pausa_fin': pausaFin,
      'estacion': estacion,
      'estado': estado,
      if (creadoEn != null) 'creado_en': creadoEn!.toIso8601String(),
    };
  }

  String get horarioFormat => '$horaInicio - $horaFin';

  double get duracionHoras {
    try {
      final startParts = horaInicio.split(':').map(int.parse).toList();
      final endParts = horaFin.split(':').map(int.parse).toList();
      final startMin = startParts[0] * 60 + startParts[1];
      var endMin = endParts[0] * 60 + endParts[1];
      if (endMin < startMin) endMin += 24 * 60; // Turno nocturno
      return (endMin - startMin) / 60.0;
    } catch (_) {
      return 8.0;
    }
  }

  Turno copyWith({
    String? id,
    String? colaboradorId,
    String? supervisorId,
    String? restauranteId,
    DateTime? fecha,
    String? horaInicio,
    String? horaFin,
    String? pausaInicio,
    String? pausaFin,
    String? estacion,
    String? estado,
    DateTime? creadoEn,
    String? colaboradorNombre,
    String? colaboradorCedula,
  }) {
    return Turno(
      id: id ?? this.id,
      colaboradorId: colaboradorId ?? this.colaboradorId,
      supervisorId: supervisorId ?? this.supervisorId,
      restauranteId: restauranteId ?? this.restauranteId,
      fecha: fecha ?? this.fecha,
      horaInicio: horaInicio ?? this.horaInicio,
      horaFin: horaFin ?? this.horaFin,
      pausaInicio: pausaInicio ?? this.pausaInicio,
      pausaFin: pausaFin ?? this.pausaFin,
      estacion: estacion ?? this.estacion,
      estado: estado ?? this.estado,
      creadoEn: creadoEn ?? this.creadoEn,
      colaboradorNombre: colaboradorNombre ?? this.colaboradorNombre,
      colaboradorCedula: colaboradorCedula ?? this.colaboradorCedula,
    );
  }
}

