/// Enums oficiales basados en el esquema de base de datos Supabase de Frisby Turnos.
library;

enum RolUsuario {
  superadmin,
  jefeZona,
  administrador,
  colaborador;

  static RolUsuario fromString(String val) {
    switch (val.toLowerCase().trim()) {
      case 'superadmin':
        return RolUsuario.superadmin;
      case 'jefe_zona':
      case 'jefezona':
        return RolUsuario.jefeZona;
      case 'administrador':
      case 'admin':
        return RolUsuario.administrador;
      default:
        return RolUsuario.colaborador;
    }
  }

  String toDbValue() {
    switch (this) {
      case RolUsuario.superadmin:
        return 'superadmin';
      case RolUsuario.jefeZona:
        return 'jefe_zona';
      case RolUsuario.administrador:
        return 'administrador';
      case RolUsuario.colaborador:
        return 'colaborador';
    }
  }

  String get displayName {
    switch (this) {
      case RolUsuario.superadmin:
        return 'Superadministrador';
      case RolUsuario.jefeZona:
        return 'Jefe de Zona';
      case RolUsuario.administrador:
        return 'Administrador de Punto';
      case RolUsuario.colaborador:
        return 'Colaborador';
    }
  }

  bool get isAdminLevel =>
      this == RolUsuario.superadmin ||
      this == RolUsuario.jefeZona ||
      this == RolUsuario.administrador;
}

enum EstadoSolicitud {
  pendiente,
  aprobada,
  rechazada;

  static EstadoSolicitud fromString(String val) {
    switch (val.toLowerCase().trim()) {
      case 'aprobada':
        return EstadoSolicitud.aprobada;
      case 'rechazada':
        return EstadoSolicitud.rechazada;
      default:
        return EstadoSolicitud.pendiente;
    }
  }

  String toDbValue() {
    switch (this) {
      case EstadoSolicitud.pendiente:
        return 'pendiente';
      case EstadoSolicitud.aprobada:
        return 'aprobada';
      case EstadoSolicitud.rechazada:
        return 'rechazada';
    }
  }

  String get displayName {
    switch (this) {
      case EstadoSolicitud.pendiente:
        return 'Pendiente';
      case EstadoSolicitud.aprobada:
        return 'Aprobada';
      case EstadoSolicitud.rechazada:
        return 'Rechazada';
    }
  }
}

enum TipoNovedad {
  descanso,
  citaMedica,
  calamidad,
  sugerencia;

  static TipoNovedad fromString(String val) {
    switch (val.toLowerCase().trim()) {
      case 'cita_medica':
      case 'citamedica':
        return TipoNovedad.citaMedica;
      case 'calamidad':
        return TipoNovedad.calamidad;
      case 'sugerencia':
        return TipoNovedad.sugerencia;
      default:
        return TipoNovedad.descanso;
    }
  }

  String toDbValue() {
    switch (this) {
      case TipoNovedad.descanso:
        return 'descanso';
      case TipoNovedad.citaMedica:
        return 'cita_medica';
      case TipoNovedad.calamidad:
        return 'calamidad';
      case TipoNovedad.sugerencia:
        return 'sugerencia';
    }
  }

  String get displayName {
    switch (this) {
      case TipoNovedad.descanso:
        return 'Día de Descanso';
      case TipoNovedad.citaMedica:
        return 'Cita Médica / EPS';
      case TipoNovedad.calamidad:
        return 'Calamidad Doméstica';
      case TipoNovedad.sugerencia:
        return 'Sugerencia / Petición';
    }
  }
}
