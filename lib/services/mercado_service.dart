import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/models.dart';

class MercadoService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Obtiene los turnos disponibles en el mercado
  Future<List<MercadoTurno>> getTurnosDisponibles() async {
    try {
      final data = await _supabase
          .from('mercado_turnos')
          .select('''
            *,
            turnos:turno_id(*),
            solicitante:solicitante_id(nombre),
            receptor:receptor_id(nombre)
          ''')
          .eq('estado', 'pendiente')
          .order('creado_en', ascending: false);

      return (data as List).map((row) => MercadoTurno.fromJson(row)).toList();
    } catch (_) {
      return [];
    }
  }

  /// Obtiene todas las solicitudes del mercado (para el panel de administración)
  Future<List<MercadoTurno>> getTodasLasSolicitudes() async {
    try {
      final data = await _supabase
          .from('mercado_turnos')
          .select('''
            *,
            turnos:turno_id(*),
            solicitante:solicitante_id(nombre),
            receptor:receptor_id(nombre)
          ''')
          .order('creado_en', ascending: false);

      return (data as List).map((row) => MercadoTurno.fromJson(row)).toList();
    } catch (_) {
      return [];
    }
  }

  /// Publica un turno en el mercado para que un compañero lo tome
  Future<bool> publicarTurnoEnMercado({
    required String turnoId,
    required String solicitanteId,
  }) async {
    try {
      await _supabase.from('mercado_turnos').insert({
        'turno_id': turnoId,
        'solicitante_id': solicitanteId,
        'estado': 'pendiente',
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Un colaborador se postula para tomar el turno publicado
  Future<bool> tomarTurno({
    required String mercadoId,
    required String receptorId,
  }) async {
    try {
      await _supabase
          .from('mercado_turnos')
          .update({'receptor_id': receptorId})
          .eq('id', mercadoId);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// El Administrador aprueba el intercambio y actualiza el colaborador del turno
  Future<bool> aprobarIntercambio({
    required String mercadoId,
    required String turnoId,
    required String nuevoColaboradorId,
  }) async {
    try {
      // 1. Aprobar solicitud en mercado_turnos
      await _supabase
          .from('mercado_turnos')
          .update({'estado': 'aprobada'})
          .eq('id', mercadoId);

      // 2. Transferir el turno al nuevo colaborador
      await _supabase
          .from('turnos')
          .update({'colaborador_id': nuevoColaboradorId})
          .eq('id', turnoId);

      return true;
    } catch (_) {
      return false;
    }
  }

  /// El Administrador rechaza el intercambio
  Future<bool> rechazarIntercambio(String mercadoId) async {
    try {
      await _supabase
          .from('mercado_turnos')
          .update({'estado': 'rechazada'})
          .eq('id', mercadoId);
      return true;
    } catch (_) {
      return false;
    }
  }
}
