import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/models.dart';

/// Player playback state
enum PlaybackState { stopped, playing, paused }

/// Current player state
class PlayerState {
  final Track? currentTrack;
  final PlaybackState playbackState;
  final double currentTime;
  final double duration;
  final double volume;
  final Float32List waveform;

  PlayerState({
    this.currentTrack,
    this.playbackState = PlaybackState.stopped,
    this.currentTime = 0,
    this.duration = 0,
    this.volume = 0.8,
    Float32List? waveform,
  }) : waveform = waveform ?? Float32List(0);

  /// Default state with no track loaded
  static final empty = PlayerState();

  PlayerState copyWith({
    Track? currentTrack,
    PlaybackState? playbackState,
    double? currentTime,
    double? duration,
    double? volume,
    Float32List? waveform,
  }) {
    return PlayerState(
      currentTrack: currentTrack ?? this.currentTrack,
      playbackState: playbackState ?? this.playbackState,
      currentTime: currentTime ?? this.currentTime,
      duration: duration ?? this.duration,
      volume: volume ?? this.volume,
      waveform: waveform ?? this.waveform,
    );
  }

  bool get isPlaying => playbackState == PlaybackState.playing;
  bool get isPaused => playbackState == PlaybackState.paused;
  bool get isStopped => playbackState == PlaybackState.stopped;
  bool get hasTrack => currentTrack != null;

  double get progress => duration > 0 ? currentTime / duration : 0;
}

/// Player state notifier
class PlayerStateNotifier extends StateNotifier<PlayerState> {
  PlayerStateNotifier() : super(PlayerState.empty);

  void loadTrack(Track track) {
    // Generate demo waveform for now (in real app, this comes from native)
    final waveform = _generateDemoWaveform();
    state = state.copyWith(
      currentTrack: track,
      playbackState: PlaybackState.paused,
      currentTime: 0,
      duration: track.durationSeconds ?? 180,
      waveform: waveform,
    );
  }

  void play() {
    if (state.hasTrack) {
      state = state.copyWith(playbackState: PlaybackState.playing);
      _startPlaybackSimulation();
    }
  }

  void pause() {
    state = state.copyWith(playbackState: PlaybackState.paused);
  }

  void togglePlayPause() {
    if (state.isPlaying) {
      pause();
    } else {
      play();
    }
  }

  void stop() {
    state = state.copyWith(
      playbackState: PlaybackState.stopped,
      currentTime: 0,
    );
  }

  void seek(double seconds) {
    final clampedTime = seconds.clamp(0.0, state.duration);
    state = state.copyWith(currentTime: clampedTime);
  }

  void seekToProgress(double progress) {
    seek(progress * state.duration);
  }

  void skipForward([double seconds = 10]) {
    seek(state.currentTime + seconds);
  }

  void skipBackward([double seconds = 10]) {
    seek(state.currentTime - seconds);
  }

  void setVolume(double volume) {
    state = state.copyWith(volume: volume.clamp(0.0, 1.0));
  }

  void updateTime(double currentTime) {
    state = state.copyWith(currentTime: currentTime);
  }

  void _startPlaybackSimulation() {
    // In a real app, this would be driven by the native audio engine
    // For demo purposes, we'll simulate playback progress
    Future.delayed(const Duration(milliseconds: 100), () {
      if (state.isPlaying && mounted) {
        final newTime = state.currentTime + 0.1;
        if (newTime >= state.duration) {
          state = state.copyWith(
            playbackState: PlaybackState.paused,
            currentTime: 0,
          );
        } else {
          state = state.copyWith(currentTime: newTime);
          _startPlaybackSimulation();
        }
      }
    });
  }

  Float32List _generateDemoWaveform() {
    final list = Float32List(200);
    for (var i = 0; i < list.length; i++) {
      final phase = i / list.length;
      // Generate a realistic-looking waveform pattern
      list[i] = 0.3 +
          0.4 * _sin(phase * 3.14159 * 4) +
          0.2 * _sin(phase * 3.14159 * 8) +
          0.1 * _sin(phase * 3.14159 * 16);
      list[i] = list[i].clamp(0.1, 1.0);
    }
    return list;
  }

  double _sin(double x) {
    // Simple sine approximation
    x = x % (2 * 3.14159);
    if (x < 0) x += 2 * 3.14159;
    if (x > 3.14159) {
      x -= 3.14159;
      return -_sinHelper(x);
    }
    return _sinHelper(x);
  }

  double _sinHelper(double x) {
    // Taylor series approximation for 0 to pi
    final x2 = x * x;
    return x * (1 - x2 / 6 * (1 - x2 / 20 * (1 - x2 / 42)));
  }
}

/// Global player state provider
final playerStateProvider = StateNotifierProvider<PlayerStateNotifier, PlayerState>((ref) {
  return PlayerStateNotifier();
});

/// Provider for whether mini player should be visible
final miniPlayerVisibleProvider = Provider<bool>((ref) {
  final playerState = ref.watch(playerStateProvider);
  return playerState.hasTrack;
});
