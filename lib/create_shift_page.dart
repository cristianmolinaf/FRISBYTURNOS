import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'google_fonts_wrapper.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CreateShiftPage extends StatefulWidget {
  final String username;
  final String currentStore;
  final List<Map<String, dynamic>> teamMembers;
  final Function(Map<String, dynamic> newShift)? onShiftCreated;
  final bool? forceIOS;

  const CreateShiftPage({
    super.key,
    this.username = 'admin@frisby.com',
    this.currentStore = 'Frisby Parque Arboleda',
    this.teamMembers = const [],
    this.onShiftCreated,
    this.forceIOS,
  });

  @override
  State<CreateShiftPage> createState() => _CreateShiftPageState();
}

class _CreateShiftPageState extends State<CreateShiftPage> {
  // Theme override state
  bool? _isDarkModeOverride;

  // Form Controllers & State
  final _formKey = GlobalKey<FormState>();
  final _colaboradorController = TextEditingController();
  final _notasController = TextEditingController();

  Map<String, dynamic>? _selectedCollaborator;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _horaInicio = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _horaFin = const TimeOfDay(hour: 16, minute: 0);
  String _selectedStation = 'Cocina';
  bool _isLoading = false;

  late List<Map<String, dynamic>> _collaboratorsList;

  final List<Map<String, dynamic>> _stations = [
    {'name': 'Caja', 'icon': Icons.point_of_sale},
    {'name': 'Cocina', 'icon': Icons.restaurant},
    {'name': 'Armado', 'icon': Icons.layers_outlined},
    {'name': 'Freidoras', 'icon': Icons.local_fire_department},
    {'name': 'Domicilios', 'icon': Icons.delivery_dining},
  ];

  @override
  void initState() {
    super.initState();
    _collaboratorsList = widget.teamMembers.isNotEmpty
        ? widget.teamMembers
        : [
            {'id': '10002', 'name': 'Carlos Mendoza', 'role': 'Cocina', 'status': 'En turno'},
            {'id': '10003', 'name': 'Laura Restrepo', 'role': 'Caja', 'status': 'En turno'},
            {'id': '10004', 'name': 'Mateo Gómez', 'role': 'Freidoras', 'status': 'Pausa'},
            {'id': '10005', 'name': 'Sofía Morales', 'role': 'Armado', 'status': 'Fuera de turno'},
            {'id': '10006', 'name': 'Andrés Vargas', 'role': 'Domicilios', 'status': 'Fuera de turno'},
          ];

    if (_collaboratorsList.isNotEmpty) {
      _selectedCollaborator = _collaboratorsList.first;
      _colaboradorController.text = _selectedCollaborator!['name'] as String;
    }
  }

  @override
  void dispose() {
    _colaboradorController.dispose();
    _notasController.dispose();
    super.dispose();
  }

  bool _isDarkMode(BuildContext context) {
    if (_isDarkModeOverride != null) return _isDarkModeOverride!;
    return MediaQuery.of(context).platformBrightness == Brightness.dark;
  }

  void _toggleTheme() {
    setState(() {
      _isDarkModeOverride = !_isDarkMode(context);
    });
  }

