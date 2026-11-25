import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// 1. DYNAMIC STATUS PILL (Top App Bar)
/// Replaces the jarring pulsing warning triangle with a calm, informative Liquid Glass pill.
class DynamicStatusPill extends StatelessWidget {
  final int criticalCount;
  final int warningCount;
  final VoidCallback onTap;
  final bool isDark;

  const DynamicStatusPill({
    super.key,
    required this.criticalCount,
    required this.warningCount,
    required this.onTap,
    this.isDark = false,
  });

  @override
  Widget build(BuildContext context) {
    final bool isCritical = criticalCount > 0;
    final bool isWarning = !isCritical && warningCount > 0;

    final Color dotColor = isCritical
        ? const Color(0xFFC8102E) // Frisby Ruby Red
        : (isWarning ? const Color(0xFFF59E0B) : const Color(0xFF10B981));

    final Color bgColor = isCritical
        ? const Color(0xFFC8102E).withValues(alpha: isDark ? 0.22 : 0.10)
        : (isWarning
            ? const Color(0xFFF59E0B).withValues(alpha: isDark ? 0.22 : 0.12)
            : const Color(0xFF10B981).withValues(alpha: isDark ? 0.20 : 0.10));

    final Color borderColor = dotColor.withValues(alpha: isDark ? 0.45 : 0.28);

    final String label = isCritical
        ? '$criticalCount Crítica${criticalCount > 1 ? 's' : ''}'
        : (isWarning ? '$warningCount Ajuste${warningCount > 1 ? 's' : ''}' : 'Óptimo');

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 240),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: borderColor, width: 1.0),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: dotColor.withValues(alpha: 0.45),
                    blurRadius: 4,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.hankenGrotesk(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : dotColor,
                letterSpacing: -0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 2. SMART OPERATIONAL ALERTS CARD (Dashboard Feed)
/// Swipeable, actionable card with severity accent, impact time chip, and 1-click action button.
class SmartOperationalAlertsCard extends StatefulWidget {
  final List<Map<String, dynamic>> alerts;
  final bool isIOS;
  final bool isDark;
  final void Function(Map<String, dynamic> alert) onQuickAction;
  final VoidCallback onViewAll;

  const SmartOperationalAlertsCard({
    super.key,
    required this.alerts,
    required this.isIOS,
    required this.isDark,
    required this.onQuickAction,
    required this.onViewAll,
  });

  @override
  State<SmartOperationalAlertsCard> createState() =>
      _SmartOperationalAlertsCardState();
}

class _SmartOperationalAlertsCardState
    extends State<SmartOperationalAlertsCard> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.alerts.isEmpty) {
      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: widget.isDark
              ? const Color(0xFF1E2923).withValues(alpha: 0.7)
              : const Color(0xFFF0FDF4),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: const Color(0xFF10B981).withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.check_circle_rounded,
                color: Color(0xFF10B981), size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Operación al 100% — Sin alertas pendientes',
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: widget.isDark
                      ? const Color(0xFFA7F3D0)
                      : const Color(0xFF065F46),
                ),
              ),
            ),
          ],
        ),
      );
    }

    final cardBg = widget.isDark
        ? const Color(0xFF241B1B).withValues(alpha: 0.85)
        : Colors.white;
    final borderColor = widget.isDark
        ? Colors.white.withValues(alpha: 0.10)
        : Colors.black.withValues(alpha: 0.06);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: widget.isDark ? 0.25 : 0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 128,
            child: PageView.builder(
              controller: _pageController,
              itemCount: widget.alerts.length,
              onPageChanged: (idx) => setState(() => _currentPage = idx),
              itemBuilder: (context, index) {
                final alert = widget.alerts[index];
                final Color accent =
                    (alert['color'] as Color?) ?? const Color(0xFFC8102E);
                final String title = alert['title']?.toString() ?? 'Alerta';
                final String station = alert['station']?.toString() ?? '';
                final String time = alert['time']?.toString() ?? '';
                final String actionLabel =
                    alert['actionLabel']?.toString() ?? 'Resolver';

                return Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Left severity bar
                      Container(
                        width: 4,
                        decoration: BoxDecoration(
                          color: accent,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Top row: Station + Time Chip
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: accent.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    station.isNotEmpty ? station : 'Operación',
                                    style: GoogleFonts.hankenGrotesk(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w700,
                                      color: accent,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    time,
                                    style: GoogleFonts.hankenGrotesk(
                                      fontSize: 11,
                                      color: widget.isDark
                                          ? Colors.white60
                                          : const Color(0xFF6B7280),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),

                            // Title
                            Text(
                              title,
                              style: GoogleFonts.hankenGrotesk(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: widget.isDark
                                    ? Colors.white
                                    : const Color(0xFF1A1A1A),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),

                            // Bottom row: 1-Click Action Pill + Ver todas
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    HapticFeedback.mediumImpact();
                                    widget.onQuickAction(alert);
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: accent,
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.bolt_rounded,
                                            color: Colors.white, size: 14),
                                        const SizedBox(width: 4),
                                        Text(
                                          actionLabel,
                                          style: GoogleFonts.hankenGrotesk(
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: widget.onViewAll,
                                  child: Text(
                                    'Ver todas (${widget.alerts.length})',
                                    style: GoogleFonts.hankenGrotesk(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600,
                                      color: widget.isDark
                                          ? Colors.white70
                                          : const Color(0xFF6B7280),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          if (widget.alerts.length > 1)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(widget.alerts.length, (i) {
                  final active = i == _currentPage;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: active ? 16 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: active
                          ? const Color(0xFFC8102E)
                          : (widget.isDark
                              ? Colors.white24
                              : Colors.black12),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  );
                }),
              ),
            ),
        ],
      ),
    );
  }
}

/// 3. UNIFIED NOTIFICATION CENTER MODAL
/// Segmented tabs (Operativas, Solicitudes, Informativas) with 1-tap Approve/Reject & Swipe-to-resolve.
class UnifiedNotificationCenterModal extends StatefulWidget {
  final List<Map<String, dynamic>> operationalAlerts;
  final bool isDark;
  final void Function(Map<String, dynamic> alert) onResolveAlert;

  const UnifiedNotificationCenterModal({
    super.key,
    required this.operationalAlerts,
    required this.isDark,
    required this.onResolveAlert,
  });

  @override
  State<UnifiedNotificationCenterModal> createState() =>
      _UnifiedNotificationCenterModalState();
}

class _UnifiedNotificationCenterModalState
    extends State<UnifiedNotificationCenterModal> {
  int _selectedTab = 0; // 0: Operativas, 1: Solicitudes, 2: Informativas

  final List<Map<String, dynamic>> _requests = [
    {
      'id': 'req-1',
      'title': 'Cambio de Turno · Freidoras',
      'subtitle': 'Mateo Gómez solicita ceder turno de 14:00 - 22:00 a Sofía',
      'time': 'Hace 12 min',
    },
    {
      'id': 'req-2',
      'title': 'Permiso Médico · Caja',
      'subtitle': 'Laura Restrepo adjuntó soporte para mañana 08:00 AM',
      'time': 'Hace 45 min',
    },
  ];

  final List<Map<String, dynamic>> _infoItems = [
    {
      'id': 'inf-1',
      'title': 'Cierre de Nómina Quincenal',
      'subtitle': 'Recuerda validar horas extras antes del viernes 6:00 PM.',
      'time': 'Hoy · 09:00 AM',
    },
    {
      'id': 'inf-2',
      'title': 'Actualización de Protocolo',
      'subtitle': 'Nuevo checklist de apertura disponible en estación Empaque.',
      'time': 'Ayer',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final bg = widget.isDark ? const Color(0xFF18181B) : Colors.white;
    final textPrimary = widget.isDark ? Colors.white : const Color(0xFF18181B);
    final textSecondary =
        widget.isDark ? Colors.white60 : const Color(0xFF6B7280);

    return Container(
      height: MediaQuery.of(context).size.height * 0.78,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 10),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: widget.isDark ? Colors.white24 : Colors.black12,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Centro de Alertas y Avisos',
                  style: GoogleFonts.sora(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close_rounded, color: textSecondary),
                ),
              ],
            ),
          ),

          // Segmented Tabs
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: widget.isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                children: [
                  _buildTab(0, 'Operativas (${widget.operationalAlerts.length})'),
                  _buildTab(1, 'Solicitudes (${_requests.length})'),
                  _buildTab(2, 'Informativas'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Content List
          Expanded(
            child: _selectedTab == 0
                ? _buildOperationalList(textPrimary, textSecondary)
                : (_selectedTab == 1
                    ? _buildRequestsList(textPrimary, textSecondary)
                    : _buildInfoList(textPrimary, textSecondary)),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(int index, String label) {
    final active = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _selectedTab = index);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: active
                ? (widget.isDark ? const Color(0xFF27272A) : Colors.white)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.hankenGrotesk(
                fontSize: 12,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                color: active
                    ? (widget.isDark ? Colors.white : const Color(0xFFC8102E))
                    : (widget.isDark ? Colors.white60 : const Color(0xFF6B7280)),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOperationalList(Color textPrimary, Color textSecondary) {
    if (widget.operationalAlerts.isEmpty) {
      return Center(
        child: Text(
          'Sin alertas operativas pendientes',
          style: GoogleFonts.hankenGrotesk(color: textSecondary),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      itemCount: widget.operationalAlerts.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final alert = widget.operationalAlerts[index];
        final accent = (alert['color'] as Color?) ?? const Color(0xFFC8102E);
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: widget.isDark
                ? Colors.white.withValues(alpha: 0.05)
                : const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: accent.withValues(alpha: 0.25)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    (alert['icon'] as IconData?) ?? Icons.warning_rounded,
                    color: accent,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      alert['title']?.toString() ?? '',
                      style: GoogleFonts.hankenGrotesk(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                alert['description']?.toString() ?? '',
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 12.5,
                  color: textSecondary,
                ),
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    widget.onResolveAlert(alert);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accent,
                    foregroundColor: Colors.white,
                    shape: const StadiumBorder(),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.bolt_rounded, size: 16),
                  label: Text(
                    alert['actionLabel']?.toString() ?? 'Resolver',
                    style: GoogleFonts.hankenGrotesk(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRequestsList(Color textPrimary, Color textSecondary) {
    if (_requests.isEmpty) {
      return Center(
        child: Text(
          'No hay solicitudes pendientes',
          style: GoogleFonts.hankenGrotesk(color: textSecondary),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      itemCount: _requests.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final req = _requests[index];
        return Dismissible(
          key: ValueKey(req['id']),
          background: Container(
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.only(left: 20),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.check_rounded, color: Colors.white),
          ),
          secondaryBackground: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            decoration: BoxDecoration(
              color: const Color(0xFF6B7280),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.snooze_rounded, color: Colors.white),
          ),
          onDismissed: (_) {
            setState(() => _requests.removeAt(index));
          },
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: widget.isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: widget.isDark ? Colors.white12 : Colors.black12,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      req['title'] as String,
                      style: GoogleFonts.hankenGrotesk(
                        fontWeight: FontWeight.w700,
                        fontSize: 13.5,
                        color: textPrimary,
                      ),
                    ),
                    Text(
                      req['time'] as String,
                      style: GoogleFonts.hankenGrotesk(
                        fontSize: 11,
                        color: textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  req['subtitle'] as String,
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 12.5,
                    color: textSecondary,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: () =>
                          setState(() => _requests.removeAt(index)),
                      style: OutlinedButton.styleFrom(
                        shape: const StadiumBorder(),
                        foregroundColor: textSecondary,
                        side: BorderSide(color: textSecondary.withValues(alpha: 0.3)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 6),
                      ),
                      child: const Text('Rechazar', style: TextStyle(fontSize: 12)),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () =>
                          setState(() => _requests.removeAt(index)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        shape: const StadiumBorder(),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 6),
                      ),
                      child: const Text('Aprobar', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoList(Color textPrimary, Color textSecondary) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      itemCount: _infoItems.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final item = _infoItems[index];
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: widget.isDark
                ? Colors.white.withValues(alpha: 0.05)
                : const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.info_outline_rounded,
                  color: Color(0xFF3B82F6), size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['title'] as String,
                      style: GoogleFonts.hankenGrotesk(
                        fontWeight: FontWeight.w700,
                        fontSize: 13.5,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item['subtitle'] as String,
                      style: GoogleFonts.hankenGrotesk(
                        fontSize: 12.5,
                        color: textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                item['time'] as String,
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 10.5,
                  color: textSecondary,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
