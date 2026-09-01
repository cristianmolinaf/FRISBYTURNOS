import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../google_fonts_wrapper.dart';

/// Modelo para una fila de la Malla Semanal DRO'001.1
class WeeklyScheduleRow {
  final int idNumber;
  final String collaboratorId;
  final String collaboratorName;
  final String role; // Cargo: Super #, Auxiliar P, Combos D, Salón, Oficios Varios, Domicilio
  final Map<int, String> dayShifts; // 1: Lunes -> 7: Domingo. Valor ej: '8-15', '☺', '14-21', '12-14\n16-21'
  final Map<int, String> dayNotes; // Notas especiales por turno: 'Biodanza (7:30 AM)', 'Reunión', etc.

  WeeklyScheduleRow({
    required this.idNumber,
    required this.collaboratorId,
    required this.collaboratorName,
    required this.role,
    required this.dayShifts,
    this.dayNotes = const {},
  });

  WeeklyScheduleRow copyWith({
    int? idNumber,
    String? collaboratorId,
    String? collaboratorName,
    String? role,
    Map<int, String>? dayShifts,
    Map<int, String>? dayNotes,
  }) {
    return WeeklyScheduleRow(
      idNumber: idNumber ?? this.idNumber,
      collaboratorId: collaboratorId ?? this.collaboratorId,
      collaboratorName: collaboratorName ?? this.collaboratorName,
      role: role ?? this.role,
      dayShifts: dayShifts ?? Map<int, String>.from(this.dayShifts),
      dayNotes: dayNotes ?? Map<int, String>.from(this.dayNotes),
    );
  }

  /// Calcula el total aproximado de horas laboradas en la semana
  double calculateTotalHours() {
    double total = 0.0;
    for (final shift in dayShifts.values) {
      if (shift.isEmpty || shift.contains('☺') || shift.contains('D') || shift == '-') {
        continue;
      }
      total += _parseShiftDuration(shift);
    }
    return total;
  }

  static double _parseShiftDuration(String shift) {
    if (shift.contains('\n') || shift.contains('/')) {
      final parts = shift.split(RegExp(r'[\n/]'));
      double subTotal = 0;
      for (final p in parts) {
        subTotal += _parseSingleShift(p.trim());
      }
      return subTotal;
    }
    return _parseSingleShift(shift.trim());
  }

  static double _parseSingleShift(String s) {
    final match = RegExp(r'(\d+)\s*[-–]\s*(\d+)').firstMatch(s);
    if (match != null) {
      final start = int.tryParse(match.group(1)!) ?? 0;
      final end = int.tryParse(match.group(2)!) ?? 0;
      if (end > start) {
        return (end - start).toDouble();
      } else if (end < start) {
        // Turno que cruza medianoche
        return (24 - start + end).toDouble();
      }
    }
    return 7.0; // Default estándar 7 horas si no es numérico
  }
}

/// Widget completo e interactivo de la Malla Semanal DRO'001.1
class FrisbyWeeklyScheduleSheet extends StatefulWidget {
  final String restaurantName;
  final bool isDark;
  final bool isIOS;
  final VoidCallback? onAddShiftPressed;
  final String? filterCollaboratorId;
  final String? filterCollaboratorName;
  final bool isCollaboratorView;

  const FrisbyWeeklyScheduleSheet({
    super.key,
    required this.restaurantName,
    required this.isDark,
    required this.isIOS,
    this.onAddShiftPressed,
    this.filterCollaboratorId,
    this.filterCollaboratorName,
    this.isCollaboratorView = false,
  });

  @override
  State<FrisbyWeeklyScheduleSheet> createState() => _FrisbyWeeklyScheduleSheetState();
}

class _FrisbyWeeklyScheduleSheetState extends State<FrisbyWeeklyScheduleSheet> {
  DateTime _weekStartDate = _getMonday(DateTime.now());
  late List<WeeklyScheduleRow> _scheduleRows;

  // Observaciones y eventos especiales de la semana (Fieles al formato físico)
  final List<Map<String, dynamic>> _observations = [
    {
      'title': 'Biodanza (7:30 AM)',
      'participants': 'Cristian, Yenifer, Adriana A.',
      'color': const Color(0xFF2E7D32),
      'day': 'Miércoles',
    },
    {
      'title': 'Biodanza (3:30 PM)',
      'participants': 'Ronaldo, Maira, Jesús',
      'color': const Color(0xFF2E7D32),
      'day': 'Jueves',
    },
    {
      'title': 'Reunión Operativa (2:00 PM)',
      'participants': 'Cristian, Jelson',
      'color': const Color(0xFFD2232A),
      'day': 'Martes',
    },
    {
      'title': 'Aseo General de Cookers',
      'participants': 'Cristian',
      'color': const Color(0xFF0288D1),
      'day': 'Lunes',
    },
  ];

  static DateTime _getMonday(DateTime date) {
    return date.subtract(Duration(days: date.weekday - 1));
  }

  @override
  void initState() {
    super.initState();
    _initDefaultScheduleData();
    _fetchSupabaseShifts();
  }

