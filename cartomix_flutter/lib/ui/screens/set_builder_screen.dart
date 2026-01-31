import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/theme.dart';
import '../../core/providers/app_state.dart';
import '../../models/models.dart';
import '../widgets/set_builder/energy_arc.dart';
import '../widgets/set_builder/set_track_item.dart';
import '../widgets/set_builder/transition_indicator.dart';

/// Set Builder screen for composing and optimizing DJ sets
class SetBuilderScreen extends ConsumerWidget {
  const SetBuilderScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final setTracks = ref.watch(setTracksProvider);
    final selectedIndex = ref.watch(selectedSetTrackIndexProvider);

    return Row(
      key: const Key('setBuilder.screen'),
      children: [
        // Set list panel (2/3)
        Expanded(
          flex: 2,
          child: Column(
            children: [
              _SetBuilderToolbar(),
              const Divider(height: 1),
              Expanded(
                child: setTracks.isEmpty
                    ? _buildEmptyState(ref)
                    : _SetTrackList(
                        tracks: setTracks,
                        selectedIndex: selectedIndex,
                      ),
              ),
            ],
          ),
        ),
        // Sidebar (1/3)
        const VerticalDivider(width: 1),
        SizedBox(
          width: 360,
          child: _SetBuilderSidebar(),
        ),
      ],
    );
  }

  Widget _buildEmptyState(WidgetRef ref) {
    return Center(
      key: const Key('setBuilder.emptyState'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(CartoMixSpacing.lg),
            decoration: BoxDecoration(
              color: CartoMixColors.bgTertiary,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.queue_music_outlined,
              size: 64,
              color: CartoMixColors.textMuted,
            ),
          ),
          const SizedBox(height: CartoMixSpacing.lg),
          Text(
            'No tracks in set',
            style: CartoMixTypography.headline.copyWith(
              color: CartoMixColors.textSecondary,
            ),
          ),
          const SizedBox(height: CartoMixSpacing.sm),
          Text(
            'Double-click tracks in the library to add them\nor drag them here',
            style: CartoMixTypography.body.copyWith(
              color: CartoMixColors.textMuted,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: CartoMixSpacing.xl),
          // Demo button to add sample tracks
          OutlinedButton.icon(
            onPressed: () => _addDemoTracks(ref),
            icon: const Icon(Icons.science_outlined, size: 16),
            label: const Text('Add Demo Tracks'),
          ),
        ],
      ),
    );
  }

  void _addDemoTracks(WidgetRef ref) {
    // Add some demo tracks for testing
    final demoTracks = [
      _createDemoTrack(1, 'Summer Nights', 'DJ Sunset', 124.0, '8B', 6),
      _createDemoTrack(2, 'Electric Dreams', 'Neon Pulse', 126.0, '9B', 7),
      _createDemoTrack(3, 'Bass Drop', 'The Heavy', 128.0, '9A', 9),
      _createDemoTrack(4, 'Midnight Run', 'Dark Matter', 128.0, '10A', 10),
      _createDemoTrack(5, 'Chill Vibes', 'Smooth Operator', 122.0, '7B', 5),
      _createDemoTrack(6, 'Sunrise', 'Morning Glory', 120.0, '6B', 4),
    ];

    for (final track in demoTracks) {
      ref.read(setTracksProvider.notifier).addTrack(track);
    }
  }

  Track _createDemoTrack(int id, String title, String artist, double bpm, String key, int energy) {
    return Track(
      id: id,
      contentHash: 'demo_$id',
      path: '/demo/$title.mp3',
      title: title,
      artist: artist,
      album: '',
      fileSize: 10000000,
      fileModifiedAt: DateTime.now(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      analysis: TrackAnalysis(
        id: id,
        trackId: id,
        version: 1,
        status: AnalysisStatus.complete,
        durationSeconds: 240.0 + (id * 10),
        bpm: bpm,
        bpmConfidence: 0.95,
        keyValue: key,
        keyFormat: 'camelot',
        keyConfidence: 0.9,
        energyGlobal: energy,
        integratedLUFS: -8.0,
        truePeakDB: -0.5,
        loudnessRange: 8.0,
        waveformPreview: Float32List(0),
        sections: [],
        cuePoints: [],
        qaFlags: [],
        hasOpenL3Embedding: false,
        trainingLabels: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
  }
}

/// Toolbar with set mode selector and actions
class _SetBuilderToolbar extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final setMode = ref.watch(setModeProvider);
    final setTracks = ref.watch(setTracksProvider);
    final stats = ref.watch(setStatsProvider);

    return Container(
      key: const Key('setBuilder.toolbar'),
      padding: const EdgeInsets.all(CartoMixSpacing.md),
      color: CartoMixColors.bgSecondary,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Set mode selector
            SegmentedButton<SetMode>(
              segments: const [
                ButtonSegment(
                  value: SetMode.warmup,
                  label: Text('Warm-up'),
                  icon: Icon(Icons.wb_twilight, size: 16),
                ),
                ButtonSegment(
                  value: SetMode.peakTime,
                  label: Text('Peak'),
                  icon: Icon(Icons.flash_on, size: 16),
                ),
                ButtonSegment(
                  value: SetMode.openFormat,
                  label: Text('Open'),
                  icon: Icon(Icons.explore, size: 16),
                ),
              ],
              selected: {setMode},
              onSelectionChanged: (value) {
                ref.read(setModeProvider.notifier).state = value.first;
              },
              style: ButtonStyle(
                textStyle: WidgetStateProperty.all(CartoMixTypography.badge),
                visualDensity: VisualDensity.compact,
              ),
            ),
            const SizedBox(width: CartoMixSpacing.md),
            // Track count badge
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: CartoMixSpacing.sm,
                vertical: CartoMixSpacing.xxs,
              ),
              decoration: BoxDecoration(
                color: CartoMixColors.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(CartoMixSpacing.radiusPill),
              ),
              child: Text(
                '${setTracks.length} track${setTracks.length == 1 ? '' : 's'}',
                style: CartoMixTypography.badge.copyWith(
                  color: CartoMixColors.primary,
                ),
              ),
            ),
            if (stats['totalDuration'] != null && stats['totalDuration'] > 0) ...[
              const SizedBox(width: CartoMixSpacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: CartoMixSpacing.sm,
                  vertical: CartoMixSpacing.xxs,
                ),
                decoration: BoxDecoration(
                  color: CartoMixColors.accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(CartoMixSpacing.radiusPill),
                ),
                child: Text(
                  _formatDuration(stats['totalDuration'] as double),
                  style: CartoMixTypography.badge.copyWith(
                    color: CartoMixColors.accent,
                  ),
                ),
              ),
            ],
            const SizedBox(width: CartoMixSpacing.lg),
            // Actions
            OutlinedButton.icon(
              onPressed: setTracks.isNotEmpty
                  ? () => _showOptimizeDialog(context, ref)
                  : null,
              icon: const Icon(Icons.auto_awesome, size: 16),
              label: const Text('Optimize'),
            ),
            const SizedBox(width: CartoMixSpacing.sm),
            OutlinedButton.icon(
              onPressed: setTracks.isNotEmpty
                  ? () => ref.read(setTracksProvider.notifier).clearSet()
                  : null,
              icon: const Icon(Icons.clear_all, size: 16),
              label: const Text('Clear'),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(double seconds) {
    final hours = (seconds / 3600).floor();
    final minutes = ((seconds % 3600) / 60).floor();
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }

  void _showOptimizeDialog(BuildContext context, WidgetRef ref) {
    final setMode = ref.read(setModeProvider);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Optimize Set'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Optimize tracks for ${setMode.name} set?'),
            const SizedBox(height: CartoMixSpacing.md),
            Text(
              'This will reorder tracks to create smooth transitions based on BPM, key, and energy.',
              style: CartoMixTypography.caption.copyWith(
                color: CartoMixColors.textSecondary,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _optimizeSet(ref, setMode);
            },
            child: const Text('Optimize'),
          ),
        ],
      ),
    );
  }

  void _optimizeSet(WidgetRef ref, SetMode mode) {
    final tracks = [...ref.read(setTracksProvider)];

    switch (mode) {
      case SetMode.warmup:
        // Sort by energy ascending (start low, build up)
        tracks.sort((a, b) => (a.energy ?? 5).compareTo(b.energy ?? 5));
        break;
      case SetMode.peakTime:
        // Sort to create an energy arc: low -> high -> medium
        tracks.sort((a, b) {
          final aEnergy = a.energy ?? 5;
          final bEnergy = b.energy ?? 5;
          return aEnergy.compareTo(bEnergy);
        });
        // Rearrange for peak in middle
        if (tracks.length >= 4) {
          final sorted = [...tracks];
          final result = <Track>[];
          // Take from both ends alternating
          while (sorted.isNotEmpty) {
            result.add(sorted.removeAt(0));
            if (sorted.isNotEmpty) {
              result.add(sorted.removeLast());
            }
          }
          // Reverse second half to create peak
          final mid = result.length ~/ 2;
          tracks.clear();
          tracks.addAll(result.sublist(0, mid));
          tracks.addAll(result.sublist(mid).reversed);
        }
        break;
      case SetMode.openFormat:
        // Sort by BPM for smooth mixing, then by key compatibility
        tracks.sort((a, b) {
          final bpmA = a.bpm ?? 120;
          final bpmB = b.bpm ?? 120;
          return bpmA.compareTo(bpmB);
        });
        break;
    }

    ref.read(setTracksProvider.notifier).setTracks(tracks);
  }
}

