import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class DonutSegment {
  const DonutSegment({
    required this.label,
    required this.value,
    required this.color,
    this.percentage = 0.0,
    this.percentageFormatted,
    this.formattedAmount,
    this.icon,
  });

  final String label;
  final double value;
  final Color color;
  final double percentage;
  final String? percentageFormatted;
  final String? formattedAmount;
  final IconData? icon;
}

class DonutBreakdownChart extends StatelessWidget {
  const DonutBreakdownChart({
    super.key,
    required this.segments,
    this.size = 135,
    this.strokeWidth = 16,
    this.centerWidget,
  });

  final List<DonutSegment> segments;
  final double size;
  final double strokeWidth;
  final Widget? centerWidget;

  @override
  Widget build(BuildContext context) {
    final total = segments.fold<double>(0, (sum, s) => sum + s.value);

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(size, size),
            painter: _DonutChartPainter(
              segments: segments,
              total: total > 0 ? total : 1.0,
              strokeWidth: strokeWidth,
            ),
          ),
          if (centerWidget != null)
            centerWidget!
          else
            _buildDefaultCenter(context),
        ],
      ),
    );
  }

  Widget _buildDefaultCenter(BuildContext context) {
    if (segments.isEmpty) return const SizedBox.shrink();

    final topSegment = segments.first;
    final displayPct = topSegment.percentageFormatted ??
        (topSegment.percentage > 0 ? '${topSegment.percentage.toStringAsFixed(0)}%' : '');

    return Container(
      width: size - (strokeWidth * 2) - 14,
      height: size - (strokeWidth * 2) - 14,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF14151A),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              displayPct,
              style: TextStyle(
                fontSize: size > 130 ? 17 : 14,
                fontWeight: FontWeight.w800,
                color: topSegment.color,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text(
                topSegment.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.darkTextSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DonutChartPainter extends CustomPainter {
  _DonutChartPainter({
    required this.segments,
    required this.total,
    required this.strokeWidth,
  });

  final List<DonutSegment> segments;
  final double total;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Draw background track ring
    final bgPaint = Paint()
      ..color = const Color(0xFF22242D)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, bgPaint);

    if (segments.isEmpty || total <= 0) return;

    final nonZeroSegments = segments.where((s) => s.value > 0).toList();
    if (nonZeroSegments.isEmpty) return;

    if (nonZeroSegments.length == 1) {
      final seg = nonZeroSegments.first;
      final paint = Paint()
        ..color = seg.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(rect, -math.pi / 2, 2 * math.pi, false, paint);
      return;
    }

    // For multiple segments, calculate proportional arcs with modern rounded gaps
    const gapAngle = 0.08;
    final totalGap = gapAngle * nonZeroSegments.length;
    final availableSweep = (2 * math.pi) - totalGap;

    double startAngle = -math.pi / 2;

    for (final seg in nonZeroSegments) {
      final rawSweep = (seg.value / total) * availableSweep;
      final sweepAngle = math.max(rawSweep, 0.06);

      final paint = Paint()
        ..color = seg.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(rect, startAngle, sweepAngle, false, paint);
      startAngle += sweepAngle + gapAngle;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutChartPainter oldDelegate) {
    return oldDelegate.segments != segments || oldDelegate.total != total;
  }
}
