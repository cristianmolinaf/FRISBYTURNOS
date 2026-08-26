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

  WeeklyScheduleRow({
    required this.idNumber,
    required this.collaboratorId,
    required this.collaboratorName,
    required this.role,
    required this.dayShifts,
  });

  WeeklyScheduleRow copyWith({
    int? idNumber,
    String? collaboratorId,
    String? collaboratorName,
    String? role,
    Map<int, String>? dayShifts,
  }) {
    return WeeklyScheduleRow(
      idNumber: idNumber ?? this.idNumber,
      collaboratorId: collaboratorId ?? this.collaboratorId,
      collaboratorName: collaboratorName ?? this.collaboratorName,
      role: role ?? this.role,
      dayShifts: dayShifts ?? Map<int, String>.from(this.dayShifts),
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

  const FrisbyWeeklyScheduleSheet({
    super.key,
    required this.restaurantName,
    required this.isDark,
    required this.isIOS,
    this.onAddShiftPressed,
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

              Text(
                'Selección Rápida de Horario (1 Toque):',
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white70 : const Color(0xFF555555),
                ),
              ),
              const SizedBox(height: 10),

              // Grid de presets rápidos
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: shiftPresets.map((p) {
                  final val = p['val'] as String;
                  final isSelected = currentShift == val;
                  final pColor = p['color'] as Color;

                  return InkWell(
                    onTap: () {
                      _updateShift(row.idNumber, dayIndex, val);
                      Navigator.pop(ctx);
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? pColor.withValues(alpha: 0.25)
                            : (isDark ? Colors.white10 : const Color(0xFFF3F4F6)),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? pColor : (isDark ? Colors.white12 : Colors.grey[300]!),
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
                        ],
                      ),
                    ),
                  );
                }).toList(),
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
                      if (val.isNotEmpty) {
                        _updateShift(row.idNumber, dayIndex, val);
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

  void _updateShift(int idNumber, int dayIndex, String newShift) {
    setState(() {
      final index = _scheduleRows.indexWhere((r) => r.idNumber == idNumber);
      if (index != -1) {
        final row = _scheduleRows[index];
        final updatedShifts = Map<int, String>.from(row.dayShifts);
        updatedShifts[dayIndex] = newShift;
        _scheduleRows[index] = row.copyWith(dayShifts: updatedShifts);
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Horario actualizado: $newShift'),
        duration: const Duration(seconds: 1),
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
    final headerCellBg = isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFF3F4F6);
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
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFFAFBFD),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              border: Border(bottom: BorderSide(color: borderColor)),
            ),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              runSpacing: 10,
              children: [
                // Logo Frisby y Título de la Planilla Oficial
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: primaryRed,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'FRISBY',
                          style: GoogleFonts.sora(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'PROGRAMACIÓN DE HORARIOS',
                              style: GoogleFonts.hankenGrotesk(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
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

                // Selector y Navegador de Semana
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.chevron_left, size: 20),
                          onPressed: _previousWeek,
                          tooltip: 'Semana Anterior',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white10 : const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(8),
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
                        const SizedBox(width: 6),
                        IconButton(
                          icon: const Icon(Icons.chevron_right, size: 20),
                          onPressed: _nextWeek,
                          tooltip: 'Siguiente Semana',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),

                    // Botón para agregar colaborador
                    ElevatedButton.icon(
                      onPressed: _addNewCollaboratorRow,
                      icon: const Icon(Icons.person_add, size: 14),
                      label: const Text('Agregar Fila', style: TextStyle(fontSize: 12)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryRed,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 2. TABLA SEMANAL DRO'001.1 (Con Scroll Horizontal en pantallas pequeñas)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: isDesktop ? 960 : 850),
              child: DataTable(
                headingRowHeight: 48,
                dataRowMinHeight: 46,
                dataRowMaxHeight: 56,
                horizontalMargin: 12,
                columnSpacing: 14,
                headingRowColor: WidgetStateProperty.all(headerCellBg),
                border: TableBorder(
                  horizontalInside: BorderSide(color: borderColor, width: 0.8),
                  verticalInside: BorderSide(color: borderColor, width: 0.8),
                ),
                columns: [
                  DataColumn(
                    label: Text('N°', style: _headerTextStyle(primaryRed)),
                  ),
                  DataColumn(
                    label: Text('Nombre colaborador', style: _headerTextStyle(titleColor)),
                  ),
                  DataColumn(
                    label: Text('Cargo', style: _headerTextStyle(titleColor)),
                  ),
                  // Columnas de días de la semana con fecha (Lunes [24] .. Domingo [30])
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
                              fontSize: 13,
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
                    label: Text('Horas\nLaboradas', textAlign: TextAlign.center, style: _headerTextStyle(primaryRed)),
                  ),
                ],
                rows: _scheduleRows.map((row) {
                  final totalHours = row.calculateTotalHours();
                  final isOvertime = totalHours > 48;

                  return DataRow(
                    cells: [
                      // N°
                      DataCell(
                        Text(
                          '${row.idNumber}',
                          style: GoogleFonts.hankenGrotesk(fontWeight: FontWeight.bold, color: primaryRed, fontSize: 13),
                        ),
                      ),
                      // Nombre colaborador
                      DataCell(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircleAvatar(
                              radius: 12,
                              backgroundColor: primaryRed.withValues(alpha: 0.12),
                              child: Text(
                                row.collaboratorName.substring(0, 1).toUpperCase(),
                                style: GoogleFonts.hankenGrotesk(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: primaryRed,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
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
                        Text(
                          row.role,
                          style: GoogleFonts.hankenGrotesk(
                            fontSize: 12,
                            color: subtextColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      // 7 Celdas de días (Lunes a Domingo)
                      ...List.generate(7, (i) {
                        final dayIndex = i + 1;
                        final shift = row.dayShifts[dayIndex] ?? '-';
                        final dayDate = weekDaysList[i];

                        return DataCell(
                          InkWell(
                            onTap: () => _showQuickShiftEditor(
                              context: context,
                              row: row,
                              dayIndex: dayIndex,
                              dayDate: dayDate,
                              currentShift: shift,
                            ),
                            borderRadius: BorderRadius.circular(6),
                            child: Container(
                              alignment: Alignment.center,
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                              decoration: BoxDecoration(
                                color: shift == '☺'
                                    ? const Color(0xFF2E7D32).withValues(alpha: 0.12)
                                    : (shift.isEmpty || shift == '-'
                                        ? Colors.transparent
                                        : (isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFFFF4F4))),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: _buildShiftCellContent(shift, isDark),
                            ),
                          ),
                        );
                      }),
                      // Horas Laboradas
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: isOvertime
                                ? const Color(0xFFBA1A1A).withValues(alpha: 0.15)
                                : const Color(0xFF2E7D32).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${totalHours.toStringAsFixed(0)}h',
                            style: GoogleFonts.hankenGrotesk(
                              fontSize: 12,
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

          // 3. SECCIÓN INFERIOR DE OBSERVACIONES Y EVENTOS (Fiel al pie de la planilla)
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
                    Text(
                      'Toca cualquier celda para editar el turno',
                      style: GoogleFonts.hankenGrotesk(fontSize: 11, color: subtextColor, fontStyle: FontStyle.italic),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: _observations.map((obs) {
                    final obsColor = obs['color'] as Color;
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.black26 : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: obsColor.withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(color: obsColor, shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 8),
                          RichText(
                            text: TextSpan(
                              style: GoogleFonts.hankenGrotesk(fontSize: 12, color: titleColor),
                              children: [
                                TextSpan(
                                  text: '${obs['day']} • ${obs['title']}: ',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                TextSpan(
                                  text: obs['participants'] as String,
                                  style: TextStyle(color: isDark ? Colors.white70 : const Color(0xFF555555)),
                                ),
                              ],
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

  Widget _buildShiftCellContent(String shift, bool isDark) {
    if (shift == '☺') {
      return const Text(
        '☺',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color(0xFF2E7D32),
        ),
      );
    }
    if (shift == '-' || shift.isEmpty) {
      return Text(
        '-',
        style: GoogleFonts.hankenGrotesk(fontSize: 12, color: Colors.grey),
      );
    }
    return Text(
      shift,
      textAlign: TextAlign.center,
      style: GoogleFonts.hankenGrotesk(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        color: isDark ? Colors.white : const Color(0xFFAC0017),
        height: 1.1,
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
