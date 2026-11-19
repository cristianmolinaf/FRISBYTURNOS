import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'google_fonts_wrapper.dart';
import 'models/models.dart';
import 'services/services.dart';
import 'widgets/frisby_weekly_schedule_sheet.dart';

class CreateShiftPage extends StatefulWidget {
  final String username;
  final String currentStore;
  final String? role;
  final List<Map<String, dynamic>> teamMembers;
  final Function(Map<String, dynamic> newShift)? onShiftCreated;
  final bool? forceIOS;

  const CreateShiftPage({
    super.key,
    this.username = 'admin@frisby.com',
    this.currentStore = 'Frisby Parque Arboleda',
    this.role = 'jefe_zona',
    this.teamMembers = const [],
    this.onShiftCreated,
    this.forceIOS,
  });

  @override
  State<CreateShiftPage> createState() => _CreateShiftPageState();
}

class _CreateShiftPageState extends State<CreateShiftPage> {
  bool? _isDarkModeOverride;

  // Selected Mode: 0 = Asignador Rápido, 1 = Auto-Programación & Plantillas, 2 = Malla Semanal DRO'001
  int _selectedMode = 0;

  // Active Store & Zone (Essential for Jefe de Zona & Super Admin)
  late String _activeStore;
  String _activeZone = 'Zona Eje Cafetero';

  // Available stores
  final List<String> _stores = [
    'Frisby Parque Arboleda',
    'Frisby Victoria Plaza',
    'Frisby Unicentro Pereira',
    'Frisby Av. Circunvalar',
    'Frisby Cerritos Mall',
  ];

  // Available zones (for Super Admin)
  final List<String> _zones = [
    'Zona Eje Cafetero',
    'Zona Antioquia',
    'Zona Bogotá Norte',
    'Zona Valle del Cauca',
  ];

  // Team members list with local hours tracking
  late List<Map<String, dynamic>> _collaborators;

  // Selection states
  final Set<int> _selectedCollaboratorIndices = {0};
  final Set<int> _selectedDays = {1, 2, 3, 4, 5}; // 1: Lun, 2: Mar, 3: Mié, 4: Jue, 5: Vie

  // Selected Shift Preset
  int _selectedPresetIndex = 0; // 0: Escribe Horario Personalizado (Primero por solicitud de usuario)
  String _overrideStation = 'Auto'; // 'Auto' or specific station

  // Controller for custom schedule input
  final TextEditingController _customHoursController =
      TextEditingController(text: '08:00 - 16:00');

  final Map<int, String> _dayNames = {
    1: 'Lunes',
    2: 'Martes',
    3: 'Miércoles',
    4: 'Jueves',
    5: 'Viernes',
    6: 'Sábado',
    7: 'Domingo',
  };

  // Turnos Service
  final TurnosService _turnosService = TurnosService();

  // Shift Presets definition: "Escribe Horario Personalizado" PRIMERO para los roles administrativos
  final List<Map<String, dynamic>> _shiftPresets = [
    {
      'title': 'Escribe Horario Personalizado',
      'hours': 'Escribe horario libre',
      'duration': 8.0,
      'icon': Icons.edit_calendar_rounded,
      'color': const Color(0xFFAC0017), // Frisby Red
      'desc': 'Escribe la hora exacta de entrada y salida',
      'isCustom': true,
    },
    {
      'title': 'Apertura',
      'hours': '08:00 - 16:00',
      'duration': 8.0,
      'icon': Icons.wb_sunny_outlined,
      'color': const Color(0xFF00C853), // Green
      'desc': 'Fritura, alistamiento y apertura',
      'isCustom': false,
    },
    {
      'title': 'Intermedio',
      'hours': '11:00 - 19:00',
      'duration': 8.0,
      'icon': Icons.wb_twilight_rounded,
      'color': const Color(0xFFFF9100), // Orange
      'desc': 'Refuerzo de almuerzo y plancha',
      'isCustom': false,
    },
    {
      'title': 'Tarde / Cierre',
      'hours': '14:00 - 22:00',
      'duration': 8.0,
      'icon': Icons.nights_stay_outlined,
      'color': const Color(0xFF2E66E5), // Blue
      'desc': 'Servicio noche, aseo y cierre POS',
      'isCustom': false,
    },
    {
      'title': 'Cierre Extendido',
      'hours': '16:00 - 00:00',
      'duration': 8.0,
      'icon': Icons.dark_mode_outlined,
      'color': const Color(0xFF7C4DFF), // Purple
      'desc': 'Fin de semana y eventos especiales',
      'isCustom': false,
    },
    {
      'title': 'Descanso (D)',
      'hours': 'Libre (☺)',
      'duration': 0.0,
      'icon': Icons.beach_access_rounded,
      'color': const Color(0xFF009688), // Teal
      'desc': 'Día libre rotativo compensatorio',
      'isCustom': false,
    },
  ];

  @override
  void dispose() {
    _customHoursController.dispose();
    super.dispose();
  }