/// Scrollable list of tracks with drag-and-drop reordering
class _SetTrackList extends ConsumerWidget {
  final List<Track> tracks;
  final int? selectedIndex;

  const _SetTrackList({
    required this.tracks,
    this.selectedIndex,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ReorderableListView.builder(
      key: const Key('setBuilder.trackList'),
      padding: const EdgeInsets.all(CartoMixSpacing.md),
      buildDefaultDragHandles: false,
      onReorder: (oldIndex, newIndex) {
        ref.read(setTracksProvider.notifier).reorderTracks(oldIndex, newIndex);
      },
      proxyDecorator: (child, index, animation) {
        return AnimatedBuilder(
          animation: animation,
          builder: (context, child) {
            final elevation = Tween<double>(begin: 0, end: 8).animate(animation);
            return Material(
              elevation: elevation.value,
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(CartoMixSpacing.radiusMd),
              child: child,
            );
          },
          child: child,
        );
      },
      itemCount: _calculateItemCount(),
      itemBuilder: (context, index) {
        // Even indices are tracks, odd indices are transitions
        if (index.isEven) {
          final trackIndex = index ~/ 2;
          final track = tracks[trackIndex];
          return KeyedSubtree(
            key: ValueKey('track_${track.id}'),
            child: SetTrackItem(
              track: track,
              position: trackIndex + 1,
              isSelected: selectedIndex == trackIndex,
              onTap: () {
                ref.read(selectedSetTrackIndexProvider.notifier).state =
                    selectedIndex == trackIndex ? null : trackIndex;
              },
              onRemove: () {
                ref.read(setTracksProvider.notifier).removeTrack(track.id);
                if (selectedIndex == trackIndex) {
                  ref.read(selectedSetTrackIndexProvider.notifier).state = null;
                }
              },
            ),
          );
        } else {
          // Transition indicator
          final fromIndex = index ~/ 2;
          final toIndex = fromIndex + 1;
          if (toIndex >= tracks.length) {
            return const SizedBox.shrink(key: ValueKey('empty_transition'));
          }
          return KeyedSubtree(
            key: ValueKey('transition_${fromIndex}_$toIndex'),
            child: TransitionIndicator(
              fromTrack: tracks[fromIndex],
              toTrack: tracks[toIndex],
            ),
          );
        }
      },
    );
  }

  int _calculateItemCount() {
    // Track count + transition count (n-1 transitions between n tracks)
    if (tracks.isEmpty) return 0;
    return tracks.length * 2 - 1;
  }
}

/// Sidebar with energy journey, stats, and export
class _SetBuilderSidebar extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final energyValues = ref.watch(setEnergyValuesProvider);
    final selectedIndex = ref.watch(selectedSetTrackIndexProvider);
    final stats = ref.watch(setStatsProvider);
    final setTracks = ref.watch(setTracksProvider);

