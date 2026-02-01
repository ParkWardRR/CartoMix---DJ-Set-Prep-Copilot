import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/theme.dart';
import '../../core/providers/app_state.dart';
import '../../core/providers/player_state.dart';
import '../../models/models.dart';
import '../widgets/common/colored_badge.dart';
import '../widgets/library/track_card.dart';
import '../widgets/library/track_list_item.dart';
import '../widgets/waveform/waveform_view.dart';
import '../widgets/import/import_dialog.dart';
import '../widgets/common/empty_state.dart';

/// Library screen showing all tracks with search and filtering
class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedTrack = ref.watch(selectedTrackProvider);

    return Row(
      key: const Key('library.screen'),
      children: [
        // Main library panel
        Expanded(
          flex: 2,
          child: Column(
            children: [
              const _LibraryToolbar(),
              const Divider(height: 1),
              const Expanded(
                child: _TrackDisplay(),
              ),
            ],
          ),
        ),
        // Detail panel
        if (selectedTrack != null) ...[
          const VerticalDivider(width: 1),
          SizedBox(
            width: 400,
            child: _DetailPanel(track: selectedTrack),
          ),
        ],
      ],
    );
  }
}

/// Toolbar with search, filters, and view mode toggle
class _LibraryToolbar extends ConsumerWidget {
  const _LibraryToolbar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sortBy = ref.watch(sortModeProvider);
    final showAnalyzedOnly = ref.watch(showAnalyzedOnlyProvider);
    final showHighEnergyOnly = ref.watch(showHighEnergyOnlyProvider);
    final tracks = ref.watch(filteredTracksProvider);
    final tracksAsync = ref.watch(tracksProvider);

