import 'package:flutter/material.dart';

/// Rolling LAF trace: [capacity] slots across the width, newest at the right.
class LevelHistoryChart extends StatelessWidget {
  const LevelHistoryChart({
    super.key,
    required this.levels,
    required this.capacity,
    this.minDb = 30,
    this.maxDb = 110,
  });

  final List<double> levels;
  final int capacity;
  final double minDb;
  final double maxDb;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AspectRatio(
      aspectRatio: 2,
      child: CustomPaint(
        painter: _HistoryPainter(
          levels: levels,
          capacity: capacity,
          minDb: minDb,
          maxDb: maxDb,
          lineColor: scheme.primary,
          gridColor: scheme.outlineVariant,
          labelStyle: Theme.of(context)
              .textTheme
              .labelSmall!
              .copyWith(color: scheme.onSurfaceVariant),
        ),
      ),
    );
  }
}

class _HistoryPainter extends CustomPainter {
  _HistoryPainter({
    required this.levels,
    required this.capacity,
    required this.minDb,
    required this.maxDb,
    required this.lineColor,
    required this.gridColor,
    required this.labelStyle,
  });

  static const _gridStepDb = 20.0;
  static const _labelGutter = 28.0;

  final List<double> levels;
  final int capacity;
  final double minDb;
  final double maxDb;
  final Color lineColor;
  final Color gridColor;
  final TextStyle labelStyle;

  @override
  void paint(Canvas canvas, Size size) {
    final plot = Rect.fromLTRB(_labelGutter, 0, size.width, size.height);
    double yFor(double db) =>
        plot.bottom - (db.clamp(minDb, maxDb) - minDb) / (maxDb - minDb) * plot.height;

    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    for (var db = minDb; db <= maxDb; db += _gridStepDb) {
      final y = yFor(db);
      canvas.drawLine(Offset(plot.left, y), Offset(plot.right, y), gridPaint);
      final label = TextPainter(
        text: TextSpan(text: db.toStringAsFixed(0), style: labelStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      label.paint(canvas, Offset(0, (y - label.height / 2).clamp(0, size.height - label.height)));
    }

    if (levels.length < 2) return;
    final dx = plot.width / (capacity - 1);
    final startX = plot.right - (levels.length - 1) * dx;
    final path = Path()..moveTo(startX, yFor(levels.first));
    for (var i = 1; i < levels.length; i++) {
      path.lineTo(startX + i * dx, yFor(levels[i]));
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = lineColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_HistoryPainter old) =>
      !identical(old.levels, levels) ||
      old.lineColor != lineColor ||
      old.gridColor != gridColor;
}