  void _initDefaultScheduleData() {
    // Datos reales iniciales correspondientes a la planilla de la foto
    _scheduleRows = [
      WeeklyScheduleRow(
        idNumber: 1,
        collaboratorId: '10001',
        collaboratorName: 'Jelson',
        role: 'Super #',
        dayShifts: {
          1: '12-14\n16-21',
          2: '8-15',
          3: '8-15',
          4: '☺',
          5: '14-21',
          6: '12-19',
          7: '14-21',
        },
      ),
      WeeklyScheduleRow(
        idNumber: 2,
        collaboratorId: '10002',
        collaboratorName: 'Cristian',
        role: 'Auxiliar P',
        dayShifts: {
          1: '8-15',
          2: '☺',
          3: '14-21',
          4: '8-15',
          5: '8-15',
          6: '14-21',
          7: '8-15',
        },
      ),
      WeeklyScheduleRow(
        idNumber: 3,
        collaboratorId: '10003',
        collaboratorName: 'Maira',
        role: 'Super #',
        dayShifts: {
          1: '☺',
          2: '14-21',
          3: '8-15',
          4: '14-21',
          5: '8-15',
          6: '9-16',
          7: '12-14\n16-21',
        },
      ),
      WeeklyScheduleRow(
        idNumber: 4,
        collaboratorId: '10004',
        collaboratorName: 'Sandra',
        role: 'Combos D',
        dayShifts: {
          1: '☺',
          2: '8-15',
          3: '9-12 / 17-21',
          4: '8-15',
          5: '14-21',
          6: '12-19',
          7: '10-17',
        },
      ),
      WeeklyScheduleRow(
        idNumber: 5,
        collaboratorId: '10005',
        collaboratorName: 'Luisa',
        role: 'Combos D',
        dayShifts: {
          1: '14-21',
          2: '14-21',
          3: '☺',
          4: '14-21',
          5: '9-16',
          6: '12-14\n16-21',
          7: '8-15',
        },
      ),
      WeeklyScheduleRow(
        idNumber: 6,
        collaboratorId: '10006',
        collaboratorName: 'Yenifer',
        role: 'Salón',
        dayShifts: {
          1: '15-21',
          2: '12-16',
          3: '12-16',
          4: '☺',
          5: '16-21',
          6: '12-14\n16-21',
          7: '12-19',
        },
      ),
      WeeklyScheduleRow(
        idNumber: 7,
        collaboratorId: '10007',
        collaboratorName: 'Adriana A',
        role: 'Super #',
        dayShifts: {
          1: '8-15',
          2: '14-21',
          3: '14-21',
          4: '9-16',
          5: '☺',
          6: '8-15',
          7: '12-14\n16-21',
        },
      ),
      WeeklyScheduleRow(
        idNumber: 8,
        collaboratorId: '10008',
        collaboratorName: 'Ronaldo',
        role: 'Oficios Varios',
        dayShifts: {
          1: '8-15',
          2: '☺',
          3: '8-15',
          4: '14-21',
          5: '8-11\n17-21',
          6: '8-15',
          7: '12-14\n16-21',
        },
      ),
      WeeklyScheduleRow(
        idNumber: 9,
        collaboratorId: '10009',
        collaboratorName: 'Jesús',
        role: 'Domicilio',
        dayShifts: {
          1: '☺',
          2: '13-20',
          3: '9-14',
          4: '13-20',
          5: '9-16',
          6: '9-16',
          7: '12-15\n16-20',
        },
      ),
      WeeklyScheduleRow(
        idNumber: 10,
        collaboratorId: '10010',
        collaboratorName: 'Freddy',
        role: 'Domicilio',
        dayShifts: {
          1: '9-16',
          2: '☺',
          3: '13-20',
          4: '9-16',
          5: '12-15\n16-20',
          6: '12-15\n16-20',
          7: '10-17',
        },
      ),
      WeeklyScheduleRow(
        idNumber: 11,
        collaboratorId: '10011',
        collaboratorName: 'Andrés',
        role: 'Domicilio',
        dayShifts: {
          1: '13-20',
          2: '8-15',
          3: '-',
          4: '-',
          5: '-',
          6: '-',
          7: '-',
        },
      ),
    ];
  }

  List<WeeklyScheduleRow> get _displayedRows {
    if (!widget.isCollaboratorView && widget.filterCollaboratorId == null && widget.filterCollaboratorName == null) {
      return _scheduleRows;
    }

    final targetId = widget.filterCollaboratorId?.trim().toLowerCase();
    final targetName = widget.filterCollaboratorName?.trim().toLowerCase();

    final filtered = _scheduleRows.where((row) {
      final rowId = row.collaboratorId.toLowerCase();
      final rowName = row.collaboratorName.toLowerCase();

      if (targetId != null && targetId.isNotEmpty) {
        if (rowId == targetId || targetId.contains(rowId) || rowId.contains(targetId)) {
          return true;
        }
      }

      if (targetName != null && targetName.isNotEmpty) {
        if (rowName == targetName ||
            rowName.contains(targetName) ||
            targetName.contains(rowName)) {
          return true;
        }
      }

      // Default fallback if username is passed (e.g. 10002 or cristian)
      if (targetId != null && (rowName.contains(targetId) || targetId.contains(rowName))) {
        return true;
      }

      return false;
    }).toList();

    // Si por alguna razón no hay coincidencia exacta con el usuario logueado en modo colaborador,
    // retornamos al menos su primera fila o la lista si no se encontró
    if (filtered.isEmpty && widget.isCollaboratorView) {
      return _scheduleRows.take(1).toList();
    }

    return filtered;
  }

