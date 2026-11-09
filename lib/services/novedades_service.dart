import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/models.dart';

class NovedadesService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Obtiene todas las solicitudes de novedad y disponibilidad (para Administrador)
  Future<List<Disponibilidad>> getNovedades() async {
    try {
      final data = await _supabase
          .from('disponibilidad')
          .select('*, perfiles:colaborador_id(nombre, cedula)')
          .order('creado_en', ascending: false);

      return (data as List).map((row) => Disponibilidad.fromJson(row)).toList();
    } catch (_) {
      return [];
    }
  }

  /// Obtiene las novedades solicitadas por un colaborador específico
  Future<List<Disponibilidad>> getMisNovedades(String colaboradorId) async {
    try {
      final data = await _supabase
          .from('disponibilidad')
          .select('*, perfiles:colaborador_id(nombre, cedula)')
          .eq('colaborador_id', colaboradorId)
          .order('fecha', ascending: false);

      return (data as List).map((row) => Disponibilidad.fromJson(row)).toList();
    } catch (_) {
      return [];
    }
  }

  /// Registra una solicitud de día libre, cita médica o calamidad
  Future<bool> crearSolicitud(Disponibilidad novedad) async {
    try {
      final json = novedad.toJson();
      json.remove('id');
      await _supabase.from('disponibilidad').insert(json);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// El Administrador aprueba o rechaza la solicitud de novedad
  Future<bool> responderSolicitud({
    required String id,
    required EstadoSolicitud estado,
  }) async {
    try {
      await _supabase
          .from('disponibilidad')
          .update({'estado': estado.toDbValue()})
          .eq('id', id);
      return true;
    } catch (_) {
      return false;
    }
  }
}
