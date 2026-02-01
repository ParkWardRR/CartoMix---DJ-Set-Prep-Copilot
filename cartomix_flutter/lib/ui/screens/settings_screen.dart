import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_info.dart';
import '../../core/providers/update_state.dart';
import '../../core/theme/theme.dart';

/// Settings screen for app configuration
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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

              // Updates
              _buildSection(
                'Updates',
                'Signed Sparkle auto-updates with background checks',
                _buildUpdateSection(context, ref),
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
        _buildInfoRow(
            'Database location', '~/Library/Application Support/CartoMix/'),
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

  Widget _buildUpdateSection(BuildContext context, WidgetRef ref) {
    final update = ref.watch(updateProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(CartoMixSpacing.sm),
              decoration: BoxDecoration(
                color: CartoMixColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(CartoMixSpacing.radiusMd),
              ),
              child: const Icon(Icons.system_update_alt,
                  color: CartoMixColors.primary),
            ),
            const SizedBox(width: CartoMixSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sparkle auto-updates',
                    style: CartoMixTypography.body,
                  ),
                  const SizedBox(height: CartoMixSpacing.xxs),
                  Text(
                    update.formattedLastCheck(),
                    style: CartoMixTypography.caption.copyWith(
                      color: CartoMixColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: CartoMixSpacing.sm,
                vertical: CartoMixSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: update.isChecking
                    ? CartoMixColors.warning.withValues(alpha: 0.18)
                    : CartoMixColors.success.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(CartoMixSpacing.radiusSm),
                border: Border.all(
                  color: update.isChecking
                      ? CartoMixColors.warning
                      : CartoMixColors.success,
                ),
              ),
              child: Text(
                update.isChecking ? 'Checking…' : 'Auto',
                style: CartoMixTypography.caption.copyWith(
                  color: update.isChecking
                      ? CartoMixColors.warning
                      : CartoMixColors.success,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: CartoMixSpacing.md),
        Row(
          children: [
            ElevatedButton.icon(
              onPressed: update.isChecking
                  ? null
                  : () async {
                      await ref.read(updateProvider.notifier).checkForUpdates();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Checking for updates… Sparkle will show a window if an update is available.',
                            ),
                          ),
                        );
                      }
                    },
              icon: const Icon(Icons.refresh),
              label: const Text('Check for Updates'),
            ),
            const SizedBox(width: CartoMixSpacing.sm),
            OutlinedButton.icon(
              onPressed: update.isChecking
                  ? null
                  : () => ref.read(updateProvider.notifier).refreshLastCheck(),
              icon: const Icon(Icons.history),
              label: const Text('Refresh status'),
            ),
          ],
        ),
        const SizedBox(height: CartoMixSpacing.sm),
        Text(
          update.statusMessage,
          style: CartoMixTypography.caption.copyWith(
            color: CartoMixColors.textMuted,
          ),
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
                  'Version ${AppInfo.version} (Codename: ${AppInfo.codename})',
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
