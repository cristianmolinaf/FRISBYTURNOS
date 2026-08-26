import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'google_fonts_wrapper.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login_page.dart';

class AdminDashboardPage extends StatefulWidget {
  final String username;
  final String? profileName;
  final String? role;

  const AdminDashboardPage({
    super.key,
    required this.username,
    this.profileName,
    this.role,
  });

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  int _currentIndex = 0;

  // Real-time / Mock data for Admin Operations
  final int _activeEmployees = 24;
  int _pendingAbsences = 2;
  final double _coveragePercentage = 0.85;

  final List<Map<String, dynamic>> _pendingRequests = [
    {
      'id': 'req-1',
      'name': 'María Gómez',
      'type': 'Cambio de turno',
      'typeKey': 'cambio',
      'icon': Icons.swap_horiz,
      'time': 'Hace 2h',
      'avatar':
          'https://lh3.googleusercontent.com/aida-public/AB6AXuBNY0vcgDJNmdb9NZ6AH_zOekOlaUC4PMOwi2TWudtjoqVSymtElDz8RZ48dIRBk1I-Jk4oT72ucqI9I5p4VZYV2IquJdzqWeUjGVX3sor_r4TWeag7j-Iu3IW17JjJjlA3miDuuUK0DyJXIlWIvQE4HjrBhVKJ_TN9QQnmylHmNs1bwlifFbuQWiCdNlb04K1YupZ5oiXA99431dOkIUBvkfn-EYGjZX_uSzDLYQ3TulWLIuifQ4YrVA',
      'details': 'Solicita ceder turno de Freidoras (08:00 - 16:00) a Laura Morales.',
      'status': 'pendiente',
    },
    {
      'id': 'req-2',
      'name': 'Carlos Ruiz',
      'type': 'Permiso médico',
      'typeKey': 'permiso',
      'icon': Icons.medical_services_outlined,
      'time': 'Hace 4h',
      'avatar':
          'https://lh3.googleusercontent.com/aida-public/AB6AXuCIHDgQ7NsN4YIAqdqt1jAnGNQPzGH3diy_zs-wT5c6rqderXgGYClNBff8SQPYnHcOykCxKY6CqA5qErolIOT-lQEbu0WXK4DQVChrvdsfOgaQ6RdXwT8vcVFy16XnOQrEZSmze0mTKzib4TiV24TGVdn5Eb9Qx817ccP5uxkft6_i8gcCePhXF2MnoHiAjgchwWs_Btwjq3xdOHajQB0F99k5zOuour4yncwohz0szSv3OjLyfJlN_w',
      'details': 'Cita médica odontológica programada para mañana a las 10:00 AM.',
      'status': 'pendiente',
    },
    {
      'id': 'req-3',
      'name': 'Juan Pérez',
      'type': 'Calamidad doméstica',
      'typeKey': 'permiso',
      'icon': Icons.home_repair_service_outlined,
      'time': 'Hace 5h',
      'avatar':
          'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150',
      'details': 'Reparación urgente de tubería en vivienda familiar.',
      'status': 'pendiente',
    },
  ];

  List<Map<String, dynamic>> _teamMembers = [
    {
      'name': 'María Gómez',
      'cedula': '10002',
      'station': 'Freidoras',
      'team': 'Cocina A',
      'status': 'En turno',
      'shift': '08:00 - 16:00',
    },
    {
      'name': 'Carlos Ruiz',
      'cedula': '10003',
      'station': 'Plancha',
      'team': 'Cocina A',
      'status': 'En turno',
      'shift': '14:00 - 22:00',
    },
    {
      'name': 'Laura Morales',
      'cedula': '10004',
      'station': 'Caja',
      'team': 'Servicio',
      'status': 'Descanso',
      'shift': 'Libre',
    },
    {
      'name': 'Juan Pérez',
      'cedula': '10005',
      'station': 'Armado',
      'team': 'Cocina B',
      'status': 'Próximo',
      'shift': '16:00 - 00:00',
    },
    {
      'name': 'Andrés Castro',
      'cedula': '10006',
      'station': 'Domicilios',
      'team': 'Logística',
      'status': 'En turno',
      'shift': '11:00 - 19:00',
    },
  ];

  @override
  void initState() {
    super.initState();
    _fetchSupabaseData();
  }

