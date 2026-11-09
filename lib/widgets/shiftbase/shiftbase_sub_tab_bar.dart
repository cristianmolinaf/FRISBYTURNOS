import 'package:flutter/material.dart';
import '../../google_fonts_wrapper.dart';

/// Shiftbase Pill Sub-Tab Bar
/// Cloned directly from Shiftbase iOS sub-tab header (e.g. My schedule | Team | Open shifts).
class ShiftbaseSubTabBar extends StatelessWidget {
  final List<String> tabs;
  final int selectedIndex;
  final ValueChanged<int> onTabSelected;
  final bool isDark;

  const ShiftbaseSubTabBar({
    super.key,
    required this.tabs,
    required this.selectedIndex,
    required this.onTabSelected,
    this.isDark = false,
  });

  @override
  Widget build(BuildContext context) {
    final containerBg = isDark
        ? const Color(0xFF22262E)
        : const Color(0xFFEBECE8);

    final activePillBg = isDark
        ? const Color(0xFF323844)
        : Colors.white;

    final activeTextColor = isDark
        ? Colors.white
        : const Color(0xFF191C1E);

    final inactiveTextColor = isDark
        ? Colors.white54
        : const Color(0xFF6F747A);

    return Container(
      height: 44,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: containerBg,
        borderRadius: BorderRadius.circular(22),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final tabWidth = constraints.maxWidth / tabs.length;

          return Stack(
            children: [
              // Animated Active Sliding Capsule
              AnimatedPositioned(
                duration: const Duration(milliseconds: 240),
                curve: Curves.easeOutCubic,
                left: selectedIndex * tabWidth,
                top: 0,
                bottom: 0,
                width: tabWidth,
                child: Container(
                  decoration: BoxDecoration(
                    color: activePillBg,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),

              // Tab Buttons Row
              Row(
                children: List.generate(tabs.length, (index) {
                  final isSelected = selectedIndex == index;
                  return Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => onTabSelected(index),
                      child: Center(
                        child: Text(
                          tabs[index],
                          style: GoogleFonts.hankenGrotesk(
                            fontSize: 13,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            color: isSelected ? activeTextColor : inactiveTextColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          );
        },
      ),
    );
  }
}
