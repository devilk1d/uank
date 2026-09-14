import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class SegmentItem {
  final String label;
  final num value;
  final Color color;
  final String? subtitle;

  const SegmentItem({
    required this.label,
    required this.value,
    required this.color,
    this.subtitle,
  });
}

class SegmentedProgressBar extends StatelessWidget {
  const SegmentedProgressBar({
    super.key,
    required this.items,
    this.height = 8,
    this.showLegend = true,
    this.legendSpacing = 12,
  });

  final List<SegmentItem> items;
  final double height;
  final bool showLegend;
  final double legendSpacing;

  @override
  Widget build(BuildContext context) {
    final total = items.fold<num>(0, (sum, item) => sum + item.value);
    final validItems = items.where((i) => i.value > 0).toList();

    if (total <= 0 || validItems.isEmpty) {
      return Container(
        height: height,
        decoration: BoxDecoration(
          color: AppColors.darkTextMuted.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(height / 2),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(height / 2),
          child: SizedBox(
            height: height,
            child: Row(
              children: validItems.map((item) {
                final flex = (item.value / total * 1000).round().clamp(1, 1000);
                return Expanded(
                  flex: flex,
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 1),
                    decoration: BoxDecoration(
                      color: item.color,
                      borderRadius: BorderRadius.circular(height / 2),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        if (showLegend) ...[
          SizedBox(height: legendSpacing),
          Wrap(
            spacing: 14,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: validItems.map((item) {
              final pct = ((item.value / total) * 100).toStringAsFixed(0);
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: item.color,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    item.subtitle != null
                        ? '${item.label} ${item.subtitle}'
                        : '${item.label} $pct%',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppColors.darkTextSecondary,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ],
    );
  }
}
