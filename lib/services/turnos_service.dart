import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/models.dart';

class TurnosService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Obtiene los turnos de un restaurante para una semana específica
  Future<List<Turno>> getTurnosSemana({
    required String restauranteId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final startStr =
          "${startDate.year.toString().padLeft(4, '0')}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}";
      final endStr =
          "${endDate.year.toString().padLeft(4, '0')}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')}";

      final data = await _supabase
          .from('turnos')
          .select('*, perfiles:colaborador_id(nombre, cedula)')
          .eq('restaurante_id', restauranteId)
          .gte('fecha', startStr)
          .lte('fecha', endStr)
          .order('fecha', ascending: true)
          .order('hora_inicio', ascending: true);

      return (data as List).map((row) => Turno.fromJson(row)).toList();
    } catch (_) {
      return [];
    }
  }

  /// Obtiene los turnos individuales asignados a un colaborador
  Future<List<Turno>> getMisTurnos(String colaboradorId) async {
    try {
      final data = await _supabase
          .from('turnos')
          .select('*, perfiles:colaborador_id(nombre, cedula)')
          .eq('colaborador_id', colaboradorId)
          .order('fecha', ascending: true)
          .order('hora_inicio', ascending: true);

      return (data as List).map((row) => Turno.fromJson(row)).toList();
    } catch (_) {
      return [];
    }
  }

  /// Crea un nuevo turno programado
  Future<Turno?> crearTurno(Turno turno) async {
    try {
      final json = turno.toJson();
      json.remove('id'); // Generado por PostgreSQL UUID
      final res = await _supabase.from('turnos').insert(json).select().single();
      return Turno.fromJson(res);
    } catch (_) {
      return null;
    }
  }

  /// Actualiza un turno existente (cambio de horario, estación o colaborador)
  Future<bool> actualizarTurno(Turno turno) async {
    try {
      await _supabase.from('turnos').update(turno.toJson()).eq('id', turno.id);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Elimina un turno
  Future<bool> eliminarTurno(String id) async {
    try {
      await _supabase.from('turnos').delete().eq('id', id);
      return true;
    } catch (_) {
      return false;
    }
  }
}
