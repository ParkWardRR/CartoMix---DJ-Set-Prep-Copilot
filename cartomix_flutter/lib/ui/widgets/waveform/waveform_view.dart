import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../../core/theme/theme.dart';
import '../../../models/models.dart';

/// Full waveform view matching web UI design
/// Features: section overlays, beat grid, cue markers, playhead with glow
class WaveformView extends StatelessWidget {
  final Float32List waveform;
  final List<TrackSection> sections;
  final List<CuePoint> cuePoints;
  final double durationSeconds;
  final double currentTime;
  final double? bpm;
  final bool showBeatGrid;
  final bool showSections;
  final bool showCues;
  final ValueChanged<double>? onSeek;

  const WaveformView({
    super.key,
    required this.waveform,
    this.sections = const [],
    this.cuePoints = const [],
    this.durationSeconds = 0,
    this.currentTime = 0,
    this.bpm,
    this.showBeatGrid = true,
    this.showSections = true,
    this.showCues = true,
    this.onSeek,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          onTapDown: onSeek != null
              ? (details) {
                  final position = details.localPosition.dx / constraints.maxWidth;
                  onSeek!(position * durationSeconds);
                }
              : null,
          onHorizontalDragUpdate: onSeek != null
              ? (details) {
                  final position = details.localPosition.dx / constraints.maxWidth;
                  onSeek!((position.clamp(0, 1)) * durationSeconds);
                }
              : null,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(CartoMixSpacing.radiusMd),
            child: CustomPaint(
              painter: _WaveformPainter(
                waveform: waveform,
                sections: sections,
                cuePoints: cuePoints,
                durationSeconds: durationSeconds,
                currentTime: currentTime,
                bpm: bpm,
                showBeatGrid: showBeatGrid,
                showSections: showSections,
                showCues: showCues,
              ),
              size: Size(constraints.maxWidth, constraints.maxHeight),
            ),
          ),
        );
      },
    );
  }
}

class _WaveformPainter extends CustomPainter {
  final Float32List waveform;
  final List<TrackSection> sections;
  final List<CuePoint> cuePoints;
  final double durationSeconds;
  final double currentTime;
  final double? bpm;
  final bool showBeatGrid;
  final bool showSections;
  final bool showCues;

  _WaveformPainter({
    required this.waveform,
    required this.sections,
    required this.cuePoints,
    required this.durationSeconds,
    required this.currentTime,
    required this.bpm,
    required this.showBeatGrid,
    required this.showSections,
    required this.showCues,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = CartoMixColors.bgTertiary,
    );

    // Draw sections (background overlays)
    if (showSections) {
      _drawSections(canvas, size);
    }

    // Draw beat grid
    if (showBeatGrid && bpm != null && bpm! > 0) {
      _drawBeatGrid(canvas, size);
    }

    // Draw waveform
    _drawWaveform(canvas, size);

    // Draw cue markers
    if (showCues) {
      _drawCueMarkers(canvas, size);
    }

    // Draw playhead
    _drawPlayhead(canvas, size);
  }