  String _formatDate(DateTime date) {
    final months = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];
    return '${date.day} de ${months[date.month - 1]}, ${date.year}';
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  int _calculateHours() {
    final startMinutes = _horaInicio.hour * 60 + _horaInicio.minute;
    var endMinutes = _horaFin.hour * 60 + _horaFin.minute;
    if (endMinutes < startMinutes) {
      endMinutes += 24 * 60; // Overnight shift
    }
    return ((endMinutes - startMinutes) / 60).round();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 7)),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      builder: (context, child) {
        final isDark = _isDarkMode(context);
        return Theme(
          data: isDark
              ? ThemeData.dark().copyWith(
                  colorScheme: const ColorScheme.dark(
                    primary: Color(0xFFAC0017),
                    onPrimary: Colors.white,
                    surface: Color(0xFF1E1E1E),
                    onSurface: Colors.white,
                  ),
                )
              : ThemeData.light().copyWith(
                  colorScheme: const ColorScheme.light(
                    primary: Color(0xFFAC0017),
                    onPrimary: Colors.white,
                    surface: Colors.white,
                    onSurface: Color(0xFF191C1E),
                  ),
                ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _selectTime({required bool isStart}) async {
    final initialTime = isStart ? _horaInicio : _horaFin;
    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        final isDark = _isDarkMode(context);
        return Theme(
          data: isDark
              ? ThemeData.dark().copyWith(
                  colorScheme: const ColorScheme.dark(
                    primary: Color(0xFFAC0017),
                    onPrimary: Colors.white,
                    surface: Color(0xFF1E1E1E),
                    onSurface: Colors.white,
                  ),
                )
              : ThemeData.light().copyWith(
                  colorScheme: const ColorScheme.light(
                    primary: Color(0xFFAC0017),
                    onPrimary: Colors.white,
                    surface: Colors.white,
                    onSurface: Color(0xFF191C1E),
                  ),
                ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _horaInicio = picked;
        } else {
          _horaFin = picked;
        }
      });
    }
  }

  void _showCollaboratorSearchDialog(bool isDark) {
    final titleColor = isDark ? Colors.white : const Color(0xFF191C1E);
    final dialogBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;

    showDialog(
      context: context,
      builder: (context) {
        String searchQuery = '';
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final filtered = _collaboratorsList.where((c) {
              final name = (c['name'] as String).toLowerCase();
              final role = (c['role'] as String? ?? '').toLowerCase();
              return name.contains(searchQuery.toLowerCase()) || role.contains(searchQuery.toLowerCase());
            }).toList();

            return AlertDialog(
              backgroundColor: dialogBg,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text(
                'Seleccionar Colaborador',
                style: GoogleFonts.hankenGrotesk(fontWeight: FontWeight.bold, color: titleColor),
              ),
              content: SizedBox(
                width: 400,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      autofocus: true,
                      style: GoogleFonts.hankenGrotesk(color: titleColor),
                      decoration: InputDecoration(
                        hintText: 'Buscar por nombre o estación...',
                        hintStyle: GoogleFonts.hankenGrotesk(color: Colors.grey),
                        prefixIcon: const Icon(Icons.search, color: Color(0xFFAC0017)),
                        filled: true,
                        fillColor: isDark ? Colors.white10 : const Color(0xFFF3F4F6),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      onChanged: (val) {
                        setDialogState(() => searchQuery = val);
                      },
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 250,
                      child: filtered.isEmpty
                          ? Center(
                              child: Text(
                                'No se encontraron colaboradores.',
                                style: GoogleFonts.hankenGrotesk(color: Colors.grey),
                              ),
                            )
                          : ListView.separated(
                              shrinkWrap: true,
                              itemCount: filtered.length,
                              separatorBuilder: (context, index) => const Divider(height: 1, color: Colors.white10),
                              itemBuilder: (context, index) {
                                final col = filtered[index];
                                final isSelected = _selectedCollaborator?['id'] == col['id'];
                                return ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: const Color(0xFFAC0017).withValues(alpha: 0.12),
                                    child: Text(
                                      (col['name'] as String).substring(0, 1).toUpperCase(),
                                      style: GoogleFonts.hankenGrotesk(fontWeight: FontWeight.bold, color: const Color(0xFFAC0017)),
                                    ),
                                  ),
                                  title: Text(
                                    col['name'] as String,
                                    style: GoogleFonts.hankenGrotesk(
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                      color: isSelected ? const Color(0xFFAC0017) : titleColor,
                                    ),
                                  ),
                                  subtitle: Text(
                                    'Estación habitual: ${col['role'] ?? 'Cocina'}',
                                    style: GoogleFonts.hankenGrotesk(fontSize: 12, color: Colors.grey),
                                  ),
                                  trailing: isSelected ? const Icon(Icons.check_circle, color: Color(0xFFAC0017), size: 20) : null,
                                  onTap: () {
                                    setState(() {
                                      _selectedCollaborator = col;
                                      _colaboradorController.text = col['name'] as String;
                                      if (col['role'] != null && _stations.any((s) => s['name'] == col['role'])) {
                                        _selectedStation = col['role'] as String;
                                      }
                                    });
                                    Navigator.pop(context);
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Cancelar',
                    style: GoogleFonts.hankenGrotesk(color: Colors.grey, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _submitCreateShift() async {
    if (_selectedCollaborator == null && _colaboradorController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Por favor selecciona o ingresa un colaborador.',
            style: GoogleFonts.hankenGrotesk(color: Colors.white),
          ),
          backgroundColor: const Color(0xFFBA1A1A),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final collaboratorName = _selectedCollaborator?['name'] ?? _colaboradorController.text.trim();
    final newShift = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'colaborador_id': _selectedCollaborator?['id'] ?? 'colab_gen',
      'colaborador_nombre': collaboratorName,
      'estacion': _selectedStation,
      'fecha': _selectedDate.toIso8601String().split('T').first,
      'hora_inicio': '${_horaInicio.hour.toString().padLeft(2, '0')}:${_horaInicio.minute.toString().padLeft(2, '0')}',
      'hora_fin': '${_horaFin.hour.toString().padLeft(2, '0')}:${_horaFin.minute.toString().padLeft(2, '0')}',
      'duracion': '${_calculateHours()} hrs',
      'estado': 'programado',
      'restaurante': widget.currentStore,
      'notas': _notasController.text.trim(),
    };

    try {
      // Attempt insert into Supabase if accessible
      await Supabase.instance.client.from('turnos').insert({
        'colaborador_id': _selectedCollaborator?['id'] ?? '00000000-0000-0000-0000-000000000000',
        'supervisor_id': '00000000-0000-0000-0000-000000000000',
        'restaurante_id': '00000000-0000-0000-0000-000000000000',
        'fecha': newShift['fecha'],
        'hora_inicio': '${newShift['hora_inicio']}:00',
        'hora_fin': '${newShift['hora_fin']}:00',
        'estacion': _selectedStation,
        'estado': 'programado',
      }).timeout(const Duration(milliseconds: 1500));
    } catch (_) {
      // Fallback to local state
    }

    if (widget.onShiftCreated != null) {
      widget.onShiftCreated!(newShift);
    }

    if (mounted) {
      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '¡Turno creado con éxito para $collaboratorName en $_selectedStation!',
                  style: GoogleFonts.hankenGrotesk(color: Colors.white, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF2E7D32),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );

      Navigator.pop(context, newShift);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final isDesktop = mediaQuery.size.width > 800;
    final isIOS = widget.forceIOS ?? (Theme.of(context).platform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.iOS);
    final isDark = _isDarkMode(context);

    if (isDesktop) {
      return _buildDesktopLayout(isDark);
    } else if (isIOS) {
      return _buildIOSLayout(isDark);
    } else {
      return _buildAndroidLayout(isDark);
    }
  }

  // ==========================================
  // 1. DESKTOP WEB / ESCRITORIO LAYOUT
  // ==========================================
  Widget _buildDesktopLayout(bool isDark) {
    const primaryRed = Color(0xFFAC0017);
    final surfaceBg = isDark ? const Color(0xFF141414) : const Color(0xFFF8F9FB);
    final sidebarBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final cardBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final titleColor = isDark ? const Color(0xFFE1E2E4) : const Color(0xFF191C1E);
    final subtextColor = isDark ? const Color(0xFFC6C6C7) : const Color(0xFF545D80);
    final borderColor = isDark ? Colors.white12 : const Color(0xFFE5BDBA).withValues(alpha: 0.3);
    final fieldBg = isDark ? Colors.white10 : const Color(0xFFF3F4F6);

    return Scaffold(
      backgroundColor: surfaceBg,
      body: Row(
        children: [
          // Sidebar (270px)
          Container(
            width: 270,
            decoration: BoxDecoration(
              color: sidebarBg,
              border: Border(right: BorderSide(color: borderColor)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                  blurRadius: 10,
                  offset: const Offset(2, 0),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: primaryRed,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'FRISBY',
                              style: GoogleFonts.hankenGrotesk(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 13,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'TURNOS',
                            style: GoogleFonts.hankenGrotesk(
                              color: titleColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: const BoxDecoration(
                              color: Color(0xFFD2232A),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.admin_panel_settings, color: Colors.white, size: 24),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Admin Central',
                                  style: GoogleFonts.hankenGrotesk(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: primaryRed,
                                  ),
                                ),
                                Text(
                                  'Gestión de Operaciones',
                                  style: GoogleFonts.hankenGrotesk(
                                    fontSize: 12,
                                    color: subtextColor,
                                  ),
                                ),
                                Text(
                                  widget.currentStore,
                                  style: GoogleFonts.hankenGrotesk(
                                    fontSize: 11,
                                    color: subtextColor.withValues(alpha: 0.8),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const Divider(height: 1, color: Colors.white10),

                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                    children: [
                      _buildSidebarNavItem(
                        icon: Icons.dashboard_outlined,
                        title: 'Panel Principal',
                        isSelected: false,
                        isDark: isDark,
                        onTap: () => Navigator.pop(context),
                      ),
                      _buildSidebarNavItem(
                        icon: Icons.edit_calendar,
                        title: 'Crear Turnos',
                        isSelected: true,
                        isDark: isDark,
                        onTap: () {},
                      ),
                      _buildSidebarNavItem(
                        icon: Icons.restaurant_outlined,
                        title: 'Estaciones',
                        isSelected: false,
                        isDark: isDark,
                        onTap: () => Navigator.pop(context),
                      ),
                      _buildSidebarNavItem(
                        icon: Icons.sync_alt,
                        title: 'Solicitudes',
                        isSelected: false,
                        isDark: isDark,
                        onTap: () => Navigator.pop(context),
                      ),
                      _buildSidebarNavItem(
                        icon: Icons.switch_account_outlined,
                        title: 'Asistencia',
                        isSelected: false,
                        isDark: isDark,
                        onTap: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back, size: 16, color: Colors.grey),
                        label: Text('Volver', style: GoogleFonts.hankenGrotesk(color: Colors.grey)),
                      ),
                      IconButton(
                        icon: Icon(isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined, color: titleColor),
                        onPressed: _toggleTheme,
                        tooltip: 'Cambiar Tema',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Main Area
          Expanded(
            child: Column(
              children: [
                Container(
                  height: 64,
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  decoration: BoxDecoration(
                    color: sidebarBg,
                    border: Border(bottom: BorderSide(color: borderColor)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          InkWell(
                            onTap: () => Navigator.pop(context),
                            child: Text(
                              'Turnos',
                              style: GoogleFonts.hankenGrotesk(fontSize: 13, color: subtextColor, fontWeight: FontWeight.w500),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
                          const SizedBox(width: 8),
                          Text(
                            'Crear Nuevo Turno',
                            style: GoogleFonts.hankenGrotesk(fontSize: 13, fontWeight: FontWeight.bold, color: titleColor),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white10 : const Color(0xFFF3F4F6),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.storefront, size: 14, color: primaryRed),
                                const SizedBox(width: 6),
                                Text(
                                  widget.currentStore,
                                  style: GoogleFonts.hankenGrotesk(fontSize: 12, fontWeight: FontWeight.w600, color: titleColor),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          IconButton(
                            icon: Icon(isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined, color: titleColor),
                            onPressed: _toggleTheme,
                            tooltip: 'Cambiar Tema',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 720),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                InkWell(
                                  borderRadius: BorderRadius.circular(30),
                                  onTap: () => Navigator.pop(context),
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: isDark ? Colors.white10 : const Color(0xFFEDEEF0),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(Icons.arrow_back, size: 20, color: titleColor),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Crear Nuevo Turno',
                                      style: GoogleFonts.hankenGrotesk(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: titleColor,
                                      ),
                                    ),
                                    Text(
                                      'Asigna un horario y estación a un colaborador.',
                                      style: GoogleFonts.hankenGrotesk(
                                        fontSize: 14,
                                        color: subtextColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            Container(
                              padding: const EdgeInsets.all(32),
                              decoration: BoxDecoration(
                                color: cardBg,
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
                              child: _buildFormContent(titleColor, subtextColor, fieldBg, borderColor, primaryRed),
                            ),
                          ],
                        ),
                      ),
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

  // ==========================================
  // 2. iOS NATIVE LAYOUT (Flat / Glassmorphism)
  // ==========================================
  Widget _buildIOSLayout(bool isDark) {
    const primaryRed = Color(0xFFC8102E);
    final surfaceBg = isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF9F9F9);
    final cardBg = isDark ? const Color(0xFF2C2C2E) : Colors.white;
    final titleColor = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final subtextColor = isDark ? const Color(0xFFB0B0B0) : const Color(0xFF757575);
    final borderColor = isDark ? Colors.white12 : const Color(0xFFE0E0E0);
    final fieldBg = isDark ? Colors.white10 : const Color(0xFFF2F2F7);

    return Scaffold(
      backgroundColor: surfaceBg,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        foregroundColor: isDark ? Colors.white : const Color(0xFF1A1A1A),
        elevation: 0.5,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Crear Nuevo Turno',
          style: GoogleFonts.sora(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: titleColor,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode, color: primaryRed),
            onPressed: _toggleTheme,
            tooltip: 'Cambiar Tema',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // iOS Section Header
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'DETALLES DE LA JORNADA',
                    style: GoogleFonts.sora(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                      color: subtextColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.currentStore,
                    style: GoogleFonts.sora(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: titleColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // iOS Form Card (White with 14px radius and drop shadow)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                    blurRadius: 12,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: _buildFormContent(titleColor, subtextColor, fieldBg, borderColor, primaryRed),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: cardBg,
          border: Border(top: BorderSide(color: borderColor)),
        ),
        child: SafeArea(
          child: BottomNavigationBar(
            currentIndex: 0,
            backgroundColor: cardBg,
            selectedItemColor: primaryRed,
            unselectedItemColor: subtextColor,
            type: BottomNavigationBarType.fixed,
            selectedLabelStyle: GoogleFonts.sora(fontSize: 11, fontWeight: FontWeight.bold),
            unselectedLabelStyle: GoogleFonts.sora(fontSize: 11),
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.event_note), label: 'Turnos'),
              BottomNavigationBarItem(icon: Icon(Icons.swap_horiz), label: 'Cambios'),
              BottomNavigationBarItem(icon: Icon(Icons.medical_services_outlined), label: 'Permisos'),
              BottomNavigationBarItem(icon: Icon(Icons.group_outlined), label: 'Equipo'),
            ],
            onTap: (_) => Navigator.pop(context),
          ),
        ),
      ),
    );
  }

  // ==========================================
  // 3. ANDROID NATIVE LAYOUT (Material Red)
  // ==========================================
  Widget _buildAndroidLayout(bool isDark) {
    const primaryRed = Color(0xFFAC0017);
    final surfaceBg = isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FB);
    final cardBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final titleColor = isDark ? const Color(0xFFE1E2E4) : const Color(0xFF191C1E);
    final subtextColor = isDark ? const Color(0xFFC6C6C7) : const Color(0xFF545D80);
    final borderColor = isDark ? Colors.white12 : const Color(0xFFE5BDBA).withValues(alpha: 0.3);
    final fieldBg = isDark ? Colors.white10 : const Color(0xFFF3F4F6);

    return Scaffold(
      backgroundColor: surfaceBg,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1F1F1F) : primaryRed,
        foregroundColor: Colors.white,
        elevation: 1,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Crear Nuevo Turno',
          style: GoogleFonts.hankenGrotesk(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: Icon(isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
            onPressed: _toggleTheme,
            tooltip: 'Cambiar Tema',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Información de la Jornada',
              style: GoogleFonts.hankenGrotesk(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: titleColor,
              ),
            ),
            Text(
              'Asigna horario y estación en ${widget.currentStore}',
              style: GoogleFonts.hankenGrotesk(fontSize: 13, color: subtextColor),
            ),
            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: _buildFormContent(titleColor, subtextColor, fieldBg, borderColor, primaryRed),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: cardBg,
          border: Border(top: BorderSide(color: borderColor)),
        ),
        child: BottomNavigationBar(
          currentIndex: 0,
          backgroundColor: cardBg,
          selectedItemColor: primaryRed,
          unselectedItemColor: subtextColor,
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.event_note), label: 'Turnos'),
            BottomNavigationBarItem(icon: Icon(Icons.swap_horiz), label: 'Cambios'),
            BottomNavigationBarItem(icon: Icon(Icons.medical_services_outlined), label: 'Permisos'),
            BottomNavigationBarItem(icon: Icon(Icons.group_outlined), label: 'Equipo'),
          ],
          onTap: (_) => Navigator.pop(context),
        ),
      ),
    );
  }

  // ==========================================
  // SHARED FORM CONTENT COMPONENT
  // ==========================================
  Widget _buildFormContent(Color titleColor, Color subtextColor, Color fieldBg, Color borderColor, Color primaryRed) {
    final isDark = _isDarkMode(context);

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Colaborador Field
          _buildFieldLabel('Colaborador', titleColor),
          const SizedBox(height: 6),
          InkWell(
            onTap: () => _showCollaboratorSearchDialog(isDark),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: fieldBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor),
              ),
              child: Row(
                children: [
                  Icon(Icons.person_outline, color: subtextColor, size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _selectedCollaborator?['name'] ?? 'Seleccionar colaborador...',
                      style: GoogleFonts.hankenGrotesk(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: _selectedCollaborator != null ? titleColor : Colors.grey,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: primaryRed.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.search, color: primaryRed, size: 18),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // 2. Fecha del Turno
          _buildFieldLabel('Fecha del Turno', titleColor),
          const SizedBox(height: 6),
          InkWell(
            onTap: _selectDate,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: fieldBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor),
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_month_outlined, color: subtextColor, size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _formatDate(_selectedDate),
                      style: GoogleFonts.hankenGrotesk(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: titleColor,
                      ),
                    ),
                  ),
                  const Icon(Icons.arrow_drop_down, color: Colors.grey),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // 3. Horario Grid (Inicio y Fin)
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFieldLabel('Hora Inicio', titleColor),
                    const SizedBox(height: 6),
                    InkWell(
                      onTap: () => _selectTime(isStart: true),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                        decoration: BoxDecoration(
                          color: fieldBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: borderColor),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.schedule, color: subtextColor, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              _formatTime(_horaInicio),
                              style: GoogleFonts.hankenGrotesk(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: titleColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFieldLabel('Hora Fin', titleColor),
                    const SizedBox(height: 6),
                    InkWell(
                      onTap: () => _selectTime(isStart: false),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                        decoration: BoxDecoration(
                          color: fieldBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: borderColor),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.schedule, color: subtextColor, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              _formatTime(_horaFin),
                              style: GoogleFonts.hankenGrotesk(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: titleColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 14, color: primaryRed),
                const SizedBox(width: 6),
                Text(
                  'Duración: ${_calculateHours()} horas programadas',
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 12,
                    color: subtextColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // 4. Estación Asignada
          _buildFieldLabel('Estación Asignada', titleColor),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _stations.map((s) {
              final isSelected = _selectedStation == s['name'];
              return InkWell(
                onTap: () => setState(() => _selectedStation = s['name'] as String),
                borderRadius: BorderRadius.circular(30),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFFD2232A) : fieldBg,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: isSelected ? primaryRed : borderColor,
                      width: isSelected ? 1.5 : 1.0,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: primaryRed.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        s['icon'] as IconData,
                        size: 18,
                        color: isSelected ? Colors.white : subtextColor,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        s['name'] as String,
                        style: GoogleFonts.hankenGrotesk(
                          fontSize: 13,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected ? Colors.white : titleColor,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 24),

          // 5. Notas Adicionales
          _buildFieldLabel('Notas Adicionales (Opcional)', titleColor),
          const SizedBox(height: 6),
          TextField(
            controller: _notasController,
            maxLines: 3,
            style: GoogleFonts.hankenGrotesk(color: titleColor),
            decoration: InputDecoration(
              hintText: 'Observaciones del turno...',
              hintStyle: GoogleFonts.hankenGrotesk(color: Colors.grey, fontSize: 13),
              filled: true,
              fillColor: fieldBg,
              contentPadding: const EdgeInsets.all(16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: borderColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: primaryRed, width: 1.5),
              ),
            ),
          ),

          const SizedBox(height: 32),

          // Submit Button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _submitCreateShift,
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Icon(Icons.add_task, size: 20),
              label: Text(
                _isLoading ? 'Creando Turno...' : 'Crear Turno',
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.2,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryRed,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                shadowColor: primaryRed.withValues(alpha: 0.4),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldLabel(String label, Color color) {
    return Text(
      label,
      style: GoogleFonts.hankenGrotesk(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: color,
        letterSpacing: 0.1,
      ),
    );
  }

  Widget _buildSidebarNavItem({
    required IconData icon,
    required String title,
    required bool isSelected,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    final activeBg = isDark ? const Color(0xFFD2232A).withValues(alpha: 0.2) : const Color(0xFFCCD6FE);
    final activeText = isDark ? const Color(0xFFFFB3AD) : const Color(0xFF101A39);
    final inactiveText = isDark ? const Color(0xFFC6C6C7) : const Color(0xFF545D80);

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        dense: true,
        tileColor: isSelected ? activeBg : Colors.transparent,
        leading: Icon(
          icon,
          size: 20,
          color: isSelected ? const Color(0xFFAC0017) : inactiveText,
        ),
        title: Text(
          title,
          style: GoogleFonts.hankenGrotesk(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? activeText : inactiveText,
          ),
        ),
        onTap: onTap,
      ),
    );
  }
}