  double _getCustomCalculatedHours() {
    final text = _customHoursController.text;
    final match = RegExp(
            r'(\d{1,2})(?::\d{2})?\s*[-–]\s*(\d{1,2})(?::\d{2})?')
        .firstMatch(text);
    if (match != null) {
      final start = int.tryParse(match.group(1)!) ?? 8;
      final end = int.tryParse(match.group(2)!) ?? 16;
      if (end > start) {
        return (end - start).toDouble();
      } else if (end < start) {
        return (24 - start + end).toDouble();
      }
    }
    return 8.0;
  }

  @override
  void initState() {
    super.initState();
    _activeStore = widget.currentStore;

    // Initialize team members with weekly hours calculated
    if (widget.teamMembers.isNotEmpty) {
      _collaborators = widget.teamMembers.map((m) {
        final copy = Map<String, dynamic>.from(m);
        copy['hoursAssigned'] = copy['hoursAssigned'] ?? 32.0;
        return copy;
      }).toList();
    } else {
      _collaborators = [
        {
          'name': 'María Gómez',
          'cedula': '10002',
          'station': 'Freidoras',
          'team': 'Cocina A',
          'status': 'En turno',
          'shift': '08:00 - 16:00',
          'hoursAssigned': 32.0,
          'skills': ['Freidoras', 'Armado', 'Plancha'],
        },
        {
          'name': 'Carlos Ruiz',
          'cedula': '10003',
          'station': 'Plancha',
          'team': 'Cocina A',
          'status': 'En turno',
          'shift': '14:00 - 22:00',
          'hoursAssigned': 24.0,
          'skills': ['Plancha', 'Freidoras'],
        },
        {
          'name': 'Laura Morales',
          'cedula': '10004',
          'station': 'Caja',
          'team': 'Servicio',
          'status': 'Descanso',
          'shift': 'Libre',
          'hoursAssigned': 16.0,
          'skills': ['Caja', 'Servicio'],
        },
        {
          'name': 'Andrés Felipe Castro',
          'cedula': '10005',
          'station': 'Armado y Empaque',
          'team': 'Operaciones',
          'status': 'En turno',
          'shift': '09:00 - 17:00',
          'hoursAssigned': 40.0,
          'skills': ['Armado y Empaque', 'Freidoras'],
        },
        {
          'name': 'Valentina Ríos',
          'cedula': '10006',
          'station': 'Servicio y Mesas',
          'team': 'Servicio',
          'status': 'Activo',
          'shift': '11:00 - 19:00',
          'hoursAssigned': 32.0,
          'skills': ['Servicio y Mesas', 'Caja'],
        },
      ];
    }
  }

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

  String _getRoleLabel() {
    final r = (widget.role ?? 'jefe_zona').toLowerCase();
    if (r.contains('super')) {
      return 'Super Admin Nacional';
    } else if (r.contains('jefe')) {
      return 'Jefe de Zona • Eje Cafetero';
    } else {
      return 'Administrador de Sucursal';
    }
  }

  IconData _getRoleIcon() {
    final r = (widget.role ?? 'jefe_zona').toLowerCase();
    if (r.contains('super')) {
      return Icons.shield_outlined;
    } else if (r.contains('jefe')) {
      return Icons.storefront_outlined;
    } else {
      return Icons.badge_outlined;
    }
  }

