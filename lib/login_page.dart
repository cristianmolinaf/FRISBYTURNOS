import 'package:flutter/material.dart';
import 'google_fonts_wrapper.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dashboard_page.dart';
import 'admin_dashboard_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;
  bool? _isDarkModeOverride;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool _isDarkMode(BuildContext context) {
    if (_isDarkModeOverride != null) {
      return _isDarkModeOverride!;
    }
    return MediaQuery.of(context).platformBrightness == Brightness.dark;
  }

  void _handleAuth() async {
    if (_formKey.currentState!.validate()) {
      final username = _usernameController.text.trim();
      final password = _passwordController.text;

      setState(() {
        _isLoading = true;
      });

      final email = '$username@frisbyturnos.com';

      try {
        final response = await Supabase.instance.client.auth.signInWithPassword(
          email: email,
          password: password,
        );

        String userRole = 'colaborador';
        String profileName = username;

        try {
          final perfil = await Supabase.instance.client
              .from('perfiles')
              .select('nombre, rol, cedula')
              .eq('cedula', username)
              .maybeSingle();

          if (perfil != null) {
            userRole = (perfil['rol'] ?? 'colaborador').toString();
            profileName = (perfil['nombre'] ?? username).toString();
          }
        } catch (_) {}

        if (mounted) {
          setState(() {
            _isLoading = false;
          });

          final isAdmin = userRole == 'administrador' ||
              userRole == 'superadmin' ||
              userRole == 'jefe_zona' ||
              username == '10001' ||
              username.toLowerCase().contains('admin');

          if (isAdmin) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => AdminDashboardPage(
                  username: username,
                  profileName: profileName,
                  role: userRole,
                ),
              ),
            );
          } else {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => DashboardPage(
                  username: response.user?.email ?? email,
                ),
              ),
            );
          }
        }
      } on AuthException catch (error) {
        // Demo fallback for seed accounts
        if (password == '123456' && (username == '10001' || username == '10002' || username == '10003')) {
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
            if (username == '10001') {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => AdminDashboardPage(
                    username: username,
                    profileName: 'Laura Restrepo (Admin)',
                    role: 'administrador',
                  ),
                ),
              );
            } else {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => DashboardPage(
                    username: email,
                  ),
                ),
              );
            }
            return;
          }
        }

        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _getErrorMessage(error),
                style: GoogleFonts.hankenGrotesk(color: Colors.white),
              ),
              backgroundColor: const Color(0xFFBA1A1A),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (error) {
        if (password == '123456' && (username == '10001' || username == '10002')) {
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
            if (username == '10001') {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => AdminDashboardPage(
                    username: username,
                    profileName: 'Laura Restrepo (Admin)',
                    role: 'administrador',
                  ),
                ),
              );
            } else {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => DashboardPage(
                    username: email,
                  ),
                ),
              );
            }
            return;
          }
        }

        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Ocurrió un error inesperado. Por favor intente de nuevo.',
                style: GoogleFonts.hankenGrotesk(color: Colors.white),
              ),
              backgroundColor: const Color(0xFFBA1A1A),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  String _getErrorMessage(AuthException error) {
    final message = error.message.toLowerCase();
    if (message.contains('invalid login credentials')) {
      return 'Cédula o contraseña incorrectos.';
    }
    if (message.contains('email not confirmed')) {
      return 'Por favor confirma tu dirección de correo electrónico.';
    }
    if (message.contains('schema') || message.contains('unexpected_failure')) {
      return 'Error de validación en la base de datos. Verifica tus credenciales.';
    }
    return error.message;
  }

  void _handleForgotPassword(bool isDark) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: isDark ? const BorderSide(color: Colors.white12) : BorderSide.none,
        ),
        title: Text(
          'Recuperar Contraseña',
          style: GoogleFonts.hankenGrotesk(
            color: isDark ? const Color(0xFFFBDBD8) : const Color(0xFF121C3B),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Por seguridad, para recuperar o cambiar tu contraseña asignada por favor comunícate con el Administrador de Sistemas o el encargado de tu sucursal de Frisby.',
          style: GoogleFonts.hankenGrotesk(
            color: isDark ? const Color(0xFFE5BDBA) : const Color(0xFF5C403D),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Entendido',
              style: GoogleFonts.hankenGrotesk(
                color: isDark ? const Color(0xFFFFB3AD) : const Color(0xFFAC0017),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _fillDemoCredentials(String username) {
    setState(() {
      _usernameController.text = username;
      _passwordController.text = '123456';
    });
  }

  // --- DESKTOP WEB SPLIT-SCREEN LAYOUT ---

  Widget _buildDesktopWebLogin(bool isDark) {
    final bg = isDark ? const Color(0xFF121212) : const Color(0xFFF6F7F9);
    final cardBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final borderColor = isDark ? Colors.white12 : const Color(0xFFE5E7EB);
    final titleColor = isDark ? Colors.white : const Color(0xFF111827);
    final subtextColor = isDark ? Colors.white60 : const Color(0xFF6B7280);
    final primaryRed = const Color(0xFFAC0017);
    final inputBg = isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF9FAFB);

    return Scaffold(
      backgroundColor: bg,
      body: Row(
        children: [
          // 1. LEFT BRAND HERO PANEL (45% Width)
          Expanded(
            flex: 9,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [const Color(0xFF2B0A0D), const Color(0xFF120305), const Color(0xFF0F0F0F)]
                      : [const Color(0xFF990012), const Color(0xFFBA0C20), const Color(0xFFD2232A)],
                ),
              ),
              child: Stack(
                children: [
                  // Ambient Frisby Polka/Circle Glows
                  Positioned(
                    top: -100,
                    left: -100,
                    child: Container(
                      width: 450,
                      height: 450,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            const Color(0xFFF7B640).withValues(alpha: isDark ? 0.15 : 0.25),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -80,
                    right: -80,
                    child: Container(
                      width: 400,
                      height: 400,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            Colors.white.withValues(alpha: isDark ? 0.08 : 0.18),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Brand Hero Content
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 48),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Header Logo
                        Row(
                          children: [
                            Image.network(
                              'https://lh3.googleusercontent.com/aida-public/AB6AXuATkXAerVPsE2m4hfUiQnl2Y9rqFfI7Ps4kylZ4pKqTsLdljqPy3P98NcAsZSxf5IhL9PT0EuZTt6uWZCyEwE_d0EleeKeYd7eOti54uHUm05djF0vMkj200IOm-HymlHKOB1bF3OJNLf_BwQHd8Xi08O5wdJgwONmRr9t7QwTuRiigzmxj8wDxdOTExQV5qztVYJNP5jaE-OQsRnV5_zkiTrVLmwvYv0XeIEm_LEo0hkxVXoQTGx_frjCjDWomYU7yXM8',
                              height: 42,
                              errorBuilder: (c, e, s) => Text(
                                'Frisby',
                                style: GoogleFonts.sora(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white24,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'PORTAL WEB',
                                style: GoogleFonts.hankenGrotesk(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ),
                          ],
                        ),

                        // Center Message & Features
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Sistema Integral de Gestión de Turnos & Operaciones',
                              style: GoogleFonts.sora(
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Plataforma oficial para colaboradores, administradores y jefes de zona de restaurantes Frisby Colombia.',
                              style: GoogleFonts.hankenGrotesk(
                                fontSize: 16,
                                color: Colors.white.withValues(alpha: 0.85),
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 36),

                            // Feature Pills
                            _buildHeroFeatureItem(
                              icon: Icons.calendar_today,
                              title: 'Malla y Turnos en Tiempo Real',
                              desc: 'Consulta tu horario semanal y estaciones de trabajo asignadas.',
                            ),
                            const SizedBox(height: 16),
                            _buildHeroFeatureItem(
                              icon: Icons.sync_alt,
                              title: 'Mercado de Intercambio Ágil',
                              desc: 'Cede y solicita turnos con aprobación directa de tu supervisor.',
                            ),
                            const SizedBox(height: 16),
                            _buildHeroFeatureItem(
                              icon: Icons.analytics,
                              title: 'Control y Cobertura Operativa',
                              desc: 'Monitoreo de puntualidad y horas programadas por sucursal.',
                            ),
                          ],
                        ),

                        // Footer
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '© 2026 Frisby S.A. • Todos los derechos reservados',
                              style: GoogleFonts.hankenGrotesk(
                                fontSize: 12,
                                color: Colors.white60,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2E7D32).withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.4)),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: const BoxDecoration(
                                      color: Colors.greenAccent,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Servidor Operativo',
                                    style: GoogleFonts.hankenGrotesk(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 2. RIGHT LOGIN FORM PANEL (55% Width)
          Expanded(
            flex: 11,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 64, vertical: 32),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 460),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top Theme switcher
                      Align(
                        alignment: Alignment.topRight,
                        child: IconButton(
                          icon: Icon(isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined, color: titleColor),
                          onPressed: () => setState(() => _isDarkModeOverride = !isDark),
                          tooltip: 'Cambiar Tema',
                        ),
                      ),
                      const SizedBox(height: 8),

                      Text(
                        'Iniciar Sesión',
                        style: GoogleFonts.hankenGrotesk(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: titleColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Ingresa tu número de cédula y contraseña asignada para acceder al portal.',
                        style: GoogleFonts.hankenGrotesk(
                          fontSize: 14,
                          color: subtextColor,
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Login Form
                      Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Cédula Field
                            Text(
                              'Número de Cédula',
                              style: GoogleFonts.hankenGrotesk(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: titleColor,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _usernameController,
                              keyboardType: TextInputType.number,
                              textInputAction: TextInputAction.next,
                              style: GoogleFonts.hankenGrotesk(color: titleColor, fontSize: 14),
                              decoration: InputDecoration(
                                hintText: 'Ej. 10001',
                                hintStyle: GoogleFonts.hankenGrotesk(color: subtextColor, fontSize: 14),
                                prefixIcon: Icon(Icons.badge_outlined, color: primaryRed, size: 20),
                                filled: true,
                                fillColor: inputBg,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(color: borderColor),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(color: borderColor),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(color: primaryRed, width: 1.5),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Por favor ingrese su cédula';
                                }
                                final numberRegex = RegExp(r'^\d+$');
                                if (!numberRegex.hasMatch(value.trim())) {
                                  return 'La cédula debe contener solo números';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 18),

                            // Password Field
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Contraseña',
                                  style: GoogleFonts.hankenGrotesk(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: titleColor,
                                  ),
                                ),
                                InkWell(
                                  onTap: () => _handleForgotPassword(isDark),
                                  child: Text(
                                    '¿Olvidaste tu contraseña?',
                                    style: GoogleFonts.hankenGrotesk(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: primaryRed,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) => _handleAuth(),
                              style: GoogleFonts.hankenGrotesk(color: titleColor, fontSize: 14),
                              decoration: InputDecoration(
                                hintText: '••••••••',
                                hintStyle: GoogleFonts.hankenGrotesk(color: subtextColor, fontSize: 14),
                                prefixIcon: Icon(Icons.lock_outline, color: primaryRed, size: 20),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                    color: subtextColor,
                                    size: 20,
                                  ),
                                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                ),
                                filled: true,
                                fillColor: inputBg,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(color: borderColor),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(color: borderColor),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(color: primaryRed, width: 1.5),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Por favor ingrese su contraseña';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 24),

                            // Submit Button
                            SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _handleAuth,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryRed,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2.5,
                                        ),
                                      )
                                    : Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            'Ingresar al Portal',
                                            style: GoogleFonts.hankenGrotesk(
                                              fontSize: 15,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          const Icon(Icons.arrow_forward, size: 18),
                                        ],
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 28),

                      // Demo Quick Access Container
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: borderColor),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.info_outline, size: 16, color: Color(0xFF966100)),
                                const SizedBox(width: 6),
                                Text(
                                  'Cuentas de Prueba Rápida (Demo)',
                                  style: GoogleFonts.hankenGrotesk(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: titleColor,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                ActionChip(
                                  avatar: const Icon(Icons.admin_panel_settings, size: 14, color: Color(0xFFAC0017)),
                                  label: Text('Admin: 10001', style: GoogleFonts.hankenGrotesk(fontSize: 11)),
                                  onPressed: () => _fillDemoCredentials('10001'),
                                ),
                                ActionChip(
                                  avatar: const Icon(Icons.person, size: 14, color: Color(0xFF545D80)),
                                  label: Text('Colaborador: 10002', style: GoogleFonts.hankenGrotesk(fontSize: 11)),
                                  onPressed: () => _fillDemoCredentials('10002'),
                                ),
                                ActionChip(
                                  avatar: const Icon(Icons.person_outline, size: 14, color: Color(0xFF545D80)),
                                  label: Text('Colaborador: 10003', style: GoogleFonts.hankenGrotesk(fontSize: 11)),
                                  onPressed: () => _fillDemoCredentials('10003'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroFeatureItem({
    required IconData icon,
    required String title,
    required String desc,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                desc,
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 12,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- MOBILE LAYOUT ---

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final isDesktop = mediaQuery.size.width > 800;
    final isDark = _isDarkMode(context);

    // If on a desktop/web browser with wide screen, render the modern Split Web Portal
    if (isDesktop) {
      return _buildDesktopWebLogin(isDark);
    }

    // Otherwise, mobile login screen
    final bgColor = isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FB);
    final titleTextColor = isDark ? const Color(0xFFFBDBD8) : const Color(0xFF121C3B);
    final subtitleTextColor = isDark ? const Color(0xFFE5BDBA) : const Color(0xFF5C403D);
    final inputFillColor = isDark ? Colors.white.withValues(alpha: 0.08) : Colors.white;
    final inputTextColor = isDark ? Colors.white : const Color(0xFF191C1E);
    final inputBorderColor = isDark ? Colors.white24 : Colors.grey[300]!;
    final linkColor = isDark ? const Color(0xFFFFB3AD) : const Color(0xFF121C3B);

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          // Yellow Blob (Top-Right decoration)
          Positioned(
            top: -60,
            right: -60,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF966100).withValues(alpha: 0.25) : const Color(0xFFF7B640),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(100),
                  topRight: Radius.circular(120),
                  bottomLeft: Radius.circular(120),
                  bottomRight: Radius.circular(100),
                ),
              ),
            ),
          ),

          // Main Mobile Form
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 20),

                    // Logo
                    Image.network(
                      'https://lh3.googleusercontent.com/aida-public/AB6AXuDqvuqN7g75NbJqkJOIB9ZNtyOPPUPel08Jl-bMBVKX-kK1Z00iI0gMCb0N-RelUihdC1hm4RgiCUSFPQuoG7zypByIhgs3XTFNfzs35KPmid_T1rmBiuwpyqmn7r4ZSeVOqAmlxGJfcVtojoGQd4Qx6Duui0Exc1uc1kfQucfnX6jTiKQ0P0JkMhZKbtUlbc6e-xiOW3dQc5IVYi5cROAJwz59sMgg4a2WkqX5mifMfd7GrWF2lm74IILQdNVypw8feZE',
                      width: 180,
                      errorBuilder: (context, error, stackTrace) {
                        return Text(
                          'Frisby',
                          style: GoogleFonts.hankenGrotesk(
                            fontSize: 44,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFFAC0017),
                            fontStyle: FontStyle.italic,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 20),

                    // Title
                    Text(
                      'Bienvenido a\nFrisby Turnos',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.hankenGrotesk(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: titleTextColor,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Subtitle
                    Text(
                      'Ingresa tus credenciales de acceso',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.hankenGrotesk(
                        fontSize: 14,
                        color: subtitleTextColor,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Form
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          // Cédula field
                          TextFormField(
                            controller: _usernameController,
                            keyboardType: TextInputType.number,
                            textInputAction: TextInputAction.next,
                            style: GoogleFonts.hankenGrotesk(
                              fontSize: 14,
                              color: inputTextColor,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Cédula / Usuario',
                              hintStyle: GoogleFonts.hankenGrotesk(
                                fontSize: 14,
                                color: Colors.grey[isDark ? 500 : 400],
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 16,
                              ),
                              filled: true,
                              fillColor: inputFillColor,
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30),
                                borderSide: BorderSide(
                                  color: inputBorderColor,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30),
                                borderSide: const BorderSide(
                                  color: Color(0xFFAC0017),
                                  width: 1.5,
                                ),
                              ),
                              errorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30),
                                borderSide: const BorderSide(
                                  color: Color(0xFFBA1A1A),
                                ),
                              ),
                              focusedErrorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30),
                                borderSide: const BorderSide(
                                  color: Color(0xFFBA1A1A),
                                  width: 1.5,
                                ),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Por favor ingrese su cédula';
                              }
                              final numberRegex = RegExp(r'^\d+$');
                              if (!numberRegex.hasMatch(value.trim())) {
                                return 'La cédula debe contener solo números';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Password field
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _handleAuth(),
                            style: GoogleFonts.hankenGrotesk(
                              fontSize: 14,
                              color: inputTextColor,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Contraseña',
                              hintStyle: GoogleFonts.hankenGrotesk(
                                fontSize: 14,
                                color: Colors.grey[isDark ? 500 : 400],
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 16,
                              ),
                              filled: true,
                              fillColor: inputFillColor,
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30),
                                borderSide: BorderSide(
                                  color: inputBorderColor,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30),
                                borderSide: const BorderSide(
                                  color: Color(0xFFAC0017),
                                  width: 1.5,
                                ),
                              ),
                              errorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30),
                                borderSide: const BorderSide(
                                  color: Color(0xFFBA1A1A),
                                ),
                              ),
                              focusedErrorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30),
                                borderSide: const BorderSide(
                                  color: Color(0xFFBA1A1A),
                                  width: 1.5,
                                ),
                              ),
                              suffixIcon: Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                    color: Colors.grey[isDark ? 500 : 400],
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Por favor ingrese su contraseña';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),

                          // Submit Button
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(30),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFAC0017).withValues(alpha: 0.3),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _handleAuth,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFAC0017),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  elevation: 0,
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2.5,
                                        ),
                                      )
                                    : Text(
                                        'Ingresar',
                                        style: GoogleFonts.hankenGrotesk(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Forgot password link
                    TextButton(
                      onPressed: () => _handleForgotPassword(isDark),
                      child: Text(
                        '¿Olvidó su contraseña?',
                        style: GoogleFonts.hankenGrotesk(
                          fontSize: 13,
                          color: linkColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