    return Container(
      key: const Key('library.toolbar'),
      padding: const EdgeInsets.all(CartoMixSpacing.md),
      color: CartoMixColors.bgSecondary,
      child: Row(
        children: [
          // Left side - filters and controls
          Expanded(
            child: Wrap(
              spacing: CartoMixSpacing.md,
              runSpacing: CartoMixSpacing.sm,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                // Search
                SizedBox(
                  width: 200,
                  child: TextField(
                    key: const Key('library.search'),
                    decoration: const InputDecoration(
                      hintText: 'Search tracks...',
                      prefixIcon: Icon(Icons.search, size: 18),
                      isDense: true,
                    ),
                    style: CartoMixTypography.bodySmall,
                    onChanged: (value) {
                      ref.read(searchQueryProvider.notifier).state = value;
                    },
                  ),
                ),
                // Track count
                ColoredBadge(
                  label: '${tracks.length} tracks',
                  color: CartoMixColors.primary,
                ),
                // Filters
                _buildCheckbox(
                  'Analyzed',
                  showAnalyzedOnly,
                  (v) => ref.read(showAnalyzedOnlyProvider.notifier).state = v ?? false,
                ),
                _buildCheckbox(
                  'High Energy',
                  showHighEnergyOnly,
                  (v) => ref.read(showHighEnergyOnlyProvider.notifier).state = v ?? false,
                ),
                // Sort dropdown
                DropdownButton<String>(
                  key: const Key('library.sort'),
                  value: sortBy,
                  underline: const SizedBox(),
                  isDense: true,
                  style: CartoMixTypography.caption,
                  items: const [
                    DropdownMenuItem(value: 'title', child: Text('Title')),
                    DropdownMenuItem(value: 'artist', child: Text('Artist')),
                    DropdownMenuItem(value: 'bpm_asc', child: Text('BPM ↑')),
                    DropdownMenuItem(value: 'bpm_desc', child: Text('BPM ↓')),
                    DropdownMenuItem(value: 'energy_desc', child: Text('Energy ↓')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      ref.read(sortModeProvider.notifier).state = value;
                    }
                  },
                ),
                // View mode toggle
                Container(
                  decoration: BoxDecoration(
                    color: CartoMixColors.bgTertiary,
                    borderRadius: BorderRadius.circular(CartoMixSpacing.radiusSm),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _ViewModeButton(
                        icon: Icons.view_list,
                        mode: LibraryViewMode.list,
                        tooltip: 'List View',
                      ),
                      _ViewModeButton(
                        icon: Icons.grid_view,
                        mode: LibraryViewMode.grid,
                        tooltip: 'Grid View',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: CartoMixSpacing.md),
          // Import button
          OutlinedButton.icon(
            key: const Key('library.import'),
            onPressed: () => showImportDialog(context),
            icon: const Icon(Icons.file_upload, size: 16),
            label: const Text('Import'),
          ),
          const SizedBox(width: CartoMixSpacing.sm),
          // Analyze all button (right side)
          ElevatedButton.icon(
            key: const Key('library.analyzeAll'),
            onPressed: tracksAsync.hasValue && tracksAsync.value!.isNotEmpty
                ? () {
                    // TODO: Implement analyze all
                  }
                : null,
            icon: const Icon(Icons.analytics, size: 16),
            label: const Text('Analyze All'),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckbox(String label, bool value, ValueChanged<bool?> onChanged) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 16,
          height: 16,
          child: Checkbox(
            value: value,
            onChanged: onChanged,
          ),
        ),
        const SizedBox(width: CartoMixSpacing.xs),
        Text(label, style: CartoMixTypography.caption),
      ],
    );
  }
}

/// View mode toggle button
class _ViewModeButton extends ConsumerWidget {
  final IconData icon;
  final LibraryViewMode mode;
  final String tooltip;

  const _ViewModeButton({
    required this.icon,
    required this.mode,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentMode = ref.watch(libraryViewModeProvider);
    final isActive = currentMode == mode;

    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: () => ref.read(libraryViewModeProvider.notifier).state = mode,
        borderRadius: BorderRadius.circular(CartoMixSpacing.radiusSm),
        child: Container(
          padding: const EdgeInsets.all(CartoMixSpacing.xs),
          decoration: BoxDecoration(
            color: isActive ? CartoMixColors.primary.withValues(alpha: 0.2) : Colors.transparent,
            borderRadius: BorderRadius.circular(CartoMixSpacing.radiusSm),
          ),
          child: Icon(
            icon,
            size: 18,
            color: isActive ? CartoMixColors.primary : CartoMixColors.textMuted,
          ),
        ),
      ),
    );
  }
}

/// Track display area (list or grid)
class _TrackDisplay extends ConsumerWidget {
  const _TrackDisplay();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tracksAsync = ref.watch(tracksProvider);
    final filteredTracks = ref.watch(filteredTracksProvider);
    final viewMode = ref.watch(libraryViewModeProvider);
    final libraryPaths = ref.watch(libraryPathsProvider);

    return tracksAsync.when(
      loading: () => const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: CartoMixSpacing.md),
            Text('Scanning library...'),
          ],
        ),
      ),
      error: (error, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: CartoMixColors.error,
            ),
            const SizedBox(height: CartoMixSpacing.md),
            Text(
              'Error loading library',
              style: CartoMixTypography.headline.copyWith(
                color: CartoMixColors.textSecondary,
              ),
            ),
            const SizedBox(height: CartoMixSpacing.sm),
            Text(
              error.toString(),
              style: CartoMixTypography.body.copyWith(
                color: CartoMixColors.textMuted,
              ),
            ),
          ],
        ),
      ),
      data: (allTracks) {
        // Empty state - no library paths configured
        if (libraryPaths.isEmpty) {
          return _buildEmptyState(
            context,
            ref,
            icon: Icons.folder_open_outlined,
            title: 'No Music Folders Added',
            subtitle: 'Add your music folders in Settings to get started',
            action: ElevatedButton.icon(
              key: const Key('library.openSettings'),
              onPressed: () {
                // Navigate to settings
                // This will be handled by the parent
              },
              icon: const Icon(Icons.settings, size: 16),
              label: const Text('Open Settings'),
            ),
          );
        }

        // Empty state - no tracks found
        if (allTracks.isEmpty) {
          return _buildEmptyState(
            context,
            ref,
            icon: Icons.music_off_outlined,
            title: 'No Tracks Found',
            subtitle: 'No audio files were found in your library folders',
            action: ElevatedButton.icon(
              key: const Key('library.rescan'),
              onPressed: () {
                ref.read(tracksProvider.notifier).rescan();
              },
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Rescan Library'),
            ),
          );
        }

        // Empty state - no tracks match filters
        if (filteredTracks.isEmpty) {
          return _buildEmptyState(
            context,
            ref,
            icon: Icons.search_off_outlined,
            title: 'No Matching Tracks',
            subtitle: 'Try adjusting your search or filters',
            action: TextButton(
              onPressed: () {
                ref.read(searchQueryProvider.notifier).state = '';
                ref.read(showAnalyzedOnlyProvider.notifier).state = false;
                ref.read(showHighEnergyOnlyProvider.notifier).state = false;
              },
              child: const Text('Clear Filters'),
            ),
          );
        }

        // List view (default)
        if (viewMode == LibraryViewMode.list) {
          return Column(
            children: [
              const _ListHeader(),
              const Divider(height: 1),
              Expanded(
                child: ListView.builder(
                  key: const Key('library.trackList'),
                  itemCount: filteredTracks.length,
                  itemBuilder: (context, index) {
                    final track = filteredTracks[index];
                    return TrackListItem(
                      key: Key('library.track.${track.id}'),
                      track: track,
                      isSelected: ref.watch(selectedTrackProvider)?.id == track.id,
                      onTap: () {
                        ref.read(selectedTrackProvider.notifier).state = track;
                      },
                      onDoubleTap: () {
                        ref.read(setTracksProvider.notifier).addTrack(track);
                      },
                    );
                  },
                ),
              ),
            ],
          );
        }

        // Grid view
        return GridView.builder(
          key: const Key('library.trackGrid'),
          padding: const EdgeInsets.all(CartoMixSpacing.md),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 320,
            childAspectRatio: 2.2,
            crossAxisSpacing: CartoMixSpacing.md,
            mainAxisSpacing: CartoMixSpacing.md,
          ),
          itemCount: filteredTracks.length,
          itemBuilder: (context, index) {
            final track = filteredTracks[index];
            return TrackCard(
              key: Key('library.card.${track.id}'),
              track: track,
              isSelected: ref.watch(selectedTrackProvider)?.id == track.id,
              onTap: () {
                ref.read(selectedTrackProvider.notifier).state = track;
              },
              onDoubleTap: () {
                ref.read(setTracksProvider.notifier).addTrack(track);
              },
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    WidgetRef ref, {
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? action,
  }) {
    // Enhanced empty state with v0.12.0 animations
    return Center(
      key: const Key('library.emptyState'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Animated icon container
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 600),
            curve: Curves.elasticOut,
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: child,
              );
            },
            child: Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: CartoMixColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(
                  color: CartoMixColors.primary.withValues(alpha: 0.3),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: CartoMixColors.primary.withValues(alpha: 0.2),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Icon(
                icon,
                size: 48,
                color: CartoMixColors.primary.withValues(alpha: 0.7),
              ),
            ),
          ),
          const SizedBox(height: CartoMixSpacing.xl),
          // Title with fade animation
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOut,
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, 10 * (1 - value)),
                  child: child,
                ),
              );
            },
            child: Text(
              title,
              style: CartoMixTypography.headline.copyWith(
                color: CartoMixColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: CartoMixSpacing.sm),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOut,
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: child,
              );
            },
            child: Text(
              subtitle,
              style: CartoMixTypography.body.copyWith(
                color: CartoMixColors.textMuted,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          if (action != null) ...[
            const SizedBox(height: CartoMixSpacing.xl),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOut,
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset(0, 20 * (1 - value)),
                    child: child,
                  ),
                );
              },
              child: action,
            ),
          ],
        ],
      ),
    );
  }
}

