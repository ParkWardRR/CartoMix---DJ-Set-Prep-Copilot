import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../../core/theme/theme.dart';
import '../../../models/models.dart';
import '../common/colored_badge.dart';

/// Card widget for displaying a track in the library grid
class TrackCard extends StatefulWidget {
  final Track track;
  final bool isSelected;
  final VoidCallback? onTap;
  final VoidCallback? onDoubleTap;

  const TrackCard({
    super.key,
    required this.track,
    this.isSelected = false,
    this.onTap,
    this.onDoubleTap,
  });

  @override
  State<TrackCard> createState() => _TrackCardState();
}

class _TrackCardState extends State<TrackCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final track = widget.track;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        onDoubleTap: widget.onDoubleTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: CartoMixSpacing.animFast),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? CartoMixColors.primary.withValues(alpha: 0.1)
                : CartoMixColors.bgSecondary,
            borderRadius: BorderRadius.circular(CartoMixSpacing.radiusLg),
            border: Border.all(
              color: widget.isSelected
                  ? CartoMixColors.primary
                  : _isHovered
                      ? CartoMixColors.primary.withValues(alpha: 0.5)
                      : CartoMixColors.border,
            ),
            boxShadow: widget.isSelected
                ? CartoMixTheme.glowShadow(CartoMixColors.primary)
                : null,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(CartoMixSpacing.radiusLg - 1),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Compact waveform preview
                _buildWaveformPreview(track),
                // Track info
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(CartoMixSpacing.sm),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Title and artist
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              track.title,
                              style: CartoMixTypography.trackTitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 1),
                            Text(
                              track.artist,
                              style: CartoMixTypography.trackArtist,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                        // Metadata badges
                        _buildBadgeRow(track),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWaveformPreview(Track track) {
    return Container(
      height: CartoMixSpacing.waveformHeightCompact,
      decoration: BoxDecoration(
        gradient: track.isAnalyzed ? CartoMixGradients.waveform : null,
        color: track.isAnalyzed ? null : CartoMixColors.bgTertiary,
      ),
      child: track.isAnalyzed
          ? CustomPaint(
              painter: _CompactWaveformPainter(
                waveform: track.analysis?.waveformPreview ?? Float32List(0),
                sections: track.analysis?.sections ?? [],
              ),
              size: Size.infinite,
            )
          : Center(
              child: Icon(
                track.isAnalyzing ? Icons.hourglass_top : Icons.graphic_eq,
                color: CartoMixColors.textMuted,
                size: 20,
              ),
            ),
    );
  }

  Widget _buildBadgeRow(Track track) {
    return Wrap(
      spacing: CartoMixSpacing.xs,
      runSpacing: CartoMixSpacing.xxs,
      children: [
        if (!track.isAnalyzed && !track.isAnalyzing)
          StatusBadge(status: track.analysisStatus.name),
        if (track.isAnalyzing) const StatusBadge(status: 'analyzing'),
        if (track.isAnalyzed) ...[
          BpmBadge(bpm: track.bpm),
          KeyBadge(keyValue: track.key),
          EnergyBadge(energy: track.energy),
          DurationBadge(duration: track.durationFormatted),
        ],
      ],
    );
  }
}

/// Simple waveform painter for compact preview
class _CompactWaveformPainter extends CustomPainter {
  final Float32List waveform;
  final List<TrackSection> sections;

  _CompactWaveformPainter({
    required this.waveform,
    required this.sections,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (waveform.isEmpty) {
      // Draw placeholder bars
      _drawPlaceholderBars(canvas, size);
      return;
    }

    // Draw section backgrounds
    for (final section in sections) {
      final startX = (section.startTime / (sections.lastOrNull?.endTime ?? 1)) * size.width;
      final endX = (section.endTime / (sections.lastOrNull?.endTime ?? 1)) * size.width;
      final paint = Paint()
        ..color = section.color.withValues(alpha: 0.2)
        ..style = PaintingStyle.fill;
      canvas.drawRect(
        Rect.fromLTRB(startX, 0, endX, size.height),
        paint,
      );
    }

    // Draw waveform bars
    final barWidth = size.width / waveform.length;
    final midY = size.height / 2;
    final maxHeight = size.height / 2 - 2;

    for (var i = 0; i < waveform.length; i++) {
      final value = waveform[i].abs().clamp(0.0, 1.0);
      final height = value * maxHeight;
      final x = i * barWidth;

      // Gradient color based on position
      final t = i / waveform.length;
      final color = Color.lerp(
        CartoMixGradients.waveformColors.first,
        CartoMixGradients.waveformColors.last,
        t,
      )!;

      final paint = Paint()
        ..color = color.withValues(alpha: 0.8)
        ..style = PaintingStyle.fill;

      // Draw mirrored bar
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset(x + barWidth / 2, midY),
          width: barWidth * 0.8,
          height: height * 2,
        ),
        paint,
      );
    }
  }

  void _drawPlaceholderBars(Canvas canvas, Size size) {
    final barCount = 50;
    final barWidth = size.width / barCount;
    final midY = size.height / 2;
    final maxHeight = size.height / 2 - 4;

    for (var i = 0; i < barCount; i++) {
      // Simulate a natural-looking waveform
      final phase = i / barCount;
      final value = 0.3 +
          0.3 * _sin(phase * 3.14159 * 4) +
          0.2 * _sin(phase * 3.14159 * 8) +
          0.1 * _sin(phase * 3.14159 * 16);
      final height = value.clamp(0.1, 1.0) * maxHeight;
      final x = i * barWidth;

      // Gradient color
      final t = i / barCount;
      final color = Color.lerp(
        CartoMixGradients.waveformColors.first,
        CartoMixGradients.waveformColors.last,
        t,
      )!;

      final paint = Paint()
        ..color = color.withValues(alpha: 0.5)
        ..style = PaintingStyle.fill;

      canvas.drawRect(
        Rect.fromCenter(
          center: Offset(x + barWidth / 2, midY),
          width: barWidth * 0.6,
          height: height * 2,
        ),
        paint,
      );
    }
  }

  double _sin(double x) => (x - x * x * x / 6 + x * x * x * x * x / 120).clamp(-1, 1);

  @override
  bool shouldRepaint(_CompactWaveformPainter oldDelegate) {
    return waveform != oldDelegate.waveform;
  }
}
