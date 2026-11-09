import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../google_fonts_wrapper.dart';

/// Shiftbase Circular Balance Donut Card
/// Cloned from Shiftbase "Time off balances" (e.g. Statutory 64h 0m remaining)
class ShiftbaseBalanceRing extends StatelessWidget {
  final String title;
  final String subtitle;
  final double progress; // 0.0 to 1.0
  final Color ringColor;
  final VoidCallback? onTap;
  final bool isDark;

  const ShiftbaseBalanceRing({
    super.key,
    required this.title,
    required this.subtitle,
    required this.progress,
    this.ringColor = const Color(0xFF2E66E5),
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

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            // Circular Ring Painter
            SizedBox(
              width: 32,
              height: 32,
              child: CustomPaint(
                painter: _CircularProgressPainter(
                  progress: progress,
                  ringColor: ringColor,
                  trackColor: isDark
                      ? Colors.white12
                      : const Color(0xFFE5E7EB),
                ),
              ),
            ),
            const SizedBox(width: 14),

            // Texts: Title & Subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.hankenGrotesk(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: titleColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.hankenGrotesk(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: subtextColor,
                    ),
                  ),
                ],
              ),
            ),

            // Trailing Chevron
            Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: isDark ? Colors.white38 : const Color(0xFFB0B4BC),
            ),
          ],
        ),
      ),
    );
  }
}

class _CircularProgressPainter extends CustomPainter {
  final double progress;
  final Color ringColor;
  final Color trackColor;

  _CircularProgressPainter({
    required this.progress,
    required this.ringColor,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 4) / 2;

    // Track
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, trackPaint);

    // Progress Arc
    final sweepAngle = 2 * math.pi * progress.clamp(0.0, 1.0);
    final progressPaint = Paint()
      ..color = ringColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _CircularProgressPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.ringColor != ringColor ||
        oldDelegate.trackColor != trackColor;
  }
}