/// List view header with column labels
class _ListHeader extends StatelessWidget {
  const _ListHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('library.listHeader'),
      padding: const EdgeInsets.symmetric(
        horizontal: CartoMixSpacing.md,
        vertical: CartoMixSpacing.sm,
      ),
      color: CartoMixColors.bgTertiary,
      child: Row(
        children: [
          // Thumbnail space
          const SizedBox(width: 48),
          const SizedBox(width: CartoMixSpacing.md),
          // Title/Artist
          Expanded(
            flex: 3,
            child: Text(
              'TITLE / ARTIST',
              style: CartoMixTypography.badgeSmall.copyWith(
                color: CartoMixColors.textMuted,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(width: CartoMixSpacing.md),
          // Metadata columns
          SizedBox(
            width: 48,
            child: Text(
              'BPM',
              style: CartoMixTypography.badgeSmall.copyWith(
                color: CartoMixColors.textMuted,
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(
            width: 48,
            child: Text(
              'KEY',
              style: CartoMixTypography.badgeSmall.copyWith(
                color: CartoMixColors.textMuted,
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(
            width: 32,
            child: Text(
              'E',
              style: CartoMixTypography.badgeSmall.copyWith(
                color: CartoMixColors.textMuted,
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(
            width: 56,
            child: Text(
              'TIME',
              style: CartoMixTypography.badgeSmall.copyWith(
                color: CartoMixColors.textMuted,
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

/// Detail panel showing selected track info
class _DetailPanel extends ConsumerWidget {
  final Track track;

  const _DetailPanel({required this.track});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      key: const Key('library.detailPanel'),
      color: CartoMixColors.bgSecondary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(CartoMixSpacing.md),
            child: Consumer(
              builder: (context, ref, _) => Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          track.title,
                          style: CartoMixTypography.headline,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: CartoMixSpacing.xxs),
                        Text(
                          track.artist,
                          style: CartoMixTypography.body.copyWith(
                            color: CartoMixColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    key: const Key('library.closeDetail'),
                    icon: const Icon(Icons.close),
                    iconSize: 18,
                    onPressed: () {
                      ref.read(selectedTrackProvider.notifier).state = null;
                    },
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 1),
          // Waveform view
          Container(
            height: CartoMixSpacing.waveformHeightFull,
            margin: const EdgeInsets.all(CartoMixSpacing.md),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(CartoMixSpacing.radiusMd),
              border: Border.all(color: CartoMixColors.border),
            ),
            clipBehavior: Clip.antiAlias,
            child: WaveformView(
              key: const Key('library.waveform'),
              waveform: track.analysis?.waveformPreview ?? Float32List(0),
              sections: track.analysis?.sections ?? [],
              cuePoints: track.analysis?.cuePoints ?? [],
              durationSeconds: track.analysis?.durationSeconds ?? 0,
              currentTime: 0,
              bpm: track.bpm,
              showBeatGrid: true,
              showSections: true,
              showCues: true,
            ),
          ),
          // Analysis data
          if (track.isAnalyzed) ...[
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: CartoMixSpacing.md,
              ),
              child: _buildAnalysisSection(track),
            ),
          ] else ...[
            Padding(
              padding: const EdgeInsets.all(CartoMixSpacing.md),
              child: ElevatedButton.icon(
                key: const Key('library.analyzeTrack'),
                onPressed: () {
                  // TODO: Implement analyze single track
                },
                icon: const Icon(Icons.analytics, size: 16),
                label: const Text('Analyze Track'),
              ),
            ),
          ],
          const Spacer(),
          // Actions
          Padding(
            padding: const EdgeInsets.all(CartoMixSpacing.md),
            child: Row(
              children: [
                // Play button
                ElevatedButton.icon(
                  key: const Key('library.playTrack'),
                  onPressed: () {
                    ref.read(playerStateProvider.notifier).loadTrack(track);
                    ref.read(playerStateProvider.notifier).play();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: CartoMixColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.play_arrow, size: 16),
                  label: const Text('Play'),
                ),
                const SizedBox(width: CartoMixSpacing.sm),
                Expanded(
                  child: OutlinedButton.icon(
                    key: const Key('library.addToSet'),
                    onPressed: () {
                      ref.read(setTracksProvider.notifier).addTrack(track);
                    },
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Add to Set'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisSection(Track track) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // BPM / Key / Energy row
        Row(
          children: [
            _buildStatBox('BPM', track.bpmFormatted ?? '-', CartoMixColors.primary),
            const SizedBox(width: CartoMixSpacing.sm),
            _buildStatBox('Key', track.key ?? '-', track.keyColor),
            const SizedBox(width: CartoMixSpacing.sm),
            _buildStatBox('Energy', '${track.energy ?? '-'}', track.energyColor),
            const SizedBox(width: CartoMixSpacing.sm),
            _buildStatBox('Duration', track.durationFormatted ?? '-', CartoMixColors.accent),
          ],
        ),
      ],
    );
  }

  Widget _buildStatBox(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(CartoMixSpacing.sm),
        decoration: BoxDecoration(
          color: CartoMixColors.bgTertiary,
          borderRadius: BorderRadius.circular(CartoMixSpacing.radiusMd),
          border: Border.all(color: CartoMixColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: CartoMixTypography.badgeSmall.copyWith(
                color: CartoMixColors.textMuted,
              ),
            ),
            const SizedBox(height: CartoMixSpacing.xxs),
            Text(
              value,
              style: CartoMixTypography.headline.copyWith(
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
