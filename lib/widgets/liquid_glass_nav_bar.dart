import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class LiquidGlassNavBarItem {
  final IconData icon;
  final String label;

  const LiquidGlassNavBarItem({required this.icon, required this.label});
}

class LiquidGlassNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<LiquidGlassNavBarItem> items;
  final bool isDark;
  final Color activeColor;

  const LiquidGlassNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
    this.isDark = false,
    this.activeColor = const Color(0xFF007AFF),
  });

  @override
  Widget build(BuildContext context) {
    final capsuleGradient = isDark
        ? LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withValues(alpha: 0.16),
              const Color(0xFF1E2127).withValues(alpha: 0.35),
              Colors.black.withValues(alpha: 0.50),
            ],
            stops: const [0.0, 0.45, 1.0],
          )
        : LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withValues(alpha: 0.38),
              Colors.white.withValues(alpha: 0.12),
              const Color(0xFFE2EBF5).withValues(alpha: 0.22),
            ],
            stops: const [0.0, 0.5, 1.0],
          );

    final capsuleBorder = isDark
        ? Colors.white.withValues(alpha: 0.32)
        : Colors.white.withValues(alpha: 0.80);

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        alignment: Alignment.center,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(44),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
            child: Container(
              height: 66,
              constraints: const BoxConstraints(maxWidth: 420),
              decoration: BoxDecoration(
                gradient: capsuleGradient,
                borderRadius: BorderRadius.circular(44),
                border: Border.all(color: capsuleBorder, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
                    blurRadius: 28,
                    spreadRadius: -2,
                    offset: const Offset(0, 10),
                  ),
                  BoxShadow(
                    color: Colors.white.withValues(alpha: isDark ? 0.16 : 0.95),
                    blurRadius: 6,
                    offset: const Offset(0, -1),
                  ),
                  BoxShadow(
                    color: Colors.white.withValues(alpha: isDark ? 0.05 : 0.45),
                    blurRadius: 14,
                    spreadRadius: -3,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final totalItems = items.length;
                  final itemWidth = constraints.maxWidth / totalItems;
                  final safeIndex = currentIndex.clamp(0, totalItems - 1);

                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onHorizontalDragUpdate: (details) {
                      final localX = details.localPosition.dx.clamp(
                        0.0,
                        constraints.maxWidth,
                      );
                      final newIndex = (localX / itemWidth).floor().clamp(
                        0,
                        totalItems - 1,
                      );
                      if (newIndex != currentIndex) {
                        HapticFeedback.selectionClick();
                        onTap(newIndex);
                      }
                    },
                    onHorizontalDragEnd: (details) {
                      HapticFeedback.lightImpact();
                    },
                    child: Stack(
                      children: [
                        // Sliding Water-drop Glass Lens Dome
                        AnimatedPositioned(
                          duration: const Duration(milliseconds: 280),
                          curve: Curves.easeOutBack,
                          left: safeIndex * itemWidth,
                          top: 0,
                          bottom: 0,
                          width: itemWidth,
                          child: Container(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 2,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: isDark
                                    ? [
                                        Colors.white.withValues(alpha: 0.28),
                                        Colors.white.withValues(alpha: 0.08),
                                        const Color(0xFF1E2530)
                                            .withValues(alpha: 0.20),
                                      ]
                                    : [
                                        Colors.white.withValues(alpha: 0.55),
                                        Colors.white.withValues(alpha: 0.18),
                                        const Color(0xFFE8EEF5)
                                            .withValues(alpha: 0.32),
                                      ],
                              ),
                              borderRadius: BorderRadius.circular(36),
                              border: Border.all(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.45)
                                    : Colors.white.withValues(alpha: 0.90),
                                width: 1.4,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: activeColor.withValues(
                                    alpha: isDark ? 0.30 : 0.15,
                                  ),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                                BoxShadow(
                                  color: Colors.white.withValues(
                                    alpha: isDark ? 0.20 : 0.95,
                                  ),
                                  blurRadius: 4,
                                  offset: const Offset(0, -1),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Navigation Items Row
                        Row(
                          children: List.generate(totalItems, (index) {
                            final item = items[index];
                            final isActive = safeIndex == index;
                            final inactiveColor = isDark
                                ? Colors.white.withValues(alpha: 0.65)
                                : const Color(0xFF1C1C1E)
                                      .withValues(alpha: 0.65);

                            return Expanded(
                              child: GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  onTap(index);
                                },
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    AnimatedScale(
                                      scale: isActive ? 1.12 : 1.0,
                                      duration: const Duration(
                                        milliseconds: 200,
                                      ),
                                      child: Icon(
                                        item.icon,
                                        size: 22,
                                        color: isActive
                                            ? activeColor
                                            : inactiveColor,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    AnimatedDefaultTextStyle(
                                      duration: const Duration(
                                        milliseconds: 200,
                                      ),
                                      style: GoogleFonts.hankenGrotesk(
                                        fontSize: 10.5,
                                        fontWeight: isActive
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                        color: isActive
                                            ? activeColor
                                            : inactiveColor,
                                        letterSpacing: -0.2,
                                      ),
                                      child: Text(item.label),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
