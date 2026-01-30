import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../../core/theme/theme.dart';

/// Energy arc visualization matching web UI's SVG bezier curve
/// Shows the energy journey across a DJ set as a smooth curve
class EnergyArc extends StatelessWidget {
  final List<int> energyValues; // Energy values per track (1-10)
  final int? highlightedIndex; // Currently highlighted track
  final ValueChanged<int>? onTrackTap;
  final bool showLabels;
  final bool showGrid;

  const EnergyArc({
    super.key,
    required this.energyValues,
    this.highlightedIndex,
    this.onTrackTap,
    this.showLabels = true,
    this.showGrid = true,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return CustomPaint(
          painter: _EnergyArcPainter(
            energyValues: energyValues,
            highlightedIndex: highlightedIndex,
            showLabels: showLabels,
            showGrid: showGrid,
          ),
          size: Size(constraints.maxWidth, constraints.maxHeight),
          child: _buildTapTargets(constraints),
        );
      },
    );
  }

  Widget? _buildTapTargets(BoxConstraints constraints) {
    if (onTrackTap == null || energyValues.isEmpty) return null;

    return Stack(
      children: List.generate(energyValues.length, (index) {
        final x = _getXForIndex(index, constraints.maxWidth);
        return Positioned(
          left: x - 16,
          top: 0,
          bottom: 0,
          width: 32,
          child: GestureDetector(
            onTap: () => onTrackTap!(index),
            behavior: HitTestBehavior.opaque,
            child: const SizedBox.expand(),
          ),
        );
      }),
    );
  }

  double _getXForIndex(int index, double width) {
    if (energyValues.length <= 1) return width / 2;
    final padding = 24.0;
    final usableWidth = width - padding * 2;
    return padding + (index / (energyValues.length - 1)) * usableWidth;
  }
}

class _EnergyArcPainter extends CustomPainter {
  final List<int> energyValues;
  final int? highlightedIndex;
  final bool showLabels;
  final bool showGrid;

  _EnergyArcPainter({
    required this.energyValues,
    required this.highlightedIndex,
    required this.showLabels,
    required this.showGrid,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final padding = 24.0;
    final labelHeight = showLabels ? 20.0 : 0.0;
    final chartTop = labelHeight;
    final chartHeight = size.height - chartTop - 8;
    final chartWidth = size.width - padding * 2;

    // Draw grid
    if (showGrid) {
      _drawGrid(canvas, size, padding, chartTop, chartHeight, chartWidth);
    }

    if (energyValues.isEmpty) {
      _drawEmptyState(canvas, size);
      return;
    }

    // Calculate points
    final points = <Offset>[];
    for (var i = 0; i < energyValues.length; i++) {
      final x = padding + (i / math.max(energyValues.length - 1, 1)) * chartWidth;
      final normalizedEnergy = (energyValues[i] - 1) / 9.0; // Normalize 1-10 to 0-1
      final y = chartTop + chartHeight * (1 - normalizedEnergy);
      points.add(Offset(x, y));
    }

    // Draw fill under curve
    _drawFill(canvas, points, chartTop, chartHeight, size);

    // Draw curve
    _drawCurve(canvas, points);

    // Draw points
    _drawPoints(canvas, points);
  }

  void _drawGrid(Canvas canvas, Size size, double padding, double chartTop,
      double chartHeight, double chartWidth) {
    final gridPaint = Paint()
      ..color = CartoMixColors.border.withValues(alpha: 0.3)
      ..strokeWidth = 1;

    // Horizontal lines for energy levels (every 2 levels)
    for (var level = 2; level <= 10; level += 2) {
      final normalizedY = (level - 1) / 9.0;
      final y = chartTop + chartHeight * (1 - normalizedY);

      canvas.drawLine(
        Offset(padding, y),
        Offset(size.width - padding, y),
        gridPaint,
      );

      // Level label
      if (showLabels) {
        final textPainter = TextPainter(
          text: TextSpan(
            text: '$level',
            style: CartoMixTypography.badgeSmall.copyWith(
              color: CartoMixColors.textMuted,
              fontSize: 9,
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        textPainter.paint(canvas, Offset(4, y - textPainter.height / 2));
      }
    }
  }

  void _drawEmptyState(Canvas canvas, Size size) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: 'Add tracks to see energy journey',
        style: CartoMixTypography.caption.copyWith(
          color: CartoMixColors.textMuted,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        (size.width - textPainter.width) / 2,
        (size.height - textPainter.height) / 2,
      ),
    );
  }

  void _drawFill(Canvas canvas, List<Offset> points, double chartTop,
      double chartHeight, Size size) {
    if (points.length < 2) return;

    final path = Path();
    path.moveTo(points.first.dx, chartTop + chartHeight);
    path.lineTo(points.first.dx, points.first.dy);

    // Create smooth curve through points using bezier
    for (var i = 0; i < points.length - 1; i++) {
      final p0 = points[i];
      final p1 = points[i + 1];
      final midX = (p0.dx + p1.dx) / 2;

      path.cubicTo(midX, p0.dy, midX, p1.dy, p1.dx, p1.dy);
    }

    path.lineTo(points.last.dx, chartTop + chartHeight);
    path.close();

    // Gradient fill
    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          CartoMixColors.accent.withValues(alpha: 0.3),
          CartoMixColors.accent.withValues(alpha: 0.05),
        ],
      ).createShader(Rect.fromLTWH(0, chartTop, size.width, chartHeight));

    canvas.drawPath(path, fillPaint);
  }