  void _drawSections(Canvas canvas, Size size) {
    if (durationSeconds <= 0) return;

    for (final section in sections) {
      final startX = (section.startTime / durationSeconds) * size.width;
      final endX = (section.endTime / durationSeconds) * size.width;
      final color = CartoMixColors.colorForSectionOverlay(section.type.name);

      canvas.drawRect(
        Rect.fromLTRB(startX, 0, endX, size.height),
        Paint()..color = color,
      );

      // Section label at top
      final textPainter = TextPainter(
        text: TextSpan(
          text: section.type.name.toUpperCase(),
          style: CartoMixTypography.badgeSmall.copyWith(
            color: CartoMixColors.colorForSection(section.type.name),
            fontSize: 9,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      if (endX - startX > textPainter.width + 8) {
        textPainter.paint(canvas, Offset(startX + 4, 4));
      }
    }
  }

  void _drawBeatGrid(Canvas canvas, Size size) {
    if (durationSeconds <= 0 || bpm == null || bpm! <= 0) return;

    final beatDuration = 60.0 / bpm!;
    final totalBeats = (durationSeconds / beatDuration).floor();

    for (var i = 0; i <= totalBeats; i++) {
      final x = (i * beatDuration / durationSeconds) * size.width;
      final isStrong = i % 4 == 0; // Stronger line every 4 beats (bar)

      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        Paint()
          ..color = isStrong ? CartoMixColors.beatGridStrong : CartoMixColors.beatGridWeak
          ..strokeWidth = isStrong ? 1.0 : 0.5,
      );
    }
  }

  void _drawWaveform(Canvas canvas, Size size) {
    if (waveform.isEmpty) {
      _drawPlaceholderWaveform(canvas, size);
      return;
    }

    final playPosition = durationSeconds > 0 ? currentTime / durationSeconds : 0.0;
    final playX = playPosition * size.width;
    final barWidth = size.width / waveform.length;
    final midY = size.height / 2;
    final maxHeight = size.height / 2 - 8; // Leave space for cues

    for (var i = 0; i < waveform.length; i++) {
      final value = waveform[i].abs().clamp(0.0, 1.0);
      final height = value * maxHeight;
      final x = i * barWidth;

      // Color based on played/unplayed
      final isPlayed = x < playX;
      final t = i / waveform.length;

      Color color;
      if (isPlayed) {
        // Gradient from primary-ish to accent for played portion
        color = Color.lerp(
          CartoMixColors.waveformPlayed,
          CartoMixColors.waveformPlayed.withValues(alpha: 0.8),
          t,
        )!;
      } else {
        // Blue for unplayed portion
        color = Color.lerp(
          CartoMixColors.waveformUnplayed,
          CartoMixColors.waveformUnplayed.withValues(alpha: 0.7),
          t,
        )!;
      }

      canvas.drawRect(
        Rect.fromCenter(
          center: Offset(x + barWidth / 2, midY),
          width: barWidth * 0.8,
          height: height * 2,
        ),
        Paint()
          ..color = color
          ..style = PaintingStyle.fill,
      );
    }
  }

  void _drawPlaceholderWaveform(Canvas canvas, Size size) {
    final barCount = 100;
    final barWidth = size.width / barCount;
    final midY = size.height / 2;
    final maxHeight = size.height / 2 - 8;

    for (var i = 0; i < barCount; i++) {
      final phase = i / barCount;
      final value = 0.3 +
          0.3 * _sin(phase * math.pi * 4) +
          0.2 * _sin(phase * math.pi * 8) +
          0.1 * _sin(phase * math.pi * 16);
      final height = value.clamp(0.1, 1.0) * maxHeight;
      final x = i * barWidth;

      final t = i / barCount;
      final color = Color.lerp(
        CartoMixColors.waveformUnplayed,
        CartoMixColors.accent,
        t,
      )!;

      canvas.drawRect(
        Rect.fromCenter(
          center: Offset(x + barWidth / 2, midY),
          width: barWidth * 0.6,
          height: height * 2,
        ),
        Paint()
          ..color = color.withValues(alpha: 0.4)
          ..style = PaintingStyle.fill,
      );
    }
  }

  void _drawCueMarkers(Canvas canvas, Size size) {
    if (durationSeconds <= 0) return;

    for (final cue in cuePoints) {
      final x = (cue.timeSeconds / durationSeconds) * size.width;
      final color = CartoMixColors.colorForCue(cue.type.name);

      // Vertical line
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        Paint()
          ..color = color
          ..strokeWidth = 2,
      );

      // Triangle marker at top
      final path = Path()
        ..moveTo(x, 0)
        ..lineTo(x - 5, 8)
        ..lineTo(x + 5, 8)
        ..close();
      canvas.drawPath(path, Paint()..color = color);
    }
  }

  void _drawPlayhead(Canvas canvas, Size size) {
    if (durationSeconds <= 0) return;

    final position = currentTime / durationSeconds;
    final x = position * size.width;

    // Glow effect
    final glowPaint = Paint()
      ..color = CartoMixColors.waveformPlayheadGlow
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawLine(
      Offset(x, 0),
      Offset(x, size.height),
      glowPaint..strokeWidth = 6,
    );

    // Main playhead line
    canvas.drawLine(
      Offset(x, 0),
      Offset(x, size.height),
      Paint()
        ..color = CartoMixColors.waveformPlayhead
        ..strokeWidth = 2,
    );

    // Circle handle at bottom
    canvas.drawCircle(
      Offset(x, size.height - 6),
      5,
      Paint()..color = CartoMixColors.waveformPlayhead,
    );
    canvas.drawCircle(
      Offset(x, size.height - 6),
      3,
      Paint()..color = CartoMixColors.bgPrimary,
    );
  }

  double _sin(double x) => math.sin(x);

  @override
  bool shouldRepaint(_WaveformPainter oldDelegate) {
    return waveform != oldDelegate.waveform ||
        currentTime != oldDelegate.currentTime ||
        sections != oldDelegate.sections ||
        cuePoints != oldDelegate.cuePoints;
  }
}

/// Compact waveform preview for cards and list items
class CompactWaveformPreview extends StatelessWidget {
  final Float32List waveform;
  final List<TrackSection>? sections;
  final double? playPosition; // 0.0 to 1.0

