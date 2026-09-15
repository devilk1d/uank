import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class MiniBarChart extends StatelessWidget {
  const MiniBarChart({
    super.key,
    this.barHeights,
    this.barColor,
    this.barCount = 16,
    this.height = 20,
  });

  final List<double>? barHeights;
  final Color? barColor;
  final int barCount;
  final double height;

  static const _defaultPattern = [
    0.3, 0.45, 0.6, 0.4, 0.75, 0.9, 0.65, 0.5,
    0.7, 0.85, 0.6, 0.8, 0.95, 0.7, 0.55, 0.85,
    0.9, 0.6, 0.75, 0.5, 0.8, 0.95, 0.7, 0.6
  ];

  @override
  Widget build(BuildContext context) {
    final values = barHeights ?? _defaultPattern;
    final effectiveColor = barColor ?? (context.isDark ? AppColors.primary : const Color(0xFF15803D));

    return SizedBox(
      height: height,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(barCount, (index) {
          final val = values[index % values.length].clamp(0.15, 1.0);
          final opacity = (0.35 + (val * 0.65)).clamp(0.3, 1.0);

          return Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 1.5),
              height: height * val,
              decoration: BoxDecoration(
                color: effectiveColor.withValues(alpha: opacity),
                borderRadius: BorderRadius.circular(2.5),
              ),
            ),
          );
        }),
      ),
    );
  }
}