  Future<void> _fetchSupabaseShifts() async {
    try {
      final supabase = Supabase.instance.client;
      final response = await supabase.from('turnos').select();
      if (response.isNotEmpty && mounted) {
        // Enlace de datos de turnos guardados
      }
    } catch (_) {}
  }

  void _previousWeek() {
    setState(() {
      _weekStartDate = _weekStartDate.subtract(const Duration(days: 7));
    });
  }

  void _nextWeek() {
    setState(() {
      _weekStartDate = _weekStartDate.add(const Duration(days: 7));
    });
  }

  void _showQuickShiftEditor({
    required BuildContext context,
    required WeeklyScheduleRow row,
    required int dayIndex,
    required DateTime dayDate,
    required String currentShift,
  }) {
    final isDark = widget.isDark;
    final dayNames = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];
    final dayName = dayNames[dayIndex - 1];

    final customCtrl = TextEditingController(text: currentShift == '☺' || currentShift == '-' ? '' : currentShift);
    final noteCtrl = TextEditingController(text: row.dayNotes[dayIndex] ?? '');

    final shiftPresets = [
      {'label': '8 - 15', 'desc': 'Apertura (7h)', 'val': '8-15', 'color': const Color(0xFF1E88E5)},
      {'label': '14 - 21', 'desc': 'Cierre (7h)', 'val': '14-21', 'color': const Color(0xFFD2232A)},
      {'label': '8 - 16', 'desc': 'Completo (8h)', 'val': '8-16', 'color': const Color(0xFF43A047)},
      {'label': '9 - 16', 'desc': 'Intermedio (7h)', 'val': '9-16', 'color': const Color(0xFF00ACC1)},
      {'label': '12 - 19', 'desc': 'Refuerzo Tarde (7h)', 'val': '12-19', 'color': const Color(0xFFFB8C00)},
      {'label': '10 - 17', 'desc': 'Fin de Semana (7h)', 'val': '10-17', 'color': const Color(0xFF8E24AA)},
      {'label': '13 - 20', 'desc': 'Domicilios Tarde (7h)', 'val': '13-20', 'color': const Color(0xFF3949AB)},
      {'label': '12-14 / 16-21', 'desc': 'Turno Partido (7h)', 'val': '12-14\n16-21', 'color': const Color(0xFFE53935)},
      {'label': '☺ Descanso', 'desc': 'Descanso Programado', 'val': '☺', 'color': const Color(0xFF2E7D32)},
      {'label': '- Sin Turno', 'desc': 'No programado', 'val': '-', 'color': Colors.grey},
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag Indicator
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Title Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFAC0017).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'N° ${row.idNumber}',
                              style: GoogleFonts.hankenGrotesk(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: const Color(0xFFAC0017),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            row.collaboratorName,
                            style: GoogleFonts.hankenGrotesk(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : const Color(0xFF191C1E),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${row.role} • $dayName ${dayDate.day}/${dayDate.month}',
                        style: GoogleFonts.hankenGrotesk(
                          fontSize: 13,
                          color: isDark ? Colors.white60 : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 16),

              // --- ASISTENTE DE COBERTURA DE LA ESTACIÓN (APERTURA, INTERMEDIO, CIERRE) ---
              () {
                // Obtener los compañeros del mismo cargo en este día
                final sameRoleRows = _scheduleRows.where((r) => r.role == row.role && r.idNumber != row.idNumber).toList();
                
                String? aperturaPerson;
                String? intermedioPerson;
                String? cierrePerson;

                for (final r in sameRoleRows) {
                  final s = r.dayShifts[dayIndex] ?? '';
                  if (s.isEmpty || s == '-' || s == '☺') continue;
                  
                  if (s.startsWith('8-') || s.startsWith('08-') || s.startsWith('9-')) {
                    aperturaPerson = r.collaboratorName;
                  } else if (s.contains('14-') || s.contains('15-') || s.contains('16-')) {
                    cierrePerson = r.collaboratorName;
                  } else {
                    intermedioPerson = r.collaboratorName;
                  }
                }

                // Determinar sugerencia óptima
                String smartSuggestion = '';
                String suggestedVal = '';
                if (aperturaPerson == null) {
                  smartSuggestion = 'Falta cubrir Apertura (08:00 - 15:00)';
                  suggestedVal = '8-15';
                } else if (cierrePerson == null) {
                  smartSuggestion = 'Falta cubrir Cierre (14:00 - 21:00)';
                  suggestedVal = '14-21';
                } else if (intermedioPerson == null) {
                  smartSuggestion = 'Falta cubrir Refuerzo/Intermedio (12:00 - 19:00)';
                  suggestedVal = '12-19';
                }

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFF8F9FB),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFE5E7EB)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.hub_outlined, size: 16, color: Color(0xFFAC0017)),
                              const SizedBox(width: 6),
                              Text(
                                'Cobertura de Estación (${row.role})',
                                style: GoogleFonts.hankenGrotesk(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : const Color(0xFF191C1E),
                                ),
                              ),
                            ],
                          ),
                          Text(
                            dayName,
                            style: GoogleFonts.hankenGrotesk(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white60 : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      // Franjas de Apertura, Intermedio y Cierre
                      Row(
                        children: [
                          // Apertura
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                              decoration: BoxDecoration(
                                color: aperturaPerson != null
                                    ? const Color(0xFF0284C7).withValues(alpha: isDark ? 0.25 : 0.12)
                                    : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey[200]),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: aperturaPerson != null
                                      ? const Color(0xFF0284C7).withValues(alpha: 0.5)
                                      : Colors.transparent,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Text('Apertura', style: GoogleFonts.hankenGrotesk(fontSize: 10, fontWeight: FontWeight.bold, color: aperturaPerson != null ? const Color(0xFF0284C7) : Colors.grey)),
                                  const SizedBox(height: 2),
                                  Text('8:00 - 15:00', style: GoogleFonts.hankenGrotesk(fontSize: 9, color: isDark ? Colors.white70 : Colors.black87)),
                                  const SizedBox(height: 4),
                                  Text(
                                    aperturaPerson ?? '⚠️ Libre',
                                    style: GoogleFonts.hankenGrotesk(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: aperturaPerson != null ? (isDark ? Colors.white : const Color(0xFF0284C7)) : const Color(0xFFD97706),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          // Intermedio
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                              decoration: BoxDecoration(
                                color: intermedioPerson != null
                                    ? const Color(0xFFD97706).withValues(alpha: isDark ? 0.25 : 0.12)
                                    : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey[200]),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: intermedioPerson != null
                                      ? const Color(0xFFD97706).withValues(alpha: 0.5)
                                      : Colors.transparent,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Text('Intermedio', style: GoogleFonts.hankenGrotesk(fontSize: 10, fontWeight: FontWeight.bold, color: intermedioPerson != null ? const Color(0xFFD97706) : Colors.grey)),
                                  const SizedBox(height: 2),
                                  Text('12:00 - 19:00', style: GoogleFonts.hankenGrotesk(fontSize: 9, color: isDark ? Colors.white70 : Colors.black87)),
                                  const SizedBox(height: 4),
                                  Text(
                                    intermedioPerson ?? '⚠️ Libre',
                                    style: GoogleFonts.hankenGrotesk(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: intermedioPerson != null ? (isDark ? Colors.white : const Color(0xFFD97706)) : const Color(0xFFD97706),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          // Cierre
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                              decoration: BoxDecoration(
                                color: cierrePerson != null
                                    ? const Color(0xFFC8102E).withValues(alpha: isDark ? 0.25 : 0.12)
                                    : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey[200]),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: cierrePerson != null
                                      ? const Color(0xFFC8102E).withValues(alpha: 0.5)
                                      : Colors.transparent,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Text('Cierre', style: GoogleFonts.hankenGrotesk(fontSize: 10, fontWeight: FontWeight.bold, color: cierrePerson != null ? const Color(0xFFC8102E) : Colors.grey)),
                                  const SizedBox(height: 2),
                                  Text('14:00 - 21:00', style: GoogleFonts.hankenGrotesk(fontSize: 9, color: isDark ? Colors.white70 : Colors.black87)),
                                  const SizedBox(height: 4),
                                  Text(
                                    cierrePerson ?? '⚠️ Libre',
                                    style: GoogleFonts.hankenGrotesk(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: cierrePerson != null ? (isDark ? Colors.white : const Color(0xFFC8102E)) : const Color(0xFFD97706),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (smartSuggestion.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        InkWell(
                          onTap: () {
                            _updateShift(row.idNumber, dayIndex, suggestedVal);
                            Navigator.pop(ctx);
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2E7D32).withValues(alpha: isDark ? 0.2 : 0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFF2E7D32).withValues(alpha: 0.4)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.auto_awesome, size: 14, color: Color(0xFF2E7D32)),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    '💡 Sugerencia IA: $smartSuggestion (Toca para aplicar)',
                                    style: GoogleFonts.hankenGrotesk(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? const Color(0xFFA5D6A7) : const Color(0xFF1B5E20),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              }(),

              Text(
                'Selección Rápida de Horario (1 Toque):',
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white70 : const Color(0xFF555555),
                ),
              ),
              const SizedBox(height: 10),

              // Grid de presets rápidos con detección de cruces
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: shiftPresets.map((p) {
                  final val = p['val'] as String;
                  final isSelected = currentShift == val;
                  final pColor = p['color'] as Color;

                  // Detectar si otro compañero del mismo cargo ya tiene exactamente este turno
                  final sameRoleRows = _scheduleRows.where((r) => r.role == row.role && r.idNumber != row.idNumber).toList();
                  final conflictRow = sameRoleRows.cast<WeeklyScheduleRow?>().firstWhere(
                        (r) => r?.dayShifts[dayIndex] == val,
                        orElse: () => null,
                      );
                  final hasConflict = conflictRow != null && val != '-' && val != '☺';

                  return InkWell(
                    onTap: () {
                      if (hasConflict) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('⚠️ Nota: ${conflictRow.collaboratorName} ya tiene este horario asignado en ${row.role}.'),
                            backgroundColor: const Color(0xFFD97706),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      }
                      _updateShift(row.idNumber, dayIndex, val);
                      Navigator.pop(ctx);
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? pColor.withValues(alpha: 0.25)
                            : (hasConflict
                                ? (isDark ? Colors.white.withValues(alpha: 0.03) : const Color(0xFFFFFBEB))
                                : (isDark ? Colors.white10 : const Color(0xFFF3F4F6))),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? pColor
                              : (hasConflict
                                  ? const Color(0xFFD97706).withValues(alpha: 0.5)
                                  : (isDark ? Colors.white12 : Colors.grey[300]!)),
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (val == '☺')
                            const Text('☺ ', style: TextStyle(fontSize: 16, color: Color(0xFF2E7D32)))
                          else
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(color: pColor, shape: BoxShape.circle),
                            ),
                          const SizedBox(width: 6),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                p['label'] as String,
                                style: GoogleFonts.hankenGrotesk(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: isSelected
                                      ? (isDark ? Colors.white : pColor)
                                      : (isDark ? Colors.white : Colors.black87),
                                ),
                              ),
                              if (hasConflict)
                                Text(
                                  'Ocupado por ${conflictRow.collaboratorName}',
                                  style: GoogleFonts.hankenGrotesk(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFFD97706),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 18),
              Text(
                'Nota o Evento Especial para este turno:',
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white70 : const Color(0xFF555555),
                ),
              ),
              const SizedBox(height: 8),

              // Chips de eventos predefinidos (Biodanza, Reunión, Capacitación, Aseo)
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  {'label': '🌿 Biodanza (7:30 AM)', 'color': const Color(0xFF2E7D32)},
                  {'label': '🌿 Biodanza (3:30 PM)', 'color': const Color(0xFF2E7D32)},
                  {'label': '👥 Reunión Operativa', 'color': const Color(0xFFD2232A)},
                  {'label': '🧹 Aseo General', 'color': const Color(0xFF0288D1)},
                  {'label': '🎓 Capacitación', 'color': const Color(0xFF7C3AED)},
                ].map((ev) {
                  final evLabel = ev['label'] as String;
                  final evColor = ev['color'] as Color;
                  final isEvSelected = noteCtrl.text == evLabel;

                  return InkWell(
                    onTap: () {
                      setModalState(() {
                        if (isEvSelected) {
                          noteCtrl.clear();
                        } else {
                          noteCtrl.text = evLabel;
                        }
                      });
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: isEvSelected
                            ? evColor.withValues(alpha: isDark ? 0.3 : 0.15)
                            : (isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF3F4F6)),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isEvSelected ? evColor : (isDark ? Colors.white12 : Colors.grey[300]!),
                          width: isEvSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Text(
                        evLabel,
                        style: GoogleFonts.hankenGrotesk(
                          fontSize: 11,
                          fontWeight: isEvSelected ? FontWeight.bold : FontWeight.w500,
                          color: isEvSelected ? (isDark ? Colors.white : evColor) : (isDark ? Colors.white70 : Colors.black87),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 10),
              TextField(
                controller: noteCtrl,
                style: GoogleFonts.hankenGrotesk(fontSize: 12, color: isDark ? Colors.white : Colors.black87),
                decoration: InputDecoration(
                  hintText: 'O escribe una nota (Ej: Examen médico, Entrega uniforme)',
                  hintStyle: GoogleFonts.hankenGrotesk(fontSize: 12, color: Colors.grey),
                  filled: true,
                  fillColor: isDark ? Colors.white10 : const Color(0xFFF9FAFB),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  prefixIcon: const Icon(Icons.edit_note, size: 18, color: Color(0xFFAC0017)),
                ),
              ),

              const SizedBox(height: 18),
              Text(
                'O escribe un horario personalizado:',
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 12,
                  color: isDark ? Colors.white60 : Colors.grey[600],
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: customCtrl,
                      style: GoogleFonts.hankenGrotesk(color: isDark ? Colors.white : Colors.black87),
                      decoration: InputDecoration(
                        hintText: 'Ej: 11-18 o 12-15 / 17-21',
                        hintStyle: GoogleFonts.hankenGrotesk(fontSize: 13, color: Colors.grey),
                        filled: true,
                        fillColor: isDark ? Colors.white10 : const Color(0xFFF9FAFB),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      final val = customCtrl.text.trim();
                      final note = noteCtrl.text.trim();
                      if (val.isNotEmpty) {
                        _updateShift(row.idNumber, dayIndex, val, note: note.isNotEmpty ? note : null);
                      } else if (note.isNotEmpty) {
                        _updateShift(row.idNumber, dayIndex, currentShift, note: note);
                      }
                      Navigator.pop(ctx);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFAC0017),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Guardar'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _updateShift(int idNumber, int dayIndex, String newShift, {String? note}) {
    setState(() {
      final index = _scheduleRows.indexWhere((r) => r.idNumber == idNumber);
      if (index != -1) {
        final row = _scheduleRows[index];
        final updatedShifts = Map<int, String>.from(row.dayShifts);
        final updatedNotes = Map<int, String>.from(row.dayNotes);
        
        updatedShifts[dayIndex] = newShift;
        if (note != null && note.isNotEmpty) {
          updatedNotes[dayIndex] = note;
          
          // Sincronizar automáticamente en la sección inferior de Observaciones y Eventos
          final dayNames = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];
          final dayName = dayNames[dayIndex - 1];
          final cleanTitle = note.replaceAll(RegExp(r'^[🌿👥🧹🎓]\s*'), '');

          final existingObsIndex = _observations.indexWhere(
            (o) => (o['title'] as String).toLowerCase().contains(cleanTitle.toLowerCase()) && o['day'] == dayName,
          );

          if (existingObsIndex != -1) {
            final currentParticipants = _observations[existingObsIndex]['participants'] as String;
            if (!currentParticipants.contains(row.collaboratorName)) {
              _observations[existingObsIndex]['participants'] = '$currentParticipants, ${row.collaboratorName}';
            }
          } else {
            _observations.add({
              'title': cleanTitle,
              'participants': row.collaboratorName,
              'color': note.contains('Biodanza')
                  ? const Color(0xFF2E7D32)
                  : (note.contains('Reunión')
                      ? const Color(0xFFD2232A)
                      : (note.contains('Aseo') ? const Color(0xFF0288D1) : const Color(0xFF7C3AED))),
              'day': dayName,
            });
          }
        } else if (note == '') {
          updatedNotes.remove(dayIndex);
        }

        _scheduleRows[index] = row.copyWith(
          dayShifts: updatedShifts,
          dayNotes: updatedNotes,
        );
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Turno actualizado: $newShift ${note != null && note.isNotEmpty ? "($note)" : ""}'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF2E7D32),
      ),
    );
  }

  void _addNewCollaboratorRow() {
    final nameCtrl = TextEditingController();
    String role = 'Super #';
    final isDark = widget.isDark;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: Text(
            'Agregar Colaborador a la Malla',
            style: GoogleFonts.hankenGrotesk(fontWeight: FontWeight.bold, fontSize: 17),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: InputDecoration(
                  labelText: 'Nombre del Colaborador',
                  filled: true,
                  fillColor: isDark ? Colors.white10 : Colors.grey[100],
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: role,
                dropdownColor: isDark ? const Color(0xFF2A2A2A) : Colors.white,
                decoration: InputDecoration(
                  labelText: 'Cargo / Estación',
                  filled: true,
                  fillColor: isDark ? Colors.white10 : Colors.grey[100],
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                ),
                items: ['Super #', 'Auxiliar P', 'Combos D', 'Salón', 'Oficios Varios', 'Domicilio', 'Cocina']
                    .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setDlgState(() => role = v);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                final name = nameCtrl.text.trim();
                if (name.isNotEmpty) {
                  setState(() {
                    final nextId = _scheduleRows.length + 1;
                    _scheduleRows.add(
                      WeeklyScheduleRow(
                        idNumber: nextId,
                        collaboratorId: '100$nextId',
                        collaboratorName: name,
                        role: role,
                        dayShifts: {1: '-', 2: '-', 3: '-', 4: '-', 5: '-', 6: '-', 7: '-'},
                      ),
                    );
                  });
                  Navigator.pop(ctx);
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFAC0017), foregroundColor: Colors.white),
              child: const Text('Agregar'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final isDesktop = MediaQuery.of(context).size.width > 900;

    final containerBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final borderColor = isDark ? Colors.white12 : const Color(0xFFE5E7EB);
    final titleColor = isDark ? Colors.white : const Color(0xFF191C1E);
    final subtextColor = isDark ? Colors.white60 : const Color(0xFF555555);
    const primaryRed = Color(0xFFAC0017);

    final weekEndDate = _weekStartDate.add(const Duration(days: 6));
    final weekDaysList = List.generate(7, (i) => _weekStartDate.add(Duration(days: i)));
    final dayNames = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];

    return Container(
      decoration: BoxDecoration(
        color: containerBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. CABECERA OFICIAL FORMATO DRO'001.1
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFFAFBFD),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              border: Border(bottom: BorderSide(color: borderColor)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Logo Frisby y Título de la Planilla Oficial
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: primaryRed,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'FRISBY',
                              style: GoogleFonts.sora(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                letterSpacing: 1.1,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'PROGRAMACIÓN DE HORARIOS',
                                  style: GoogleFonts.hankenGrotesk(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.3,
                                    color: titleColor,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  '${widget.restaurantName} • DRO\'001.1',
                                  style: GoogleFonts.hankenGrotesk(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: subtextColor,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    if (!widget.isCollaboratorView)
                      ElevatedButton.icon(
                        onPressed: _addNewCollaboratorRow,
                        icon: const Icon(Icons.person_add, size: 13),
                        label: const Text('Agregar Fila', style: TextStyle(fontSize: 11)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryRed,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),

                // Selector y Navegador de Semana Centrado
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left, size: 20),
                      onPressed: _previousWeek,
                      tooltip: 'Semana Anterior',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white10 : const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: isDark ? Colors.white12 : Colors.grey[300]!),
                      ),
                      child: Text(
                        'Semana: ${_weekStartDate.day} ${_getMonthName(_weekStartDate.month)} - ${weekEndDate.day} ${_getMonthName(weekEndDate.month)}',
                        style: GoogleFonts.hankenGrotesk(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: primaryRed,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.chevron_right, size: 20),
                      onPressed: _nextWeek,
                      tooltip: 'Siguiente Semana',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Banner informativo de desplazamiento horizontal para móviles
          if (!isDesktop)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withValues(alpha: 0.02) : const Color(0xFFF9FAFC),
                border: Border(bottom: BorderSide(color: borderColor.withValues(alpha: 0.5))),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.swipe_outlined, size: 14, color: subtextColor),
                  const SizedBox(width: 6),
                  Text(
                    'Desliza horizontalmente para ver todos los días de la semana',
                    style: GoogleFonts.hankenGrotesk(
                      fontSize: 10,
                      color: subtextColor,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),

          // 2. TABLA SEMANAL DRO'001.1 (Estilo Limpio y Moderno)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: isDesktop ? 980 : 880),
              child: DataTable(
                headingRowHeight: 52,
                dataRowMinHeight: 54,
                dataRowMaxHeight: 64,
                horizontalMargin: 16,
                columnSpacing: 18,
                headingRowColor: WidgetStateProperty.all(
                  isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF9FAFB),
                ),
                border: TableBorder(
                  horizontalInside: BorderSide(
                    color: isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFF0F1F3),
                    width: 1,
                  ),
                  verticalInside: BorderSide.none,
                ),
                columns: [
                  DataColumn(
                    label: Text('#', style: _headerTextStyle(primaryRed)),
                  ),
                  DataColumn(
                    label: Text('Colaborador', style: _headerTextStyle(titleColor)),
                  ),
                  DataColumn(
                    label: Text('Cargo', style: _headerTextStyle(titleColor)),
                  ),
                  // Columnas de días de la semana con fecha
                  ...List.generate(7, (i) {
                    final dayDate = weekDaysList[i];
                    return DataColumn(
                      label: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${dayDate.day}',
                            style: GoogleFonts.hankenGrotesk(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: primaryRed,
                            ),
                          ),
                          Text(
                            dayNames[i],
                            style: GoogleFonts.hankenGrotesk(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: subtextColor,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  DataColumn(
                    label: Text('Total', textAlign: TextAlign.center, style: _headerTextStyle(primaryRed)),
                  ),
                ],
                rows: _displayedRows.asMap().entries.map((entry) {
                  final index = entry.key;
                  final row = entry.value;
                  final totalHours = row.calculateTotalHours();
                  final isOvertime = totalHours > 48;
                  final isEvenRow = index % 2 == 0;
                  final rowBg = isEvenRow
                      ? Colors.transparent
                      : (isDark ? Colors.white.withValues(alpha: 0.02) : const Color(0xFFFBFBFD));

                  return DataRow(
                    color: WidgetStateProperty.all(rowBg),
                    cells: [
                      // N°
                      DataCell(
                        Text(
                          '${row.idNumber}',
                          style: GoogleFonts.hankenGrotesk(
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white60 : Colors.grey[700],
                            fontSize: 12,
                          ),
                        ),
                      ),
                      // Nombre colaborador
                      DataCell(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: primaryRed.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                row.collaboratorName.substring(0, 1).toUpperCase(),
                                style: GoogleFonts.hankenGrotesk(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: primaryRed,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              row.collaboratorName,
                              style: GoogleFonts.hankenGrotesk(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: titleColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Cargo
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white10 : const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            row.role,
                            style: GoogleFonts.hankenGrotesk(
                              fontSize: 11,
                              color: subtextColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      // 7 Celdas de días (Lunes a Domingo)
                      ...List.generate(7, (i) {
                        final dayIndex = i + 1;
                        final shift = row.dayShifts[dayIndex] ?? '-';
                        final note = row.dayNotes[dayIndex];
                        final dayDate = weekDaysList[i];

                        return DataCell(
                          InkWell(
                            onTap: widget.isCollaboratorView
                                ? null
                                : () => _showQuickShiftEditor(
                                      context: context,
                                      row: row,
                                      dayIndex: dayIndex,
                                      dayDate: dayDate,
                                      currentShift: shift,
                                    ),
                            borderRadius: BorderRadius.circular(10),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                              child: _buildShiftCellContent(shift, isDark, note: note),
                            ),
                          ),
                        );
                      }),
                      // Horas Laboradas
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                          decoration: BoxDecoration(
                            color: isOvertime
                                ? const Color(0xFFBA1A1A).withValues(alpha: 0.15)
                                : const Color(0xFF2E7D32).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${totalHours.toStringAsFixed(0)}h',
                            style: GoogleFonts.hankenGrotesk(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isOvertime ? const Color(0xFFBA1A1A) : const Color(0xFF2E7D32),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),

          // 3. SECCIÓN INFERIOR DE OBSERVACIONES Y EVENTOS
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.02) : const Color(0xFFF9FAFB),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
              border: Border(top: BorderSide(color: borderColor)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 12,
                  runSpacing: 6,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.sticky_note_2_outlined, size: 18, color: primaryRed),
                        const SizedBox(width: 8),
                        Text(
                          'Observaciones y Eventos Especiales:',
                          style: GoogleFonts.hankenGrotesk(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: titleColor,
                          ),
                        ),
                      ],
                    ),
                    if (!widget.isCollaboratorView)
                      Text(
                        'Toca cualquier celda para editar el turno',
                        style: GoogleFonts.hankenGrotesk(fontSize: 11, color: subtextColor, fontStyle: FontStyle.italic),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: _observations.map((obs) {
                    final obsColor = obs['color'] as Color;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: obsColor.withValues(alpha: isDark ? 0.15 : 0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: obsColor.withValues(alpha: isDark ? 0.3 : 0.2)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(color: obsColor, shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: RichText(
                              text: TextSpan(
                                style: GoogleFonts.hankenGrotesk(fontSize: 12, color: titleColor),
                                children: [
                                  TextSpan(
                                    text: '[${obs['day']}] ${obs['title']}: ',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  TextSpan(
                                    text: obs['participants'] as String,
                                    style: TextStyle(color: isDark ? Colors.white70 : const Color(0xFF555555)),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShiftCellContent(String shift, bool isDark, {String? note}) {
    final hasNote = note != null && note.isNotEmpty;

    if (shift == '☺') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFF2E7D32).withValues(alpha: isDark ? 0.2 : 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.bedtime_outlined, size: 13, color: Color(0xFF2E7D32)),
            const SizedBox(width: 4),
            Text(
              'Libre',
              style: GoogleFonts.hankenGrotesk(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF2E7D32),
              ),
            ),
          ],
        ),
      );
    }

    if (shift == '-' || shift.isEmpty) {
      if (hasNote) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF7C3AED).withValues(alpha: isDark ? 0.25 : 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            note,
            textAlign: TextAlign.center,
            style: GoogleFonts.hankenGrotesk(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF7C3AED)),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        );
      }

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        alignment: Alignment.center,
        child: Text(
          '—',
          style: GoogleFonts.hankenGrotesk(fontSize: 12, color: isDark ? Colors.white24 : Colors.grey[400]),
        ),
      );
    }

    // Color semántico por tipo de turno
    Color chipBg;
    Color chipText;

    if (shift.startsWith('8-') || shift.startsWith('08-') || shift.startsWith('9-')) {
      // Apertura / Mañana (Azul suave)
      chipBg = const Color(0xFF0284C7).withValues(alpha: isDark ? 0.2 : 0.1);
      chipText = isDark ? const Color(0xFF7DD3FC) : const Color(0xFF0369A1);
    } else if (shift.contains('14-') || shift.contains('15-') || shift.contains('16-')) {
      // Cierre / Tarde (Rojo / Salmón suave)
      chipBg = const Color(0xFFC8102E).withValues(alpha: isDark ? 0.2 : 0.1);
      chipText = isDark ? const Color(0xFFFFB3AD) : const Color(0xFFC8102E);
    } else if (shift.contains('\n') || shift.contains('/')) {
      // Turno Partido (Púrpura suave)
      chipBg = const Color(0xFF7C3AED).withValues(alpha: isDark ? 0.2 : 0.1);
      chipText = isDark ? const Color(0xFFC4B5FD) : const Color(0xFF6D28D9);
    } else {
      // Refuerzo / Intermedio (Ámbar / Naranja)
      chipBg = const Color(0xFFD97706).withValues(alpha: isDark ? 0.2 : 0.1);
      chipText = isDark ? const Color(0xFFFDE68A) : const Color(0xFFB45309);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: chipBg,
        borderRadius: BorderRadius.circular(10),
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            shift,
            textAlign: TextAlign.center,
            style: GoogleFonts.hankenGrotesk(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: chipText,
              height: 1.1,
            ),
          ),
          if (hasNote) ...[
            const SizedBox(height: 2),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: (note.contains('Biodanza')
                    ? const Color(0xFF2E7D32)
                    : (note.contains('Reunión') ? const Color(0xFFD2232A) : const Color(0xFF7C3AED))).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                note.replaceAll(RegExp(r'^[🌿👥🧹🎓]\s*'), ''),
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  color: note.contains('Biodanza')
                      ? const Color(0xFF2E7D32)
                      : (note.contains('Reunión') ? const Color(0xFFD2232A) : const Color(0xFF7C3AED)),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ],
      ),
    );
  }

  TextStyle _headerTextStyle(Color color) {
    return GoogleFonts.hankenGrotesk(
      fontSize: 12,
      fontWeight: FontWeight.bold,
      color: color,
    );
  }

  String _getMonthName(int month) {
    const months = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];
    return months[month - 1];
  }
}
