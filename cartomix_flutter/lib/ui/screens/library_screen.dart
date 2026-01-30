import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/theme.dart';
import '../../models/models.dart';
import '../widgets/common/colored_badge.dart';
import '../widgets/library/track_card.dart';
import '../widgets/library/track_list_item.dart';
import '../widgets/waveform/waveform_view.dart';

/// View mode for track display
enum LibraryViewMode { list, grid }

/// Library screen showing all tracks with search and filtering
class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  String _searchQuery = '';
  String _sortBy = 'title';
  bool _showAnalyzedOnly = false;
  bool _showHighEnergyOnly = false;
  Track? _selectedTrack;
  LibraryViewMode _viewMode = LibraryViewMode.list; // Default to list like web UI

  // Generate realistic waveform data
  Float32List _generateWaveform(int seed, int length) {
    final waveform = Float32List(length);
    final random = seed * 1.618033988749895; // Golden ratio for variation
    for (var i = 0; i < length; i++) {
      final t = i / length;
      // Create a complex waveform pattern
      final base = 0.3 + 0.2 * _sin(t * 3.14159 * 4 + random);
      final detail = 0.15 * _sin(t * 3.14159 * 16 + random * 2);
      final peak = t > 0.3 && t < 0.7 ? 0.3 : 0.0; // Build section
      final intro = t < 0.15 ? t * 4 : 1.0; // Intro fade in
      final outro = t > 0.9 ? (1 - t) * 10 : 1.0; // Outro fade out
      waveform[i] = ((base + detail + peak) * intro * outro).clamp(0.1, 1.0);
    }
    return waveform;
  }

  double _sin(double x) => (x - x * x * x / 6 + x * x * x * x * x / 120).clamp(-1.0, 1.0);

  // Demo tracks for UI development
  late final List<Track> _demoTracks = List.generate(12, (i) {
    final waveform = _generateWaveform(i, 200);
    final duration = 180.0 + (i * 30);
    return Track(
      id: i + 1,
      contentHash: 'hash$i',
      path: '/Music/track_${i + 1}.mp3',
      title: [
        'Midnight Shadows',
        'Neon Dreams',
        'Electric Pulse',
        'Cosmic Journey',
        'Bass Cathedral',
        'Sunset Boulevard',
        'Night Protocol',
        'Digital Rain',
        'Underground Empire',
        'Peak Frequency',
        'Afterglow',
        'First Light'
      ][i],
      artist: [
        'KLØVER',
        'Midnight Protocol',
        'Circuit Breaker',
        'Astral Drift',
        'Subsonic',
        'Solar Winds',
        'NightShift',
        'DataStream',
        'Deep Current',
        'Zenith',
        'Twilight Collective',
        'Dawn Patrol'
      ][i],
      album: ['Echoes', 'Signals', 'Transmission', 'Horizons'][i % 4],
      fileSize: 10000000 + (i * 500000),
      fileModifiedAt: DateTime.now().subtract(Duration(days: i * 7)),
      createdAt: DateTime.now().subtract(Duration(days: i * 7)),
      updatedAt: DateTime.now(),
      analysis: i % 4 != 3
          ? TrackAnalysis(
              id: i + 1,
              trackId: i + 1,
              version: 1,
              status: AnalysisStatus.complete,
              durationSeconds: duration,
              bpm: [124, 126, 128, 130, 122, 125, 127, 132, 120, 128, 126, 124][i].toDouble(),
              bpmConfidence: 0.95,
              keyValue: ['8A', '9B', '10A', '11B', '12A', '1B', '2A', '3B', '4A', '5B', '6A', '7B'][i],
              keyFormat: 'camelot',
              keyConfidence: 0.9,
              energyGlobal: [5, 7, 9, 6, 8, 4, 7, 10, 6, 9, 5, 3][i],
              integratedLUFS: -14.0 + (i % 3),
              truePeakDB: -0.5,
              loudnessRange: 8.0,
              waveformPreview: waveform,
              sections: [
                TrackSection(
                  id: '${i}_intro',
                  type: SectionType.intro,
                  startTime: 0,
                  endTime: duration * 0.12,
                ),
                TrackSection(
                  id: '${i}_build1',
                  type: SectionType.build,
                  startTime: duration * 0.12,
                  endTime: duration * 0.25,
                ),
                TrackSection(
                  id: '${i}_drop1',
                  type: SectionType.drop,
                  startTime: duration * 0.25,
                  endTime: duration * 0.45,
                ),
                TrackSection(
                  id: '${i}_breakdown',
                  type: SectionType.breakdown,
                  startTime: duration * 0.45,
                  endTime: duration * 0.60,
                ),
                TrackSection(
                  id: '${i}_build2',
                  type: SectionType.build,
                  startTime: duration * 0.60,
                  endTime: duration * 0.70,
                ),
                TrackSection(
                  id: '${i}_drop2',
                  type: SectionType.drop,
                  startTime: duration * 0.70,
                  endTime: duration * 0.88,
                ),
                TrackSection(
                  id: '${i}_outro',
                  type: SectionType.outro,
                  startTime: duration * 0.88,
                  endTime: duration,
                ),
              ],
              cuePoints: [
                CuePoint(
                  index: 1,
                  type: CueType.intro,
                  timeSeconds: duration * 0.12,
                  label: 'Load',
                ),
                CuePoint(
                  index: 2,
                  type: CueType.drop,
                  timeSeconds: duration * 0.25,
                  label: 'Drop 1',
                ),
                CuePoint(
                  index: 3,
                  type: CueType.breakdown,
                  timeSeconds: duration * 0.45,
                  label: 'Break',
                ),
                CuePoint(
                  index: 4,
                  type: CueType.drop,
                  timeSeconds: duration * 0.70,
                  label: 'Drop 2',
                ),
              ],
              qaFlags: [],
              hasOpenL3Embedding: true,
              trainingLabels: [],
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            )
          : null,
    );
  });

  List<Track> get _filteredTracks {
    var tracks = _demoTracks.where((track) {
      // Search filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        if (!track.title.toLowerCase().contains(query) &&
            !track.artist.toLowerCase().contains(query)) {
          return false;
        }
      }
      // Analyzed filter
      if (_showAnalyzedOnly && !track.isAnalyzed) {
        return false;
      }
      // High energy filter
      if (_showHighEnergyOnly && (track.energy ?? 0) < 7) {
        return false;
      }
      return true;
    }).toList();

    // Sort
    switch (_sortBy) {
      case 'title':
        tracks.sort((a, b) => a.title.compareTo(b.title));
        break;
      case 'artist':
        tracks.sort((a, b) => a.artist.compareTo(b.artist));
        break;
      case 'bpm_asc':
        tracks.sort((a, b) => (a.bpm ?? 0).compareTo(b.bpm ?? 0));
        break;
      case 'bpm_desc':
        tracks.sort((a, b) => (b.bpm ?? 0).compareTo(a.bpm ?? 0));
        break;
      case 'energy_desc':
        tracks.sort((a, b) => (b.energy ?? 0).compareTo(a.energy ?? 0));
        break;
    }

    return tracks;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Main library panel
        Expanded(
          flex: 2,
          child: Column(
            children: [
              _buildToolbar(),
              const Divider(height: 1),
              Expanded(
                child: _buildTrackDisplay(),
              ),
            ],
          ),
        ),
        // Detail panel
        if (_selectedTrack != null) ...[
          const VerticalDivider(width: 1),
          SizedBox(
            width: 400,
            child: _buildDetailPanel(),
          ),
        ],
      ],
    );
  }

  Widget _buildToolbar() {
    return Container(
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
                    decoration: const InputDecoration(
                      hintText: 'Search tracks...',
                      prefixIcon: Icon(Icons.search, size: 18),
                      isDense: true,
                    ),
                    style: CartoMixTypography.bodySmall,
                    onChanged: (value) => setState(() => _searchQuery = value),
                  ),
                ),
                // Track count
                ColoredBadge(
                  label: '${_filteredTracks.length} tracks',
                  color: CartoMixColors.primary,
                ),
                // Filters
                _buildCheckbox('Analyzed', _showAnalyzedOnly, (v) {
                  setState(() => _showAnalyzedOnly = v ?? false);
                }),
                _buildCheckbox('High Energy', _showHighEnergyOnly, (v) {
                  setState(() => _showHighEnergyOnly = v ?? false);
                }),
                // Sort dropdown
                DropdownButton<String>(
                  value: _sortBy,
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
                    if (value != null) setState(() => _sortBy = value);
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
                      _buildViewModeButton(
                        icon: Icons.view_list,
                        mode: LibraryViewMode.list,
                        tooltip: 'List View',
                      ),
                      _buildViewModeButton(
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
          // Analyze all button (right side)
          ElevatedButton.icon(
            onPressed: () {},
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

  Widget _buildViewModeButton({
    required IconData icon,
    required LibraryViewMode mode,
    required String tooltip,
  }) {
    final isActive = _viewMode == mode;
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: () => setState(() => _viewMode = mode),
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

  Widget _buildTrackDisplay() {
    final tracks = _filteredTracks;

    if (tracks.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.library_music_outlined,
              size: 64,
              color: CartoMixColors.textMuted,
            ),
            const SizedBox(height: CartoMixSpacing.md),
            Text(
              'No tracks found',
              style: CartoMixTypography.headline.copyWith(
                color: CartoMixColors.textSecondary,
              ),
            ),
            const SizedBox(height: CartoMixSpacing.sm),
            Text(
              'Add music folders to get started',
              style: CartoMixTypography.body.copyWith(
                color: CartoMixColors.textMuted,
              ),
            ),
          ],
        ),
      );
    }

    // List view (default, matches web UI)
    if (_viewMode == LibraryViewMode.list) {
      return Column(
        children: [
          // Column headers
          _buildListHeader(),
          const Divider(height: 1),
          // Track list
          Expanded(
            child: ListView.builder(
              itemCount: tracks.length,
              itemBuilder: (context, index) {
                final track = tracks[index];
                return TrackListItem(
                  track: track,
                  isSelected: _selectedTrack?.id == track.id,
                  onTap: () => setState(() => _selectedTrack = track),
                  onDoubleTap: () {
                    // Add to set
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
      padding: const EdgeInsets.all(CartoMixSpacing.md),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 320,
        childAspectRatio: 2.2,
        crossAxisSpacing: CartoMixSpacing.md,
        mainAxisSpacing: CartoMixSpacing.md,
      ),
      itemCount: tracks.length,
      itemBuilder: (context, index) {
        final track = tracks[index];
        return TrackCard(
          track: track,
          isSelected: _selectedTrack?.id == track.id,
          onTap: () => setState(() => _selectedTrack = track),
          onDoubleTap: () {
            // Add to set
          },
        );
      },
    );
  }

  Widget _buildListHeader() {
    return Container(
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

  Widget _buildDetailPanel() {
    final track = _selectedTrack!;

    return Container(
      color: CartoMixColors.bgSecondary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(CartoMixSpacing.md),
            child: Row(
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
                  icon: const Icon(Icons.close),
                  iconSize: 18,
                  onPressed: () => setState(() => _selectedTrack = null),
                ),
              ],
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
              waveform: track.analysis?.waveformPreview ?? Float32List(0),
              sections: track.analysis?.sections ?? [],
              cuePoints: track.analysis?.cuePoints ?? [],
              durationSeconds: track.analysis?.durationSeconds ?? 0,
              currentTime: 0, // Will be connected to player state
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
                onPressed: () {},
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
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {},
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
