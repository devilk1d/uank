import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';

class SmoothAppSwitch extends StatelessWidget {
  const SmoothAppSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.activeIcon,
    this.inactiveIcon,
    this.activeColor,
    this.inactiveColor,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final IconData? activeIcon;
  final IconData? inactiveIcon;
  final Color? activeColor;
  final Color? inactiveColor;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final primaryAccent = activeColor ?? (isDark ? AppColors.primary : const Color(0xFF15803D));
    final inactiveBg = inactiveColor ?? (isDark ? const Color(0xFF262A34) : const Color(0xFFE2E8F0));

    return RepaintBoundary(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onChanged(!value);
        },
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          width: 50,
          height: 28,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: value ? primaryAccent : inactiveBg,
            boxShadow: value
                ? [
                    BoxShadow(
                      color: primaryAccent.withValues(alpha: isDark ? 0.35 : 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: AnimatedAlign(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            alignment: value ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: value
                    ? (isDark ? Colors.black : Colors.white)
                    : (isDark ? const Color(0xFF181B24) : Colors.white),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.12),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  switchInCurve: Curves.easeInOut,
                  switchOutCurve: Curves.easeInOut,
                  transitionBuilder: (child, anim) => FadeTransition(
                    opacity: anim,
                    child: ScaleTransition(
                      scale: Tween<double>(begin: 0.7, end: 1.0).animate(anim),
                      child: child,
                    ),
                  ),
                  child: Icon(
                    value
                        ? (activeIcon ?? Icons.check_rounded)
                        : (inactiveIcon ?? Icons.close_rounded),
                    key: ValueKey('${value}_${activeIcon.hashCode}'),
                    size: 11,
                    color: value
                        ? primaryAccent
                        : (isDark ? Colors.white38 : const Color(0xFF94A3B8)),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
