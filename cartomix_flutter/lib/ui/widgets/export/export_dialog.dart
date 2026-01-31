import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import '../../../core/theme/theme.dart';
import '../../../core/platform/native_bridge.dart';
import '../../../models/models.dart';

/// Export format options
enum ExportFormat {
  rekordbox('Rekordbox', 'xml', Icons.album),
  serato('Serato', 'crate', Icons.radio),
  traktor('Traktor', 'nml', Icons.headphones),
  json('JSON', 'json', Icons.data_object),
  m3u('M3U8', 'm3u8', Icons.playlist_play),
  csv('CSV', 'csv', Icons.table_chart);

  final String displayName;
  final String extension;
  final IconData icon;

  const ExportFormat(this.displayName, this.extension, this.icon);
}

/// Export dialog for exporting tracks to various DJ software formats
class ExportDialog extends ConsumerStatefulWidget {
  final List<Track> tracks;
  final String defaultPlaylistName;

  const ExportDialog({
    super.key,
    required this.tracks,
    this.defaultPlaylistName = 'CartoMix Set',
  });

  @override
  ConsumerState<ExportDialog> createState() => _ExportDialogState();
}

class _ExportDialogState extends ConsumerState<ExportDialog> {
  ExportFormat _selectedFormat = ExportFormat.rekordbox;
  final _playlistNameController = TextEditingController();
  bool _isExporting = false;
  String? _exportedPath;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _playlistNameController.text = widget.defaultPlaylistName;
  }

  @override
  void dispose() {
    _playlistNameController.dispose();
    super.dispose();
  }

  Future<void> _performExport() async {
    if (widget.tracks.isEmpty) {
      setState(() => _errorMessage = 'No tracks to export');
      return;
    }

    setState(() {
      _isExporting = true;
      _errorMessage = null;
      _exportedPath = null;
    });

    try {
      // Get desktop directory for export
      final directory = await getDownloadsDirectory() ?? Directory.systemTemp;
      final playlistName = _playlistNameController.text.trim().isEmpty
          ? 'CartoMix Set'
          : _playlistNameController.text.trim();

      final sanitizedName = playlistName.replaceAll(RegExp(r'[^\w\s-]'), '');
      final outputPath =
          '${directory.path}/$sanitizedName.${_selectedFormat.extension}';

      final trackIds = widget.tracks.map((t) => t.id).toList();
      String resultPath;

      switch (_selectedFormat) {
        case ExportFormat.rekordbox:
          resultPath = await NativeBridge.instance.exportRekordbox(
            trackIds: trackIds,
            playlistName: playlistName,
            outputPath: outputPath,
          );
          break;
        case ExportFormat.serato:
          resultPath = await NativeBridge.instance.exportSerato(
            trackIds: trackIds,
            playlistName: playlistName,
            outputPath: outputPath,
          );
          break;
        case ExportFormat.traktor:
          resultPath = await NativeBridge.instance.exportTraktor(
            trackIds: trackIds,
            playlistName: playlistName,
            outputPath: outputPath,
          );
          break;
        case ExportFormat.json:
          resultPath = await NativeBridge.instance.exportJSON(
            trackIds: trackIds,
            outputPath: outputPath,
          );
          break;
        case ExportFormat.m3u:
          resultPath = await NativeBridge.instance.exportM3U(
            trackIds: trackIds,
            outputPath: outputPath,
          );
          break;
        case ExportFormat.csv:
          resultPath = await NativeBridge.instance.exportCSV(
            trackIds: trackIds,
            outputPath: outputPath,
          );
          break;
      }

      setState(() {
        _exportedPath = resultPath;
        _isExporting = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isExporting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: CartoMixColors.bgSecondary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(CartoMixSpacing.radiusLg),
        side: const BorderSide(color: CartoMixColors.border),
      ),
      child: Container(
        width: 480,
        padding: const EdgeInsets.all(CartoMixSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: CartoMixColors.primary.withValues(alpha: 0.1),
                    borderRadius:
                        BorderRadius.circular(CartoMixSpacing.radiusMd),
                  ),
                  child: Icon(
                    Icons.file_download_outlined,
                    color: CartoMixColors.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: CartoMixSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Export Set',
                        style: CartoMixTypography.headline,
                      ),
                      Text(
                        '${widget.tracks.length} tracks',
                        style: CartoMixTypography.caption.copyWith(
                          color: CartoMixColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                  iconSize: 20,
                ),
              ],
            ),
            const SizedBox(height: CartoMixSpacing.xl),

            // Playlist name
            Text(
              'Playlist Name',
              style: CartoMixTypography.badge.copyWith(
                color: CartoMixColors.textSecondary,
              ),
            ),
            const SizedBox(height: CartoMixSpacing.sm),
            TextField(
              controller: _playlistNameController,
              decoration: InputDecoration(
                hintText: 'Enter playlist name...',
                prefixIcon: Icon(
                  Icons.edit,
                  size: 18,
                  color: CartoMixColors.textMuted,
                ),
              ),
            ),
            const SizedBox(height: CartoMixSpacing.lg),

            // Format selection
            Text(
              'Export Format',
              style: CartoMixTypography.badge.copyWith(
                color: CartoMixColors.textSecondary,
              ),
            ),
            const SizedBox(height: CartoMixSpacing.sm),
            Wrap(
              spacing: CartoMixSpacing.sm,
              runSpacing: CartoMixSpacing.sm,
              children: ExportFormat.values.map((format) {
                final isSelected = format == _selectedFormat;
                return InkWell(
                  onTap: () => setState(() => _selectedFormat = format),
                  borderRadius:
                      BorderRadius.circular(CartoMixSpacing.radiusMd),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: CartoMixSpacing.md,
                      vertical: CartoMixSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? CartoMixColors.primary.withValues(alpha: 0.1)
                          : CartoMixColors.bgTertiary,
                      borderRadius:
                          BorderRadius.circular(CartoMixSpacing.radiusMd),
                      border: Border.all(
                        color: isSelected
                            ? CartoMixColors.primary
                            : CartoMixColors.border,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          format.icon,
                          size: 16,
                          color: isSelected
                              ? CartoMixColors.primary
                              : CartoMixColors.textSecondary,
                        ),
                        const SizedBox(width: CartoMixSpacing.xs),
                        Text(
                          format.displayName,
                          style: CartoMixTypography.badge.copyWith(
                            color: isSelected
                                ? CartoMixColors.primary
                                : CartoMixColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: CartoMixSpacing.md),

            // Format description
            Container(
              padding: const EdgeInsets.all(CartoMixSpacing.md),
              decoration: BoxDecoration(
                color: CartoMixColors.bgTertiary,
                borderRadius: BorderRadius.circular(CartoMixSpacing.radiusMd),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: CartoMixColors.textMuted,
                  ),
                  const SizedBox(width: CartoMixSpacing.sm),
                  Expanded(
                    child: Text(
                      _getFormatDescription(_selectedFormat),
                      style: CartoMixTypography.caption.copyWith(
                        color: CartoMixColors.textMuted,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: CartoMixSpacing.lg),

            // Error message
            if (_errorMessage != null)
              Container(
                padding: const EdgeInsets.all(CartoMixSpacing.md),
                margin: const EdgeInsets.only(bottom: CartoMixSpacing.md),
                decoration: BoxDecoration(
                  color: CartoMixColors.error.withValues(alpha: 0.1),
                  borderRadius:
                      BorderRadius.circular(CartoMixSpacing.radiusMd),
                  border: Border.all(color: CartoMixColors.error),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 16,
                      color: CartoMixColors.error,
                    ),
                    const SizedBox(width: CartoMixSpacing.sm),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: CartoMixTypography.caption.copyWith(
                          color: CartoMixColors.error,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Success message
            if (_exportedPath != null)
              Container(
                padding: const EdgeInsets.all(CartoMixSpacing.md),
                margin: const EdgeInsets.only(bottom: CartoMixSpacing.md),
                decoration: BoxDecoration(
                  color: CartoMixColors.success.withValues(alpha: 0.1),
                  borderRadius:
                      BorderRadius.circular(CartoMixSpacing.radiusMd),
                  border: Border.all(color: CartoMixColors.success),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          size: 16,
                          color: CartoMixColors.success,
                        ),
                        const SizedBox(width: CartoMixSpacing.sm),
                        Text(
                          'Export successful!',
                          style: CartoMixTypography.badge.copyWith(
                            color: CartoMixColors.success,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: CartoMixSpacing.xs),
                    Text(
                      _exportedPath!,
                      style: CartoMixTypography.caption.copyWith(
                        color: CartoMixColors.textMuted,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'Cancel',
                    style: CartoMixTypography.badge.copyWith(
                      color: CartoMixColors.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(width: CartoMixSpacing.md),
                ElevatedButton(
                  onPressed:
                      _isExporting || _exportedPath != null ? null : _performExport,
                  child: _isExporting
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.file_download, size: 16),
                            const SizedBox(width: CartoMixSpacing.xs),
                            Text(_exportedPath != null ? 'Done' : 'Export'),
                          ],
                        ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getFormatDescription(ExportFormat format) {
    switch (format) {
      case ExportFormat.rekordbox:
        return 'Pioneer Rekordbox XML format. Includes cue points, BPM, key, and metadata.';
      case ExportFormat.serato:
        return 'Serato DJ crate format. Binary format with track paths and cue markers.';
      case ExportFormat.traktor:
        return 'Native Instruments Traktor NML format. Includes full track metadata and cue points.';
      case ExportFormat.json:
        return 'JSON format with all track metadata and analysis data. Great for backup or custom integrations.';
      case ExportFormat.m3u:
        return 'Standard M3U8 playlist format. Compatible with most media players.';
      case ExportFormat.csv:
        return 'CSV spreadsheet format. Easy to open in Excel or Google Sheets for analysis.';
    }
  }
}

/// Show the export dialog
Future<void> showExportDialog(
  BuildContext context,
  List<Track> tracks, {
  String defaultPlaylistName = 'CartoMix Set',
}) {
  return showDialog(
    context: context,
    builder: (context) => ExportDialog(
      tracks: tracks,
      defaultPlaylistName: defaultPlaylistName,
    ),
  );
}