  void _drawCurve(Canvas canvas, List<Offset> points) {
    if (points.length < 2) return;

    final path = Path();
    path.moveTo(points.first.dx, points.first.dy);

    // Create smooth curve through points using bezier
    for (var i = 0; i < points.length - 1; i++) {
      final p0 = points[i];
      final p1 = points[i + 1];
      final midX = (p0.dx + p1.dx) / 2;

      path.cubicTo(midX, p0.dy, midX, p1.dy, p1.dx, p1.dy);
    }

    // Glow effect
    canvas.drawPath(
      path,
      Paint()
        ..color = CartoMixColors.accent.withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );

    // Main line
    canvas.drawPath(
      path,
      Paint()
        ..color = CartoMixColors.accent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  void _drawPoints(Canvas canvas, List<Offset> points) {
    for (var i = 0; i < points.length; i++) {
      final point = points[i];
      final isHighlighted = i == highlightedIndex;
      final energy = energyValues[i];
      final color = CartoMixColors.colorForEnergy(energy);

      // Outer glow for highlighted
      if (isHighlighted) {
        canvas.drawCircle(
          point,
          10,
          Paint()
            ..color = color.withValues(alpha: 0.3)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
        );
      }

      // Point
      canvas.drawCircle(
        point,
        isHighlighted ? 6 : 4,
        Paint()..color = color,
      );

      // Inner highlight
      canvas.drawCircle(
        point,
        isHighlighted ? 3 : 2,
        Paint()..color = Colors.white.withValues(alpha: 0.6),
      );
    }
  }

  @override
  bool shouldRepaint(_EnergyArcPainter oldDelegate) {
    return energyValues != oldDelegate.energyValues ||
        highlightedIndex != oldDelegate.highlightedIndex;
  }
}

/// Mini energy arc for compact displays
class MiniEnergyArc extends StatelessWidget {
  final List<int> energyValues;

  const MiniEnergyArc({
    super.key,
    required this.energyValues,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _MiniEnergyArcPainter(energyValues: energyValues),
      size: Size.infinite,
    );
  }
}

class _MiniEnergyArcPainter extends CustomPainter {
  final List<int> energyValues;

  _MiniEnergyArcPainter({required this.energyValues});

  @override
  void paint(Canvas canvas, Size size) {
    if (energyValues.isEmpty) return;

    final points = <Offset>[];
    final padding = 2.0;

    for (var i = 0; i < energyValues.length; i++) {
      final x = padding + (i / math.max(energyValues.length - 1, 1)) * (size.width - padding * 2);
      final normalizedEnergy = (energyValues[i] - 1) / 9.0;
      final y = size.height - (normalizedEnergy * (size.height - padding * 2)) - padding;
      points.add(Offset(x, y));
    }

    if (points.length < 2) {
      canvas.drawCircle(
        points.first,
        2,
        Paint()..color = CartoMixColors.colorForEnergy(energyValues.first),
      );
      return;
    }

    // Draw curve
    final path = Path();
    path.moveTo(points.first.dx, points.first.dy);

    for (var i = 0; i < points.length - 1; i++) {
      final p0 = points[i];
      final p1 = points[i + 1];
      final midX = (p0.dx + p1.dx) / 2;
      path.cubicTo(midX, p0.dy, midX, p1.dy, p1.dx, p1.dy);
    }

    canvas.drawPath(
      path,
      Paint()
        ..color = CartoMixColors.accent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_MiniEnergyArcPainter oldDelegate) {
    return energyValues != oldDelegate.energyValues;
  }
}
