import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class LiquidGlassNavBarItem {
  final IconData icon;
  final String label;
  final int badgeCount;

  const LiquidGlassNavBarItem({
    required this.icon,
    required this.label,
    this.badgeCount = 0,
  });
}

/// A navigation bar implementing the true iOS 26+ SwiftUI Liquid Glass effect
/// as seen in the official Frisby reference screenshot:
/// - A continuous dark tinted glass pill capsule floating at the bottom with frosted blur.
/// - The active item is an elevated, enlarged refractive glass bubble with chromatic refraction & prism edge reflections.
/// - Inactive items are clean white icons and text.
/// - Support for badges (like notification count).
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
    this.isDark = true,
    this.activeColor = const Color(0xFFFF9E58), // Warm orange/peach accent from Frisby app screenshot
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.only(left: 12, right: 12, bottom: 20),
        child: SizedBox(
          height: 64,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              // 1. MAIN GLASS CAPSULE DOCK (Frosted dark glassy pill)
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(32),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(32),
                        // Dark translucent smoky glass
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            const Color(0xFF4A4A4D).withValues(alpha: 0.65),
                            const Color(0xFF222225).withValues(alpha: 0.82),
                          ],
                        ),
                        // Fine perimeter rim light
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.28),
                          width: 1.0,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.40),
                            blurRadius: 28,
                            spreadRadius: 2,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // 2. ITEMS ROW WITH INTERACTIVE BUBBLE
              Positioned.fill(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final itemWidth = constraints.maxWidth / items.length;
                    const bubbleWidth = 74.0;
                    final activeBubbleLeft = (currentIndex * itemWidth + (itemWidth - bubbleWidth) / 2).clamp(
                      0.0,
                      constraints.maxWidth - bubbleWidth,
                    );

                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        // ACTIVE REFRACTIVE LIQUID GLASS BUBBLE (Morphing lens)
                        AnimatedPositioned(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOutBack,
                          left: activeBubbleLeft,
                          top: -7,
                          bottom: -7,
                          width: bubbleWidth,
                          child: const _LiquidGlassLens(),
                        ),

                        // INTERACTIVE ITEM TOUCH TARGETS & ICONS
                        Row(
                          children: List.generate(items.length, (index) {
                            final item = items[index];
                            final isActive = currentIndex == index;

                            return Expanded(
                              child: GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  onTap(index);
                                },
                                child: _GlassNavItemContent(
                                  item: item,
                                  isActive: isActive,
                                  activeColor: activeColor,
                                ),
                              ),
                            );
                          }),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The refractive liquid glass bubble lens that floats over the active icon
class _LiquidGlassLens extends StatelessWidget {
  const _LiquidGlassLens();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(39),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(39),
              // Glass gradient fill
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: 0.25),
                  Colors.white.withValues(alpha: 0.06),
                  const Color(0xFF2A2A2E).withValues(alpha: 0.35),
                ],
              ),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.55),
                width: 1.4,
              ),
              boxShadow: [
                // Prism chromatic aberration simulation (rainbow edge glow)
                BoxShadow(
                  color: const Color(0xFF4A90E2).withValues(alpha: 0.40), // blue dispersion edge
                  blurRadius: 10,
                  spreadRadius: -1,
                  offset: const Offset(-2, 0),
                ),
                BoxShadow(
                  color: const Color(0xFFFF9E58).withValues(alpha: 0.40), // warm orange dispersion
                  blurRadius: 10,
                  spreadRadius: -1,
                  offset: const Offset(2, 0),
                ),
                // Outer elevation drop shadow
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
                // Inner highlight ring
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.40),
                  blurRadius: 4,
                  spreadRadius: -1,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Top curved glass reflection highlight
                Align(
                  alignment: Alignment.topCenter,
                  child: Container(
                    height: 12,
                    margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withValues(alpha: 0.75),
                          Colors.white.withValues(alpha: 0.0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ),
                // Bottom chromatic rim
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    height: 6,
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF64D2FF).withValues(alpha: 0.55),
                          const Color(0xFFFF9F0A).withValues(alpha: 0.55),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GlassNavItemContent extends StatelessWidget {
  final LiquidGlassNavBarItem item;
  final bool isActive;
  final Color activeColor;

  const _GlassNavItemContent({
    required this.item,
    required this.isActive,
    required this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = isActive ? activeColor : Colors.white;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(
                item.icon,
                size: 24,
                color: color,
              ),
              if (item.badgeCount > 0)
                Positioned(
                  top: -4,
                  right: -8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4.5, vertical: 1.5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF453A), // iOS system red badge
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF453A).withValues(alpha: 0.5),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Center(
                      child: Text(
                        item.badgeCount > 99 ? '99+' : '${item.badgeCount}',
                        style: GoogleFonts.hankenGrotesk(
                          color: Colors.white,
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            item.label,
            style: GoogleFonts.hankenGrotesk(
              fontSize: 10.5,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              color: color,
              letterSpacing: -0.1,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
