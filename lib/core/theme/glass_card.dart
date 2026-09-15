import 'dart:ui';
import 'package:flutter/material.dart';
import 'app_colors.dart';

class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.strong = false,
    this.borderRadius = 22,
    this.padding = const EdgeInsets.all(18),
    this.border,
    this.color,
  });

  final Widget child;
  final bool strong;
  final double borderRadius;
  final EdgeInsets padding;
  final BoxBorder? border;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final fill = color ??
        (isDark
            ? (strong ? AppColors.darkCardBg : AppColors.darkCardBg.withValues(alpha: 0.85))
            : (strong ? AppColors.lightGlassFillStrong : AppColors.lightGlassFill));
    final defaultBorder = isDark ? AppColors.darkCardBorder : AppColors.lightGlassBorder;

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          padding: padding,
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(borderRadius),
            border: border ?? Border.all(color: defaultBorder, width: 1),
            boxShadow: isDark
                ? null
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: child,
        ),
      ),
    );
  }
}
