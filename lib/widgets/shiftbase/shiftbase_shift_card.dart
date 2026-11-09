import 'package:flutter/material.dart';
import '../../google_fonts_wrapper.dart';

/// Shiftbase Shift Card & List Item
/// Cloned from Shiftbase iOS schedule & home screen shift rows.
class ShiftbaseShiftCard extends StatelessWidget {
  final String dayCode; // e.g. "JUE"
  final String dayNumber; // e.g. "17"
  final String title; // e.g. "Turno Completo" or "Mañana"
  final String timeRange; // e.g. "08:00 - 16:00"
  final String station; // e.g. "Freidoras"
  final String store; // e.g. "Frisby Parque Arboleda"
  final Color accentColor; // e.g. Green, Orange, Purple
  final String? statusBadge; // e.g. "1/3" or "Confirmado"
  final VoidCallback? onTap;
  final VoidCallback? onSwapTap;
  final bool isDark;

  const ShiftbaseShiftCard({
    super.key,
    required this.dayCode,
    required this.dayNumber,
    required this.title,
    required this.timeRange,
    required this.station,
    required this.store,
    this.accentColor = const Color(0xFF00C853), // Shiftbase Green
    this.statusBadge,
    this.onTap,
    this.onSwapTap,
    this.isDark = false,
  });

  @override
  Widget build(BuildContext context) {
    final titleColor = isDark
        ? const Color(0xFFF0F1F5)
        : const Color(0xFF1E2129);

    final subtextColor = isDark
        ? Colors.white60
        : const Color(0xFF6F747D);

    final badgeBg = isDark
        ? const Color(0xFF282D37)
        : const Color(0xFFF1F2EE);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Shiftbase Day Pill Badge (e.g. JUE 17)
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: badgeBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    dayCode.toUpperCase(),
                    style: GoogleFonts.hankenGrotesk(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.6,
                      color: isDark ? Colors.white60 : const Color(0xFF70757E),
                    ),
                  ),
                  Text(
                    dayNumber,
                    style: GoogleFonts.sora(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: titleColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),

            // Colored Vertical Strip (Shiftbase signature)
            Container(
              width: 3.5,
              height: 38,
              decoration: BoxDecoration(
                color: accentColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),

            // Shift Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$title • $timeRange',
                    style: GoogleFonts.hankenGrotesk(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: titleColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '$station • $store',
                    style: GoogleFonts.hankenGrotesk(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: subtextColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Optional Status Badge or Swap Action
            if (statusBadge != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white12 : const Color(0xFFECEEF2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  statusBadge!,
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: titleColor,
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],

            if (onSwapTap != null) ...[
              IconButton(
                onPressed: onSwapTap,
                icon: const Icon(Icons.swap_horiz_rounded),
                color: const Color(0xFFC8102E),
                tooltip: 'Solicitar Cambio',
                iconSize: 20,
              ),
            ] else ...[
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: isDark ? Colors.white38 : const Color(0xFFB0B4BC),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
