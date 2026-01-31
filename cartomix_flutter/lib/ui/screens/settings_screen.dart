import 'package:flutter/material.dart';
import '../../core/theme/theme.dart';

/// Settings screen for app configuration
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(CartoMixSpacing.xl),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                'Settings',
                style: CartoMixTypography.title,
              ),
              const SizedBox(height: CartoMixSpacing.xxl),

              // Music Locations
              _buildSection(
                'Music Locations',
                'Folders where CartoMix will scan for audio files',
                _buildMusicLocations(),
              ),

              const SizedBox(height: CartoMixSpacing.xxl),

              // Analysis Settings
              _buildSection(
                'Analysis',
                'Configure audio analysis behavior',
                _buildAnalysisSettings(),
              ),

              const SizedBox(height: CartoMixSpacing.xxl),

              // Export Settings
              _buildSection(
                'Export',
                'Default export settings',
                _buildExportSettings(),
              ),

              const SizedBox(height: CartoMixSpacing.xxl),

              // Storage
              _buildSection(
                'Storage',
                'Database and cache information',
                _buildStorageInfo(),
              ),

              const SizedBox(height: CartoMixSpacing.xxl),

              // About
              _buildSection(
                'About',
                null,
                _buildAboutSection(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, String? description, Widget content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: CartoMixTypography.headline,
        ),
        if (description != null) ...[
          const SizedBox(height: CartoMixSpacing.xs),
          Text(
            description,
            style: CartoMixTypography.caption.copyWith(
              color: CartoMixColors.textMuted,
            ),
          ),
        ],
        const SizedBox(height: CartoMixSpacing.md),
        Container(
          padding: const EdgeInsets.all(CartoMixSpacing.md),
          decoration: BoxDecoration(
            color: CartoMixColors.bgSecondary,
            borderRadius: BorderRadius.circular(CartoMixSpacing.radiusLg),
            border: Border.all(color: CartoMixColors.border),
          ),
          child: content,
        ),
      ],
    );
  }

  Widget _buildMusicLocations() {
    return Column(
      children: [
        // Placeholder for location list
        Container(
          padding: const EdgeInsets.all(CartoMixSpacing.md),
          decoration: BoxDecoration(
            color: CartoMixColors.bgTertiary,
            borderRadius: BorderRadius.circular(CartoMixSpacing.radiusMd),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.folder,
                size: 20,
                color: CartoMixColors.primary,
              ),
              const SizedBox(width: CartoMixSpacing.sm),
              Expanded(
                child: Text(
                  'No music folders added',
                  style: CartoMixTypography.body.copyWith(
                    color: CartoMixColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: CartoMixSpacing.md),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Add Music Folder'),
          ),
        ),
      ],
    );
  }

  Widget _buildAnalysisSettings() {
    return Column(
      children: [
        _buildSettingRow(
          'Auto-analyze new tracks',
          'Automatically analyze tracks when added to library',
          Switch(
            value: true,
            onChanged: (value) {},
          ),
        ),
        const Divider(height: CartoMixSpacing.lg),
        _buildSettingRow(
          'Generate embeddings',
          'Create ML embeddings for similarity matching',
          Switch(
            value: true,
            onChanged: (value) {},
          ),
        ),
        const Divider(height: CartoMixSpacing.lg),
        _buildSettingRow(
          'Detect sections',
          'Identify song structure (intro, drop, breakdown, etc.)',
          Switch(
            value: true,
            onChanged: (value) {},
          ),
        ),
      ],
    );
  }

  Widget _buildExportSettings() {
    return Column(
      children: [
        _buildSettingRow(
          'Default format',
          'Format used when exporting sets',
          DropdownButton<String>(
            value: 'rekordbox',
            underline: const SizedBox(),
            isDense: true,
            items: const [
              DropdownMenuItem(value: 'rekordbox', child: Text('Rekordbox')),
              DropdownMenuItem(value: 'serato', child: Text('Serato')),
              DropdownMenuItem(value: 'traktor', child: Text('Traktor')),
            ],
            onChanged: (value) {},
          ),
        ),
        const Divider(height: CartoMixSpacing.lg),
        _buildSettingRow(
          'Include cue points',
          'Export cue markers with tracks',
          Switch(
            value: true,
            onChanged: (value) {},
          ),
        ),
      ],
    );
  }

  Widget _buildStorageInfo() {
    return Column(
      children: [
        _buildInfoRow('Database location', '~/Library/Application Support/CartoMix/'),
        const Divider(height: CartoMixSpacing.lg),
        _buildInfoRow('Database size', '-- MB'),
        const Divider(height: CartoMixSpacing.lg),
        _buildInfoRow('Tracks', '0'),
        const Divider(height: CartoMixSpacing.lg),
        _buildInfoRow('Analyzed', '0'),
        const SizedBox(height: CartoMixSpacing.md),
        Row(
          children: [
            OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.cleaning_services, size: 16),
              label: const Text('Clear Cache'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAboutSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: CartoMixGradients.waveform,
                borderRadius: BorderRadius.circular(CartoMixSpacing.radiusMd),
              ),
              child: const Icon(
                Icons.music_note,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: CartoMixSpacing.md),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CartoMix',
                  style: CartoMixTypography.headline,
                ),
                Text(
                  'Version 0.7.0 (Codename: Cairo)',
                  style: CartoMixTypography.caption.copyWith(
                    color: CartoMixColors.textMuted,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: CartoMixSpacing.md),
        Text(
          'DJ Set Prep Copilot',
          style: CartoMixTypography.body.copyWith(
            color: CartoMixColors.textSecondary,
          ),
        ),
        const SizedBox(height: CartoMixSpacing.sm),
        Text(
          '100% offline • Neural Engine accelerated • Privacy-first',
          style: CartoMixTypography.caption.copyWith(
            color: CartoMixColors.textMuted,
          ),
        ),
      ],
    );
  }

  Widget _buildSettingRow(String title, String description, Widget control) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: CartoMixTypography.body,
              ),
              const SizedBox(height: CartoMixSpacing.xxs),
              Text(
                description,
                style: CartoMixTypography.caption.copyWith(
                  color: CartoMixColors.textMuted,
                ),
              ),
            ],
          ),
        ),
        control,
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          flex: 1,
          child: Text(
            label,
            style: CartoMixTypography.body.copyWith(
              color: CartoMixColors.textSecondary,
            ),
          ),
        ),
        const SizedBox(width: CartoMixSpacing.md),
        Flexible(
          flex: 2,
          child: Text(
            value,
            style: CartoMixTypography.monoSmall.copyWith(
              color: CartoMixColors.textPrimary,
            ),
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
