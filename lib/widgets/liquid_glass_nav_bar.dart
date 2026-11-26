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

/// A navigation bar implementing the authentic Apple Liquid Glass (iOS 26) design system:
/// 1. Translucent main container: Frosted glass (.ultraThinMaterial) with backdrop blur(24px)
///    and delicate semitransparent border allowing background content to shine through.
/// 2. Active indicator as an internal capsule: Fully contained within the dock (Capsule / rounded-full),
///    soft translucent glass tint, delicate specular top highlight, without artificial rainbow reflections.
/// 3. Clean typography & crisp icons: High contrast, uncluttered glyphs, and fine text.
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
    this.activeColor = const Color(0xFFC8102E), // Frisby Red or custom accent
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: SizedBox(
          height: 64,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final totalWidth = constraints.maxWidth;
              final itemWidth = totalWidth / items.length;
              final capsulePaddingH = 4.0;
              final capsuleWidth = itemWidth - (capsulePaddingH * 2);
              final capsuleLeft = currentIndex * itemWidth + capsulePaddingH;

              return Stack(
                children: [
                  // 1. MAIN FROSTED TRANSLUCENT GLASS DOCK (.ultraThinMaterial)
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(32),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(32),
                            // Translucent frosted glass tint letting scrolling content refract through
                            color: isDark
                                ? const Color(0xFF2C2C2E).withValues(alpha: 0.38)
                                : Colors.white.withValues(alpha: 0.35),
                            // Thin semitransparent perimeter border letting background bleed through
                            border: Border.all(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.22)
                                  : Colors.white.withValues(alpha: 0.75),
                              width: 1.2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: isDark ? 0.30 : 0.10),
                                blurRadius: 24,
                                spreadRadius: -2,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // 2. INTERNAL ACTIVE CAPSULE (Contained inside, no protruding bubble)
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 260),
                    curve: Curves.easeOutCubic,
                    left: capsuleLeft,
                    top: 6,
                    bottom: 6,
                    width: capsuleWidth,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(26),
                        // Soft translucent glass tint with gentle specular highlight
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: isDark
                              ? [
                                  Colors.white.withValues(alpha: 0.22),
                                  Colors.white.withValues(alpha: 0.08),
                                ]
                              : [
                                  Colors.white.withValues(alpha: 0.90),
                                  Colors.white.withValues(alpha: 0.55),
                                ],
                        ),
                        // Subtle specular top edge rim
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.30)
                              : Colors.white.withValues(alpha: 0.90),
                          width: 1.0,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: isDark ? 0.20 : 0.06),
                            blurRadius: 8,
                            spreadRadius: -1,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 3. INTERACTIVE ITEMS ROW (Clean crisp icons and typography)
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
                          child: _CleanGlassNavItem(
                            item: item,
                            isActive: isActive,
                            isDark: isDark,
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
      ),
    );
  }
}

class _CleanGlassNavItem extends StatelessWidget {
  final LiquidGlassNavBarItem item;
  final bool isActive;
  final bool isDark;
  final Color activeColor;

  const _CleanGlassNavItem({
    required this.item,
    required this.isActive,
    required this.isDark,
    required this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    final activeTextColor = isDark ? Colors.white : activeColor;
    final inactiveTextColor = isDark
        ? Colors.white.withValues(alpha: 0.55)
        : const Color(0xFF6E6E73);

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              AnimatedScale(
                scale: isActive ? 1.05 : 1.0,
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  item.icon,
                  size: 22,
                  color: isActive ? activeTextColor : inactiveTextColor,
                ),
              ),
              if (item.badgeCount > 0)
                Positioned(
                  top: -3,
                  right: -7,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF3B30), // Apple iOS system red
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(minWidth: 15, minHeight: 15),
                    child: Center(
                      child: Text(
                        item.badgeCount > 99 ? '99+' : '${item.badgeCount}',
                        style: GoogleFonts.hankenGrotesk(
                          color: Colors.white,
                          fontSize: 9.0,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 3),
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: GoogleFonts.hankenGrotesk(
              fontSize: 10.5,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
              color: isActive ? activeTextColor : inactiveTextColor,
              letterSpacing: -0.1,
            ),
            child: Text(
              item.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