    return Container(
      key: const Key('setBuilder.sidebar'),
      color: CartoMixColors.bgSecondary,
      child: Column(
        children: [
          // Scrollable content
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Energy Journey
                  _buildSidebarSection(
                    'Energy Journey',
                    Container(
                      height: 120,
                      decoration: BoxDecoration(
                        color: CartoMixColors.bgTertiary,
                        borderRadius: BorderRadius.circular(CartoMixSpacing.radiusMd),
                        border: Border.all(color: CartoMixColors.border),
                      ),
                      padding: const EdgeInsets.all(CartoMixSpacing.sm),
                      child: EnergyArc(
                        energyValues: energyValues,
                        highlightedIndex: selectedIndex,
                        showGrid: true,
                        showLabels: true,
                        onTrackTap: (index) {
                          ref.read(selectedSetTrackIndexProvider.notifier).state =
                              selectedIndex == index ? null : index;
                        },
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                  // Set Stats
                  _buildSidebarSection(
                    'Set Stats',
                    _buildStatsGrid(stats),
                  ),
                  const Divider(height: 1),
                  // Warnings section
                  if (setTracks.length >= 2)
                    _buildSidebarSection(
                      'Transition Warnings',
                      _buildWarnings(ref, setTracks),
                    ),
                ],
              ),
            ),
          ),
          // Export panel (fixed at bottom)
          _buildExportPanel(setTracks),
        ],
      ),
    );
  }

  Widget _buildSidebarSection(String title, Widget child) {
    return Padding(
      padding: const EdgeInsets.all(CartoMixSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: CartoMixTypography.badge.copyWith(
              color: CartoMixColors.textSecondary,
            ),
          ),
          const SizedBox(height: CartoMixSpacing.sm),
          child,
        ],
      ),
    );
  }

  Widget _buildStatsGrid(Map<String, dynamic> stats) {
    final avgBpm = stats['avgBpm'] as double?;
    final bpmRange = stats['bpmRange'] as String?;
    final avgEnergy = stats['avgEnergy'] as double?;
    final keysUsed = stats['keysUsed'] as Set<String>;

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      crossAxisSpacing: CartoMixSpacing.sm,
      mainAxisSpacing: CartoMixSpacing.sm,
      childAspectRatio: 2,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _buildStatItem(
          'Avg BPM',
          avgBpm != null ? avgBpm.toStringAsFixed(0) : '-',
          CartoMixColors.primary,
        ),
        _buildStatItem(
          'BPM Range',
          bpmRange ?? '-',
          CartoMixColors.textSecondary,
        ),
        _buildStatItem(
          'Avg Energy',
          avgEnergy != null ? avgEnergy.toStringAsFixed(1) : '-',
          avgEnergy != null
              ? CartoMixColors.colorForEnergy(avgEnergy.round())
              : CartoMixColors.textMuted,
        ),
        _buildStatItem(
          'Keys Used',
          keysUsed.isNotEmpty ? '${keysUsed.length}' : '-',
          CartoMixColors.accent,
        ),
      ],
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(CartoMixSpacing.sm),
      decoration: BoxDecoration(
        color: CartoMixColors.bgTertiary,
        borderRadius: BorderRadius.circular(CartoMixSpacing.radiusMd),
        border: Border.all(color: CartoMixColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: CartoMixTypography.headline.copyWith(color: color),
          ),
          Text(
            label,
            style: CartoMixTypography.badgeSmall.copyWith(
              color: CartoMixColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWarnings(WidgetRef ref, List<Track> tracks) {
    final warnings = <Widget>[];

    for (int i = 0; i < tracks.length - 1; i++) {
      final from = tracks[i];
      final to = tracks[i + 1];

      // Check BPM jump
      if (from.bpm != null && to.bpm != null) {
        final bpmDiff = (to.bpm! - from.bpm!).abs();
        if (bpmDiff > 8) {
          warnings.add(_buildWarningItem(
            Icons.speed,
            'Large BPM jump (${bpmDiff.toStringAsFixed(0)}) at track ${i + 2}',
            CartoMixColors.warning,
          ));
        }
      }

      // Check energy jump
      final fromEnergy = from.energy ?? 5;
      final toEnergy = to.energy ?? 5;
      final energyDiff = (toEnergy - fromEnergy).abs();
      if (energyDiff > 3) {
        warnings.add(_buildWarningItem(
          Icons.trending_up,
          'Large energy ${toEnergy > fromEnergy ? 'jump' : 'drop'} at track ${i + 2}',
          CartoMixColors.warning,
        ));
      }
    }

    if (warnings.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(CartoMixSpacing.sm),
        decoration: BoxDecoration(
          color: CartoMixColors.success.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(CartoMixSpacing.radiusMd),
          border: Border.all(color: CartoMixColors.success.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(Icons.check_circle, size: 16, color: CartoMixColors.success),
            const SizedBox(width: CartoMixSpacing.sm),
            Text(
              'All transitions look good!',
              style: CartoMixTypography.caption.copyWith(
                color: CartoMixColors.success,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: warnings.take(3).toList(),
    );
  }

  Widget _buildWarningItem(IconData icon, String message, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: CartoMixSpacing.xs),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: CartoMixSpacing.xs),
          Expanded(
            child: Text(
              message,
              style: CartoMixTypography.badgeSmall.copyWith(color: color),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExportPanel(List<Track> setTracks) {
    return Container(
      padding: const EdgeInsets.all(CartoMixSpacing.md),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: CartoMixColors.border),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Export',
            style: CartoMixTypography.badge.copyWith(
              color: CartoMixColors.textSecondary,
            ),
          ),
          const SizedBox(height: CartoMixSpacing.sm),
          DropdownButtonFormField<String>(
            value: 'rekordbox',
            decoration: const InputDecoration(
              isDense: true,
            ),
            items: const [
              DropdownMenuItem(value: 'rekordbox', child: Text('Rekordbox XML')),
              DropdownMenuItem(value: 'serato', child: Text('Serato Crate')),
              DropdownMenuItem(value: 'traktor', child: Text('Traktor NML')),
              DropdownMenuItem(value: 'json', child: Text('JSON')),
              DropdownMenuItem(value: 'm3u', child: Text('M3U Playlist')),
            ],
            onChanged: (value) {},
            style: CartoMixTypography.bodySmall,
          ),
          const SizedBox(height: CartoMixSpacing.sm),
          ElevatedButton.icon(
            onPressed: setTracks.isNotEmpty ? () {} : null,
            icon: const Icon(Icons.download, size: 16),
            label: const Text('Export Set'),
          ),
        ],
      ),
    );
  }
}
