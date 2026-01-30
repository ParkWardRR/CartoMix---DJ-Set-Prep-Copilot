import 'package:flutter/material.dart';
import '../../core/theme/theme.dart';
import '../widgets/set_builder/energy_arc.dart';

/// Set Builder screen for composing and optimizing DJ sets
class SetBuilderScreen extends StatelessWidget {
  const SetBuilderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Set list panel (2/3)
        Expanded(
          flex: 2,
          child: Column(
            children: [
              _buildToolbar(),
              const Divider(height: 1),
              Expanded(
                child: _buildSetList(),
              ),
            ],
          ),
        ),
        // Sidebar (1/3)
        const VerticalDivider(width: 1),
        SizedBox(
          width: 360,
          child: _buildSidebar(),
        ),
      ],
    );
  }

  Widget _buildToolbar() {
    return Container(
      padding: const EdgeInsets.all(CartoMixSpacing.md),
      color: CartoMixColors.bgSecondary,
      child: Row(
        children: [
          // Set mode selector
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'warmup', label: Text('Warm-up')),
              ButtonSegment(value: 'peak', label: Text('Peak Time')),
              ButtonSegment(value: 'open', label: Text('Open Format')),
            ],
            selected: const {'peak'},
            onSelectionChanged: (value) {},
            style: ButtonStyle(
              textStyle: WidgetStateProperty.all(CartoMixTypography.badge),
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
              '0 tracks',
              style: CartoMixTypography.badge.copyWith(
                color: CartoMixColors.primary,
              ),
            ),
          ),
          const Spacer(),
          // Actions
          OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.auto_awesome, size: 16),
            label: const Text('Optimize'),
          ),
          const SizedBox(width: CartoMixSpacing.sm),
          OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.clear_all, size: 16),
            label: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  Widget _buildSetList() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.queue_music_outlined,
            size: 64,
            color: CartoMixColors.textMuted,
          ),
          const SizedBox(height: CartoMixSpacing.md),
          Text(
            'No tracks in set',
            style: CartoMixTypography.headline.copyWith(
              color: CartoMixColors.textSecondary,
            ),
          ),
          const SizedBox(height: CartoMixSpacing.sm),
          Text(
            'Double-click tracks in the library to add them',
            style: CartoMixTypography.body.copyWith(
              color: CartoMixColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      color: CartoMixColors.bgSecondary,
      child: Column(
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
              child: const EnergyArc(
                energyValues: [4, 5, 6, 7, 8, 9, 10, 9, 7, 8, 6, 4], // Demo energy journey
                showGrid: true,
                showLabels: false,
              ),
            ),
          ),
          const Divider(height: 1),
          // Set Stats
          _buildSidebarSection(
            'Set Stats',
            _buildStatsGrid(),
          ),
          const Divider(height: 1),
          const Spacer(),
          // Export panel
          _buildExportPanel(),
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

  Widget _buildStatsGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      crossAxisSpacing: CartoMixSpacing.sm,
      mainAxisSpacing: CartoMixSpacing.sm,
      childAspectRatio: 2,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _buildStatItem('Avg BPM', '-'),
        _buildStatItem('BPM Range', '-'),
        _buildStatItem('Avg Energy', '-'),
        _buildStatItem('Keys Used', '-'),
      ],
    );
  }

  Widget _buildStatItem(String label, String value) {
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
            style: CartoMixTypography.headline,
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

  Widget _buildExportPanel() {
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
            onPressed: null, // Disabled when no tracks
            icon: const Icon(Icons.download, size: 16),
            label: const Text('Export Set'),
          ),
        ],
      ),
    );
  }
}
