import 'package:flutter/material.dart';

class SplineTrendChart extends StatelessWidget {
  const SplineTrendChart({
    super.key,
    this.points = const [35, 60, 45, 50, 40, 55, 48, 62, 38, 42, 30, 45, 32, 58, 65, 78, 72, 85],
    this.labels = const ['1 Jan', '8 Feb', '15 Mar', '22 Apr', '29 May'],
    this.lineColor = const Color(0xFF818CF8),
    this.highlightIndex = 11,
    this.highlightLabel = '\$420.50',
    this.height = 140,
  });

  final List<double> points;
  final List<String> labels;
  final Color lineColor;
  final int highlightIndex;
  final String highlightLabel;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: height,
          width: double.infinity,
          child: CustomPaint(
            painter: _SplineChartPainter(
              points: points,
              lineColor: lineColor,
              highlightIndex: highlightIndex,
              highlightLabel: highlightLabel,
            ),
          ),
        ),
        const SizedBox(height: 8),
        // X-axis timeline labels
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: labels
              .map(
                (l) => Text(
                  l,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF64748B),
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

class _SplineChartPainter extends CustomPainter {
  _SplineChartPainter({
    required this.points,
    required this.lineColor,
    required this.highlightIndex,
    required this.highlightLabel,
  });

  final List<double> points;
  final Color lineColor;
  final int highlightIndex;
  final String highlightLabel;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;

    final minVal = points.reduce((a, b) => a < b ? a : b);
    final maxVal = points.reduce((a, b) => a > b ? a : b);
    final range = (maxVal - minVal).clamp(1.0, double.infinity);

    // Padding for line drawing so tooltip and strokes aren't clipped
    const topPadding = 24.0;
    const bottomPadding = 12.0;
    final chartHeight = size.height - topPadding - bottomPadding;
    final dx = size.width / (points.length - 1);

    final path = Path();
    final fillPath = Path();

    final offsets = <Offset>[];
    for (int i = 0; i < points.length; i++) {
      final normalized = (points[i] - minVal) / range;
      // Invert Y because canvas Y goes downwards
      final y = size.height - bottomPadding - (normalized * chartHeight);
      final x = i * dx;
      offsets.add(Offset(x, y));
    }

    path.moveTo(offsets[0].dx, offsets[0].dy);
    fillPath.moveTo(offsets[0].dx, size.height);
    fillPath.lineTo(offsets[0].dx, offsets[0].dy);

    for (int i = 0; i < offsets.length - 1; i++) {
      final p0 = offsets[i];
      final p1 = offsets[i + 1];

      final controlPoint1 = Offset(p0.dx + (p1.dx - p0.dx) / 2, p0.dy);
      final controlPoint2 = Offset(p0.dx + (p1.dx - p0.dx) / 2, p1.dy);

      path.cubicTo(
        controlPoint1.dx,
        controlPoint1.dy,
        controlPoint2.dx,
        controlPoint2.dy,
        p1.dx,
        p1.dy,
      );

      fillPath.cubicTo(
        controlPoint1.dx,
        controlPoint1.dy,
        controlPoint2.dx,
        controlPoint2.dy,
        p1.dx,
        p1.dy,
      );
    }

    fillPath.lineTo(offsets.last.dx, size.height);
    fillPath.close();

    // 1. Draw gradient fill below wave
    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          lineColor.withValues(alpha: 0.25),
          lineColor.withValues(alpha: 0.02),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawPath(fillPath, fillPaint);

    // 2. Draw curved spline line
    final linePaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, linePaint);

    // 3. Draw Milestone / Highlight Dots
    final validHighlight = highlightIndex.clamp(0, offsets.length - 1);
    final highlightPoint = offsets[validHighlight];

    // Highlight vertical glow bar
    final glowPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          lineColor.withValues(alpha: 0.2),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(highlightPoint.dx - 16, highlightPoint.dy, 32, size.height - highlightPoint.dy));
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(highlightPoint.dx - 12, highlightPoint.dy, 24, size.height - highlightPoint.dy),
        const Radius.circular(6),
      ),
      glowPaint,
    );

    // Draw active white dot with outline
    final dotOuterPaint = Paint()..color = lineColor;
    final dotInnerPaint = Paint()..color = Colors.white;
    canvas.drawCircle(highlightPoint, 5.0, dotOuterPaint);
    canvas.drawCircle(highlightPoint, 3.0, dotInnerPaint);

    // Other milestone dots along the curve
    final milestoneIndices = [3, 7, 14];
    for (final idx in milestoneIndices) {
      if (idx < offsets.length && idx != validHighlight) {
        final p = offsets[idx];
        canvas.drawCircle(p, 3.5, Paint()..color = lineColor.withValues(alpha: 0.7));
        canvas.drawCircle(p, 1.8, Paint()..color = Colors.white);
      }
    }

    // 4. Draw Callout Tooltip text on top of highlight point
    final textSpan = TextSpan(
      text: highlightLabel,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 10,
        fontWeight: FontWeight.w700,
      ),
    );

    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    )..layout();

    final tooltipWidth = textPainter.width + 12;
    final tooltipHeight = textPainter.height + 6;
    final tooltipRect = Rect.fromCenter(
      center: Offset(highlightPoint.dx.clamp(tooltipWidth / 2, size.width - tooltipWidth / 2), highlightPoint.dy - 16),
      width: tooltipWidth,
      height: tooltipHeight,
    );

    final tooltipBgPaint = Paint()..color = const Color(0xFF1E2235);
    final tooltipBorderPaint = Paint()
      ..color = lineColor.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawRRect(RRect.fromRectAndRadius(tooltipRect, const Radius.circular(8)), tooltipBgPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(tooltipRect, const Radius.circular(8)), tooltipBorderPaint);

    textPainter.paint(
      canvas,
      Offset(tooltipRect.left + 6, tooltipRect.top + 3),
    );
  }

  @override
  bool shouldRepaint(covariant _SplineChartPainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.lineColor != lineColor ||
        oldDelegate.highlightIndex != highlightIndex;
  }
}
