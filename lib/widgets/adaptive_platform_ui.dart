import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'liquid_glass_nav_bar.dart';

enum AppPlatformStyle {
  iosLiquidGlass,
  androidMaterial3Expressive,
  webResponsive,
}

class PlatformDetector {
  static AppPlatformStyle of(BuildContext context) {
    if (kIsWeb) return AppPlatformStyle.webResponsive;
    final platform = Theme.of(context).platform;
    if (platform == TargetPlatform.iOS || platform == TargetPlatform.macOS) {
      return AppPlatformStyle.iosLiquidGlass;
    }
    return AppPlatformStyle.androidMaterial3Expressive;
  }

  static bool isIOS(BuildContext context) =>
      of(context) == AppPlatformStyle.iosLiquidGlass;

  static bool isAndroid(BuildContext context) =>
      of(context) == AppPlatformStyle.androidMaterial3Expressive;

  static bool isWeb(BuildContext context) =>
      of(context) == AppPlatformStyle.webResponsive;
}

/// Adaptive Surface Card:
/// - iOS: Liquid Glass (BackdropFilter blur + translucent tint + fine rim border)
/// - Android: Material 3 Expressive (solid tonal surfaceContainer + 24px expressive radius, no glass)
/// - Web: Clean responsive card with crisp 1px border and subtle shadow
class AdaptiveSurfaceCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final bool isDark;
  final VoidCallback? onTap;

  const AdaptiveSurfaceCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.isDark = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final style = PlatformDetector.of(context);

    Widget content;
    switch (style) {
      case AppPlatformStyle.iosLiquidGlass:
        content = ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding: padding,
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.white.withValues(alpha: 0.72),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.16)
                      : Colors.white.withValues(alpha: 0.80),
                  width: 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: child,
            ),
          ),
        );
        break;

      case AppPlatformStyle.androidMaterial3Expressive:
        final colorScheme = Theme.of(context).colorScheme;
        content = Material(
          color: isDark
              ? const Color(0xFF231F20)
              : colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(24),
          elevation: 1,
          shadowColor: Colors.black.withValues(alpha: 0.12),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(24),
            child: Padding(
              padding: padding,
              child: child,
            ),
          ),
        );
        break;

      case AppPlatformStyle.webResponsive:
        content = Container(
          padding: padding,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E22) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.10)
                  : const Color(0xFFE5E7EB),
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: child,
        );
        break;
    }

    if (onTap != null && style != AppPlatformStyle.androidMaterial3Expressive) {
      content = GestureDetector(onTap: onTap, child: content);
    }

    if (margin != null) {
      return Padding(padding: margin!, child: content);
    }
    return content;
  }
}

/// Adaptive Bottom/Top Navigation Bar:
/// - iOS: LiquidGlassNavBar (floating frosted glass with internal capsule)
/// - Android: Material 3 Expressive NavigationBar (dynamic tonal indicator, expressive shapes)
/// - Web: Clean translucent responsive navigation bar
class AdaptiveNavigationBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<LiquidGlassNavBarItem> items;
  final bool isDark;
  final Color activeColor;

  const AdaptiveNavigationBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
    this.isDark = false,
    this.activeColor = const Color(0xFFC8102E),
  });

  @override
  Widget build(BuildContext context) {
    final style = PlatformDetector.of(context);

    switch (style) {
      case AppPlatformStyle.iosLiquidGlass:
        return LiquidGlassNavBar(
          currentIndex: currentIndex,
          onTap: onTap,
          items: items,
          isDark: isDark,
          activeColor: activeColor,
        );

      case AppPlatformStyle.androidMaterial3Expressive:
        return NavigationBarTheme(
          data: NavigationBarThemeData(
            backgroundColor:
                isDark ? const Color(0xFF1C191A) : const Color(0xFFFFF8F7),
            indicatorColor: activeColor.withValues(alpha: isDark ? 0.28 : 0.14),
            indicatorShape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            labelTextStyle: WidgetStateProperty.resolveWith((states) {
              final selected = states.contains(WidgetState.selected);
              return GoogleFonts.hankenGrotesk(
                fontSize: 12,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected
                    ? (isDark ? Colors.white : activeColor)
                    : (isDark ? Colors.white60 : const Color(0xFF5C5F66)),
              );
            }),
          ),
          child: NavigationBar(
            selectedIndex: currentIndex,
            onDestinationSelected: (idx) {
              HapticFeedback.selectionClick();
              onTap(idx);
            },
            height: 72,
            elevation: 3,
            destinations: items.map((item) {
              return NavigationDestination(
                icon: Badge(
                  isLabelVisible: item.badgeCount > 0,
                  label: Text('${item.badgeCount}'),
                  child: Icon(item.icon),
                ),
                selectedIcon: Badge(
                  isLabelVisible: item.badgeCount > 0,
                  label: Text('${item.badgeCount}'),
                  child: Icon(item.icon, color: activeColor),
                ),
                label: item.label,
              );
            }).toList(),
          ),
        );

      case AppPlatformStyle.webResponsive:
        return ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              height: 64,
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF18181B).withValues(alpha: 0.88)
                    : Colors.white.withValues(alpha: 0.90),
                border: Border(
                  top: BorderSide(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.10)
                        : const Color(0xFFE5E7EB),
                  ),
                ),
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: List.generate(items.length, (index) {
                      final item = items[index];
                      final active = currentIndex == index;
                      return InkWell(
                        onTap: () => onTap(index),
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                item.icon,
                                size: 20,
                                color: active
                                    ? activeColor
                                    : (isDark
                                        ? Colors.white60
                                        : const Color(0xFF6B7280)),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                item.label,
                                style: GoogleFonts.hankenGrotesk(
                                  fontSize: 13.5,
                                  fontWeight: active
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: active
                                      ? activeColor
                                      : (isDark
                                          ? Colors.white70
                                          : const Color(0xFF374151)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ),
            ),
          ),
        );
    }
  }
}
