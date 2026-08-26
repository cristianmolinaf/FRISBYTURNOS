import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'google_fonts_wrapper.dart';
import 'widgets/frisby_weekly_schedule_sheet.dart';

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
  bool? _isDarkModeOverride;

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
    final titleColor = isDark ? const Color(0xFFE1E2E4) : const Color(0xFF191C1E);
    final subtextColor = isDark ? const Color(0xFFC6C6C7) : const Color(0xFF545D80);
    final borderColor = isDark ? Colors.white12 : const Color(0xFFE5BDBA).withValues(alpha: 0.3);

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
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'TURNOS',
                            style: GoogleFonts.hankenGrotesk(
                              color: primaryRed,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const CircleAvatar(
                            radius: 18,
                            backgroundImage: NetworkImage(
                              'https://lh3.googleusercontent.com/aida-public/AB6AXuDMgkhhPX8XzsxpqFFykCvHkvJhpP4XCWw8TmC9gw8HQzfAtsWnU96wdFRn0TK-k12jMCkVzTzRg0lknWMdZRkCC4i8mIDsHfKlEuL5tqs_8A2BYRdiwZQ885poamygDvFIbvHiCh1JwmgrzF1uBlqFLtnfKTOUJfIVusON856L9gf2pFxIlrSDTOd51irguRlRY0ayiE3q-SZMFV9NAIS_pcAy0hmQybPk9_XtRRRE1yD8xL30gQovmg',
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.username,
                                  style: GoogleFonts.hankenGrotesk(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: titleColor,
                                  ),
                                  overflow: TextOverflow.ellipsis,
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
                        title: 'Programación Semanal',
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
                            'Programación de Horarios (DRO\'001.1)',
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
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                    child: FrisbyWeeklyScheduleSheet(
                      restaurantName: widget.currentStore,
                      isDark: isDark,
                      isIOS: false,
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
          'Programación Semanal',
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
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        child: FrisbyWeeklyScheduleSheet(
          restaurantName: widget.currentStore,
          isDark: isDark,
          isIOS: true,
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
    final subtextColor = isDark ? const Color(0xFFC6C6C7) : const Color(0xFF545D80);
    final borderColor = isDark ? Colors.white12 : const Color(0xFFE5BDBA).withValues(alpha: 0.3);

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
          'Programación Semanal',
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
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        child: FrisbyWeeklyScheduleSheet(
          restaurantName: widget.currentStore,
          isDark: isDark,
          isIOS: false,
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
