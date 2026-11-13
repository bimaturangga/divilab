import 'package:flutter/material.dart';

import '../../core/health.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_text.dart';

class ChartSeries {
  const ChartSeries({required this.values, required this.color, this.dashed = false, this.offset = 0});

  /// Nilai per titik sumbu-x (null = kosong).
  final List<double?> values;
  final Color color;
  final bool dashed;

  /// Geser titik pertama ke indeks x tertentu (untuk garis prediksi).
  final int offset;
}

/// Grafik garis ringan (CustomPainter) tanpa dependensi tambahan.
class SimpleLineChart extends StatelessWidget {
  const SimpleLineChart({
    super.key,
    required this.xLabels,
    required this.series,
    required this.yMin,
    required this.yMax,
    this.yTickCount = 5,
    this.bandMin,
    this.bandMax,
    this.height = 220,
  });

  final List<String> xLabels;
  final List<ChartSeries> series;
  final double yMin;
  final double yMax;
  final int yTickCount;
  final double? bandMin;
  final double? bandMax;
  final double height;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: _ChartPainter(
          xLabels: xLabels,
          series: series,
          yMin: yMin,
          yMax: yMax,
          yTickCount: yTickCount,
          bandMin: bandMin,
          bandMax: bandMax,
          gridColor: p.borderDefault,
          labelStyle: AppText.caption.c(p.textTertiary),
          bandColor: p.success50,
          dotFill: p.bgCanvas,
        ),
      ),
    );
  }
}

class _ChartPainter extends CustomPainter {
  _ChartPainter({
    required this.xLabels,
    required this.series,
    required this.yMin,
    required this.yMax,
    required this.yTickCount,
    required this.bandMin,
    required this.bandMax,
    required this.gridColor,
    required this.labelStyle,
    required this.bandColor,
    required this.dotFill,
  });

  final List<String> xLabels;
  final List<ChartSeries> series;
  final double yMin;
  final double yMax;
  final int yTickCount;
  final double? bandMin;
  final double? bandMax;
  final Color gridColor;
  final TextStyle labelStyle;
  final Color bandColor;
  final Color dotFill;

  static const _left = 34.0;
  static const _bottom = 22.0;
  static const _top = 8.0;
  static const _right = 6.0;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width - _left - _right;
    final h = size.height - _bottom - _top;
    double yPos(double v) => _top + h - ((v - yMin) / (yMax - yMin)).clamp(0.0, 1.0).toDouble() * h;
    final n = xLabels.length;
    double xPos(int i) => _left + (n <= 1 ? w / 2 : i / (n - 1) * w);

    // Pita rentang normal.
    if (bandMin != null && bandMax != null) {
      canvas.drawRect(
        Rect.fromLTRB(_left, yPos(bandMax!), _left + w, yPos(bandMin!)),
        Paint()..color = bandColor,
      );
    }

    // Grid & label sumbu-y.
    final grid = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    for (var k = 0; k < yTickCount; k++) {
      final v = yMin + (yMax - yMin) * k / (yTickCount - 1);
      final y = yPos(v);
      canvas.drawLine(Offset(_left, y), Offset(_left + w, y), grid);
      _text(canvas, fmtNum(v, decimals: 0), Offset(_left - 6, y), alignRight: true);
    }
    // Label sumbu-x.
    for (var i = 0; i < n; i++) {
      _text(canvas, xLabels[i], Offset(xPos(i), size.height - _bottom + 6), center: true, top: true);
    }

    for (final s in series) {
      final pts = <Offset>[];
      for (var i = 0; i < s.values.length; i++) {
        final v = s.values[i];
        if (v == null) continue;
        pts.add(Offset(xPos(i + s.offset), yPos(v)));
      }
      if (pts.isEmpty) continue;
      final line = Paint()
        ..color = s.color
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      if (s.dashed) {
        for (var i = 0; i < pts.length - 1; i++) {
          _dash(canvas, pts[i], pts[i + 1], line);
        }
      } else {
        final path = Path()..moveTo(pts.first.dx, pts.first.dy);
        for (final pt in pts.skip(1)) {
          path.lineTo(pt.dx, pt.dy);
        }
        canvas.drawPath(path, line);
      }
      final fill = Paint()..color = dotFill;
      final ring = Paint()
        ..color = s.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      for (final pt in pts) {
        canvas.drawCircle(pt, 4, fill);
        canvas.drawCircle(pt, 4, ring);
      }
    }
  }

  void _dash(Canvas canvas, Offset a, Offset b, Paint paint) {
    const dash = 6.0;
    const gap = 5.0;
    final total = (b - a).distance;
    if (total == 0) return;
    final dir = (b - a) / total;
    var d = 0.0;
    while (d < total) {
      final end = (d + dash) > total ? total : d + dash;
      canvas.drawLine(a + dir * d, a + dir * end, paint);
      d += dash + gap;
    }
  }

  void _text(Canvas canvas, String text, Offset at, {bool alignRight = false, bool center = false, bool top = false}) {
    final tp = TextPainter(text: TextSpan(text: text, style: labelStyle), textDirection: TextDirection.ltr)..layout();
    var dx = at.dx;
    if (alignRight) dx -= tp.width;
    if (center) dx -= tp.width / 2;
    final dy = top ? at.dy : at.dy - tp.height / 2;
    tp.paint(canvas, Offset(dx, dy));
  }

  @override
  bool shouldRepaint(covariant _ChartPainter old) => true;
}
