import 'package:flutter/material.dart';
import '../../google_fonts_wrapper.dart';

/// Shiftbase Team Roster Item & Department Group
/// Cloned from Shiftbase iOS "Team" tab (e.g. Kitchen, Bar, Service).
class ShiftbaseTeamMemberRow extends StatelessWidget {
  final String name;
  final String role;
  final String shiftHours;
  final Color statusColor; // Green: on shift, Orange: break, Red: absent, Grey: off duty
  final String? statusText; // e.g. "Full day • 8h", "Vacaciones"
  final VoidCallback? onTap;
  final bool isDark;

  const ShiftbaseTeamMemberRow({
    super.key,
    required this.name,
    required this.role,
    required this.shiftHours,
    this.statusColor = const Color(0xFF00C853),
    this.statusText,
    this.onTap,
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

    final initials = name.trim().split(' ').map((p) => p.isNotEmpty ? p[0] : '').take(2).join();

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            // Circular Avatar with Initials
            CircleAvatar(
              radius: 19,
              backgroundColor: isDark
                  ? const Color(0xFF333B4A)
                  : const Color(0xFFE2E6EE),
              child: Text(
                initials.toUpperCase(),
                style: GoogleFonts.sora(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white70 : const Color(0xFF333A48),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Colored Vertical Status Bar
            Container(
              width: 3.5,
              height: 34,
              decoration: BoxDecoration(
                color: statusColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),

            // Member Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: GoogleFonts.hankenGrotesk(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: titleColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$shiftHours • $role',
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

            // Trailing info or chevron
            if (statusText != null) ...[
              Text(
                statusText!,
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: subtextColor,
                ),
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

