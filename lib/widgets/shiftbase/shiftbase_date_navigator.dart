import 'package:flutter/material.dart';
import '../../google_fonts_wrapper.dart';

/// Shiftbase Date & Week Navigator
/// Cloned from Shiftbase iOS header: < Tuesday 15 September >
class ShiftbaseDateNavigator extends StatelessWidget {
  final String title;
  final String? subtitle;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback? onTapTitle;
  final bool isDark;

  const ShiftbaseDateNavigator({
    super.key,
    required this.title,
    this.subtitle,
    required this.onPrevious,
    required this.onNext,
    this.onTapTitle,
    this.isDark = false,
  });

  @override
  Widget build(BuildContext context) {
    final titleColor = isDark
        ? const Color(0xFFE2E4E9)
        : const Color(0xFF1E2129);

    final buttonBg = isDark
        ? const Color(0xFF262A34)
        : const Color(0xFFF0F1ED);

    final iconColor = isDark
        ? Colors.white70
        : const Color(0xFF33373D);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Previous Day / Week Button
          Material(
            color: buttonBg,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: onPrevious,
              child: SizedBox(
                width: 38,
                height: 38,
                child: Icon(
                  Icons.chevron_left_rounded,
                  color: iconColor,
                  size: 24,
                ),
              ),
            ),
          ),

          // Date / Period Center Title (Tap to open picker)
          GestureDetector(
            onTap: onTapTitle,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.hankenGrotesk(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: titleColor,
                      ),
                    ),
                    if (onTapTitle != null) ...[
                      const SizedBox(width: 4),
                      Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 16,
                        color: iconColor,
                      ),
                    ],
                  ],
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: GoogleFonts.hankenGrotesk(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white54 : const Color(0xFF757A82),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Next Day / Week Button
          Material(
            color: buttonBg,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: onNext,
              child: SizedBox(
                width: 38,
                height: 38,
                child: Icon(
                  Icons.chevron_right_rounded,
                  color: iconColor,
                  size: 24,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