  const CompactWaveformPreview({
    super.key,
    required this.waveform,
    this.sections,
    this.playPosition,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _CompactWaveformPainter(
        waveform: waveform,
        sections: sections ?? [],
        playPosition: playPosition,
      ),
      size: Size.infinite,
    );
  }
}

class _CompactWaveformPainter extends CustomPainter {
  final Float32List waveform;
  final List<TrackSection> sections;
  final double? playPosition;

  _CompactWaveformPainter({
    required this.waveform,
    required this.sections,
    this.playPosition,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw section backgrounds
    if (sections.isNotEmpty) {
      final totalDuration = sections.last.endTime;
      for (final section in sections) {
        final startX = (section.startTime / totalDuration) * size.width;
        final endX = (section.endTime / totalDuration) * size.width;
        canvas.drawRect(
          Rect.fromLTRB(startX, 0, endX, size.height),
          Paint()..color = CartoMixColors.colorForSectionOverlay(section.type.name),
        );
      }
    }

    // Draw waveform
    if (waveform.isEmpty) {
      _drawPlaceholder(canvas, size);
      return;
    }

    final barWidth = size.width / waveform.length;
    final midY = size.height / 2;
    final maxHeight = size.height / 2 - 2;
    final playX = playPosition != null ? playPosition! * size.width : -1;

    for (var i = 0; i < waveform.length; i++) {
      final value = waveform[i].abs().clamp(0.0, 1.0);
      final height = value * maxHeight;
      final x = i * barWidth;

      final t = i / waveform.length;
      final isPlayed = playPosition != null && x < playX;

      final color = isPlayed
          ? CartoMixColors.waveformPlayed
          : Color.lerp(
              CartoMixColors.waveformUnplayed,
              CartoMixColors.accent,
              t,
            )!;

      canvas.drawRect(
        Rect.fromCenter(
          center: Offset(x + barWidth / 2, midY),
          width: barWidth * 0.8,
          height: height * 2,
        ),
        Paint()
          ..color = color.withValues(alpha: isPlayed ? 1.0 : 0.8)
          ..style = PaintingStyle.fill,
      );
    }
  }

  void _drawPlaceholder(Canvas canvas, Size size) {
    final barCount = 50;
    final barWidth = size.width / barCount;
    final midY = size.height / 2;
    final maxHeight = size.height / 2 - 2;

    for (var i = 0; i < barCount; i++) {
      final phase = i / barCount;
      final value = 0.3 +
          0.3 * math.sin(phase * math.pi * 4) +
          0.2 * math.sin(phase * math.pi * 8);
      final height = value.clamp(0.1, 1.0) * maxHeight;
      final x = i * barWidth;

      final t = i / barCount;
      final color = Color.lerp(
        CartoMixColors.waveformUnplayed,
        CartoMixColors.accent,
        t,
      )!;

      canvas.drawRect(
        Rect.fromCenter(
          center: Offset(x + barWidth / 2, midY),
          width: barWidth * 0.6,
          height: height * 2,
        ),
        Paint()
          ..color = color.withValues(alpha: 0.5)
          ..style = PaintingStyle.fill,
      );
    }
  }

  @override
  bool shouldRepaint(_CompactWaveformPainter oldDelegate) {
    return waveform != oldDelegate.waveform ||
        playPosition != oldDelegate.playPosition;
  }
}
