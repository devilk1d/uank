import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppBackground extends StatelessWidget {
  const AppBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      color: isDark ? AppColors.darkBgEnd : AppColors.lightBackground,
      child: Stack(
        children: [
          // Top ambient gradient
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 220,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: isDark
                      ? const [
                          AppColors.darkBgStart,
                          AppColors.darkBgMid,
                          AppColors.darkBgEnd,
                        ]
                      : const [
                          AppColors.lightBgStart,
                          AppColors.lightBgMid,
                          AppColors.lightBgEnd,
                        ],
                  stops: const [0.0, 0.55, 1.0],
                ),
              ),
            ),
          ),

          // Subtle top-right ambient glow spotlight
          Positioned(
            top: -80,
            right: -30,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: isDark ? 0.18 : 0.12),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Subtle top-left mint glow
          Positioned(
            top: -60,
            left: -40,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.teal.withValues(alpha: isDark ? 0.12 : 0.08),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          child,
        ],
      ),
    );
  }
}
