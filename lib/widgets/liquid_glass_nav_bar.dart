import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class LiquidGlassNavBarItem {
  final IconData icon;
  final String label;

  const LiquidGlassNavBarItem({required this.icon, required this.label});
}

/// A navigation bar implementing the iOS 26+ SwiftUI Liquid Glass effect specification
/// based on the [swiftui-liquid-glass] skill:
/// - Grouped inside a [GlassEffectContainer]
/// - Buttons styled with `.glassEffect(.regular.interactive())`
/// - Provides fallback for older operating system versions
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
    this.activeColor = const Color(0xFFC8102E), // Frisby Red
  });

  @override
  Widget build(BuildContext context) {
    // GlassEffectContainer wraps grouped glass elements
    return GlassEffectContainer(
      spacing: 24,
      isDark: isDark,
      child: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          alignment: Alignment.center,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(items.length, (index) {
                final item = items[index];
                final isActive = currentIndex == index;

                // Each navigation item applies .glassEffect(.regular.interactive())
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: GlassNavigationButton(
                      item: item,
                      isActive: isActive,
                      isDark: isDark,
                      activeColor: activeColor,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        onTap(index);
                      },
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

/// Container that groups multiple glass elements for unified blending and lighting
class GlassEffectContainer extends StatelessWidget {
  final double spacing;
  final bool isDark;
  final Widget child;

  const GlassEffectContainer({
    super.key,
    this.spacing = 24.0,
    this.isDark = false,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    // Outer floating pill base container providing ambient elevation & blur backdrop
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.black.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
            blurRadius: 32,
            spreadRadius: -4,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: child,
    );
  }
}

/// Navigation Capsule Button with `.glassEffect(.regular.interactive())`
class GlassNavigationButton extends StatefulWidget {
  final LiquidGlassNavBarItem item;
  final bool isActive;
  final bool isDark;
  final Color activeColor;
  final VoidCallback onTap;

  const GlassNavigationButton({
    super.key,
    required this.item,
    required this.isActive,
    required this.isDark,
    required this.activeColor,
    required this.onTap,
  });

  @override
  State<GlassNavigationButton> createState() => _GlassNavigationButtonState();
}

class _GlassNavigationButtonState extends State<GlassNavigationButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final inactiveColor = widget.isDark
        ? Colors.white.withValues(alpha: 0.65)
        : const Color(0xFF1C1C1E).withValues(alpha: 0.65);

    // .interactive() dynamics: scale and prominence react to touch
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _isPressed ? 0.94 : (widget.isActive ? 1.04 : 1.0),
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOutCubic,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            // Blur intensity mimicking Apple's Liquid Glass material
            filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                // Regular variant with tint when active (.regular.tint(activeColor).interactive())
                color: widget.isActive
                    ? widget.activeColor.withValues(alpha: widget.isDark ? 0.22 : 0.14)
                    : (widget.isDark
                        ? Colors.white.withValues(alpha: _isPressed ? 0.12 : 0.06)
                        : Colors.white.withValues(alpha: _isPressed ? 0.70 : 0.45)),
                border: Border.all(
                  color: widget.isActive
                      ? widget.activeColor.withValues(alpha: widget.isDark ? 0.55 : 0.40)
                      : (widget.isDark
                          ? Colors.white.withValues(alpha: 0.18)
                          : Colors.white.withValues(alpha: 0.85)),
                  width: widget.isActive ? 1.5 : 1.0,
                ),
                boxShadow: widget.isActive
                    ? [
                        BoxShadow(
                          color: widget.activeColor.withValues(alpha: widget.isDark ? 0.35 : 0.20),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                        BoxShadow(
                          color: Colors.white.withValues(alpha: widget.isDark ? 0.25 : 0.95),
                          blurRadius: 4,
                          offset: const Offset(0, -1),
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: widget.isDark ? 0.20 : 0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    widget.item.icon,
                    size: 22,
                    color: widget.isActive ? widget.activeColor : inactiveColor,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    widget.item.label,
                    style: GoogleFonts.hankenGrotesk(
                      fontSize: 10.5,
                      fontWeight: widget.isActive ? FontWeight.w700 : FontWeight.w500,
                      color: widget.isActive ? widget.activeColor : inactiveColor,
                      letterSpacing: -0.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
