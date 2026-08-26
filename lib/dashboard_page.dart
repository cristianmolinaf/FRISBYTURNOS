import 'dart:ui' show ImageFilter;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'google_fonts_wrapper.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DashboardPage extends StatefulWidget {
  final String username;
  const DashboardPage({super.key, required this.username});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _currentIndex = 0;
  
  // Theme override state
  bool? _isDarkModeOverride;

  // Calendar State Variables
  DateTime _selectedDate = DateTime(2024, 4, 4);
  DateTime _focusedMonth = DateTime(2024, 4, 1);
  bool _isWeeklyView = false;

  // Market State Variables
  int _selectedMarketTab = 0;
  final List<int> _requestedTrades = [];

  bool _isDarkMode(BuildContext context) {
    if (_isDarkModeOverride != null) {
      return _isDarkModeOverride!;
    }
    return MediaQuery.of(context).platformBrightness == Brightness.dark;
  }

  void _toggleTheme() {
    setState(() {
      _isDarkModeOverride = !_isDarkMode(context);
    });
  }

  void _onPrevMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1, 1);
    });
  }

  void _onNextMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 1);
    });
  }

  String _getMonthYearString(DateTime date) {
    final months = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _getStationName(DateTime date) {
    if (date.weekday == 7) return 'Descanso';
    final stations = ['Plancha', 'Caja', 'Cocina'];
    return stations[(date.day + date.month) % 3];
  }

  void _logout() async {
    await Supabase.instance.client.auth.signOut();
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/');
    }
  }

  String _getCurrentDateString() {
    final now = DateTime.now();
    final weekdays = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];
    final months = [
      'Enero',
      'Febrero',
      'Marzo',
      'Abril',
      'Mayo',
      'Junio',
      'Julio',
      'Agosto',
      'Septiembre',
      'Octubre',
      'Noviembre',
      'Diciembre'
    ];
    final weekday = weekdays[now.weekday - 1];
    final month = months[now.month - 1];
    final period = now.hour >= 12 ? 'PM' : 'AM';
    final hour = now.hour > 12 ? now.hour - 12 : (now.hour == 0 ? 12 : now.hour);
    final minute = now.minute.toString().padLeft(2, '0');
    return '$weekday, ${now.day} de $month | $hour:$minute $period';
  }

  void _showNotificationDialog(String title, String body, String time, bool isIOS, bool isDark) {
    final dialogBgColor = isIOS
        ? (isDark ? const Color(0xFF2C1B1A) : const Color(0xFFFFF1F0))
        : (isDark ? const Color(0xFF1E1E1E) : Colors.white);
    final dialogTextColor = isIOS
        ? (isDark ? const Color(0xFFFBDBD8) : const Color(0xFF410003))
        : (isDark ? const Color(0xFFE1E2E4) : const Color(0xFF121C3B));
    final dialogSubtextColor = isIOS
        ? (isDark ? const Color(0xFFE5BDBA) : const Color(0xFF5C403D))
        : (isDark ? const Color(0xFFC6C6C7) : const Color(0xFF5C403D));

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: dialogBgColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: (isIOS || isDark) ? const BorderSide(color: Colors.white12) : BorderSide.none,
        ),
        title: Text(
          title,
          style: GoogleFonts.hankenGrotesk(
            color: dialogTextColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              body,
              style: GoogleFonts.hankenGrotesk(
                color: dialogSubtextColor,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              time,
              style: GoogleFonts.hankenGrotesk(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cerrar',
              style: GoogleFonts.hankenGrotesk(
                color: isIOS ? const Color(0xFFD2232A) : const Color(0xFFAC0017),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== Android/Web Layout ====================
  Widget _buildHomeTabAndroid(bool isDark) {
    final cleanName = widget.username.split('@').first;
    
    final titleColor = isDark ? const Color(0xFFE1E2E4) : const Color(0xFF191C1E);
    final subtextColor = isDark ? const Color(0xFFC6C6C7) : const Color(0xFF545D80);
    final cardBgColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '¡Hola, $cleanName!',
              style: GoogleFonts.hankenGrotesk(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: titleColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _getCurrentDateString(),
              style: GoogleFonts.hankenGrotesk(
                fontSize: 14,
                color: subtextColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Mi Turno de Hoy Card
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Mi Turno de Hoy',
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: titleColor,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFBD0E1E).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'PRÓXIMO',
                    style: GoogleFonts.hankenGrotesk(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFFBD0E1E),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: cardBgColor,
                borderRadius: BorderRadius.circular(16),
                border: isDark ? Border.all(color: Colors.white12) : null,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                children: [
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    width: 6,
                    child: Container(color: const Color(0xFFAC0017)),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(22, 16, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '8:00 AM - 4:00 PM',
                                  style: GoogleFonts.hankenGrotesk(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: titleColor,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '8 horas',
                                  style: GoogleFonts.hankenGrotesk(
                                    fontSize: 13,
                                    color: subtextColor,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: isDark ? Colors.white12 : const Color(0xFFEDEEF0),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.schedule,
                                color: Color(0xFFAC0017),
                                size: 20,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Container(
                          height: 1,
                          color: const Color(0xFFE5BDBA).withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Estación',
                                    style: GoogleFonts.hankenGrotesk(
                                      fontSize: 12,
                                      color: subtextColor,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.local_fire_department,
                                        color: isDark ? const Color(0xFFFFB3AD) : const Color(0xFF5C403D),
                                        size: 18,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Plancha',
                                        style: GoogleFonts.hankenGrotesk(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: titleColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Supervisor',
                                    style: GoogleFonts.hankenGrotesk(
                                      fontSize: 12,
                                      color: subtextColor,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Container(
                                        width: 22,
                                        height: 22,
                                        decoration: const BoxDecoration(
                                          color: Color(0xFFCCD6FE),
                                          shape: BoxShape.circle,
                                        ),
                                        alignment: Alignment.center,
                                        child: Text(
                                          'MV',
                                          style: GoogleFonts.hankenGrotesk(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: const Color(0xFF535C7F),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'María V.',
                                        style: GoogleFonts.hankenGrotesk(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: titleColor,
                                        ),
                                      ),
                                    ],
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
          ],
        ),
        const SizedBox(height: 24),

        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Accesos Rápidos',
              style: GoogleFonts.hankenGrotesk(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: titleColor,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildBentoButtonAndroid(
                    icon: Icons.calendar_month,
                    label: 'Calendario',
                    iconBgColor: const Color(0xFFCCD6FE).withValues(alpha: 0.3),
                    iconColor: isDark ? const Color(0xFFBCC5ED) : const Color(0xFF545D80),
                    onTap: () => setState(() => _currentIndex = 1),
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildBentoButtonAndroid(
                    icon: Icons.storefront,
                    label: 'Mercado',
                    iconBgColor: const Color(0xFFFFDDB5).withValues(alpha: 0.3),
                    iconColor: isDark ? const Color(0xFFFFB956) : const Color(0xFF754B00),
                    onTap: () => setState(() => _currentIndex = 2),
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildBentoButtonAndroid(
                    icon: Icons.event_available,
                    label: 'Disponibilidad',
                    iconBgColor: const Color(0xFFFFDAD6).withValues(alpha: 0.3),
                    iconColor: isDark ? const Color(0xFFFFB3AD) : const Color(0xFFAC0017),
                    onTap: () {
                      _showNotificationDialog(
                        'Disponibilidad',
                        'Tu disponibilidad declarada para este ciclo ya está configurada. Comunícate con tu supervisor si necesitas hacer cambios.',
                        'Configurado hace 1 día',
                        false,
                        isDark,
                      );
                    },
                    isDark: isDark,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Recent Alertas
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Alertas Recientes',
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: titleColor,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    _showNotificationDialog(
                      'Alertas Recientes',
                      'No tienes más alertas pendientes por revisar.',
                      'Actualizado ahora',
                      false,
                      isDark,
                    );
                  },
                  child: Text(
                    'Ver todas',
                    style: GoogleFonts.hankenGrotesk(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isDark ? const Color(0xFFFFB3AD) : const Color(0xFFAC0017),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildNotificationItemAndroid(
              icon: Icons.check_circle,
              title: 'Turno aprobado',
              body: 'Tu solicitud de cambio para el Viernes ha sido aprobada.',
              time: 'Hace 2 horas',
              iconColor: isDark ? const Color(0xFFFFB3AD) : const Color(0xFFBD0E1E),
              bgColor: isDark ? const Color(0xFFD2232A).withValues(alpha: 0.2) : const Color(0xFFFFDAD6).withValues(alpha: 0.2),
              isDark: isDark,
            ),
            const SizedBox(height: 12),
            _buildNotificationItemAndroid(
              icon: Icons.update,
              title: 'Nuevo horario publicado',
              body: 'Los horarios de la próxima semana ya están disponibles.',
              time: 'Ayer, 4:30 PM',
              iconColor: isDark ? const Color(0xFFC6C6C7) : const Color(0xFF545D80),
              bgColor: isDark ? Colors.white10 : const Color(0xFFCCD6FE).withValues(alpha: 0.3),
              isDark: isDark,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBentoButtonAndroid({
    required IconData icon,
    required String label,
    required Color iconBgColor,
    required Color iconColor,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isDark ? Border.all(color: Colors.white10) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: iconBgColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: iconColor,
                    size: 24,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  label,
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isDark ? const Color(0xFFE1E2E4) : const Color(0xFF191C1E),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationItemAndroid({
    required IconData icon,
    required String title,
    required String body,
    required String time,
    required Color iconColor,
    required Color bgColor,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.white12 : const Color(0xFFEDEEF0),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: bgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: isDark ? const Color(0xFFE1E2E4) : const Color(0xFF191C1E),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 13,
                    color: isDark ? const Color(0xFFC6C6C7) : const Color(0xFF545D80),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  time,
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 11,
                    color: isDark ? Colors.grey[500] : Colors.grey[400],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


  // ==================== iOS Layout ====================
  Widget _buildHomeTabIOS(bool isDark) {
    final cleanName = widget.username.split('@').first;
    
    final titleColor = isDark ? const Color(0xFFFBDBD8) : const Color(0xFF410003);
    final subtextColor = isDark ? const Color(0xFFE5BDBA) : const Color(0xFF5C403D);
    final cardBgColor = isDark ? Colors.white.withValues(alpha: 0.06) : Colors.white.withValues(alpha: 0.65);
    final cardBorderColor = isDark ? Colors.white.withValues(alpha: 0.12) : Colors.black.withValues(alpha: 0.08);
    final dividerColor = isDark ? Colors.white12 : Colors.black12;
    final iconWrapperBg = isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.04);
    final iconWrapperBorder = isDark ? Colors.white.withValues(alpha: 0.15) : Colors.black.withValues(alpha: 0.06);

    return ListView(
      padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 88, 20, 100),
      children: [
        // Greeting
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '¡Hola, $cleanName!',
              style: GoogleFonts.sora(
                fontSize: 28,
                fontWeight: FontWeight.w600,
                color: titleColor,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _getCurrentDateString(),
              style: GoogleFonts.hankenGrotesk(
                fontSize: 15,
                color: subtextColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),

        // Mi Turno de Hoy Card
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Mi Turno de Hoy',
                  style: GoogleFonts.sora(
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                    color: titleColor,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD2232A).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFFD2232A).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    'PRÓXIMO',
                    style: GoogleFonts.hankenGrotesk(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isDark ? const Color(0xFFFFB3AD) : const Color(0xFFAC0017),
                      letterSpacing: 0.08,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Glassmorphic Card container
            ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: cardBgColor,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: cardBorderColor,
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Accent Glow Background (Glows only in dark mode)
                      if (isDark)
                        Positioned(
                          left: -50,
                          top: -50,
                          child: Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFFD2232A).withValues(alpha: 0.08),
                            ),
                          ),
                        ),
                      
                      // Content
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '8:00 AM - 4:00 PM',
                                    style: GoogleFonts.sora(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: titleColor,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '8 horas',
                                    style: GoogleFonts.hankenGrotesk(
                                      fontSize: 14,
                                      color: subtextColor,
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: iconWrapperBg,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: iconWrapperBorder,
                                  ),
                                ),
                                child: Icon(
                                  Icons.schedule,
                                  color: isDark ? const Color(0xFFFFB3AD) : const Color(0xFFAC0017),
                                  size: 22,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Container(
                            height: 1,
                            color: dividerColor,
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'ESTACIÓN',
                                      style: GoogleFonts.hankenGrotesk(
                                        fontSize: 11,
                                        color: subtextColor,
                                        letterSpacing: 0.08,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.local_fire_department,
                                          color: isDark ? const Color(0xFFFFB3AD) : const Color(0xFFAC0017),
                                          size: 20,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Plancha',
                                          style: GoogleFonts.hankenGrotesk(
                                            fontSize: 16,
                                            color: titleColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'SUPERVISOR',
                                      style: GoogleFonts.hankenGrotesk(
                                        fontSize: 11,
                                        color: subtextColor,
                                        letterSpacing: 0.08,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Container(
                                          width: 24,
                                          height: 24,
                                          decoration: const BoxDecoration(
                                            color: Color(0xFFD2232A),
                                            shape: BoxShape.circle,
                                          ),
                                          alignment: Alignment.center,
                                          child: Text(
                                            'MV',
                                            style: GoogleFonts.hankenGrotesk(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'María V.',
                                          style: GoogleFonts.hankenGrotesk(
                                            fontSize: 16,
                                            color: titleColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),

        // Bento buttons
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Accesos Rápidos',
              style: GoogleFonts.sora(
                fontSize: 20,
                fontWeight: FontWeight.w500,
                color: titleColor,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildBentoButtonIOS(
                    icon: Icons.calendar_month,
                    label: 'Calendario',
                    iconBgColor: iconWrapperBg,
                    iconColor: isDark ? const Color(0xFFFFB3AD) : const Color(0xFFAC0017),
                    onTap: () => setState(() => _currentIndex = 1),
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildBentoButtonIOS(
                    icon: Icons.storefront,
                    label: 'Mercado',
                    iconBgColor: iconWrapperBg,
                    iconColor: isDark ? const Color(0xFF85CFFF) : const Color(0xFF0074A3),
                    onTap: () => setState(() => _currentIndex = 2),
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildBentoButtonIOS(
                    icon: Icons.event_available,
                    label: 'Disponibilidad',
                    iconBgColor: iconWrapperBg,
                    iconColor: isDark ? const Color(0xFFFFB3AD) : const Color(0xFFAC0017),
                    onTap: () {
                      _showNotificationDialog(
                        'Disponibilidad',
                        'Tu disponibilidad declarada para este ciclo ya está configurada. Comunícate con tu supervisor si necesitas hacer cambios.',
                        'Configurado hace 1 día',
                        true,
                        isDark,
                      );
                    },
                    isDark: isDark,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 32),

        // Alertas Recientes
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Alertas Recientes',
                  style: GoogleFonts.sora(
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                    color: titleColor,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    _showNotificationDialog(
                      'Alertas Recientes',
                      'No tienes más alertas pendientes por revisar.',
                      'Actualizado ahora',
                      true,
                      isDark,
                    );
                  },
                  child: Text(
                    'Ver todas',
                    style: GoogleFonts.hankenGrotesk(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isDark ? const Color(0xFFFFB3AD) : const Color(0xFFAC0017),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildNotificationItemIOS(
              icon: Icons.check_circle,
              title: 'Turno aprobado',
              body: 'Tu solicitud de cambio para el Viernes ha sido aprobada.',
              time: 'Hace 2 horas',
              iconColor: isDark ? const Color(0xFFFFB3AD) : const Color(0xFFAC0017),
              bgColor: const Color(0xFFD2232A).withValues(alpha: 0.2),
              borderAccentColor: isDark 
                  ? const Color(0xFFD2232A).withValues(alpha: 0.3)
                  : const Color(0xFFD2232A).withValues(alpha: 0.15),
              isDark: isDark,
            ),
            const SizedBox(height: 12),
            _buildNotificationItemIOS(
              icon: Icons.update,
              title: 'Nuevo horario publicado',
              body: 'Los horarios de la próxima semana ya están disponibles.',
              time: 'Ayer, 4:30 PM',
              iconColor: isDark ? const Color(0xFFC6C6C7) : const Color(0xFF545D80),
              bgColor: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.03),
              borderAccentColor: cardBorderColor,
              isDark: isDark,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBentoButtonIOS({
    required IconData icon,
    required String label,
    required Color iconBgColor,
    required Color iconColor,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    final cardBgColor = isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.6);
    final cardBorderColor = isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.06);

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: cardBgColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: cardBorderColor,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
                child: Column(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: iconBgColor,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.03),
                        ),
                      ),
                      child: Icon(
                        icon,
                        color: iconColor,
                        size: 24,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      label,
                      style: GoogleFonts.hankenGrotesk(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isDark ? const Color(0xFFFBDBD8) : const Color(0xFF191C1E),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationItemIOS({
    required IconData icon,
    required String title,
    required String body,
    required String time,
    required Color iconColor,
    required Color bgColor,
    required Color borderAccentColor,
    required bool isDark,
  }) {
    final cardBgColor = isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.6);
    final subtextColor = isDark ? const Color(0xFFE5BDBA) : const Color(0xFF5C403D);
    final titleColor = isDark ? const Color(0xFFFBDBD8) : const Color(0xFF410003);

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardBgColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: borderAccentColor,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: bgColor,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.03),
                  ),
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.sora(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: titleColor,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      body,
                      style: GoogleFonts.hankenGrotesk(
                        fontSize: 14,
                        color: subtextColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      time,
                      style: GoogleFonts.hankenGrotesk(
                        fontSize: 12,
                        color: subtextColor.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  // ==================== Monthly Calendar View (Android / Web) ====================
  Widget _buildBentoStats(bool isIOS, bool isDark) {
    final titleColor = isIOS
        ? (isDark ? const Color(0xFFFBDBD8) : const Color(0xFF410003))
        : (isDark ? const Color(0xFFE1E2E4) : const Color(0xFF191C1E));
    final subtextColor = isIOS
        ? (isDark ? const Color(0xFFE5BDBA) : const Color(0xFF5C403D))
        : (isDark ? const Color(0xFFC6C6C7) : const Color(0xFF545D80));
    final cardBg = isIOS
        ? (isDark ? const Color(0xFF3A2524).withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.55))
        : (isDark ? const Color(0xFF1E1E1E) : Colors.white);
    final cardBorder = isIOS
        ? (isDark ? const Color(0xFFE5BDBA).withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05))
        : (isDark ? Colors.white12 : const Color(0xFFEDEEF0));

    Widget statCard(String value, String label, IconData icon, Color iconColor) {
      final cardBody = Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: iconColor, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: isIOS
                  ? GoogleFonts.sora(fontSize: 16, fontWeight: FontWeight.bold, color: titleColor)
                  : GoogleFonts.hankenGrotesk(fontSize: 16, fontWeight: FontWeight.bold, color: titleColor),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.hankenGrotesk(fontSize: 11, color: subtextColor),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );

      if (isIOS) {
        return Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: cardBorder),
                ),
                child: cardBody,
              ),
            ),
          ),
        );
      } else {
        return Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(12),
              border: isDark ? Border.all(color: cardBorder) : null,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: cardBody,
          ),
        );
      }
    }

    return Row(
      children: [
        statCard('120 hrs', 'Horas Mes', Icons.access_time_filled, const Color(0xFFAC0017)),
        const SizedBox(width: 8),
        statCard('15 días', 'Turnos Prog', Icons.calendar_today, const Color(0xFFF7B640)),
        const SizedBox(width: 8),
        statCard('8 días', 'Descansos', Icons.beach_access, const Color(0xFF0074A3)),
      ],
    );
  }

  Widget _buildStationBadge(String station, bool isDark) {
    Color bg;
    Color fg;
    String label = station;
    IconData icon;

    if (station == 'Plancha') {
      bg = isDark ? const Color(0xFF5A2500) : const Color(0xFFFFECD8);
      fg = isDark ? const Color(0xFFFFCC99) : const Color(0xFF7A2A00);
      icon = Icons.outdoor_grill;
      label = 'Plancha 🥩';
    } else if (station == 'Caja') {
      bg = isDark ? const Color(0xFF0A304E) : const Color(0xFFE0F2FE);
      fg = isDark ? const Color(0xFF93C5FD) : const Color(0xFF0369A1);
      icon = Icons.point_of_sale;
      label = 'Caja 🛒';
    } else if (station == 'Cocina') {
      bg = isDark ? const Color(0xFF0F3E1E) : const Color(0xFFDCFCE7);
      fg = isDark ? const Color(0xFF86EFAC) : const Color(0xFF15803D);
      icon = Icons.restaurant;
      label = 'Cocina 🍳';
    } else {
      bg = isDark ? const Color(0xFF2C2C2C) : const Color(0xFFEDEEF0);
      fg = isDark ? const Color(0xFFC6C6C7) : const Color(0xFF545D80);
      icon = Icons.beach_access;
      label = 'Libre 🏖️';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.hankenGrotesk(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarTabAndroid(bool isDark) {
    final titleColor = isDark ? const Color(0xFFE1E2E4) : const Color(0xFF191C1E);
    final subtextColor = isDark ? const Color(0xFFC6C6C7) : const Color(0xFF545D80);
    final cardBgColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final gridDayBorder = isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF3F4F6);

    // Calcular días de forma dinámica
    final firstDay = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final firstWeekday = firstDay.weekday; // 1=Lunes, 7=Domingo
    final paddingCount = firstWeekday - 1; // Espacios del mes anterior

    final lastDayOfPrevMonth = DateTime(_focusedMonth.year, _focusedMonth.month, 0);
    final prevMonthDays = List.generate(paddingCount, (i) {
      return lastDayOfPrevMonth.day - paddingCount + 1 + i;
    });

    final daysInMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0).day;
    final currentMonthDays = List.generate(daysInMonth, (i) => i + 1);

    final totalCells = ((paddingCount + daysInMonth) / 7).ceil() * 7;
    final nextMonthPaddingCount = totalCells - (paddingCount + daysInMonth);
    final nextMonthDays = List.generate(nextMonthPaddingCount, (i) => i + 1);

    bool isWorkDay(DateTime date) => date.weekday != 7;
    bool isRestDay(DateTime date) => date.weekday == 7;

    // Generar días de la semana a mostrar abajo (semana de _selectedDate)
    final diff = _selectedDate.weekday - 1;
    final mondayOfWeek = _selectedDate.subtract(Duration(days: diff));
    final weekDays = List.generate(7, (i) => mondayOfWeek.add(Duration(days: i)));

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
      children: [
        // Web Month Header layout
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Vista Mensual',
              style: GoogleFonts.hankenGrotesk(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: titleColor,
              ),
            ),
            Row(
              children: [
                IconButton(
                  icon: Icon(Icons.chevron_left, color: titleColor),
                  onPressed: _onPrevMonth,
                ),
                Text(
                  _getMonthYearString(_focusedMonth),
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFAC0017),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.chevron_right, color: titleColor),
                  onPressed: _onNextMonth,
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Bento Stats Monthly Summary Header
        _buildBentoStats(false, isDark),
        const SizedBox(height: 16),

        // Action switch row
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _isWeeklyView = !_isWeeklyView;
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFCCD6FE).withValues(alpha: isDark ? 0.2 : 0.6),
                  foregroundColor: isDark ? const Color(0xFFBCC5ED) : const Color(0xFF101a39),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                icon: Icon(_isWeeklyView ? Icons.calendar_month : Icons.view_week, size: 18),
                label: Text(_isWeeklyView ? 'Vista Mensual' : 'Vista Semanal'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _currentIndex = 2; // Redirección a Mercado
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFCCD6FE).withValues(alpha: isDark ? 0.2 : 0.6),
                  foregroundColor: isDark ? const Color(0xFFBCC5ED) : const Color(0xFF101a39),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                icon: const Icon(Icons.storefront, size: 18),
                label: const Text('Mercado de Turnos'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Calendar Grid Section
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: cardBgColor,
            borderRadius: BorderRadius.circular(16),
            border: isDark ? Border.all(color: Colors.white12) : null,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              // Calendar Grid Header — row with evenly spaced day labels
              Row(
                children: ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'].map((day) {
                  return Expanded(
                    child: SizedBox(
                      height: 28,
                      child: Center(
                        child: Text(
                          day,
                          style: GoogleFonts.hankenGrotesk(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: subtextColor,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 6),

              // Calendar Days Grid
              if (_isWeeklyView)
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    crossAxisSpacing: 4,
                    mainAxisSpacing: 4,
                    childAspectRatio: 1.0,
                  ),
                  itemCount: 7,
                  itemBuilder: (context, index) {
                    final day = weekDays[index];
                    final isActive = _isSameDay(day, _selectedDate);
                    final isSunday = day.weekday == 7;

                    // Alternating shifts AM/PM
                    final shiftType = day.day % 2 == 0 ? 'AM' : 'PM';
                    final shiftBg = shiftType == 'AM' ? const Color(0xFFE0F2FE) : const Color(0xFFFEF3C7);
                    final shiftFg = shiftType == 'AM' ? const Color(0xFF0369A1) : const Color(0xFFB45309);

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedDate = day;
                          _focusedMonth = DateTime(day.year, day.month, 1);
                        });
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: isActive
                              ? const Color(0xFFD2232A)
                              : (isSunday 
                                  ? (isDark ? const Color(0xFF2C1B1A) : const Color(0xFFFFF1F0))
                                  : (isDark ? Colors.white.withValues(alpha: 0.03) : const Color(0xFFF8F9FB))),
                          borderRadius: BorderRadius.circular(8),
                          border: isActive ? null : Border.all(color: gridDayBorder, width: 1),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '${day.day}',
                              style: GoogleFonts.hankenGrotesk(
                                fontSize: 13,
                                fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                                color: isActive ? Colors.white : titleColor,
                              ),
                            ),
                            // Fixed-height slot — same space for badge or emoji
                            SizedBox(
                              height: 14,
                              child: isWorkDay(day)
                                  ? Center(
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                                        decoration: BoxDecoration(
                                          color: isActive ? Colors.white.withValues(alpha: 0.2) : shiftBg,
                                          borderRadius: BorderRadius.circular(3),
                                        ),
                                        child: Text(
                                          shiftType,
                                          style: GoogleFonts.hankenGrotesk(
                                            fontSize: 7,
                                            fontWeight: FontWeight.bold,
                                            color: isActive ? Colors.white : shiftFg,
                                          ),
                                        ),
                                      ),
                                    )
                                  : const Center(
                                      child: Text('🏖️', style: TextStyle(fontSize: 9)),
                                    ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                )
              else
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    crossAxisSpacing: 4,
                    mainAxisSpacing: 4,
                    childAspectRatio: 1.0,
                  ),
                  itemCount: totalCells,
                  itemBuilder: (context, index) {
                    if (index < paddingCount) {
                      final prevDayNum = prevMonthDays[index];
                      return Container(
                        decoration: BoxDecoration(
                          color: gridDayBorder,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '$prevDayNum',
                          style: GoogleFonts.hankenGrotesk(
                            color: isDark ? Colors.white24 : Colors.grey[350]!,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    }

                    if (index >= paddingCount + daysInMonth) {
                      final nextDayNum = nextMonthDays[index - paddingCount - daysInMonth];
                      return Container(
                        decoration: BoxDecoration(
                          color: gridDayBorder,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '$nextDayNum',
                          style: GoogleFonts.hankenGrotesk(
                            color: isDark ? Colors.white24 : Colors.grey[350]!,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    }

                    final dayNum = currentMonthDays[index - paddingCount];
                    final cellDate = DateTime(_focusedMonth.year, _focusedMonth.month, dayNum);
                    final isActive = _isSameDay(cellDate, _selectedDate);
                    final isSunday = cellDate.weekday == 7;

                    final shiftType = cellDate.day % 2 == 0 ? 'AM' : 'PM';
                    final shiftBg = shiftType == 'AM' ? const Color(0xFFE0F2FE) : const Color(0xFFFEF3C7);
                    final shiftFg = shiftType == 'AM' ? const Color(0xFF0369A1) : const Color(0xFFB45309);

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedDate = cellDate;
                        });
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: isActive 
                              ? const Color(0xFFD2232A)
                              : (isSunday 
                                  ? (isDark ? const Color(0xFF2C1B1A) : const Color(0xFFFFF1F0))
                                  : (isDark ? Colors.white.withValues(alpha: 0.03) : const Color(0xFFF8F9FB))),
                          borderRadius: BorderRadius.circular(8),
                          border: isActive ? null : Border.all(color: gridDayBorder, width: 1),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '$dayNum',
                              style: GoogleFonts.hankenGrotesk(
                                fontSize: 13,
                                fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                                color: isActive ? Colors.white : titleColor,
                              ),
                            ),
                            // Fixed-height slot — same space for badge or emoji
                            SizedBox(
                              height: 14,
                              child: isWorkDay(cellDate)
                                  ? Center(
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                                        decoration: BoxDecoration(
                                          color: isActive ? Colors.white.withValues(alpha: 0.2) : shiftBg,
                                          borderRadius: BorderRadius.circular(3),
                                        ),
                                        child: Text(
                                          shiftType,
                                          style: GoogleFonts.hankenGrotesk(
                                            fontSize: 7,
                                            fontWeight: FontWeight.bold,
                                            color: isActive ? Colors.white : shiftFg,
                                          ),
                                        ),
                                      ),
                                    )
                                  : const Center(
                                      child: Text('🏖️', style: TextStyle(fontSize: 9)),
                                    ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              const SizedBox(height: 16),

              // Legend
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE0F2FE),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'AM / PM',
                          style: GoogleFonts.hankenGrotesk(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF0369A1),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Día Laboral',
                        style: GoogleFonts.hankenGrotesk(
                          fontSize: 12,
                          color: subtextColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 24),
                  Row(
                    children: [
                      const Text('🏖️', style: TextStyle(fontSize: 12)),
                      const SizedBox(width: 6),
                      Text(
                        'Día de Descanso',
                        style: GoogleFonts.hankenGrotesk(
                          fontSize: 12,
                          color: subtextColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Detail Section: Semana
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Vista General: Semana',
              style: GoogleFonts.hankenGrotesk(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: titleColor,
              ),
            ),
            const SizedBox(height: 12),
            ...weekDays.map((day) {
              final isRest = isRestDay(day);
              final isSelected = _isSameDay(day, _selectedDate);
              final isCompleted = day.isBefore(_selectedDate) && !isSelected;

              final weekdaysLabels = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
              final dayLabel = weekdaysLabels[day.weekday - 1];
              final station = _getStationName(day);

              return _buildCalendarDetailItem(
                isDark,
                titleColor,
                subtextColor,
                dayLabel,
                '${day.day}',
                station,
                isRest ? 'Libre' : '08:00 - 16:00',
                isCompleted,
                isSelected: isSelected,
                isFuture: !isCompleted && !isSelected && !isRest,
              );
            }),
          ],
        ),
      ],
    );
  }

  Widget _buildCalendarDetailItem(
    bool isDark,
    Color titleColor,
    Color subtextColor,
    String dayLabel,
    String dayNum,
    String station,
    String hoursLabel,
    bool isCompleted, {
    required bool isSelected,
    bool isFuture = false,
  }) {
    final cardBgColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final isRest = station == 'Descanso';
    final accentLineColor = isRest ? (isDark ? Colors.white24 : const Color(0xFFE1E2E4)) : const Color(0xFFAC0017);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(12),
        border: isSelected 
            ? Border.all(color: const Color(0xFFAC0017).withValues(alpha: 0.6), width: 2)
            : (isDark ? Border.all(color: Colors.white12) : null),
        boxShadow: [
          if (!isSelected)
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.04),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: 4,
            child: Container(color: accentLineColor),
          ),
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    SizedBox(
                      width: 40,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            dayLabel,
                            style: GoogleFonts.hankenGrotesk(
                              fontSize: 12,
                              color: subtextColor,
                            ),
                          ),
                          Text(
                            dayNum,
                            style: GoogleFonts.hankenGrotesk(
                              fontSize: 16,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              color: titleColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 1,
                      height: 28,
                      color: isDark ? Colors.white12 : const Color(0xFFE1E2E4),
                    ),
                    const SizedBox(width: 12),
                    
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildStationBadge(station, isDark),
                        const SizedBox(height: 4),
                        Text(
                          hoursLabel,
                          style: GoogleFonts.hankenGrotesk(
                            fontSize: 11,
                            color: subtextColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                
                if (isRest)
                  const Text('🏖️', style: TextStyle(fontSize: 14))
                else if (isCompleted)
                  const Icon(Icons.check_circle, color: Color(0xFFAC0017), size: 18)
                else if (isSelected)
                  const Icon(Icons.radio_button_checked, color: Color(0xFFAC0017), size: 18)
                else
                  Icon(Icons.circle_outlined, color: isDark ? Colors.white24 : const Color(0xFFD9DADC), size: 18),
              ],
            ),
          ),
        ],
      ),
    );
  }


  // ==================== Monthly Calendar View (iOS - Glassmorphism) ====================
  Widget _buildCalendarTabIOS(bool isDark) {
    // Theme mapping according to the HTML provided by the user
    final titleColor = isDark ? const Color(0xFFFAEBEA) : const Color(0xFF410003);
    final primaryColor = isDark ? const Color(0xFFFFB3AD) : const Color(0xFFAC0017);
    final onPrimaryColor = isDark ? const Color(0xFF68000A) : Colors.white;
    final secondaryColor = isDark ? const Color(0xFFE7BDB7) : const Color(0xFF5C403D);
    final outlineVariantColor = isDark ? const Color(0xFF5C403D) : Colors.grey[400]!;

    final panelBgColor = isDark 
        ? const Color(0xFF2F1B1A).withValues(alpha: 0.6) 
        : Colors.white.withValues(alpha: 0.6);
    final cardBgColor = isDark 
        ? const Color(0xFF3A2524).withValues(alpha: 0.5) 
        : Colors.white.withValues(alpha: 0.55);
    final panelBorderColor = isDark 
        ? const Color(0xFFE5BDBA).withValues(alpha: 0.15) 
        : Colors.black.withValues(alpha: 0.08);
    final cardBorderColor = isDark 
        ? const Color(0xFFE5BDBA).withValues(alpha: 0.1) 
        : Colors.black.withValues(alpha: 0.05);

    // Calcular días de forma dinámica
    final firstDay = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final firstWeekday = firstDay.weekday;
    final paddingCount = firstWeekday - 1;

    final lastDayOfPrevMonth = DateTime(_focusedMonth.year, _focusedMonth.month, 0);
    final prevMonthDays = List.generate(paddingCount, (i) {
      return lastDayOfPrevMonth.day - paddingCount + 1 + i;
    });

    final daysInMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0).day;
    final currentMonthDays = List.generate(daysInMonth, (i) => i + 1);

    final totalCells = ((paddingCount + daysInMonth) / 7).ceil() * 7;
    final nextMonthPaddingCount = totalCells - (paddingCount + daysInMonth);
    final nextMonthDays = List.generate(nextMonthPaddingCount, (i) => i + 1);

    bool isWorkDay(DateTime date) => date.weekday != 7;
    bool isRestDay(DateTime date) => date.weekday == 7;

    // Generar días de la semana a mostrar abajo (semana de _selectedDate)
    final diff = _selectedDate.weekday - 1;
    final mondayOfWeek = _selectedDate.subtract(Duration(days: diff));
    final weekDays = List.generate(7, (i) => mondayOfWeek.add(Duration(days: i)));

    return ListView(
      padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 88, 20, 100),
      children: [
        // iOS Month Header layout
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Vista Mensual',
              style: GoogleFonts.sora(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: titleColor,
              ),
            ),
            Row(
              children: [
                IconButton(
                  icon: Icon(Icons.chevron_left, color: titleColor),
                  onPressed: _onPrevMonth,
                ),
                Text(
                  _getMonthYearString(_focusedMonth),
                  style: GoogleFonts.sora(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.chevron_right, color: titleColor),
                  onPressed: _onNextMonth,
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Bento Stats Monthly Summary Header (glassmorphic)
        _buildBentoStats(true, isDark),
        const SizedBox(height: 16),

        // Action switch row
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _isWeeklyView = !_isWeeklyView;
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5D3F3B).withValues(alpha: isDark ? 0.4 : 0.2),
                  foregroundColor: primaryColor,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                    side: BorderSide(color: panelBorderColor.withValues(alpha: 0.3)),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                icon: Icon(_isWeeklyView ? Icons.calendar_month : Icons.view_week, size: 18),
                label: Text(_isWeeklyView ? 'Vista Mensual' : 'Vista Semanal'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _currentIndex = 2; // Redirección a Mercado
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5D3F3B).withValues(alpha: isDark ? 0.4 : 0.2),
                  foregroundColor: primaryColor,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                    side: BorderSide(color: panelBorderColor.withValues(alpha: 0.3)),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                icon: const Icon(Icons.storefront, size: 18),
                label: const Text('Mercado de Turnos'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Calendar Section (glass-panel)
        ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: panelBgColor,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: panelBorderColor,
                ),
              ),
              child: Column(
                children: [
                  // Calendar Grid Header — row with evenly spaced day labels
                  Row(
                    children: ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'].map((day) {
                      return Expanded(
                        child: SizedBox(
                          height: 28,
                          child: Center(
                            child: Text(
                              day,
                              style: GoogleFonts.hankenGrotesk(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: secondaryColor,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 6),

                  // Calendar Days Grid
                  if (_isWeeklyView)
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 7,
                        crossAxisSpacing: 4,
                        mainAxisSpacing: 4,
                        childAspectRatio: 1.0,
                      ),
                      itemCount: 7,
                      itemBuilder: (context, index) {
                        final day = weekDays[index];
                        final isActive = _isSameDay(day, _selectedDate);
                        final isSunday = day.weekday == 7;

                        final shiftType = day.day % 2 == 0 ? 'AM' : 'PM';
                        final shiftBg = shiftType == 'AM' 
                            ? const Color(0xFFD2232A).withValues(alpha: 0.15) 
                            : const Color(0xFFFFB956).withValues(alpha: 0.15);
                        final shiftFg = shiftType == 'AM' ? primaryColor : const Color(0xFFFFB956);

                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedDate = day;
                              _focusedMonth = DateTime(day.year, day.month, 1);
                            });
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: isActive 
                                  ? primaryColor 
                                  : (isSunday 
                                      ? const Color(0xFF5D3F3B).withValues(alpha: isDark ? 0.35 : 0.12)
                                      : Colors.transparent),
                              shape: BoxShape.circle,
                              border: isActive ? Border.all(color: primaryColor.withValues(alpha: 0.5), width: 1) : null,
                              boxShadow: isActive ? [
                                BoxShadow(
                                  color: primaryColor.withValues(alpha: 0.4),
                                  blurRadius: 15,
                                ),
                              ] : null,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '${day.day}',
                                  style: GoogleFonts.sora(
                                    fontSize: 13,
                                    fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                                    color: isActive ? onPrimaryColor : titleColor,
                                  ),
                                ),
                                // Fixed-height slot so all cells are identical height
                                SizedBox(
                                  height: 14,
                                  child: isWorkDay(day)
                                      ? Center(
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                                            decoration: BoxDecoration(
                                              color: isActive ? onPrimaryColor.withValues(alpha: 0.2) : shiftBg,
                                              borderRadius: BorderRadius.circular(3),
                                            ),
                                            child: Text(
                                              shiftType,
                                              style: GoogleFonts.hankenGrotesk(
                                                fontSize: 7,
                                                fontWeight: FontWeight.bold,
                                                color: isActive ? onPrimaryColor : shiftFg,
                                              ),
                                            ),
                                          ),
                                        )
                                      : const Center(
                                          child: Text('🏖️', style: TextStyle(fontSize: 9)),
                                        ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    )
                  else
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 7,
                        crossAxisSpacing: 4,
                        mainAxisSpacing: 4,
                        childAspectRatio: 1.0,
                      ),
                      itemCount: totalCells,
                      itemBuilder: (context, index) {
                        if (index < paddingCount) {
                          final prevDayNum = prevMonthDays[index];
                          return Container(
                            alignment: Alignment.center,
                            child: Text(
                              '$prevDayNum',
                              style: GoogleFonts.sora(
                                color: outlineVariantColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          );
                        }

                        if (index >= paddingCount + daysInMonth) {
                          final nextDayNum = nextMonthDays[index - paddingCount - daysInMonth];
                          return Container(
                            alignment: Alignment.center,
                            child: Text(
                              '$nextDayNum',
                              style: GoogleFonts.sora(
                                color: outlineVariantColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          );
                        }

                        final dayNum = currentMonthDays[index - paddingCount];
                        final cellDate = DateTime(_focusedMonth.year, _focusedMonth.month, dayNum);
                        final isActive = _isSameDay(cellDate, _selectedDate);
                        final isSunday = cellDate.weekday == 7;

                        final shiftType = cellDate.day % 2 == 0 ? 'AM' : 'PM';
                        final shiftBg = shiftType == 'AM' 
                            ? const Color(0xFFD2232A).withValues(alpha: 0.15) 
                            : const Color(0xFFFFB956).withValues(alpha: 0.15);
                        final shiftFg = shiftType == 'AM' ? primaryColor : const Color(0xFFFFB956);

                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedDate = cellDate;
                            });
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: isActive 
                                  ? primaryColor 
                                  : (isSunday 
                                      ? const Color(0xFF5D3F3B).withValues(alpha: isDark ? 0.35 : 0.12)
                                      : Colors.transparent),
                              shape: BoxShape.circle,
                              border: isActive ? Border.all(color: primaryColor.withValues(alpha: 0.5), width: 1) : null,
                              boxShadow: isActive ? [
                                BoxShadow(
                                  color: primaryColor.withValues(alpha: 0.4),
                                  blurRadius: 15,
                                ),
                              ] : null,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '$dayNum',
                                  style: GoogleFonts.sora(
                                    fontSize: 13,
                                    fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                                    color: isActive ? onPrimaryColor : titleColor,
                                  ),
                                ),
                                // Fixed-height slot so all cells are identical height
                                SizedBox(
                                  height: 14,
                                  child: isWorkDay(cellDate)
                                      ? Center(
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                                            decoration: BoxDecoration(
                                              color: isActive ? onPrimaryColor.withValues(alpha: 0.2) : shiftBg,
                                              borderRadius: BorderRadius.circular(3),
                                            ),
                                            child: Text(
                                              shiftType,
                                              style: GoogleFonts.hankenGrotesk(
                                                fontSize: 7,
                                                fontWeight: FontWeight.bold,
                                                color: isActive ? onPrimaryColor : shiftFg,
                                              ),
                                            ),
                                          ),
                                        )
                                      : const Center(
                                          child: Text('🏖️', style: TextStyle(fontSize: 9)),
                                        ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  const SizedBox(height: 16),

                  // Legend
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFD2232A).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'AM / PM',
                              style: GoogleFonts.hankenGrotesk(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: primaryColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Día Laboral',
                            style: GoogleFonts.hankenGrotesk(
                              fontSize: 12,
                              color: secondaryColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 24),
                      Row(
                        children: [
                          const Text('🏖️', style: TextStyle(fontSize: 12)),
                          const SizedBox(width: 6),
                          Text(
                            'Día de Descanso',
                            style: GoogleFonts.hankenGrotesk(
                              fontSize: 12,
                              color: secondaryColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Detail Section (Bento glass-card list)
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Vista General: Semana',
              style: GoogleFonts.sora(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: titleColor,
              ),
            ),
            const SizedBox(height: 12),
            ...weekDays.map((day) {
              final isRest = isRestDay(day);
              final isSelected = _isSameDay(day, _selectedDate);
              final isCompleted = day.isBefore(_selectedDate) && !isSelected;

              final weekdaysLabels = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
              final dayLabel = weekdaysLabels[day.weekday - 1];
              final station = _getStationName(day);

              return _buildCalendarDetailItemIOS(
                isDark,
                cardBgColor,
                cardBorderColor,
                primaryColor,
                secondaryColor,
                titleColor,
                outlineVariantColor,
                dayLabel,
                '${day.day}',
                station,
                isRest ? 'Libre' : '08:00 - 16:00',
                isCompleted,
                isSelected: isSelected,
                isFuture: !isCompleted && !isSelected && !isRest,
              );
            }),
          ],
        ),
      ],
    );
  }

  Widget _buildCalendarDetailItemIOS(
    bool isDark,
    Color cardBgColor,
    Color cardBorderColor,
    Color primaryColor,
    Color secondaryColor,
    Color titleColor,
    Color outlineVariantColor,
    String dayLabel,
    String dayNum,
    String station,
    String hoursLabel,
    bool isCompleted, {
    required bool isSelected,
    bool isFuture = false,
  }) {
    final isRest = station == 'Descanso';
    final accentLineColor = isRest ? outlineVariantColor.withValues(alpha: 0.5) : primaryColor;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            decoration: BoxDecoration(
              color: isSelected ? primaryColor.withValues(alpha: 0.15) : cardBgColor,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isSelected ? primaryColor.withValues(alpha: 0.4) : cardBorderColor,
                width: isSelected ? 1.5 : 1.0,
              ),
              boxShadow: isSelected ? [
                BoxShadow(
                  color: primaryColor.withValues(alpha: 0.15),
                  blurRadius: 15,
                ),
              ] : null,
            ),
            child: Stack(
              children: [
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  width: 4,
                  child: Container(color: accentLineColor),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          SizedBox(
                            width: 40,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  dayLabel,
                                  style: GoogleFonts.hankenGrotesk(
                                    fontSize: 12,
                                    color: secondaryColor,
                                  ),
                                ),
                                Text(
                                  dayNum,
                                  style: GoogleFonts.sora(
                                    fontSize: 16,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                    color: isSelected ? primaryColor : titleColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            width: 1,
                            height: 28,
                            color: cardBorderColor,
                          ),
                          const SizedBox(width: 12),
                          
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildStationBadge(station, isDark),
                              const SizedBox(height: 4),
                              Text(
                                hoursLabel,
                                style: GoogleFonts.hankenGrotesk(
                                  fontSize: 11,
                                  color: secondaryColor,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      
                      // Status icon
                      if (isRest)
                        const Text('🏖️', style: TextStyle(fontSize: 14))
                      else if (isCompleted)
                        Icon(
                          Icons.check_circle,
                          color: primaryColor,
                          size: 18,
                          shadows: [
                            Shadow(
                              color: primaryColor.withValues(alpha: 0.4),
                              blurRadius: 8,
                            ),
                          ],
                        )
                      else if (isSelected)
                        Icon(Icons.radio_button_checked, color: primaryColor, size: 18)
                      else
                        Icon(Icons.circle_outlined, color: outlineVariantColor, size: 18),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }


  // ==================== General secondary vistas ====================
  Widget _buildMarketTab(bool isIOS, bool isDark) {
    final titleColor = isIOS
        ? (isDark ? const Color(0xFFFBDBD8) : const Color(0xFF410003))
        : (isDark ? const Color(0xFFE1E2E4) : const Color(0xFF191C1E));
    final subtextColor = isIOS
        ? (isDark ? const Color(0xFFE5BDBA) : const Color(0xFF5C403D))
        : (isDark ? const Color(0xFFC6C6C7) : const Color(0xFF545D80));
    final primaryColor = isDark ? const Color(0xFFFFB3AD) : const Color(0xFFAC0017);
    final cardBgColor = isIOS
        ? (isDark ? const Color(0xFF3A2524).withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.55))
        : (isDark ? const Color(0xFF1E1E1E) : Colors.white);
    final cardBorderColor = isIOS
        ? (isDark ? const Color(0xFFE5BDBA).withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05))
        : (isDark ? Colors.white12 : const Color(0xFFEDEEF0));
    final switchBgColor = isIOS
        ? (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.04))
        : (isDark ? const Color(0xFF2C2C2C) : const Color(0xFFEDEEF0));
    final activeSwitchColor = isIOS
        ? (isDark ? Colors.white.withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.8))
        : (isDark ? const Color(0xFF1E1E1E) : Colors.white);

    // List of coworker trades
    final coworkersTrades = [
      {
        'id': 1,
        'name': 'Pedro M.',
        'role': 'Cajero',
        'avatar': 'https://lh3.googleusercontent.com/aida-public/AB6AXuBtUVGj8clMRCmIF-mfrHJv2MQ4y6BcWC8MwBPPpmetQHcRm0MGMdl8_csJtqxZkBmB41jy1q_ynNEF_Dr6rShF60kBlV_K0vftHIrAFR1LDiyGLnnFANE5T1mjlG_zTmtDLWDUjosBkStD4K1tkLop0w8RbzEKA-i4Yb8bnJhe_LrwECeYuwD63vN9_letfDn4BjvwG3rw4ZHI0Qzmo0TELkxAGzVW66ofEPtf7csaVJCYpPuC2ic0cg',
        'weekday': 'MIÉ',
        'day': '15',
        'month': 'ABR',
        'hours': '12:00 PM - 8:00 PM',
        'location': 'Armenia Centro',
      },
      {
        'id': 2,
        'name': 'María G.',
        'role': 'Cocina',
        'avatar': 'https://lh3.googleusercontent.com/aida-public/AB6AXuBBqUPqTd4yAJpYOq9RVFA16Yx_r-PnVDkPOoFh4dWAH-GJwqI1k3F4x6m6Zq2tZEUvTJK5Dff8ECF06479hqR0rMDhzXcmx3SUX9Xb1RbPhO7RwOL82CXXhNZUSHxlk-nQkIeOmEYaPM_GtrIUARL7Cq1Rx9m3JHD9qMJlyjiHuxIZxuvfLvIMyIBIvikOH6OMAi448HCVS_d6L51lYpDN4hmRqxjcE8Zc7LEa90ZQu4Y1HRpEygoU4g',
        'weekday': 'JUE',
        'day': '16',
        'month': 'ABR',
        'hours': '8:00 AM - 4:00 PM',
        'location': 'Armenia Norte',
      }
    ];

    void handleSolicitarTrade(int id) {
      if (_requestedTrades.contains(id)) return;
      
      final trade = coworkersTrades.firstWhere((t) => t['id'] == id);

      showDialog(
        context: context,
        builder: (context) {
          final dialogBgColor = isIOS
              ? (isDark ? const Color(0xFF2C1B1A) : const Color(0xFFFFF1F0))
              : (isDark ? const Color(0xFF1E1E1E) : Colors.white);
          final dialogTextColor = isIOS
              ? (isDark ? const Color(0xFFFBDBD8) : const Color(0xFF410003))
              : (isDark ? const Color(0xFFE1E2E4) : const Color(0xFF121C3B));
          final dialogSubtextColor = isIOS
              ? (isDark ? const Color(0xFFE5BDBA) : const Color(0xFF5C403D))
              : (isDark ? const Color(0xFFC6C6C7) : const Color(0xFF5C403D));

          return AlertDialog(
            backgroundColor: dialogBgColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: (isIOS || isDark) ? const BorderSide(color: Colors.white12) : BorderSide.none,
            ),
            title: Text(
              'Confirmar Solicitud',
              style: GoogleFonts.hankenGrotesk(
                color: dialogTextColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Text(
              '¿Deseas enviar una solicitud de trade a ${trade['name']} para trabajar el ${trade['weekday']} ${trade['day']} de ${trade['month']} en sucursal ${trade['location']}?',
              style: GoogleFonts.hankenGrotesk(
                color: dialogSubtextColor,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Cancelar',
                  style: GoogleFonts.hankenGrotesk(
                    color: Colors.grey,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  setState(() {
                    _requestedTrades.add(id);
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Solicitud enviada a ${trade['name']}. Pendiente de respuesta.',
                        style: GoogleFonts.hankenGrotesk(color: Colors.white),
                      ),
                      backgroundColor: Colors.green[800],
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD2232A),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: Text(
                  'Enviar',
                  style: GoogleFonts.hankenGrotesk(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          );
        },
      );
    }

    Widget buildSwitch() {
      final textStyleActive = isIOS
          ? GoogleFonts.sora(fontSize: 13, fontWeight: FontWeight.bold, color: titleColor)
          : GoogleFonts.hankenGrotesk(fontSize: 13, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF191C1E));
      final textStyleInactive = isIOS
          ? GoogleFonts.sora(fontSize: 13, color: subtextColor.withValues(alpha: 0.7))
          : GoogleFonts.hankenGrotesk(fontSize: 13, color: subtextColor);

      Widget toggleButton(int index, String label) {
        final isActive = _selectedMarketTab == index;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _selectedMarketTab = index),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: isActive ? activeSwitchColor : Colors.transparent,
                borderRadius: BorderRadius.circular(30),
                boxShadow: (isActive && !isIOS) ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ] : null,
              ),
              alignment: Alignment.center,
              child: Text(
                label,
                style: isActive ? textStyleActive : textStyleInactive,
              ),
            ),
          ),
        );
      }

      return Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: switchBgColor,
          borderRadius: BorderRadius.circular(30),
          border: isIOS ? Border.all(color: cardBorderColor) : null,
        ),
        child: Row(
          children: [
            toggleButton(0, 'Turnos Disponibles'),
            toggleButton(1, 'Mis Cambios'),
          ],
        ),
      );
    }

    Widget buildCoworkersList() {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Trades de Compañeros',
            style: isIOS
                ? GoogleFonts.sora(fontSize: 18, fontWeight: FontWeight.bold, color: titleColor)
                : GoogleFonts.hankenGrotesk(fontSize: 18, fontWeight: FontWeight.bold, color: titleColor),
          ),
          const SizedBox(height: 12),
          ...coworkersTrades.map((trade) {
            final id = trade['id'] as int;
            final isRequested = _requestedTrades.contains(id);

            Widget cardContent = Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(25),
                        child: Image.network(
                          trade['avatar'] as String,
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            width: 50,
                            height: 50,
                            color: Colors.grey,
                            child: const Icon(Icons.person, color: Colors.white),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${trade['name']} (${trade['role']})',
                              style: isIOS
                                  ? GoogleFonts.sora(fontSize: 15, fontWeight: FontWeight.bold, color: titleColor)
                                  : GoogleFonts.hankenGrotesk(fontSize: 15, fontWeight: FontWeight.bold, color: titleColor),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                // Date badge
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF3F4F6),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: cardBorderColor),
                                  ),
                                  child: Column(
                                    children: [
                                      Text(
                                        trade['weekday'] as String,
                                        style: GoogleFonts.hankenGrotesk(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: subtextColor,
                                        ),
                                      ),
                                      Text(
                                        trade['day'] as String,
                                        style: GoogleFonts.hankenGrotesk(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: titleColor,
                                        ),
                                      ),
                                      Text(
                                        trade['month'] as String,
                                        style: GoogleFonts.hankenGrotesk(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: subtextColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                // Vertical divider
                                Container(
                                  width: 1,
                                  height: 40,
                                  color: cardBorderColor,
                                ),
                                const SizedBox(width: 12),
                                // Details
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        trade['hours'] as String,
                                        style: GoogleFonts.hankenGrotesk(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: titleColor,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.location_on,
                                            size: 14,
                                            color: subtextColor,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            trade['location'] as String,
                                            style: GoogleFonts.hankenGrotesk(
                                              fontSize: 12,
                                              color: subtextColor,
                                            ),
                                          ),
                                        ],
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
                  const SizedBox(height: 16),
                  
                  // Action button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: isRequested ? null : () => handleSolicitarTrade(id),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isRequested 
                            ? Colors.green[800] 
                            : (isIOS ? const Color(0xFF5D3F3B).withValues(alpha: isDark ? 0.4 : 0.2) : const Color(0xFF121C3B)),
                        foregroundColor: isRequested ? Colors.white : (isIOS ? primaryColor : Colors.white),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                          side: (isIOS && !isRequested) ? BorderSide(color: primaryColor.withValues(alpha: 0.3)) : BorderSide.none,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (isRequested) ...[
                            const Icon(Icons.check, size: 18),
                            const SizedBox(width: 8),
                          ],
                          Text(
                            isRequested ? 'Solicitado' : 'Solicitar Trade',
                            style: GoogleFonts.hankenGrotesk(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );

            if (isIOS) {
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                    child: Container(
                      decoration: BoxDecoration(
                        color: cardBgColor,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: cardBorderColor),
                      ),
                      child: cardContent,
                    ),
                  ),
                ),
              );
            } else {
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: cardBgColor,
                  borderRadius: BorderRadius.circular(16),
                  border: isDark ? Border.all(color: cardBorderColor) : null,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: cardContent,
              );
            }
          }),
        ],
      );
    }

    Widget buildMyTradesList() {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Mis Solicitudes y Cambios',
            style: isIOS
                ? GoogleFonts.sora(fontSize: 18, fontWeight: FontWeight.bold, color: titleColor)
                : GoogleFonts.hankenGrotesk(fontSize: 18, fontWeight: FontWeight.bold, color: titleColor),
          ),
          const SizedBox(height: 12),
          if (_requestedTrades.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 40.0),
                child: Column(
                  children: [
                    Icon(Icons.swap_horizontal_circle, size: 64, color: subtextColor.withValues(alpha: 0.5)),
                    const SizedBox(height: 12),
                    Text(
                      'No tienes solicitudes activas',
                      style: GoogleFonts.hankenGrotesk(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: subtextColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Solicita un trade a un compañero o publica uno nuevo.',
                      style: GoogleFonts.hankenGrotesk(
                        fontSize: 13,
                        color: subtextColor.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ..._requestedTrades.map((id) {
              final trade = coworkersTrades.firstWhere((t) => t['id'] == id);

              Widget cardContent = Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.network(
                        trade['avatar'] as String,
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: 40,
                          height: 40,
                          color: Colors.grey,
                          child: const Icon(Icons.person, color: Colors.white, size: 18),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Trade con ${trade['name']}',
                            style: GoogleFonts.hankenGrotesk(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: titleColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${trade['weekday']} ${trade['day']} de ${trade['month']} | ${trade['hours']}',
                            style: GoogleFonts.hankenGrotesk(
                              fontSize: 12,
                              color: subtextColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        'PENDIENTE',
                        style: GoogleFonts.hankenGrotesk(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange[850],
                        ),
                      ),
                    ),
                  ],
                ),
              );

              if (isIOS) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        decoration: BoxDecoration(
                          color: cardBgColor,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: cardBorderColor),
                        ),
                        child: cardContent,
                      ),
                    ),
                  ),
                );
              } else {
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: cardBgColor,
                    borderRadius: BorderRadius.circular(12),
                    border: isDark ? Border.all(color: cardBorderColor) : null,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: cardContent,
                );
              }
            }),
        ],
      );
    }

    final topPadding = isIOS ? MediaQuery.of(context).padding.top + 88 : 20.0;

    return ListView(
      padding: EdgeInsets.fromLTRB(16, topPadding, 16, 100),
      children: [
        buildSwitch(),
        const SizedBox(height: 24),
        _selectedMarketTab == 0 ? buildCoworkersList() : buildMyTradesList(),
      ],
    );
  }

  Widget _buildProfileTab(bool isIOS, bool isDark) {
    final cleanName = widget.username.split('@').first;

    final titleColor = isIOS
        ? (isDark ? const Color(0xFFFBDBD8) : const Color(0xFF410003))
        : (isDark ? const Color(0xFFE1E2E4) : const Color(0xFF121C3B));
    final subtextColor = isIOS
        ? (isDark ? const Color(0xFFE5BDBA) : const Color(0xFF5C403D))
        : (isDark ? const Color(0xFFC6C6C7) : const Color(0xFF545D80));
    final primaryColor = isDark ? const Color(0xFFFFB3AD) : const Color(0xFFAC0017);
    final cardBg = isIOS
        ? (isDark ? const Color(0xFF3A2524).withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.65))
        : (isDark ? const Color(0xFF1E1E1E) : Colors.white);
    final cardBorder = isIOS
        ? (isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.07))
        : (isDark ? Colors.white12 : const Color(0xFFEDEEF0));

    final viewPaddingTop = isIOS ? MediaQuery.of(context).padding.top + 88.0 : 24.0;

    // Stat chip helper
    Widget statChip(String value, String label, IconData icon, Color accent) {
      Widget chip = Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: accent, size: 20),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: isIOS
                  ? GoogleFonts.sora(fontSize: 16, fontWeight: FontWeight.bold, color: titleColor)
                  : GoogleFonts.hankenGrotesk(fontSize: 16, fontWeight: FontWeight.bold, color: titleColor),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.hankenGrotesk(fontSize: 11, color: subtextColor),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );

      if (isIOS) {
        return Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: Container(
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: cardBorder),
                ),
                child: chip,
              ),
            ),
          ),
        );
      }
      return Expanded(
        child: Container(
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(12),
            border: isDark ? Border.all(color: cardBorder) : null,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.05),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: chip,
        ),
      );
    }

    // Info row helper
    Widget infoRow(IconData icon, String label, String value) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 18, color: primaryColor),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.hankenGrotesk(
                      fontSize: 11,
                      color: subtextColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    value,
                    style: isIOS
                        ? GoogleFonts.sora(fontSize: 14, fontWeight: FontWeight.w600, color: titleColor)
                        : GoogleFonts.hankenGrotesk(fontSize: 14, fontWeight: FontWeight.w600, color: titleColor),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    Widget buildInfoCard() {
      final content = Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Información del Empleado',
              style: isIOS
                  ? GoogleFonts.sora(fontSize: 16, fontWeight: FontWeight.bold, color: titleColor)
                  : GoogleFonts.hankenGrotesk(fontSize: 16, fontWeight: FontWeight.bold, color: titleColor),
            ),
            const SizedBox(height: 12),
            Divider(color: cardBorder),
            infoRow(Icons.badge, 'Cédula / ID', cleanName),
            Divider(color: cardBorder),
            infoRow(Icons.store, 'Sucursal', 'Frisby Unicentro Armenia'),
            Divider(color: cardBorder),
            infoRow(Icons.work, 'Cargo', 'Auxiliar de Cocina'),
            Divider(color: cardBorder),
            infoRow(Icons.schedule, 'Tipo de Contrato', 'Tiempo Parcial – 6h/día'),
            Divider(color: cardBorder),
            infoRow(Icons.supervisor_account, 'Supervisor', 'María V.'),
          ],
        ),
      );

      if (isIOS) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: cardBorder),
              ),
              child: content,
            ),
          ),
        );
      }
      return Container(
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          border: isDark ? Border.all(color: cardBorder) : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: content,
      );
    }

    return ListView(
      padding: EdgeInsets.fromLTRB(20, viewPaddingTop, 20, 100),
      children: [
        // Avatar + Name Header
        Column(
          children: [
            // Avatar Circle with glowing ring
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: primaryColor.withValues(alpha: 0.5), width: 2),
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withValues(alpha: 0.3),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: isIOS
                      ? (isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFFFDAD6))
                      : (isDark ? Colors.white10 : const Color(0xFFFFDAD6)),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(Icons.person, size: 52, color: primaryColor),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              cleanName,
              style: isIOS
                  ? GoogleFonts.sora(fontSize: 24, fontWeight: FontWeight.bold, color: titleColor)
                  : GoogleFonts.hankenGrotesk(fontSize: 22, fontWeight: FontWeight.bold, color: titleColor),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: primaryColor.withValues(alpha: 0.25)),
              ),
              child: Text(
                'Auxiliar de Cocina  •  Frisby Unicentro',
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: primaryColor,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 28),

        // Stats Grid
        Row(
          children: [
            statChip('120 hrs', 'Horas\neste mes', Icons.access_time_filled, const Color(0xFFAC0017)),
            const SizedBox(width: 8),
            statChip('15 días', 'Turnos\nprog.', Icons.calendar_today, const Color(0xFFF7B640)),
            const SizedBox(width: 8),
            statChip('8 días', 'Descansos\nprog.', Icons.beach_access, const Color(0xFF0074A3)),
          ],
        ),
        const SizedBox(height: 24),

        // Info Card
        buildInfoCard(),
        const SizedBox(height: 20),

        // Quick Actions
        Row(
          children: [
            Expanded(
              child: _buildQuickActionButton(
                icon: Icons.lock_reset,
                label: 'Cambiar\nContraseña',
                primaryColor: primaryColor,
                isDark: isDark,
                isIOS: isIOS,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Contacta a tu supervisor para restablecer la contraseña.',
                        style: GoogleFonts.hankenGrotesk(color: Colors.white),
                      ),
                      backgroundColor: const Color(0xFFD2232A),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildQuickActionButton(
                icon: Icons.help_outline,
                label: 'Soporte\nTécnico',
                primaryColor: const Color(0xFF0074A3),
                isDark: isDark,
                isIOS: isIOS,
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      title: Text('Soporte Técnico',
                        style: GoogleFonts.hankenGrotesk(
                          color: isDark ? const Color(0xFFE1E2E4) : const Color(0xFF121C3B),
                          fontWeight: FontWeight.bold,
                        )),
                      content: Text(
                        'Para soporte, contacta a:\n\nMaría V.\nmv.soporte@frisby.com\n\nLínea interna: Ext. 400',
                        style: GoogleFonts.hankenGrotesk(
                          color: isDark ? const Color(0xFFC6C6C7) : const Color(0xFF545D80),
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text('Cerrar',
                            style: GoogleFonts.hankenGrotesk(
                              color: const Color(0xFFAC0017),
                              fontWeight: FontWeight.bold,
                            )),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Logout Button
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: _logout,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFAC0017),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              elevation: 0,
            ),
            icon: const Icon(Icons.logout_rounded),
            label: Text(
              'Cerrar Sesión',
              style: GoogleFonts.hankenGrotesk(
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required Color primaryColor,
    required bool isDark,
    required bool isIOS,
    required VoidCallback onTap,
  }) {
    final cardBg = isIOS
        ? (isDark ? const Color(0xFF3A2524).withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.65))
        : (isDark ? const Color(0xFF1E1E1E) : Colors.white);
    final cardBorder = isIOS
        ? (isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.07))
        : (isDark ? Colors.white12 : const Color(0xFFEDEEF0));

    Widget content = GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: primaryColor, size: 22),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.hankenGrotesk(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? const Color(0xFFE1E2E4) : const Color(0xFF191C1E),
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );

    if (isIOS) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: cardBorder),
            ),
            child: content,
          ),
        ),
      );
    }
    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: isDark ? Border.all(color: cardBorder) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: content,
    );
  }

  void _showChangePolicyDialog(bool isIOS, bool isDark) {
    showDialog(
      context: context,
      builder: (context) {
        final dialogBgColor = isIOS
            ? (isDark ? const Color(0xFF2C1B1A) : const Color(0xFFFFF1F0))
            : (isDark ? const Color(0xFF1E1E1E) : Colors.white);
        final dialogTextColor = isIOS
            ? (isDark ? const Color(0xFFFBDBD8) : const Color(0xFF410003))
            : (isDark ? const Color(0xFFE1E2E4) : const Color(0xFF121C3B));
        final dialogSubtextColor = isIOS
            ? (isDark ? const Color(0xFFE5BDBA) : const Color(0xFF5C403D))
            : (isDark ? const Color(0xFFC6C6C7) : const Color(0xFF5C403D));

        return AlertDialog(
          backgroundColor: dialogBgColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: (isIOS || isDark) ? const BorderSide(color: Colors.white12) : BorderSide.none,
          ),
          title: Text(
            'Políticas de Cambios',
            style: GoogleFonts.hankenGrotesk(
              color: dialogTextColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SingleChildScrollView(
            child: ListBody(
              children: [
                Text(
                  '1. Plazo Límite:',
                  style: GoogleFonts.hankenGrotesk(fontWeight: FontWeight.bold, color: dialogTextColor),
                ),
                const SizedBox(height: 4),
                Text(
                  'Las solicitudes de cambio deben enviarse con al menos 24 horas de anticipación a la jornada programada.',
                  style: GoogleFonts.hankenGrotesk(color: dialogSubtextColor),
                ),
                const SizedBox(height: 12),
                Text(
                  '2. Aprobación del Supervisor:',
                  style: GoogleFonts.hankenGrotesk(fontWeight: FontWeight.bold, color: dialogTextColor),
                ),
                const SizedBox(height: 4),
                Text(
                  'Cualquier intercambio o cesión de turno está sujeto a la revisión y aprobación final del supervisor a cargo.',
                  style: GoogleFonts.hankenGrotesk(color: dialogSubtextColor),
                ),
                const SizedBox(height: 12),
                Text(
                  '3. Límite de Cambios:',
                  style: GoogleFonts.hankenGrotesk(fontWeight: FontWeight.bold, color: dialogTextColor),
                ),
                const SizedBox(height: 4),
                Text(
                  'Se permite un máximo de 3 intercambios de turno aprobados por mes para garantizar la estabilidad del servicio.',
                  style: GoogleFonts.hankenGrotesk(color: dialogSubtextColor),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Entendido',
                style: GoogleFonts.hankenGrotesk(
                  color: isIOS ? const Color(0xFFD2232A) : const Color(0xFFAC0017),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showSupportDialog(bool isIOS, bool isDark) {
    showDialog(
      context: context,
      builder: (context) {
        final dialogBgColor = isIOS
            ? (isDark ? const Color(0xFF2C1B1A) : const Color(0xFFFFF1F0))
            : (isDark ? const Color(0xFF1E1E1E) : Colors.white);
        final dialogTextColor = isIOS
            ? (isDark ? const Color(0xFFFBDBD8) : const Color(0xFF410003))
            : (isDark ? const Color(0xFFE1E2E4) : const Color(0xFF121C3B));
        final dialogSubtextColor = isIOS
            ? (isDark ? const Color(0xFFE5BDBA) : const Color(0xFF5C403D))
            : (isDark ? const Color(0xFFC6C6C7) : const Color(0xFF5C403D));

        return AlertDialog(
          backgroundColor: dialogBgColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: (isIOS || isDark) ? const BorderSide(color: Colors.white12) : BorderSide.none,
          ),
          title: Text(
            'Soporte Técnico',
            style: GoogleFonts.hankenGrotesk(
              color: dialogTextColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '¿Tienes algún problema con la aplicación o tus horarios?',
                style: GoogleFonts.hankenGrotesk(color: dialogTextColor),
              ),
              const SizedBox(height: 12),
              Text(
                'Contacto del Supervisor:',
                style: GoogleFonts.hankenGrotesk(fontWeight: FontWeight.bold, color: dialogTextColor),
              ),
              Text('María V. | mv.soporte@frisby.com', style: GoogleFonts.hankenGrotesk(color: dialogSubtextColor)),
              const SizedBox(height: 8),
              Text(
                'Línea de Atención Interna:',
                style: GoogleFonts.hankenGrotesk(fontWeight: FontWeight.bold, color: dialogTextColor),
              ),
              Text('+57 (606) 313-0000 Ext. 400', style: GoogleFonts.hankenGrotesk(color: dialogSubtextColor)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cerrar',
                style: GoogleFonts.hankenGrotesk(
                  color: isIOS ? const Color(0xFFD2232A) : const Color(0xFFAC0017),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDrawer(bool isIOS, bool isDark) {
    final cleanName = widget.username.split('@').first;
    final titleColor = isIOS
        ? (isDark ? const Color(0xFFFBDBD8) : const Color(0xFF410003))
        : (isDark ? const Color(0xFFE1E2E4) : const Color(0xFF121C3B));
    final subtextColor = isIOS
        ? (isDark ? const Color(0xFFE5BDBA) : const Color(0xFF5C403D))
        : (isDark ? const Color(0xFFC6C6C7) : const Color(0xFF545D80));
    final drawerBgColor = isIOS ? Colors.transparent : (isDark ? const Color(0xFF1E1E1E) : Colors.white);



    Widget drawerHeader() {
      if (isIOS) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                  shape: BoxShape.circle,
                  border: Border.all(color: isDark ? Colors.white24 : Colors.black12),
                ),
                child: const Icon(Icons.person, color: Color(0xFFAC0017), size: 36),
              ),
              const SizedBox(height: 16),
              Text(
                'Hola, $cleanName',
                style: GoogleFonts.sora(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: titleColor,
                ),
              ),
              Text(
                'Rol: Cocina | Frisby Unicentro',
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 13,
                  color: subtextColor,
                ),
              ),
            ],
          ),
        );
      } else {
        return DrawerHeader(
          decoration: const BoxDecoration(
            color: Color(0xFFAC0017),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              const CircleAvatar(
                backgroundColor: Colors.white,
                radius: 28,
                child: Icon(Icons.person, color: Color(0xFFAC0017), size: 36),
              ),
              const SizedBox(height: 12),
              Text(
                'Hola, $cleanName',
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                'Rol: Cocina | Frisby Unicentro',
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 13,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        );
      }
    }

    Widget drawerItem({
      required IconData icon,
      required String label,
      required VoidCallback onTap,
      Color? color,
    }) {
      final tileColor = color ?? titleColor;
      return ListTile(
        leading: Icon(icon, color: tileColor),
        title: Text(
          label,
          style: isIOS
              ? GoogleFonts.sora(fontSize: 14, color: tileColor, fontWeight: color != null ? FontWeight.bold : FontWeight.w500)
              : GoogleFonts.hankenGrotesk(fontSize: 14, color: tileColor, fontWeight: color != null ? FontWeight.bold : FontWeight.w500),
        ),
        onTap: onTap,
      );
    }

    final listContent = ListView(
      padding: EdgeInsets.zero,
      children: [
        drawerHeader(),
        if (isIOS) const Divider(color: Colors.white12),
        drawerItem(
          icon: Icons.home,
          label: 'Inicio / Turnos',
          onTap: () {
            Navigator.pop(context);
            setState(() => _currentIndex = 0);
          },
        ),
        drawerItem(
          icon: Icons.calendar_month,
          label: 'Calendario',
          onTap: () {
            Navigator.pop(context);
            setState(() => _currentIndex = 1);
          },
        ),
        drawerItem(
          icon: Icons.storefront,
          label: 'Mercado de Turnos',
          onTap: () {
            Navigator.pop(context);
            setState(() => _currentIndex = 2);
          },
        ),
        drawerItem(
          icon: Icons.person,
          label: 'Mi Perfil',
          onTap: () {
            Navigator.pop(context);
            setState(() => _currentIndex = 3);
          },
        ),
        const Divider(color: Colors.white12),
        SwitchListTile(
          title: Text(
            'Modo Oscuro',
            style: isIOS
                ? GoogleFonts.sora(fontSize: 14, color: titleColor, fontWeight: FontWeight.w500)
                : GoogleFonts.hankenGrotesk(fontSize: 14, color: titleColor, fontWeight: FontWeight.w500),
          ),
          value: isDark,
          onChanged: (val) {
            _toggleTheme();
          },
          secondary: Icon(
            isDark ? Icons.dark_mode : Icons.light_mode,
            color: titleColor,
          ),
          activeThumbColor: const Color(0xFFD2232A),
        ),
        drawerItem(
          icon: Icons.gavel_outlined,
          label: 'Políticas de Cambios',
          onTap: () {
            Navigator.pop(context);
            _showChangePolicyDialog(isIOS, isDark);
          },
        ),
        drawerItem(
          icon: Icons.support_agent,
          label: 'Soporte Técnico',
          onTap: () {
            Navigator.pop(context);
            _showSupportDialog(isIOS, isDark);
          },
        ),
        const Divider(color: Colors.white12),
        drawerItem(
          icon: Icons.logout_rounded,
          label: 'Cerrar Sesión',
          color: const Color(0xFFAC0017),
          onTap: () {
            Navigator.pop(context);
            _logout();
          },
        ),
      ],
    );

    if (isIOS) {
      final barBg = isDark ? const Color(0xFF2C1B1A).withValues(alpha: 0.8) : Colors.white.withValues(alpha: 0.8);
      final barBorder = isDark ? Colors.white.withValues(alpha: 0.15) : Colors.black.withValues(alpha: 0.08);

      return Drawer(
        backgroundColor: Colors.transparent,
        child: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              decoration: BoxDecoration(
                color: barBg,
                border: Border(
                  right: BorderSide(color: barBorder),
                ),
              ),
              child: SafeArea(child: listContent),
            ),
          ),
        ),
      );
    } else {
      return Drawer(
        backgroundColor: drawerBgColor,
        child: listContent,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final isDesktop = mediaQuery.size.width > 800;

    // Evaluate dark mode state
    final isDark = _isDarkMode(context);

    // If running on desktop or wide web window, render the Desktop Collaborator Portal
    if (isDesktop) {
      return _buildDesktopCollaboratorPortal(isDark);
    }

    // Active target platform is iOS
    final isIOS = !kIsWeb && Theme.of(context).platform == TargetPlatform.iOS;


    // Android / Web solid App Bar
    PreferredSizeWidget? mobileAppBarAndroid() {
      if (isDesktop || isIOS) return null;
      
      final appBarBg = isDark ? const Color(0xFF1F1F1F) : const Color(0xFFAC0017);
      final textColor = Colors.white;

      return AppBar(
        backgroundColor: appBarBg,
        elevation: 1,
        centerTitle: true,
        title: _currentIndex == 0
            ? Image.network(
                'https://lh3.googleusercontent.com/aida-public/AB6AXuATkXAerVPsE2m4hfUiQnl2Y9rqFfI7Ps4kylZ4pKqTsLdljqPy3P98NcAsZSxf5IhL9PT0EuZTt6uWZCyEwE_d0EleeKeYd7eOti54uHUm05djF0vMkj200IOm-HymlHKOB1bF3OJNLf_BwQHd8Xi08O5wdJgwONmRr9t7QwTuRiigzmxj8wDxdOTExQV5qztVYJNP5jaE-OQsRnV5_zkiTrVLmwvYv0XeIEm_LEo0hkxVXoQTGx_frjCjDWomYU7yXM8',
                height: 32,
                errorBuilder: (context, error, stackTrace) => Text(
                  'Frisby Turnos',
                  style: GoogleFonts.hankenGrotesk(
                    fontWeight: FontWeight.bold,
                    color: textColor,
                    fontSize: 20,
                  ),
                ),
              )
            : Text(
                _currentIndex == 1 
                    ? 'Mi Calendario' 
                    : (_currentIndex == 2 ? 'Mercado de Turnos' : 'Mi Perfil'),
                style: GoogleFonts.hankenGrotesk(
                  fontWeight: FontWeight.bold,
                  color: textColor,
                  fontSize: 18,
                ),
              ),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications, color: Colors.white),
                onPressed: () {
                  _showNotificationDialog(
                    'Alertas Recientes',
                    'Revisa tus turnos aprobados para la jornada de esta semana en tu historial.',
                    'Actualizado hace 2 horas',
                    false,
                    isDark,
                  );
                },
              ),
              Positioned(
                right: 12,
                top: 12,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFFBA1A1A),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ],
      );
    }

    // iOS Floating Glassmorphic TopAppBar
    Widget mobileAppBarIOS() {
      final barBg = isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.6);
      final barBorder = isDark ? Colors.white.withValues(alpha: 0.15) : Colors.black.withValues(alpha: 0.08);
      final accentIconColor = isDark ? const Color(0xFFFFB3AD) : const Color(0xFFAC0017);

      return Positioned(
        top: MediaQuery.of(context).padding.top + 8,
        left: 20,
        right: 20,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: barBg,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: barBorder,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
                    blurRadius: 40,
                    offset: const Offset(0, 20),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Builder(
                    builder: (context) => IconButton(
                      icon: Icon(Icons.menu, color: accentIconColor),
                      onPressed: () => Scaffold.of(context).openDrawer(),
                    ),
                  ),
                  Image.network(
                    'https://lh3.googleusercontent.com/aida-public/AB6AXuATkXAerVPsE2m4hfUiQnl2Y9rqFfI7Ps4kylZ4pKqTsLdljqPy3P98NcAsZSxf5IhL9PT0EuZTt6uWZCyEwE_d0EleeKeYd7eOti54uHUm05djF0vMkj200IOm-HymlHKOB1bF3OJNLf_BwQHd8Xi08O5wdJgwONmRr9t7QwTuRiigzmxj8wDxdOTExQV5qztVYJNP5jaE-OQsRnV5_zkiTrVLmwvYv0XeIEm_LEo0hkxVXoQTGx_frjCjDWomYU7yXM8',
                    height: 32,
                    errorBuilder: (context, error, stackTrace) => Text(
                      'Frisby',
                      style: GoogleFonts.sora(
                        color: accentIconColor,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Stack(
                        children: [
                          IconButton(
                            icon: Icon(Icons.notifications, color: accentIconColor),
                            onPressed: () {
                              _showNotificationDialog(
                                'Alertas Recientes',
                                'Revisa tus turnos aprobados para la jornada de esta semana en tu historial.',
                                'Actualizado hace 2 horas',
                                true,
                                isDark,
                              );
                            },
                          ),
                          Positioned(
                            right: 12,
                            top: 12,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Color(0xFFBA1A1A),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // Active tab body content
    Widget activeTabContent() {
      switch (_currentIndex) {
        case 0:
          return isIOS ? _buildHomeTabIOS(isDark) : _buildHomeTabAndroid(isDark);
        case 1:
          return isIOS ? _buildCalendarTabIOS(isDark) : _buildCalendarTabAndroid(isDark);
        case 2:
          return _buildMarketTab(isIOS, isDark);
        case 3:
          return _buildProfileTab(isIOS, isDark);
        default:
          return isIOS ? _buildHomeTabIOS(isDark) : _buildHomeTabAndroid(isDark);
      }
    }

    // Android/Web solid bottom nav bar
    Widget bottomNavBarAndroid() {
      final navBgColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
      final borderSide = BorderSide(
        color: isDark ? Colors.white12 : Colors.grey[200]!,
        width: 1,
      );

      return Container(
        decoration: BoxDecoration(
          color: navBgColor,
          border: Border(
            top: borderSide,
          ),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 64,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItemAndroid(0, Icons.home, 'Inicio', isDark),
                _buildNavItemAndroid(1, Icons.calendar_month, 'Calendario', isDark),
                _buildNavItemAndroid(2, Icons.storefront, 'Mercado', isDark),
                _buildNavItemAndroid(3, Icons.person, 'Perfil', isDark),
              ],
            ),
          ),
        ),
      );
    }

    // iOS Floating Glassmorphic bottom nav bar
    Widget bottomNavBarIOS() {
      final barBg = isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.6);
      final barBorder = isDark ? Colors.white.withValues(alpha: 0.15) : Colors.black.withValues(alpha: 0.08);

      return SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                height: 68,
                decoration: BoxDecoration(
                  color: barBg,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: barBorder,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
                      blurRadius: 30,
                      offset: const Offset(0, -10),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildNavItemIOS(0, Icons.schedule, 'Shifts', isDark),
                    _buildNavItemIOS(1, Icons.calendar_month, 'Calendar', isDark),
                    _buildNavItemIOS(2, Icons.storefront, 'Market', isDark),
                    _buildNavItemIOS(3, Icons.person, 'Profile', isDark),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    // Outer layout builder
    Widget mainCanvas() {
      return Scaffold(
        backgroundColor: Colors.transparent, // Handled by outer body background decoration
        appBar: mobileAppBarAndroid(),
        drawer: _buildDrawer(isIOS, isDark),
        body: Stack(
          children: [
            // Tab content
            activeTabContent(),

            // Floating header for iOS
            if (isIOS) mobileAppBarIOS(),
            
            // Bottom navigation bar
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: isIOS ? bottomNavBarIOS() : bottomNavBarAndroid(),
            ),
          ],
        ),
      );
    }

    Widget innerAppContainer() {
      if (isIOS) {
        // Render with radial glow stack for iOS theme
        final iosGradStart = isDark ? const Color(0xFF1F0F0E) : const Color(0xFFFFF8F7);
        final iosGradEnd = isDark ? const Color(0xFF190A09) : const Color(0xFFF4F5F7);
        final radialColor1 = isDark 
            ? const Color(0xFFD2232A).withValues(alpha: 0.15) 
            : const Color(0xFFD2232A).withValues(alpha: 0.04);
        final radialColor2 = isDark 
            ? const Color(0xFFD2232A).withValues(alpha: 0.1) 
            : const Color(0xFFAC0017).withValues(alpha: 0.03);

        return Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: isDesktop ? BorderRadius.circular(40) : BorderRadius.zero,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                iosGradStart,
                iosGradEnd,
              ],
            ),
          ),
          child: Stack(
            children: [
              // Radial Glow 1 (Center-Left)
              Positioned(
                left: -150,
                top: 250,
                child: Container(
                  width: 350,
                  height: 350,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        radialColor1,
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              
              // Radial Glow 2 (Right-Top)
              Positioned(
                right: -100,
                top: 80,
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        radialColor2,
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              
              // The main canvas
              mainCanvas(),
            ],
          ),
        );
      } else {
        // Normal Android / Web container
        final androidBgColor = isDark ? const Color(0xFF121212) : const Color(0xFFF4F5F7);

        return Container(
          decoration: BoxDecoration(
            color: androidBgColor,
          ),
          child: mainCanvas(),
        );
      }
    }

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF4F5F7),
      body: innerAppContainer(),
    );
  }

  Widget _buildDesktopCollaboratorPortal(bool isDark) {
    final bg = isDark ? const Color(0xFF141414) : const Color(0xFFF6F7F9);
    final sidebarBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final borderColor = isDark ? Colors.white12 : const Color(0xFFE5E7EB);
    final titleColor = isDark ? Colors.white : const Color(0xFF111827);
    final subtextColor = isDark ? Colors.white60 : const Color(0xFF6B7280);
    final primaryRed = const Color(0xFFAC0017);

    final cleanUsername = widget.username.split('@')[0];

    Widget navItem({
      required int index,
      required IconData icon,
      required String title,
      VoidCallback? customTap,
    }) {
      final isActive = _currentIndex == index && customTap == null;
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
        child: InkWell(
          onTap: customTap ?? () => setState(() => _currentIndex = index),
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isActive ? primaryRed.withValues(alpha: isDark ? 0.25 : 0.12) : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: isActive ? primaryRed : (isDark ? Colors.white70 : const Color(0xFF4B5563)),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 14,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                    color: isActive ? primaryRed : (isDark ? Colors.white : const Color(0xFF1F2937)),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    Widget sectionTitle(String text) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 6),
        child: Text(
          text,
          style: GoogleFonts.hankenGrotesk(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.1,
            color: subtextColor,
          ),
        ),
      );
    }

    Widget activeContent() {
      switch (_currentIndex) {
        case 0:
          return _buildHomeTabAndroid(isDark);
        case 1:
          return _buildCalendarTabAndroid(isDark);
        case 2:
          return _buildMarketTab(false, isDark);
        case 3:
          return _buildProfileTab(false, isDark);
        default:
          return _buildHomeTabAndroid(isDark);
      }
    }

    return Scaffold(
      backgroundColor: bg,
      body: Row(
        children: [
          // 1. LEFT SIDEBAR (260px)
          Container(
            width: 260,
            decoration: BoxDecoration(
              color: sidebarBg,
              border: Border(right: BorderSide(color: borderColor)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Brand Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: borderColor)),
                  ),
                  child: Row(
                    children: [
                      Image.network(
                        'https://lh3.googleusercontent.com/aida-public/AB6AXuATkXAerVPsE2m4hfUiQnl2Y9rqFfI7Ps4kylZ4pKqTsLdljqPy3P98NcAsZSxf5IhL9PT0EuZTt6uWZCyEwE_d0EleeKeYd7eOti54uHUm05djF0vMkj200IOm-HymlHKOB1bF3OJNLf_BwQHd8Xi08O5wdJgwONmRr9t7QwTuRiigzmxj8wDxdOTExQV5qztVYJNP5jaE-OQsRnV5_zkiTrVLmwvYv0XeIEm_LEo0hkxVXoQTGx_frjCjDWomYU7yXM8',
                        height: 28,
                        errorBuilder: (c, e, s) => Text(
                          'Frisby',
                          style: GoogleFonts.sora(fontSize: 22, fontWeight: FontWeight.bold, color: primaryRed),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: primaryRed.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'COLABORADOR',
                          style: GoogleFonts.hankenGrotesk(fontSize: 10, fontWeight: FontWeight.bold, color: primaryRed),
                        ),
                      ),
                    ],
                  ),
                ),

                // Store badge
                Container(
                  margin: const EdgeInsets.all(12),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white10 : const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: borderColor),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.storefront, size: 18, color: Color(0xFFAC0017)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Frisby Parque Arboleda',
                              style: GoogleFonts.hankenGrotesk(fontSize: 12, fontWeight: FontWeight.w600, color: titleColor),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'Estación: Freidoras',
                              style: GoogleFonts.hankenGrotesk(fontSize: 11, color: subtextColor),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Navigation Items
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      sectionTitle('MI JORNADA'),
                      navItem(index: 0, icon: Icons.home_outlined, title: 'Inicio / Mi Turno'),
                      navItem(index: 1, icon: Icons.calendar_month_outlined, title: 'Mi Calendario'),
                      navItem(index: 2, icon: Icons.swap_horiz_outlined, title: 'Mercado de Turnos'),
                      navItem(index: 3, icon: Icons.person_outline, title: 'Mi Perfil y Horas'),

                      sectionTitle('ACCIONES RÁPIDAS'),
                      navItem(
                        index: 99,
                        icon: Icons.gavel_outlined,
                        title: 'Políticas de Cambios',
                        customTap: () => _showChangePolicyDialog(false, isDark),
                      ),
                      navItem(
                        index: 99,
                        icon: Icons.support_agent,
                        title: 'Soporte Técnico',
                        customTap: () => _showSupportDialog(false, isDark),
                      ),

                      sectionTitle('SISTEMA'),
                      navItem(
                        index: 99,
                        icon: Icons.palette_outlined,
                        title: isDark ? 'Modo Claro' : 'Modo Oscuro',
                        customTap: _toggleTheme,
                      ),
                    ],
                  ),
                ),

                // User Profile footer
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border(top: BorderSide(color: borderColor)),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: primaryRed.withValues(alpha: 0.12),
                        child: Text(
                          cleanUsername.length >= 2 ? cleanUsername.substring(0, 2).toUpperCase() : 'CO',
                          style: GoogleFonts.hankenGrotesk(fontSize: 11, fontWeight: FontWeight.bold, color: primaryRed),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              cleanUsername,
                              style: GoogleFonts.hankenGrotesk(fontWeight: FontWeight.bold, fontSize: 13, color: titleColor),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text('Colaborador Activo', style: GoogleFonts.hankenGrotesk(fontSize: 11, color: subtextColor)),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.logout, size: 18, color: Color(0xFFBA1A1A)),
                        onPressed: _logout,
                        tooltip: 'Cerrar Sesión',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 2. MAIN DESKTOP CONTENT AREA
          Expanded(
            child: Column(
              children: [
                // Top App Bar Header
                Container(
                  height: 64,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  decoration: BoxDecoration(
                    color: sidebarBg,
                    border: Border(bottom: BorderSide(color: borderColor)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Breadcrumb
                      Row(
                        children: [
                          Text('Frisby', style: GoogleFonts.hankenGrotesk(fontSize: 13, color: subtextColor)),
                          const SizedBox(width: 6),
                          const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
                          const SizedBox(width: 6),
                          Text(
                            _currentIndex == 0
                                ? 'Inicio y Mi Turno'
                                : (_currentIndex == 1
                                    ? 'Mi Calendario'
                                    : (_currentIndex == 2 ? 'Mercado de Turnos' : 'Mi Perfil')),
                            style: GoogleFonts.hankenGrotesk(fontSize: 13, fontWeight: FontWeight.bold, color: titleColor),
                          ),
                        ],
                      ),

                      // Right Header Actions
                      Row(
                        children: [
                          // Clock
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white10 : const Color(0xFFF3F4F6),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.schedule, size: 14, color: Color(0xFFAC0017)),
                                const SizedBox(width: 6),
                                Text(
                                  _getCurrentDateString(),
                                  style: GoogleFonts.hankenGrotesk(fontSize: 12, fontWeight: FontWeight.w500, color: titleColor),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: Icon(isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined, color: titleColor),
                            onPressed: _toggleTheme,
                            tooltip: 'Cambiar Tema',
                          ),
                          IconButton(
                            icon: const Icon(Icons.notifications_outlined, color: Color(0xFFAC0017)),
                            onPressed: () {
                              _showNotificationDialog(
                                'Alertas Recientes',
                                'Revisa tus turnos aprobados para la jornada de esta semana en tu historial.',
                                'Actualizado hace 2 horas',
                                false,
                                isDark,
                              );
                            },
                            tooltip: 'Notificaciones',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Main Scrollable Canvas with responsive bounds
                Expanded(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1100),
                      child: activeContent(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Nav Item Builder for Android/Web (Solid style with active pill background)
  Widget _buildNavItemAndroid(int index, IconData icon, String label, bool isDark) {
    final isActive = _currentIndex == index;
    final activeColor = isDark ? const Color(0xFFFFB3AD) : const Color(0xFFAC0017);
    final inactiveColor = isDark ? const Color(0xFFC6C6C7) : const Color(0xFF545D80);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => setState(() => _currentIndex = index),
        child: SizedBox(
          width: 80,
          height: 64,
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (isActive)
                Positioned(
                  top: 8,
                  child: Container(
                    width: 48,
                    height: 28,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD2232A).withValues(alpha: isDark ? 0.25 : 0.20),
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    color: isActive ? activeColor : inactiveColor,
                    size: 22,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: GoogleFonts.hankenGrotesk(
                      fontSize: 11,
                      fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                      color: isActive ? activeColor : inactiveColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Nav Item Builder for iOS (Floating style without active pill, only changes color/scale)
  Widget _buildNavItemIOS(int index, IconData icon, String label, bool isDark) {
    final isActive = _currentIndex == index;
    final activeColor = isDark ? const Color(0xFFFFB3AD) : const Color(0xFFAC0017);
    final inactiveColor = isDark 
        ? const Color(0xFFE5BDBA).withValues(alpha: 0.6) 
        : const Color(0xFF5C403D).withValues(alpha: 0.6);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => setState(() => _currentIndex = index),
        child: SizedBox(
          width: 75,
          height: 68,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isActive ? activeColor : inactiveColor,
                size: isActive ? 24 : 22,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 11,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  color: isActive ? activeColor : inactiveColor,
                  letterSpacing: 0.02,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