  void _showSwitchStoreDialog(bool isDark) {
    HapticFeedback.lightImpact();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E222A) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            const Icon(Icons.storefront_rounded, color: Color(0xFFAC0017)),
            const SizedBox(width: 10),
            Text(
              'Seleccionar Sucursal',
              style: GoogleFonts.sora(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF191C1E),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: _stores.map((s) {
            final isSelected = _activeStore == s;
            return Container(
              margin: const EdgeInsets.only(bottom: 6),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFFAC0017).withValues(alpha: isDark ? 0.2 : 0.1)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? const Color(0xFFAC0017) : (isDark ? Colors.white10 : Colors.grey[200]!),
                ),
              ),
              child: ListTile(
                dense: true,
                title: Text(
                  s,
                  style: GoogleFonts.hankenGrotesk(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isDark ? Colors.white : const Color(0xFF191C1E),
                  ),
                ),
                trailing: isSelected ? const Icon(Icons.check_circle, color: Color(0xFFAC0017), size: 20) : null,
                onTap: () {
                  setState(() => _activeStore = s);
                  Navigator.pop(ctx);
                  HapticFeedback.selectionClick();
                },
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showSwitchZoneDialog(bool isDark) {
    HapticFeedback.lightImpact();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E222A) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            const Icon(Icons.map_rounded, color: Color(0xFFAC0017)),
            const SizedBox(width: 10),
            Text(
              'Seleccionar Zona Nacional',
              style: GoogleFonts.sora(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF191C1E),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: _zones.map((z) {
            final isSelected = _activeZone == z;
            return ListTile(
              dense: true,
              title: Text(
                z,
                style: GoogleFonts.hankenGrotesk(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isDark ? Colors.white : const Color(0xFF191C1E),
                ),
              ),
              trailing: isSelected ? const Icon(Icons.check_circle, color: Color(0xFFAC0017), size: 20) : null,
              onTap: () {
                setState(() => _activeZone = z);
                Navigator.pop(ctx);
                HapticFeedback.selectionClick();
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _applyQuickAssignment() async {
    HapticFeedback.mediumImpact();
    if (_selectedCollaboratorIndices.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor selecciona al menos un colaborador'),
          backgroundColor: Color(0xFFBA1A1A),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_selectedDays.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor selecciona al menos un día de la semana'),
          backgroundColor: Color(0xFFBA1A1A),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final preset = _shiftPresets[_selectedPresetIndex];
    final isCustom = preset['isCustom'] == true;
    final shiftTitle = preset['title'] as String;
    final shiftHours = isCustom
        ? (_customHoursController.text.trim().isEmpty ? '08:00 - 16:00' : _customHoursController.text.trim())
        : (preset['hours'] as String);
    final hoursPerDay = isCustom
        ? _getCustomCalculatedHours()
        : (preset['duration'] as double);
    final totalAddedHours = hoursPerDay * _selectedDays.length;

    setState(() {
      for (final idx in _selectedCollaboratorIndices) {
        final col = _collaborators[idx];
        final currentH = (col['hoursAssigned'] as num).toDouble();
        col['hoursAssigned'] = (currentH + totalAddedHours).clamp(0.0, 60.0);
        col['shift'] = shiftHours;
        if (_overrideStation != 'Auto') {
          col['station'] = _overrideStation;
        }
      }
    });

    // Persist to Supabase if available
    for (final idx in _selectedCollaboratorIndices) {
      final col = _collaborators[idx];
      try {
        await _turnosService.crearTurno(
          Turno(
            id: 'shift-${DateTime.now().millisecondsSinceEpoch}',
            colaboradorId: (col['cedula'] ?? '10002').toString(),
            supervisorId: widget.username,
            restauranteId: _activeStore,
            fecha: DateTime.now(),
            horaInicio: shiftHours.split('-').first.trim(),
            horaFin: shiftHours.contains('-') ? shiftHours.split('-').last.trim() : '16:00',
            estacion: _overrideStation == 'Auto' ? (col['station'] as String? ?? 'Freidoras') : _overrideStation,
          ),
        );
      } catch (_) {}
    }

    // Notify parent if provided
    final firstCol = _collaborators[_selectedCollaboratorIndices.first];
    widget.onShiftCreated?.call({
      'id': 'shift-${DateTime.now().millisecondsSinceEpoch}',
      'colaborador_nombre': firstCol['name'],
      'estacion': _overrideStation == 'Auto' ? firstCol['station'] : _overrideStation,
      'hora_inicio': shiftHours.split('-').first.trim(),
      'hora_fin': shiftHours.contains('-') ? shiftHours.split('-').last.trim() : '00:00',
    });

    if (!mounted) return;
    final assignedCols = _selectedCollaboratorIndices.map((i) => _collaborators[i]).toList();
    final isDark = _isDarkMode(context);

    _showAssignmentSuccessPopup(
      shiftTitle: shiftTitle,
      shiftHours: shiftHours,
      hoursPerDay: hoursPerDay,
      assignedCollaborators: assignedCols,
      days: _selectedDays.toList(),
      station: _overrideStation,
      store: _activeStore,
      isDark: isDark,
    );
  }

  void _showAssignmentSuccessPopup({
    required String shiftTitle,
    required String shiftHours,
    required double hoursPerDay,
    required List<Map<String, dynamic>> assignedCollaborators,
    required List<int> days,
    required String station,
    required String store,
    required bool isDark,
  }) {
    HapticFeedback.heavyImpact();
    final sortedDays = List<int>.from(days)..sort();
    final dayNamesList = sortedDays.map((d) => _dayNames[d] ?? 'Día $d').join(', ');
    final totalHoursPerPerson = (hoursPerDay * days.length).toStringAsFixed(1);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1E222A) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          contentPadding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: const Color(0xFF00C853).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: Color(0xFF00C853),
                  size: 40,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '¡Turno Asignado Exitosamente!',
                textAlign: TextAlign.center,
                style: GoogleFonts.sora(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF191C1E),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'El horario ha sido registrado en el sistema Frisby',
                textAlign: TextAlign.center,
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 12,
                  color: isDark ? Colors.white60 : Colors.grey[600],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF9F9FB),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? Colors.white12 : const Color(0xFFE5E7EB),
                  ),
                ),
                child: Column(
                  children: [
                    _buildPopupDetailRow(
                      icon: Icons.storefront_outlined,
                      label: 'Sucursal',
                      value: store,
                      isDark: isDark,
                    ),
                    const Divider(height: 14),
                    _buildPopupDetailRow(
                      icon: Icons.access_time_rounded,
                      label: 'Horario',
                      value: shiftHours,
                      valueColor: const Color(0xFFAC0017),
                      isDark: isDark,
                    ),
                    const Divider(height: 14),
                    _buildPopupDetailRow(
                      icon: Icons.soup_kitchen_outlined,
                      label: 'Estación',
                      value: station == 'Auto' ? 'Automática por perfil' : station,
                      isDark: isDark,
                    ),
                    const Divider(height: 14),
                    _buildPopupDetailRow(
                      icon: Icons.calendar_month_outlined,
                      label: 'Días',
                      value: '${days.length} día(s): $dayNamesList',
                      isDark: isDark,
                    ),
                    const Divider(height: 14),
                    _buildPopupDetailRow(
                      icon: Icons.timelapse_rounded,
                      label: 'Total Horas',
                      value: '$totalHoursPerPerson hrs por colaborador',
                      valueColor: const Color(0xFF00C853),
                      isDark: isDark,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Colaborador(es) asignado(s) (${assignedCollaborators.length}):',
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white70 : Colors.grey[800],
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: assignedCollaborators.map((c) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFAC0017).withValues(alpha: isDark ? 0.2 : 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFAC0017).withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.person_rounded, size: 12, color: Color(0xFFAC0017)),
                        const SizedBox(width: 4),
                        Text(
                          c['name'] as String,
                          style: GoogleFonts.hankenGrotesk(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFAC0017),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        setState(() => _selectedMode = 2); // Ver en Malla Semanal
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: const BorderSide(color: Color(0xFFAC0017)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      ),
                      child: Text(
                        'Ver Malla',
                        style: GoogleFonts.hankenGrotesk(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFAC0017),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFAC0017),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                        elevation: 0,
                      ),
                      child: Text(
                        'Aceptar',
                        style: GoogleFonts.hankenGrotesk(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPopupDetailRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
    required bool isDark,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: isDark ? Colors.white60 : Colors.grey[600]),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: GoogleFonts.hankenGrotesk(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white70 : Colors.grey[700],
          ),
        ),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: GoogleFonts.hankenGrotesk(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: valueColor ?? (isDark ? Colors.white : const Color(0xFF191C1E)),
            ),
          ),
        ),
      ],
    );
  }

  void _duplicatePreviousWeek() {
    HapticFeedback.heavyImpact();
    setState(() {
      for (final col in _collaborators) {
        col['hoursAssigned'] = 47.0; // Standard 47h legal week
        col['status'] = 'Programado';
      }
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '⚡ ¡Horario de la semana anterior duplicado con éxito en $_activeStore!',
          style: GoogleFonts.hankenGrotesk(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF00C853),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _autoGenerateSmartSchedule() {
    HapticFeedback.heavyImpact();
    setState(() {
      final stationsPool = ['Freidoras', 'Plancha', 'Armado y Empaque', 'Caja', 'Servicio y Mesas'];
      for (int i = 0; i < _collaborators.length; i++) {
        final col = _collaborators[i];
        col['hoursAssigned'] = 47.0;
        col['station'] = stationsPool[i % stationsPool.length];
        col['shift'] = i % 2 == 0 ? '08:00 - 16:00' : '14:00 - 22:00';
      }
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '🤖 ¡Cuadrilla completa balanceada con Ley 2101 (47h máx y 1 descanso)!',
          style: GoogleFonts.hankenGrotesk(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF2E66E5),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final isDesktop = mediaQuery.size.width > 900;
    final isIOS = widget.forceIOS ??
        (Theme.of(context).platform == TargetPlatform.iOS ||
            defaultTargetPlatform == TargetPlatform.iOS);
    final isDark = _isDarkMode(context);

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF121418)
          : (isIOS ? const Color(0xFFF9F9FB) : const Color(0xFFF4F6F9)),
      appBar: _buildCustomAppBar(isIOS, isDark),
      body: SafeArea(
        child: isDesktop
            ? _buildDesktopView(isDark)
            : _buildMobileView(isIOS, isDark),
      ),
      bottomNavigationBar: _selectedMode == 0 ? _buildFloatingActionBottomBar(isIOS, isDark) : null,
    );
  }

  PreferredSizeWidget _buildCustomAppBar(bool isIOS, bool isDark) {
    final titleColor = isDark ? Colors.white : const Color(0xFF191C1E);
    final primaryRed = const Color(0xFFAC0017);

    return AppBar(
      elevation: 0,
      backgroundColor: isDark ? const Color(0xFF1A1D24) : Colors.white,
      foregroundColor: titleColor,
      centerTitle: false,
      leading: IconButton(
        icon: Icon(isIOS ? Icons.arrow_back_ios_new : Icons.arrow_back, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Flexible(
                child: Text(
                  'Asignación de Horarios',
                  style: GoogleFonts.sora(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: titleColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: primaryRed.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_getRoleIcon(), size: 11, color: primaryRed),
                    const SizedBox(width: 3),
                    Text(
                      _getRoleLabel().split('•').first.trim(),
                      style: GoogleFonts.hankenGrotesk(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: primaryRed,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          InkWell(
            onTap: () => _showSwitchStoreDialog(isDark),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.storefront_rounded, size: 13, color: primaryRed),
                const SizedBox(width: 4),
                Text(
                  _activeStore,
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white70 : Colors.grey[700],
                  ),
                ),
                const Icon(Icons.arrow_drop_down, size: 16, color: Colors.grey),
              ],
            ),
          ),
        ],
      ),
      actions: [
        if ((widget.role ?? '').toLowerCase().contains('super'))
          IconButton(
            icon: const Icon(Icons.map_outlined),
            tooltip: 'Cambiar Zona',
            onPressed: () => _showSwitchZoneDialog(isDark),
          ),
        IconButton(
          icon: Icon(isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
          tooltip: 'Cambiar Tema',
          onPressed: _toggleTheme,
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  Widget _buildMobileView(bool isIOS, bool isDark) {
    return Column(
      children: [
        // Mode Selector Pills (Asignador Rápido | Auto-Programación | Malla DRO'001)
        _buildModeSelectorHeader(isDark),

        // Body according to selected mode
        Expanded(
          child: _selectedMode == 0
              ? _buildQuickAssignmentView(isIOS, isDark)
              : (_selectedMode == 1
                  ? _buildAutoScheduleTemplatesView(isIOS, isDark)
                  : _buildScheduleSheetEmbed(isIOS, isDark)),
        ),
      ],
    );
  }

  Widget _buildDesktopView(bool isDark) {
    return Row(
      children: [
        // Left Column: Quick Configurator
        Expanded(
          flex: 6,
          child: Column(
            children: [
              _buildModeSelectorHeader(isDark),
              Expanded(
                child: _selectedMode == 0
                    ? _buildQuickAssignmentView(false, isDark)
                    : _buildAutoScheduleTemplatesView(false, isDark),
              ),
            ],
          ),
        ),
        // Right Column: Live Schedule Matrix DRO'001
        Expanded(
          flex: 7,
          child: Container(
            decoration: BoxDecoration(
              border: Border(left: BorderSide(color: isDark ? Colors.white12 : Colors.grey[300]!)),
            ),
            child: _buildScheduleSheetEmbed(false, isDark),
          ),
        ),
      ],
    );
  }

  Widget _buildModeSelectorHeader(bool isDark) {
    final modes = [
      {'title': 'Asignación Rápida', 'icon': Icons.flash_on_rounded},
      {'title': 'Auto-Plantillas', 'icon': Icons.auto_awesome_rounded},
      {'title': 'Malla DRO\'001', 'icon': Icons.table_chart_outlined},
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      color: isDark ? const Color(0xFF161920) : Colors.white,
      child: Container(
        height: 42,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFEFF1F4),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: List.generate(modes.length, (i) {
            final isSelected = _selectedMode == i;
            return Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() => _selectedMode = i);
                  HapticFeedback.selectionClick();
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFFAC0017) : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: const Color(0xFFAC0017).withValues(alpha: 0.3),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        modes[i]['icon'] as IconData,
                        size: 15,
                        color: isSelected ? Colors.white : (isDark ? Colors.white60 : Colors.grey[600]),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        modes[i]['title'] as String,
                        style: GoogleFonts.hankenGrotesk(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                          color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.grey[700]),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  // ==========================================
  // TAB 0: ASIGNADOR RÁPIDO E INTUITIVO
  // ==========================================
  Widget _buildQuickAssignmentView(bool isIOS, bool isDark) {
    final titleColor = isDark ? Colors.white : const Color(0xFF191C1E);
    final cardBg = isDark ? const Color(0xFF1E222A) : Colors.white;
    final cardBorder = isDark ? Colors.white12 : const Color(0xFFE5E7EB);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
      children: [
        // 1. SELECCIONAR COLABORADORES
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '1. ¿A quién(es) vas a programar?',
              style: GoogleFonts.sora(fontSize: 15, fontWeight: FontWeight.bold, color: titleColor),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  if (_selectedCollaboratorIndices.length == _collaborators.length) {
                    _selectedCollaboratorIndices.clear();
                  } else {
                    _selectedCollaboratorIndices.addAll(List.generate(_collaborators.length, (i) => i));
                  }
                });
                HapticFeedback.selectionClick();
              },
              child: Text(
                _selectedCollaboratorIndices.length == _collaborators.length ? 'Deseleccionar' : 'Todos',
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFAC0017),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),

        // Collaborators Selector Cards
        ...List.generate(_collaborators.length, (i) {
          final col = _collaborators[i];
          final isSelected = _selectedCollaboratorIndices.contains(i);
          final hours = (col['hoursAssigned'] as num).toDouble();
          final progress = (hours / 47.0).clamp(0.0, 1.0);
          final isOvertime = hours > 47.0;

          return InkWell(
            onTap: () {
              setState(() {
                if (isSelected) {
                  _selectedCollaboratorIndices.remove(i);
                } else {
                  _selectedCollaboratorIndices.add(i);
                }
              });
              HapticFeedback.selectionClick();
            },
            borderRadius: BorderRadius.circular(14),
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFFAC0017).withValues(alpha: isDark ? 0.15 : 0.08)
                    : cardBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected ? const Color(0xFFAC0017) : cardBorder,
                  width: isSelected ? 1.5 : 1.0,
                ),
              ),
              child: Row(
                children: [
                  Checkbox(
                    value: isSelected,
                    activeColor: const Color(0xFFAC0017),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    onChanged: (val) {
                      setState(() {
                        if (val == true) {
                          _selectedCollaboratorIndices.add(i);
                        } else {
                          _selectedCollaboratorIndices.remove(i);
                        }
                      });
                    },
                  ),
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: const Color(0xFFAC0017).withValues(alpha: 0.15),
                    child: Text(
                      (col['name'] as String).substring(0, 1),
                      style: GoogleFonts.sora(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFFAC0017)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              col['name'] as String,
                              style: GoogleFonts.hankenGrotesk(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : const Color(0xFF191C1E),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: isOvertime
                                    ? Colors.redAccent.withValues(alpha: 0.15)
                                    : (hours >= 35 ? Colors.green.withValues(alpha: 0.15) : Colors.orange.withValues(alpha: 0.15)),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '${hours.toInt()} / 47 hrs',
                                style: GoogleFonts.hankenGrotesk(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: isOvertime ? Colors.redAccent : (hours >= 35 ? Colors.green : Colors.orange),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Text(
                              '${col['station']} • ${col['team']}',
                              style: GoogleFonts.hankenGrotesk(
                                fontSize: 11,
                                color: isDark ? Colors.white60 : Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 4,
                            backgroundColor: isDark ? Colors.white10 : Colors.grey[200],
                            valueColor: AlwaysStoppedAnimation<Color>(
                              isOvertime ? Colors.redAccent : (progress > 0.8 ? const Color(0xFF00C853) : const Color(0xFF2E66E5)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }),

        const SizedBox(height: 18),

        // 2. SELECCIONAR DÍAS DE LA SEMANA
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '2. ¿Qué días de la semana?',
              style: GoogleFonts.sora(fontSize: 15, fontWeight: FontWeight.bold, color: titleColor),
            ),
            Row(
              children: [
                _buildQuickDayShortcut('L-V', [1, 2, 3, 4, 5], isDark),
                const SizedBox(width: 4),
                _buildQuickDayShortcut('S-D', [6, 7], isDark),
                const SizedBox(width: 4),
                _buildQuickDayShortcut('Todos', [1, 2, 3, 4, 5, 6, 7], isDark),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),

        // 7 Days Interactive Pills
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            {'num': 1, 'name': 'Lun'},
            {'num': 2, 'name': 'Mar'},
            {'num': 3, 'name': 'Mié'},
            {'num': 4, 'name': 'Jue'},
            {'num': 5, 'name': 'Vie'},
            {'num': 6, 'name': 'Sáb'},
            {'num': 7, 'name': 'Dom'},
          ].map((d) {
            final dayNum = d['num'] as int;
            final isSelected = _selectedDays.contains(dayNum);
            final isWeekend = dayNum == 6 || dayNum == 7;

            return Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _selectedDays.remove(dayNum);
                    } else {
                      _selectedDays.add(dayNum);
                    }
                  });
                  HapticFeedback.selectionClick();
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFFAC0017)
                        : (isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF3F4F6)),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? const Color(0xFFAC0017) : cardBorder,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        d['name'] as String,
                        style: GoogleFonts.hankenGrotesk(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                          color: isSelected ? Colors.white : (isWeekend ? const Color(0xFFAC0017) : titleColor),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Icon(
                        isSelected ? Icons.check_circle : Icons.circle_outlined,
                        size: 13,
                        color: isSelected ? Colors.white : Colors.grey[400],
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: 22),

        // 3. SELECCIONAR PLANTILLA O TURNO PRECONFIGURADO
        Text(
          '3. Selecciona el Turno o Preset de Frisby',
          style: GoogleFonts.sora(fontSize: 15, fontWeight: FontWeight.bold, color: titleColor),
        ),
        const SizedBox(height: 8),

        // Grid of Presets
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 2.1,
          ),
          itemCount: _shiftPresets.length,
          itemBuilder: (ctx, i) {
            final p = _shiftPresets[i];
            final isSelected = _selectedPresetIndex == i;
            final pColor = p['color'] as Color;

            return InkWell(
              onTap: () {
                setState(() => _selectedPresetIndex = i);
                HapticFeedback.selectionClick();
              },
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isSelected ? pColor.withValues(alpha: isDark ? 0.2 : 0.1) : cardBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected ? pColor : cardBorder,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: pColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(p['icon'] as IconData, size: 20, color: pColor),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p['title'] as String,
                            style: GoogleFonts.sora(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : const Color(0xFF191C1E),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            p['hours'] as String,
                            style: GoogleFonts.hankenGrotesk(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: pColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),

        // Horario Personalizado (Visible cuando está seleccionado el preset 0)
        if (_shiftPresets[_selectedPresetIndex]['isCustom'] == true) ...[
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E222A) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFAC0017), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFAC0017).withValues(alpha: isDark ? 0.2 : 0.08),
                  blurRadius: 10,
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
                        const Icon(Icons.edit_calendar_rounded, color: Color(0xFFAC0017), size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Escribe un Horario Personalizado:',
                          style: GoogleFonts.sora(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : const Color(0xFF191C1E),
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00C853).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${_getCustomCalculatedHours().toStringAsFixed(1)} hrs/día',
                        style: GoogleFonts.hankenGrotesk(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF00C853),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _customHoursController,
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF191C1E),
                  ),
                  decoration: InputDecoration(
                    hintText: 'Ej. 07:00 - 15:00 o 10:30 - 19:00',
                    hintStyle: GoogleFonts.hankenGrotesk(
                      fontSize: 13,
                      color: isDark ? Colors.white38 : Colors.grey[400],
                    ),
                    prefixIcon: const Icon(Icons.alarm, color: Color(0xFFAC0017), size: 20),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _customHoursController.clear();
                        setState(() {});
                      },
                    ),
                    filled: true,
                    fillColor: isDark ? Colors.black.withValues(alpha: 0.2) : const Color(0xFFF9F9FB),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: isDark ? Colors.white12 : const Color(0xFFE5E7EB)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: isDark ? Colors.white12 : const Color(0xFFE5E7EB)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFAC0017), width: 1.5),
                    ),
                  ),
                  onChanged: (val) {
                    setState(() {});
                  },
                ),
                const SizedBox(height: 10),
                Text(
                  'Horarios rápidos de sugerencia:',
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white60 : Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    '06:00 - 14:00',
                    '07:00 - 15:00',
                    '09:30 - 17:30',
                    '10:00 - 18:00',
                    '12:00 - 20:00',
                    '13:00 - 21:00',
                    '15:00 - 23:00',
                    '17:00 - 01:00',
                  ].map((quickH) {
                    final isCurrent = _customHoursController.text.trim() == quickH;
                    return InkWell(
                      onTap: () {
                        setState(() {
                          _customHoursController.text = quickH;
                        });
                        HapticFeedback.selectionClick();
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: isCurrent
                              ? const Color(0xFFAC0017)
                              : (isDark ? Colors.white10 : const Color(0xFFF0F2F5)),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isCurrent ? const Color(0xFFAC0017) : Colors.transparent,
                          ),
                        ),
                        child: Text(
                          quickH,
                          style: GoogleFonts.hankenGrotesk(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isCurrent ? Colors.white : (isDark ? Colors.white70 : const Color(0xFF191C1E)),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 18),

        // Optional Station Override Picker
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: cardBorder),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.soup_kitchen_outlined, size: 18, color: Color(0xFFAC0017)),
                  const SizedBox(width: 8),
                  Text(
                    'Estación de Trabajo:',
                    style: GoogleFonts.hankenGrotesk(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF191C1E),
                    ),
                  ),
                ],
              ),
              DropdownButton<String>(
                value: _overrideStation,
                underline: const SizedBox(),
                dropdownColor: isDark ? const Color(0xFF1E222A) : Colors.white,
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFAC0017),
                ),
                items: [
                  'Auto',
                  'Freidoras',
                  'Plancha',
                  'Armado y Empaque',
                  'Caja Registradora',
                  'Servicio y Mesas',
                ].map((st) {
                  return DropdownMenuItem<String>(
                    value: st,
                    child: Text(st == 'Auto' ? 'Automática por perfil' : st),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _overrideStation = val);
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickDayShortcut(String label, List<int> days, bool isDark) {
    return InkWell(
      onTap: () {
        setState(() {
          _selectedDays.clear();
          _selectedDays.addAll(days);
        });
        HapticFeedback.selectionClick();
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isDark ? Colors.white10 : const Color(0xFFF0F2F5),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: GoogleFonts.hankenGrotesk(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: const Color(0xFFAC0017),
          ),
        ),
      ),
    );
  }

  // ==========================================
  // TAB 1: AUTO-PROGRAMACIÓN & PLANTILLAS
  // ==========================================
  Widget _buildAutoScheduleTemplatesView(bool isIOS, bool isDark) {
    final titleColor = isDark ? Colors.white : const Color(0xFF191C1E);
    final cardBg = isDark ? const Color(0xFF1E222A) : Colors.white;
    final cardBorder = isDark ? Colors.white12 : const Color(0xFFE5E7EB);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      children: [
        Text(
          'Herramientas Inteligentes de Planificación',
          style: GoogleFonts.sora(fontSize: 17, fontWeight: FontWeight.bold, color: titleColor),
        ),
        const SizedBox(height: 4),
        Text(
          'Ahorra horas de trabajo aplicando cuadrillas completas en 1 solo clic',
          style: GoogleFonts.hankenGrotesk(fontSize: 13, color: isDark ? Colors.white60 : Colors.grey[600]),
        ),
        const SizedBox(height: 18),

        // Template 1: Duplicar Semana Anterior
        _buildToolActionCard(
          icon: Icons.copy_all_rounded,
          iconColor: const Color(0xFF00C853),
          title: 'Duplicar Semana Anterior',
          description: 'Copia toda la rotación y turnos de la semana pasada a la semana en curso en $_activeStore.',
          badge: 'Más Utilizado',
          buttonLabel: '⚡ Duplicar Semana Ahora',
          onPressed: _duplicatePreviousWeek,
          isDark: isDark,
          cardBg: cardBg,
          cardBorder: cardBorder,
        ),
        const SizedBox(height: 14),

        // Template 2: Auto-Balanceador Ley 2101
        _buildToolActionCard(
          icon: Icons.balance_rounded,
          iconColor: const Color(0xFF2E66E5),
          title: 'Balanceador Inteligente Ley 2101',
          description: 'Calcula automáticamente 47 horas por colaborador, asegurando descansos legales rotativos y cobertura completa en cocina y caja.',
          badge: 'Legal & Nómina',
          buttonLabel: '🤖 Auto-Balancear Cuadrilla',
          onPressed: _autoGenerateSmartSchedule,
          isDark: isDark,
          cardBg: cardBg,
          cardBorder: cardBorder,
        ),
        const SizedBox(height: 14),

        // Template 3: Pico de Fin de Semana
        _buildToolActionCard(
          icon: Icons.local_fire_department_rounded,
          iconColor: const Color(0xFFFF9100),
          title: 'Plantilla Fin de Semana / Alto Tráfico',
          description: 'Refuerza doble freidora, 3 colaboradores en plancha y apoyo en punto de venta para viernes, sábado y domingo.',
          badge: 'Alto Volumen',
          buttonLabel: '🍗 Cargar Plantilla Fin de Semana',
          onPressed: () {
            HapticFeedback.mediumImpact();
            if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('¡Plantilla de Alto Tráfico aplicada a Viernes, Sábado y Domingo!'),
                backgroundColor: Color(0xFFFF9100),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
          isDark: isDark,
          cardBg: cardBg,
          cardBorder: cardBorder,
        ),
      ],
    );
  }

  Widget _buildToolActionCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
    required String badge,
    required String buttonLabel,
    required VoidCallback onPressed,
    required bool isDark,
    required Color cardBg,
    required Color cardBorder,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
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
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: iconColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: iconColor, size: 22),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    title,
                    style: GoogleFonts.sora(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF191C1E),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  badge,
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: iconColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            description,
            style: GoogleFonts.hankenGrotesk(
              fontSize: 13,
              color: isDark ? Colors.white70 : Colors.grey[700],
              height: 1.3,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: iconColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: Text(
                buttonLabel,
                style: GoogleFonts.hankenGrotesk(fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 2: MALLA SEMANAL DRO'001 EMBED
  // ==========================================
  Widget _buildScheduleSheetEmbed(bool isIOS, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      child: FrisbyWeeklyScheduleSheet(
        restaurantName: _activeStore,
        isDark: isDark,
        isIOS: isIOS,
      ),
    );
  }

  // Floating Action Bottom Bar for Quick Assignment
  Widget _buildFloatingActionBottomBar(bool isIOS, bool isDark) {
    final preset = _shiftPresets[_selectedPresetIndex];
    final isCustom = preset['isCustom'] == true;
    final hoursPerDay = isCustom ? _getCustomCalculatedHours() : (preset['duration'] as double);
    final totalHours = (hoursPerDay * _selectedDays.length).toStringAsFixed(1);
    final totalShifts = _selectedCollaboratorIndices.length * _selectedDays.length;
    final displayHours = isCustom
        ? (_customHoursController.text.trim().isEmpty ? '08:00 - 16:00' : _customHoursController.text.trim())
        : (preset['hours'] as String);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E222A) : Colors.white,
        border: Border(top: BorderSide(color: isDark ? Colors.white12 : Colors.grey[200]!)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Resumen de Asignación:',
                    style: GoogleFonts.hankenGrotesk(fontSize: 11, color: isDark ? Colors.white60 : Colors.grey[600]),
                  ),
                  Text(
                    isCustom ? 'Personalizado ($displayHours)' : '${preset['title']} • $totalShifts turno(s)',
                    style: GoogleFonts.sora(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF191C1E),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '$totalHours hrs por persona (${_selectedDays.length} días)',
                    style: GoogleFonts.hankenGrotesk(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF00C853)),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 4,
              child: SizedBox(
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _applyQuickAssignment,
                  icon: const Icon(Icons.flash_on_rounded, size: 18),
                  label: Text(
                    'Asignar Horario',
                    style: GoogleFonts.hankenGrotesk(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFAC0017),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    elevation: 3,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
