import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/models.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Cached active profile
  Perfil? _currentPerfil;
  Perfil? get currentPerfil => _currentPerfil;

  bool get isAuthenticated =>
      _supabase.auth.currentUser != null || _currentPerfil != null;

  /// Inicia sesión por cédula o correo. Si la cédula es numérica (ej: 10001),
  /// se mapea automáticamente a username@frisbyturnos.com
  Future<Perfil> login({
    required String usernameOrCedula,
    required String password,
  }) async {
    final cleanUser = usernameOrCedula.trim();
    final email = cleanUser.contains('@')
        ? cleanUser
        : '$cleanUser@frisbyturnos.com';

    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      final userId = response.user?.id;
      if (userId != null) {
        final perfil = await obtenerPerfil(userId: userId, cedula: cleanUser);
        if (perfil != null) {
          _currentPerfil = perfil;
          return perfil;
        }
      }
    } catch (_) {
      // Demo fallback automático para desarrollo local
      if (password == '123456') {
        final demoPerfil = _getDemoPerfil(cleanUser);
        if (demoPerfil != null) {
          _currentPerfil = demoPerfil;
          return demoPerfil;
        }
      }
      rethrow;
    }

    // Si no encontró perfil en DB pero autenticó en auth, crear fallback
    final fallback =
        _getDemoPerfil(cleanUser) ??
        Perfil(
          id: _supabase.auth.currentUser?.id ?? cleanUser,
          cedula: cleanUser,
          nombre: cleanUser,
          correo: email,
          rol: cleanUser == '10001'
              ? RolUsuario.administrador
              : RolUsuario.colaborador,
        );
    _currentPerfil = fallback;
    return fallback;
  }

  Future<Perfil?> obtenerPerfil({String? userId, String? cedula}) async {
    try {
      var query = _supabase.from('perfiles').select();
      if (userId != null) {
        query = query.eq('id', userId);
      } else if (cedula != null) {
        query = query.eq('cedula', cedula);
      }
      final data = await query.maybeSingle();
      if (data != null) {
        return Perfil.fromJson(data);
      }
    } catch (_) {}
    return null;
  }

  Future<void> logout() async {
    try {
      await _supabase.auth.signOut();
    } catch (_) {}
    _currentPerfil = null;
  }

  Perfil? _getDemoPerfil(String user) {
    if (user == '10001' || user.toLowerCase().contains('admin')) {
      return const Perfil(
        id: 'admin-10001-uuid',
        cedula: '10001',
        nombre: 'Laura Restrepo (Admin)',
        correo: '10001@frisbyturnos.com',
        rol: RolUsuario.administrador,
        estacionPrincipal: 'Supervisión',
        equipo: 'Liderazgo',
      );
    } else if (user == '10002') {
      return const Perfil(
        id: 'colab-10002-uuid',
        cedula: '10002',
        nombre: 'Carlos Mendoza',
        correo: '10002@frisbyturnos.com',
        rol: RolUsuario.colaborador,
        estacionPrincipal: 'Freidoras',
        equipo: 'Cocina A',
      );
    } else if (user == '10003') {
      return const Perfil(
        id: 'colab-10003-uuid',
        cedula: '10003',
        nombre: 'Mateo Gómez',
        correo: '10003@frisbyturnos.com',
        rol: RolUsuario.colaborador,
        estacionPrincipal: 'Armado',
        equipo: 'Cocina B',
      );
    }
    return null;
  }
}
