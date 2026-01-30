import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../../core/theme/theme.dart';
import '../../../models/models.dart';
import '../common/colored_badge.dart';

/// List-style track item matching web UI design
/// Used in library list view and set builder
class TrackListItem extends StatefulWidget {
  final Track track;
  final bool isSelected;
  final bool showIndex;
  final int? index;
  final VoidCallback? onTap;
  final VoidCallback? onDoubleTap;
  final Widget? trailing;

  const TrackListItem({
    super.key,
    required this.track,
    this.isSelected = false,
    this.showIndex = false,
    this.index,
    this.onTap,
    this.onDoubleTap,
    this.trailing,
  });

  @override
  State<TrackListItem> createState() => _TrackListItemState();
}

class _TrackListItemState extends State<TrackListItem> {
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
          padding: const EdgeInsets.symmetric(
            horizontal: CartoMixSpacing.md,
            vertical: CartoMixSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? CartoMixColors.selection
                : _isHovered
                    ? CartoMixColors.hoverHighlight
                    : Colors.transparent,
            border: Border(
              left: BorderSide(
                color: widget.isSelected
                    ? CartoMixColors.primary
                    : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Row(
            children: [
              // Index (if shown)
              if (widget.showIndex) ...[
                SizedBox(
                  width: 32,
                  child: Text(
                    '${widget.index ?? 0}',
                    style: CartoMixTypography.caption.copyWith(
                      color: CartoMixColors.textMuted,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(width: CartoMixSpacing.sm),
              ],

              // Waveform thumbnail / Status indicator
              _buildThumbnail(track),
              const SizedBox(width: CartoMixSpacing.md),

              // Title and artist
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      track.title,
                      style: CartoMixTypography.trackTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      track.artist,
                      style: CartoMixTypography.trackArtist,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: CartoMixSpacing.md),

              // Metadata columns (BPM, Key, Energy, Duration)
              if (track.isAnalyzed) ...[
                _buildMetadataCell(
                  track.bpmFormatted ?? '-',
                  CartoMixColors.primary,
                  width: 48,
                ),
                _buildMetadataCell(
                  track.key ?? '-',
                  track.keyColor,
                  width: 48,
                ),
                _buildMetadataCell(
                  '${track.energy ?? '-'}',
                  track.energyColor,
                  width: 32,
                ),
                _buildMetadataCell(
                  track.durationFormatted ?? '-',
                  CartoMixColors.textSecondary,
                  width: 56,
                ),
              ] else ...[
                // Status badge for non-analyzed tracks
                SizedBox(
                  width: 184,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      StatusBadge(status: track.analysisStatus.name),
                    ],
                  ),
                ),
              ],

              // Trailing widget (actions, drag handle, etc.)
              if (widget.trailing != null) ...[
                const SizedBox(width: CartoMixSpacing.sm),
                widget.trailing!,
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThumbnail(Track track) {
    return Container(
      width: 48,
      height: 32,
      decoration: BoxDecoration(
        color: CartoMixColors.bgTertiary,
        borderRadius: BorderRadius.circular(CartoMixSpacing.radiusSm),
        border: Border.all(color: CartoMixColors.border),
        gradient: track.isAnalyzed ? CartoMixGradients.waveform : null,
      ),
      child: track.isAnalyzed
          ? ClipRRect(
              borderRadius: BorderRadius.circular(CartoMixSpacing.radiusSm - 1),
              child: CustomPaint(
                painter: _MiniWaveformPainter(
                  waveform: track.analysis?.waveformPreview ?? Float32List(0),
                ),
                size: const Size(48, 32),
              ),
            )
          : Center(
              child: Icon(
                track.isAnalyzing ? Icons.hourglass_top : Icons.graphic_eq,
                color: CartoMixColors.textMuted,
                size: 14,
              ),
            ),
    );
  }

  Widget _buildMetadataCell(String value, Color color, {required double width}) {
    return SizedBox(
      width: width,
      child: Text(
        value,
        style: CartoMixTypography.badge.copyWith(
          color: color,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

/// Mini waveform painter for list thumbnails
class _MiniWaveformPainter extends CustomPainter {
  final Float32List waveform;

  _MiniWaveformPainter({required this.waveform});

  @override
  void paint(Canvas canvas, Size size) {
    if (waveform.isEmpty) {
      _drawPlaceholder(canvas, size);
      return;
    }

    final barCount = waveform.length.clamp(1, 24);
    final step = waveform.length ~/ barCount;
    final barWidth = size.width / barCount;
    final midY = size.height / 2;
    final maxHeight = size.height / 2 - 2;

    for (var i = 0; i < barCount; i++) {
      final sampleIndex = (i * step).clamp(0, waveform.length - 1);
      final value = waveform[sampleIndex].abs().clamp(0.0, 1.0);
      final height = value * maxHeight;
      final x = i * barWidth;

      // Gradient color based on position
      final t = i / barCount;
      final color = Color.lerp(
        CartoMixColors.primary,
        CartoMixColors.accent,
        t,
      )!;

      final paint = Paint()
        ..color = color.withValues(alpha: 0.8)
        ..style = PaintingStyle.fill;

      canvas.drawRect(
        Rect.fromCenter(
          center: Offset(x + barWidth / 2, midY),
          width: barWidth * 0.7,
          height: height * 2,
        ),
        paint,
      );
    }
  }

  void _drawPlaceholder(Canvas canvas, Size size) {
    final barCount = 16;
    final barWidth = size.width / barCount;
    final midY = size.height / 2;
    final maxHeight = size.height / 2 - 2;

    for (var i = 0; i < barCount; i++) {
      final phase = i / barCount;
      final value = 0.3 + 0.4 * _sin(phase * 3.14159 * 3);
      final height = value.clamp(0.1, 1.0) * maxHeight;
      final x = i * barWidth;

      final t = i / barCount;
      final color = Color.lerp(
        CartoMixColors.primary,
        CartoMixColors.accent,
        t,
      )!;

      final paint = Paint()
        ..color = color.withValues(alpha: 0.4)
        ..style = PaintingStyle.fill;

      canvas.drawRect(
        Rect.fromCenter(
          center: Offset(x + barWidth / 2, midY),
          width: barWidth * 0.5,
          height: height * 2,
        ),
        paint,
      );
    }
  }

  double _sin(double x) => (x - x * x * x / 6 + x * x * x * x * x / 120).clamp(-1, 1);

  @override
  bool shouldRepaint(_MiniWaveformPainter oldDelegate) {
    return waveform != oldDelegate.waveform;
  }
}