  Future<void> _fetchSupabaseData() async {
    try {
      final supabase = Supabase.instance.client;
      final perfilesResponse = await supabase.from('perfiles').select();
      if (perfilesResponse.isNotEmpty && mounted) {
        setState(() {
          _teamMembers = (perfilesResponse as List).map((p) {
            return {
              'name': p['nombre'] ?? 'Colaborador',
              'cedula': p['cedula'] ?? '',
              'station': p['estacion_principal'] ?? 'General',
              'team': p['equipo'] ?? 'Operaciones',
              'status': p['rol'] == 'administrador' ? 'Admin' : 'Activo',
              'shift': '08:00 - 16:00',
            };
          }).toList();
        });
      }
    } catch (_) {}
  }

  bool _isDarkMode(BuildContext context) {
    return MediaQuery.of(context).platformBrightness == Brightness.dark;
  }

  void _handleSignOut() async {
    try {
      await Supabase.instance.client.auth.signOut();
    } catch (_) {}

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    }
  }

  void _handleApproveRequest(Map<String, dynamic> request) {
    setState(() {
      _pendingRequests.removeWhere((r) => r['id'] == request['id']);
      if (request['typeKey'] == 'permiso') {
        if (_pendingAbsences > 0) _pendingAbsences--;
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Solicitud de ${request['name']} aprobada exitosamente.',
          style: GoogleFonts.hankenGrotesk(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF2E7D32),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _handleRejectRequest(Map<String, dynamic> request) {
    setState(() {
      _pendingRequests.removeWhere((r) => r['id'] == request['id']);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Solicitud de ${request['name']} rechazada.',
          style: GoogleFonts.hankenGrotesk(color: Colors.white),
        ),
        backgroundColor: const Color(0xFFBA1A1A),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showCreateShiftModal(bool isIOS, bool isDark) {
    String selectedEmployee = _teamMembers.first['name'];
    String selectedStation = 'Plancha';
    String shiftTime = '08:00 - 16:00';

    final modalBg = isIOS ? Colors.white : (isDark ? const Color(0xFF1E1E1E) : Colors.white);
    final titleColor = isIOS ? const Color(0xFF1A1A1A) : (isDark ? Colors.white : const Color(0xFF191C1E));
    final labelColor = isIOS ? const Color(0xFF757575) : (isDark ? Colors.white70 : Colors.grey[700]);
    final fieldFill = isIOS ? const Color(0xFFF9F9F9) : (isDark ? Colors.white10 : Colors.grey[100]);
    final primaryBtnColor = const Color(0xFFC8102E);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: modalBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(
              24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Crear Nuevo Turno',
                    style: GoogleFonts.hankenGrotesk(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: titleColor,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: titleColor),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Colaborador',
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: labelColor,
                ),
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                initialValue: selectedEmployee,
                dropdownColor: modalBg,
                style: GoogleFonts.hankenGrotesk(color: titleColor),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: fieldFill,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(isIOS ? 12 : 12),
                    borderSide: isIOS ? const BorderSide(color: Color(0xFFE0E0E0)) : BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(isIOS ? 12 : 12),
                    borderSide: isIOS ? const BorderSide(color: Color(0xFFE0E0E0)) : BorderSide.none,
                  ),
                ),
                items: _teamMembers
                    .map((m) => DropdownMenuItem<String>(
                          value: m['name'] as String,
                          child: Text(m['name'] as String),
                        ))
                    .toList(),
                onChanged: (val) {
                  if (val != null) setModalState(() => selectedEmployee = val);
                },
              ),
              const SizedBox(height: 16),
              Text(
                'Estación Asignada',
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: labelColor,
                ),
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                initialValue: selectedStation,
                dropdownColor: modalBg,
                style: GoogleFonts.hankenGrotesk(color: titleColor),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: fieldFill,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: isIOS ? const BorderSide(color: Color(0xFFE0E0E0)) : BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: isIOS ? const BorderSide(color: Color(0xFFE0E0E0)) : BorderSide.none,
                  ),
                ),
                items: ['Plancha', 'Freidoras', 'Caja', 'Armado', 'Domicilios']
                    .map((s) => DropdownMenuItem<String>(
                          value: s,
                          child: Text(s),
                        ))
                    .toList(),
                onChanged: (val) {
                  if (val != null) setModalState(() => selectedStation = val);
                },
              ),
              const SizedBox(height: 16),
              Text(
                'Horario',
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: labelColor,
                ),
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                initialValue: shiftTime,
                dropdownColor: modalBg,
                style: GoogleFonts.hankenGrotesk(color: titleColor),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: fieldFill,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: isIOS ? const BorderSide(color: Color(0xFFE0E0E0)) : BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: isIOS ? const BorderSide(color: Color(0xFFE0E0E0)) : BorderSide.none,
                  ),
                ),
                items: [
                  '08:00 - 16:00 (Apertura)',
                  '11:00 - 19:00 (Intermedio)',
                  '14:00 - 22:00 (Cierre)',
                  '16:00 - 00:00 (Noche)'
                ].map((s) {
                  final parts = s.split(' ');
                  final timeVal = '${parts[0]} - ${parts[2]}';
                  return DropdownMenuItem<String>(
                    value: timeVal,
                    child: Text(s),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setModalState(() => shiftTime = val);
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Turno creado para $selectedEmployee ($selectedStation, $shiftTime)',
                          style: GoogleFonts.hankenGrotesk(color: Colors.white),
                        ),
                        backgroundColor: primaryBtnColor,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBtnColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  child: Text(
                    'Confirmar y Guardar Turno',
                    style: GoogleFonts.hankenGrotesk(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAssignStationModal(bool isIOS, bool isDark) {
    String selectedEmployee = _teamMembers.first['name'];
    String selectedStation = 'Freidoras';

    final modalBg = isIOS ? Colors.white : (isDark ? const Color(0xFF1E1E1E) : Colors.white);
    final titleColor = isIOS ? const Color(0xFF1A1A1A) : (isDark ? Colors.white : const Color(0xFF191C1E));
    final fieldFill = isIOS ? const Color(0xFFF9F9F9) : (isDark ? Colors.white10 : Colors.grey[100]);
    final secondaryBtnColor = const Color(0xFF0B1B3D);

    showModalBottomSheet(
      context: context,
      backgroundColor: modalBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Reasignar Estación de Trabajo',
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: titleColor,
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: selectedEmployee,
                dropdownColor: modalBg,
                style: GoogleFonts.hankenGrotesk(color: titleColor),
                decoration: InputDecoration(
                  labelText: 'Seleccionar Colaborador',
                  labelStyle: GoogleFonts.hankenGrotesk(color: const Color(0xFF757575)),
                  filled: true,
                  fillColor: fieldFill,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: isIOS ? const BorderSide(color: Color(0xFFE0E0E0)) : BorderSide.none,
                  ),
                ),
                items: _teamMembers
                    .map((m) => DropdownMenuItem<String>(
                          value: m['name'] as String,
                          child: Text(m['name'] as String),
                        ))
                    .toList(),
                onChanged: (val) {
                  if (val != null) setModalState(() => selectedEmployee = val);
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: selectedStation,
                dropdownColor: modalBg,
                style: GoogleFonts.hankenGrotesk(color: titleColor),
                decoration: InputDecoration(
                  labelText: 'Nueva Estación',
                  labelStyle: GoogleFonts.hankenGrotesk(color: const Color(0xFF757575)),
                  filled: true,
                  fillColor: fieldFill,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: isIOS ? const BorderSide(color: Color(0xFFE0E0E0)) : BorderSide.none,
                  ),
                ),
                items: ['Freidoras', 'Plancha', 'Caja', 'Armado', 'Domicilios']
                    .map((s) => DropdownMenuItem<String>(
                          value: s,
                          child: Text(s),
                        ))
                    .toList(),
                onChanged: (val) {
                  if (val != null) setModalState(() => selectedStation = val);
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      final idx = _teamMembers
                          .indexWhere((m) => m['name'] == selectedEmployee);
                      if (idx != -1) {
                        _teamMembers[idx]['station'] = selectedStation;
                      }
                    });
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          '$selectedEmployee asignado(a) a $selectedStation',
                          style: GoogleFonts.hankenGrotesk(color: Colors.white),
                        ),
                        backgroundColor: secondaryBtnColor,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: secondaryBtnColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  child: Text(
                    'Guardar Asignación',
                    style: GoogleFonts.hankenGrotesk(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showBroadcastNoticeModal(bool isIOS, bool isDark) {
    final controller = TextEditingController();
    final modalBg = isIOS ? Colors.white : (isDark ? const Color(0xFF1E1E1E) : Colors.white);
    final titleColor = isIOS ? const Color(0xFF1A1A1A) : (isDark ? Colors.white : const Color(0xFF191C1E));
    final fieldFill = isIOS ? const Color(0xFFF9F9F9) : (isDark ? Colors.white10 : Colors.grey[100]);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: modalBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
            24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enviar Aviso General al Equipo',
              style: GoogleFonts.hankenGrotesk(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: titleColor,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              maxLines: 4,
              style: GoogleFonts.hankenGrotesk(color: titleColor),
              decoration: InputDecoration(
                hintText: 'Escribe el mensaje o aviso para la sucursal...',
                hintStyle: GoogleFonts.hankenGrotesk(
                  color: isIOS ? const Color(0xFF757575) : (isDark ? Colors.white38 : Colors.grey[400]),
                ),
                filled: true,
                fillColor: fieldFill,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: isIOS ? const BorderSide(color: Color(0xFFE0E0E0)) : BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () {
                  final msg = controller.text.trim();
                  Navigator.pop(context);
                  if (msg.isNotEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Aviso enviado a todos los colaboradores del restaurante.',
                          style: GoogleFonts.hankenGrotesk(color: Colors.white),
                        ),
                        backgroundColor: const Color(0xFFC8102E),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFC8102E),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                icon: const Icon(Icons.send, size: 18),
                label: Text(
                  'Difundir Notificación',
                  style: GoogleFonts.hankenGrotesk(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // TAB 0: RESUMEN OPERATIVO + ACCIONES RÁPIDAS + SOLICITUDES
  Widget _buildTurnosTab(bool isIOS, bool isDark) {
    // iOS Design Tokens (Flat White / Light theme)
    final titleColor = isIOS ? const Color(0xFF1A1A1A) : (isDark ? const Color(0xFFE1E2E4) : const Color(0xFF191C1E));
    final subtextColor = isIOS ? const Color(0xFF757575) : (isDark ? Colors.white60 : const Color(0xFF5C403D));
    final cardBgColor = isIOS ? Colors.white : (isDark ? const Color(0xFF1E1E1E) : Colors.white);
    final cardRadius = BorderRadius.circular(isIOS ? 14 : 16);
    final cardBorder = isIOS 
        ? Border.all(color: const Color(0xFFE0E0E0), width: 0.8) 
        : (isDark ? Border.all(color: Colors.white12) : null);
    final cardShadow = [
      BoxShadow(
        color: isIOS ? Colors.black.withValues(alpha: 0.04) : Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
        blurRadius: isIOS ? 16 : 16,
        offset: const Offset(0, 4),
      ),
    ];
    final primaryRed = const Color(0xFFC8102E);
    final secondaryNavy = const Color(0xFF0B1B3D);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      children: [
        // Section 1: Resumen Operativo (Bento Grid)
        Text(
          'Resumen Operativo',
          style: GoogleFonts.hankenGrotesk(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: titleColor,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Active employees card
            Expanded(
              child: Container(
                height: 160,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardBgColor,
                  borderRadius: cardRadius,
                  border: cardBorder,
                  boxShadow: cardShadow,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Icon(Icons.group, color: primaryRed, size: 26),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isIOS
                                ? const Color(0xFFF0F1F5)
                                : (isDark ? Colors.white10 : const Color(0xFFEDEFE0)),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Turno Actual',
                            style: GoogleFonts.hankenGrotesk(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: isIOS ? secondaryNavy : (isDark ? Colors.white70 : const Color(0xFF5C403D)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$_activeEmployees',
                          style: GoogleFonts.hankenGrotesk(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: primaryRed,
                          ),
                        ),
                        Text(
                          'Empleados Activos',
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
            ),
            const SizedBox(width: 12),
            // Ausencias & Cobertura column
            Expanded(
              child: Column(
                children: [
                  Container(
                    height: 74,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: cardBgColor,
                      borderRadius: cardRadius,
                      border: cardBorder,
                      boxShadow: cardShadow,
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFBA1A1A).withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.warning_amber_rounded,
                              color: Color(0xFFBA1A1A), size: 18),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Ausencias',
                              style: GoogleFonts.hankenGrotesk(
                                fontSize: 11,
                                color: const Color(0xFFBA1A1A),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              '$_pendingAbsences Pendientes',
                              style: GoogleFonts.hankenGrotesk(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: titleColor,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    height: 74,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: cardBgColor,
                      borderRadius: cardRadius,
                      border: cardBorder,
                      boxShadow: cardShadow,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.schedule,
                                    color: secondaryNavy, size: 16),
                                const SizedBox(width: 4),
                                Text(
                                  'Cobertura',
                                  style: GoogleFonts.hankenGrotesk(
                                    fontSize: 11,
                                    color: subtextColor,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              '${(_coveragePercentage * 100).toInt()}%',
                              style: GoogleFonts.hankenGrotesk(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: primaryRed,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: _coveragePercentage,
                            minHeight: 6,
                            backgroundColor: const Color(0xFFE0E0E0),
                            valueColor: AlwaysStoppedAnimation<Color>(primaryRed),
                          ),
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

        // Section 2: Acciones Rápidas
        Text(
          'Acciones Rápidas',
          style: GoogleFonts.hankenGrotesk(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: titleColor,
          ),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildQuickActionBtn(
                icon: Icons.event_available,
                label: 'Crear\nTurno',
                color: primaryRed,
                isIOS: isIOS,
                isDark: isDark,
                onTap: () => _showCreateShiftModal(isIOS, isDark),
              ),
              const SizedBox(width: 12),
              _buildQuickActionBtn(
                icon: Icons.restaurant,
                label: 'Asignar\nEstación',
                color: secondaryNavy,
                isIOS: isIOS,
                isDark: isDark,
                onTap: () => _showAssignStationModal(isIOS, isDark),
              ),
              const SizedBox(width: 12),
              _buildQuickActionBtn(
                icon: Icons.campaign_outlined,
                label: 'Enviar\nAviso',
                color: const Color(0xFFB86000),
                isIOS: isIOS,
                isDark: isDark,
                onTap: () => _showBroadcastNoticeModal(isIOS, isDark),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Section 3: Solicitudes Pendientes
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Solicitudes Pendientes',
              style: GoogleFonts.hankenGrotesk(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: titleColor,
              ),
            ),
            if (_pendingRequests.isNotEmpty)
              TextButton(
                onPressed: () => setState(() => _currentIndex = 1),
                child: Text(
                  'Ver todas (${_pendingRequests.length})',
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: primaryRed,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (_pendingRequests.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: cardBgColor,
              borderRadius: cardRadius,
              border: cardBorder,
              boxShadow: cardShadow,
            ),
            child: Center(
              child: Text(
                '🎉 No hay solicitudes pendientes por revisar.',
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 14,
                  color: subtextColor,
                ),
              ),
            ),
          )
        else
          ..._pendingRequests.map((req) => _buildRequestCard(req, isIOS, isDark)),
      ],
    );
  }

  Widget _buildQuickActionBtn({
    required IconData icon,
    required String label,
    required Color color,
    required bool isIOS,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(isIOS ? 14 : 16),
      child: Container(
        width: 110,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: isIOS ? Colors.white : (isDark ? const Color(0xFF1E1E1E) : Colors.white),
          borderRadius: BorderRadius.circular(isIOS ? 14 : 16),
          border: isIOS ? Border.all(color: const Color(0xFFE0E0E0), width: 0.8) : (isDark ? Border.all(color: Colors.white12) : null),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isIOS ? 0.04 : (isDark ? 0.2 : 0.04)),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.hankenGrotesk(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isIOS ? const Color(0xFF1A1A1A) : (isDark ? Colors.white : const Color(0xFF191C1E)),
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestCard(Map<String, dynamic> req, bool isIOS, bool isDark) {
    final cardBgColor = isIOS ? Colors.white : (isDark ? const Color(0xFF1E1E1E) : Colors.white);
    final cardBorder = isIOS ? Border.all(color: const Color(0xFFE0E0E0), width: 0.8) : (isDark ? Border.all(color: Colors.white12) : null);
    final titleColor = isIOS ? const Color(0xFF1A1A1A) : (isDark ? const Color(0xFFE1E2E4) : const Color(0xFF191C1E));
    final subtextColor = isIOS ? const Color(0xFF757575) : (isDark ? Colors.white60 : Colors.grey[600]!);
    final primaryRed = const Color(0xFFC8102E);
    final secondaryNavy = const Color(0xFF0B1B3D);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(isIOS ? 14 : 16),
        border: cardBorder,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isIOS ? 0.04 : (isDark ? 0.2 : 0.04)),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundImage: NetworkImage(req['avatar']),
                    backgroundColor: const Color(0xFFF0F1F5),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        req['name'],
                        style: GoogleFonts.hankenGrotesk(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: titleColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(req['icon'] as IconData,
                              size: 14, color: isIOS ? secondaryNavy : const Color(0xFF545D80)),
                          const SizedBox(width: 4),
                          Text(
                            req['type'],
                            style: GoogleFonts.hankenGrotesk(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: isIOS ? secondaryNavy : const Color(0xFF545D80),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              Text(
                req['time'],
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 11,
                  color: subtextColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            req['details'],
            style: GoogleFonts.hankenGrotesk(
              fontSize: 13,
              color: isIOS ? const Color(0xFF1A1A1A) : (isDark ? Colors.white70 : Colors.black87),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 38,
                  child: ElevatedButton(
                    onPressed: () => _handleRejectRequest(req),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isIOS ? const Color(0xFF0B1B3D) : const Color(0xFF545D80),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    child: Text(
                      'Rechazar',
                      style: GoogleFonts.hankenGrotesk(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 38,
                  child: ElevatedButton(
                    onPressed: () => _handleApproveRequest(req),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryRed,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    child: Text(
                      'Aprobar',
                      style: GoogleFonts.hankenGrotesk(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // TAB 1: CAMBIOS DE TURNO (MERCADO)
  Widget _buildCambiosTab(bool isIOS, bool isDark) {
    final titleColor = isIOS ? const Color(0xFF1A1A1A) : (isDark ? const Color(0xFFE1E2E4) : const Color(0xFF191C1E));
    final subtextColor = isIOS ? const Color(0xFF757575) : (isDark ? Colors.white60 : Colors.grey[600]!);
    final cambios = _pendingRequests.where((r) => r['typeKey'] == 'cambio').toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      children: [
        Text(
          'Intercambio de Turnos',
          style: GoogleFonts.hankenGrotesk(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: titleColor,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Revisa y aprueba solicitudes entre colaboradores del restaurante',
          style: GoogleFonts.hankenGrotesk(
            fontSize: 13,
            color: subtextColor,
          ),
        ),
        const SizedBox(height: 20),
        if (cambios.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: isIOS ? Colors.white : (isDark ? const Color(0xFF1E1E1E) : Colors.white),
              borderRadius: BorderRadius.circular(isIOS ? 14 : 16),
              border: isIOS ? Border.all(color: const Color(0xFFE0E0E0), width: 0.8) : null,
            ),
            child: Column(
              children: [
                const Icon(Icons.check_circle_outline,
                    color: Color(0xFF2E7D32), size: 48),
                const SizedBox(height: 12),
                Text(
                  'Al día',
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: titleColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'No hay solicitudes de intercambio de turnos pendientes.',
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 13,
                    color: subtextColor,
                  ),
                ),
              ],
            ),
          )
        else
          ...cambios.map((req) => _buildRequestCard(req, isIOS, isDark)),
      ],
    );
  }

  // TAB 2: PERMISOS Y NOVEDADES
  Widget _buildPermisosTab(bool isIOS, bool isDark) {
    final titleColor = isIOS ? const Color(0xFF1A1A1A) : (isDark ? const Color(0xFFE1E2E4) : const Color(0xFF191C1E));
    final subtextColor = isIOS ? const Color(0xFF757575) : (isDark ? Colors.white60 : Colors.grey[600]!);
    final permisos = _pendingRequests.where((r) => r['typeKey'] == 'permiso').toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      children: [
        Text(
          'Permisos y Novedades Médicas',
          style: GoogleFonts.hankenGrotesk(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: titleColor,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Gestiona incapacidades, citas médicas y calamidades del equipo',
          style: GoogleFonts.hankenGrotesk(
            fontSize: 13,
            color: subtextColor,
          ),
        ),
        const SizedBox(height: 20),
        if (permisos.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: isIOS ? Colors.white : (isDark ? const Color(0xFF1E1E1E) : Colors.white),
              borderRadius: BorderRadius.circular(isIOS ? 14 : 16),
              border: isIOS ? Border.all(color: const Color(0xFFE0E0E0), width: 0.8) : null,
            ),
            child: Column(
              children: [
                const Icon(Icons.health_and_safety_outlined,
                    color: Color(0xFF2E7D32), size: 48),
                const SizedBox(height: 12),
                Text(
                  'Sin Novedades Pendientes',
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: titleColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Todas las ausencias y permisos médicos han sido procesados.',
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 13,
                    color: subtextColor,
                  ),
                ),
              ],
            ),
          )
        else
          ...permisos.map((req) => _buildRequestCard(req, isIOS, isDark)),
      ],
    );
  }

  // TAB 3: EQUIPO Y ESTACIONES
  Widget _buildEquipoTab(bool isIOS, bool isDark) {
    final titleColor = isIOS ? const Color(0xFF1A1A1A) : (isDark ? const Color(0xFFE1E2E4) : const Color(0xFF191C1E));
    final subtextColor = isIOS ? const Color(0xFF757575) : (isDark ? Colors.white60 : Colors.grey[600]!);
    final cardBgColor = isIOS ? Colors.white : (isDark ? const Color(0xFF1E1E1E) : Colors.white);
    final primaryRed = const Color(0xFFC8102E);
    final secondaryNavy = const Color(0xFF0B1B3D);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Equipo de Restaurante',
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: titleColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_teamMembers.length} Colaboradores Registrados',
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 13,
                    color: subtextColor,
                  ),
                ),
              ],
            ),
            IconButton(
              onPressed: () => _showCreateShiftModal(isIOS, isDark),
              icon: Icon(Icons.person_add_alt_1_outlined, color: primaryRed),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ..._teamMembers.map((member) {
          final isWorking = member['status'] == 'En turno' || member['status'] == 'Admin';
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardBgColor,
              borderRadius: BorderRadius.circular(isIOS ? 14 : 16),
              border: isIOS ? Border.all(color: const Color(0xFFE0E0E0), width: 0.8) : (isDark ? Border.all(color: Colors.white12) : null),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isIOS ? 0.04 : (isDark ? 0.2 : 0.04)),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: primaryRed.withValues(alpha: 0.12),
                  child: Text(
                    member['name'].substring(0, 2).toUpperCase(),
                    style: GoogleFonts.hankenGrotesk(
                      fontWeight: FontWeight.bold,
                      color: primaryRed,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        member['name'],
                        style: GoogleFonts.hankenGrotesk(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: titleColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: secondaryNavy.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              member['station'],
                              style: GoogleFonts.hankenGrotesk(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: secondaryNavy,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            member['shift'],
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
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isWorking
                        ? const Color(0xFFE8F5E9)
                        : const Color(0xFFFFF3E0),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    member['status'],
                    style: GoogleFonts.hankenGrotesk(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isWorking ? const Color(0xFF2E7D32) : const Color(0xFFE65100),
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isIOS = defaultTargetPlatform == TargetPlatform.iOS;
    final isDark = !isIOS && _isDarkMode(context);
    final mediaQuery = MediaQuery.of(context);
    final isDesktop = mediaQuery.size.width > 480;

    // Colors matching user's iOS rules (Flat / White background / Frisby Red / Navy)
    final bgColor = isIOS ? const Color(0xFFF9F9F9) : (isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FB));
    final appBarBg = isIOS ? const Color(0xFFC8102E) : (isDark ? const Color(0xFF1F1F1F) : const Color(0xFFAC0017));
    final bottomNavBg = isIOS ? Colors.white : (isDark ? const Color(0xFF1E1E1E) : Colors.white);
    final bottomBorderColor = isIOS ? const Color(0xFFE0E0E0) : (isDark ? Colors.white12 : Colors.grey[200]!);

    Widget activeContent() {
      switch (_currentIndex) {
        case 0:
          return _buildTurnosTab(isIOS, isDark);
        case 1:
          return _buildCambiosTab(isIOS, isDark);
        case 2:
          return _buildPermisosTab(isIOS, isDark);
        case 3:
          return _buildEquipoTab(isIOS, isDark);
        default:
          return _buildTurnosTab(isIOS, isDark);
      }
    }

    Widget scaffoldContent() {
      return Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          backgroundColor: appBarBg,
          elevation: isIOS ? 0 : 2,
          centerTitle: true,
          title: Text(
            'Admin Frisby Turnos',
            style: GoogleFonts.hankenGrotesk(
              fontWeight: FontWeight.bold,
              color: Colors.white,
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
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: CircleAvatar(
                radius: 16,
                backgroundImage: const NetworkImage(
                  'https://lh3.googleusercontent.com/aida-public/AB6AXuDMgkhhPX8XzsxpqFFykCvHkvJhpP4XCWw8TmC9gw8HQzfAtsWnU96wdFRn0TK-k12jMCkVzTzRg0lknWMdZRkCC4i8mIDsHfKlEuL5tqs_8A2BYRdiwZQ885poamygDvFIbvHiCh1JwmgrzF1uBlqFLtnfKTOUJfIVusON856L9gf2pFxIlrSDTOd51irguRlRY0ayiE3q-SZMFV9NAIS_pcAy0hmQybPk9_XtRRRE1yD8xL30gQovmg',
                ),
              ),
            ),
          ],
        ),
        drawer: Drawer(
          backgroundColor: isIOS ? Colors.white : (isDark ? const Color(0xFF1E1E1E) : Colors.white),
          child: Column(
            children: [
              UserAccountsDrawerHeader(
                decoration: const BoxDecoration(
                  color: Color(0xFFC8102E),
                ),
                accountName: Text(
                  widget.profileName ?? 'Administrador General',
                  style: GoogleFonts.hankenGrotesk(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                accountEmail: Text(
                  '${widget.username} (Rol: Administrador)',
                  style: GoogleFonts.hankenGrotesk(fontSize: 12),
                ),
                currentAccountPicture: const CircleAvatar(
                  backgroundImage: NetworkImage(
                    'https://lh3.googleusercontent.com/aida-public/AB6AXuDMgkhhPX8XzsxpqFFykCvHkvJhpP4XCWw8TmC9gw8HQzfAtsWnU96wdFRn0TK-k12jMCkVzTzRg0lknWMdZRkCC4i8mIDsHfKlEuL5tqs_8A2BYRdiwZQ885poamygDvFIbvHiCh1JwmgrzF1uBlqFLtnfKTOUJfIVusON856L9gf2pFxIlrSDTOd51irguRlRY0ayiE3q-SZMFV9NAIS_pcAy0hmQybPk9_XtRRRE1yD8xL30gQovmg',
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.store, color: Color(0xFFC8102E)),
                title: Text(
                  'Sucursal: Parque Arboleda',
                  style: GoogleFonts.hankenGrotesk(
                    fontWeight: FontWeight.w600,
                    color: isIOS ? const Color(0xFF1A1A1A) : null,
                  ),
                ),
                subtitle: Text(
                  'Zona Eje Cafetero',
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 12,
                    color: isIOS ? const Color(0xFF757575) : null,
                  ),
                ),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.logout, color: Color(0xFFBA1A1A)),
                title: Text(
                  'Cerrar Sesión',
                  style: GoogleFonts.hankenGrotesk(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFBA1A1A),
                  ),
                ),
                onTap: _handleSignOut,
              ),
            ],
          ),
        ),
        body: activeContent(),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: bottomNavBg,
            border: Border(
              top: BorderSide(
                color: bottomBorderColor,
                width: isIOS ? 0.8 : 1,
              ),
            ),
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: 64,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavTab(0, Icons.event_note, 'Turnos', isIOS, isDark),
                  _buildNavTab(1, Icons.swap_horiz, 'Cambios', isIOS, isDark),
                  _buildNavTab(2, Icons.medical_services_outlined, 'Permisos', isIOS, isDark),
                  _buildNavTab(3, Icons.group_outlined, 'Equipo', isIOS, isDark),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return isDesktop
        ? Center(
            child: Container(
              width: 375,
              height: 812,
              decoration: BoxDecoration(
                color: isIOS ? Colors.white : (isDark ? const Color(0xFF1E1E1E) : Colors.white),
                borderRadius: BorderRadius.circular(40),
                border: Border.all(
                  color: isDark ? Colors.black26 : Colors.white,
                  width: 8,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: scaffoldContent(),
            ),
          )
        : scaffoldContent();
  }

  Widget _buildNavTab(int index, IconData icon, String label, bool isIOS, bool isDark) {
    final isActive = _currentIndex == index;
    final activeColor = isIOS ? const Color(0xFFC8102E) : (isDark ? const Color(0xFFFFB3AD) : const Color(0xFFAC0017));
    final inactiveColor = isIOS ? const Color(0xFF757575) : (isDark ? const Color(0xFFC6C6C7) : const Color(0xFF545D80));

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => setState(() => _currentIndex = index),
        child: SizedBox(
          width: 75,
          height: 64,
          child: Column(
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
        ),
      ),
    );
  }
}
