import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/theme.dart';
import '../../../core/providers/player_state.dart';
import '../../../models/models.dart';
import '../waveform/waveform_view.dart';

/// Mini player bar for persistent audio playback
/// Shows current track info, waveform preview, and playback controls
class MiniPlayer extends ConsumerWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(playerStateProvider);
    final player = ref.read(playerStateProvider.notifier);

    if (!playerState.hasTrack) {
      return const SizedBox.shrink();
    }

    final track = playerState.currentTrack!;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 60 * (1 - value)),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: Container(
        key: const Key('miniPlayer'),
        height: 60,
        decoration: BoxDecoration(
          color: CartoMixColors.bgElevated,
          border: Border(
            top: BorderSide(color: CartoMixColors.border),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Album art placeholder / Now playing indicator
            _buildNowPlayingIndicator(playerState),

            // Track info
            Expanded(
              flex: 2,
              child: _buildTrackInfo(track, playerState),
            ),

            // Waveform preview
            Expanded(
              flex: 3,
              child: _buildWaveformPreview(playerState, player),
            ),

            // Time display
            _buildTimeDisplay(playerState),

            // Playback controls
            _buildPlaybackControls(playerState, player),

            // Volume control
            _buildVolumeControl(playerState, player),

            const SizedBox(width: CartoMixSpacing.md),
          ],
        ),
      ),
    );
  }

  Widget _buildNowPlayingIndicator(PlayerState playerState) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: CartoMixColors.bgTertiary,
        border: Border(
          right: BorderSide(color: CartoMixColors.border),
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Album art placeholder with gradient
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(CartoMixSpacing.radiusSm),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  CartoMixColors.primary.withValues(alpha: 0.3),
                  CartoMixColors.accent.withValues(alpha: 0.3),
                ],
              ),
            ),
            child: Icon(
              Icons.music_note,
              color: CartoMixColors.primary,
              size: 24,
            ),
          ),
          // Playing indicator animation
          if (playerState.isPlaying)
            Positioned(
              bottom: 4,
              right: 4,
              child: _PlayingIndicator(),
            ),
        ],
      ),
    );
  }

  Widget _buildTrackInfo(Track track, PlayerState playerState) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: CartoMixSpacing.md),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            track.title,
            style: CartoMixTypography.body.copyWith(
              color: CartoMixColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              Flexible(
                child: Text(
                  track.artist,
                  style: CartoMixTypography.caption.copyWith(
                    color: CartoMixColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (track.bpm != null) ...[
                const SizedBox(width: CartoMixSpacing.sm),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: CartoMixSpacing.xs,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: CartoMixColors.bgTertiary,
                    borderRadius: BorderRadius.circular(CartoMixSpacing.radiusSm),
                  ),
                  child: Text(
                    '${track.bpm!.round()} BPM',
                    style: CartoMixTypography.badgeSmall.copyWith(
                      color: CartoMixColors.textMuted,
                    ),
                  ),
                ),
              ],
              if (track.key != null) ...[
                const SizedBox(width: CartoMixSpacing.xs),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: CartoMixSpacing.xs,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: CartoMixColors.bgTertiary,
                    borderRadius: BorderRadius.circular(CartoMixSpacing.radiusSm),
                  ),
                  child: Text(
                    track.key!,
                    style: CartoMixTypography.badgeSmall.copyWith(
                      color: CartoMixColors.textMuted,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWaveformPreview(PlayerState playerState, PlayerStateNotifier player) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: CartoMixSpacing.md,
        vertical: CartoMixSpacing.sm,
      ),
      child: GestureDetector(
        onTapDown: (details) {
          // Seek to position
        },
        onHorizontalDragUpdate: (details) {
          // Scrub through waveform
        },
        child: LayoutBuilder(
          builder: (context, constraints) {
            return GestureDetector(
              onTapDown: (details) {
                final progress = details.localPosition.dx / constraints.maxWidth;
                player.seekToProgress(progress.clamp(0.0, 1.0));
              },
              onHorizontalDragUpdate: (details) {
                final progress = details.localPosition.dx / constraints.maxWidth;
                player.seekToProgress(progress.clamp(0.0, 1.0));
              },
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: CompactWaveformPreview(
                  waveform: playerState.waveform,
                  playPosition: playerState.progress,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTimeDisplay(PlayerState playerState) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: CartoMixSpacing.sm),
      child: Text(
        '${_formatTime(playerState.currentTime)} / ${_formatTime(playerState.duration)}',
        style: CartoMixTypography.badge.copyWith(
          color: CartoMixColors.textMuted,
          fontFeatures: [const FontFeature.tabularFigures()],
        ),
      ),
    );
  }

  Widget _buildPlaybackControls(PlayerState playerState, PlayerStateNotifier player) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Skip back
        _ControlButton(
          icon: Icons.replay_10,
          onPressed: () => player.skipBackward(10),
          tooltip: 'Skip back 10s',
        ),

        // Play/Pause
        _PlayPauseButton(
          isPlaying: playerState.isPlaying,
          onPressed: player.togglePlayPause,
        ),

        // Skip forward
        _ControlButton(
          icon: Icons.forward_10,
          onPressed: () => player.skipForward(10),
          tooltip: 'Skip forward 10s',
        ),
      ],
    );
  }

  Widget _buildVolumeControl(PlayerState playerState, PlayerStateNotifier player) {
    return SizedBox(
      width: 100,
      child: Row(
        children: [
          Icon(
            playerState.volume > 0 ? Icons.volume_up : Icons.volume_off,
            size: 16,
            color: CartoMixColors.textMuted,
          ),
          const SizedBox(width: CartoMixSpacing.xs),
          Expanded(
            child: SliderTheme(
              data: SliderThemeData(
                trackHeight: 3,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
                activeTrackColor: CartoMixColors.primary,
                inactiveTrackColor: CartoMixColors.bgTertiary,
                thumbColor: CartoMixColors.primary,
                overlayColor: CartoMixColors.primary.withValues(alpha: 0.2),
              ),
              child: Slider(
                value: playerState.volume,
                onChanged: player.setVolume,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(double seconds) {
    final mins = (seconds / 60).floor();
    final secs = (seconds % 60).floor();
    return '${mins}:${secs.toString().padLeft(2, '0')}';
  }
}

/// Play/Pause button with animation
class _PlayPauseButton extends StatelessWidget {
  final bool isPlaying;
  final VoidCallback onPressed;

  const _PlayPauseButton({
    required this.isPlaying,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: CartoMixColors.primary,
            boxShadow: [
              BoxShadow(
                color: CartoMixColors.primary.withValues(alpha: 0.3),
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ],
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 150),
            child: Icon(
              isPlaying ? Icons.pause : Icons.play_arrow,
              key: ValueKey(isPlaying),
              color: Colors.white,
              size: 24,
            ),
          ),
        ),
      ),
    );
  }
}

/// Control button for skip/volume
class _ControlButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final String tooltip;

  const _ControlButton({
    required this.icon,
    required this.onPressed,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(
              icon,
              size: 20,
              color: CartoMixColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

/// Animated playing indicator bars
class _PlayingIndicator extends StatefulWidget {
  @override
  State<_PlayingIndicator> createState() => _PlayingIndicatorState();
}

class _PlayingIndicatorState extends State<_PlayingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: 16,
          height: 12,
          decoration: BoxDecoration(
            color: CartoMixColors.bgElevated,
            borderRadius: BorderRadius.circular(2),
          ),
          padding: const EdgeInsets.all(2),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(3, (i) {
              final phase = (_controller.value + i * 0.3) % 1.0;
              final height = 4 + 4 * _sin(phase * 3.14159);
              return Container(
                width: 3,
                height: height,
                decoration: BoxDecoration(
                  color: CartoMixColors.primary,
                  borderRadius: BorderRadius.circular(1),
                ),
              );
            }),
          ),
        );
      },
    );
  }

  double _sin(double x) {
    x = x % (2 * 3.14159);
    if (x > 3.14159) return -_sinH(x - 3.14159);
    return _sinH(x);
  }

  double _sinH(double x) {
    final x2 = x * x;
    return x * (1 - x2 / 6 * (1 - x2 / 20));
  }
}
