import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/theme.dart';
import '../../../core/platform/native_bridge.dart';

/// Import format options
enum ImportFormat {
  rekordbox('Rekordbox', 'xml', Icons.album),
  serato('Serato', 'crate', Icons.radio),
  traktor('Traktor', 'nml', Icons.headphones),
  m3u('M3U/M3U8', 'm3u8', Icons.playlist_play);

  final String displayName;
  final String extension;
  final IconData icon;

  const ImportFormat(this.displayName, this.extension, this.icon);
}

/// Import dialog for importing tracks from various DJ software formats
class ImportDialog extends ConsumerStatefulWidget {
  const ImportDialog({super.key});

  @override
  ConsumerState<ImportDialog> createState() => _ImportDialogState();
}

class _ImportDialogState extends ConsumerState<ImportDialog> {
  ImportFormat _selectedFormat = ImportFormat.rekordbox;
  String? _selectedFilePath;
  bool _isImporting = false;
  bool _isAddingToLibrary = false;
  ImportResult? _importResult;
  String? _errorMessage;
  int _addedCount = 0;

  Future<void> _selectFile() async {
    // Use file picker to select file based on format
    final extensions = <String>[];
    switch (_selectedFormat) {
      case ImportFormat.rekordbox:
        extensions.add('xml');
        break;
      case ImportFormat.serato:
        extensions.add('crate');
        break;
      case ImportFormat.traktor:
        extensions.add('nml');
        break;
      case ImportFormat.m3u:
        extensions.addAll(['m3u', 'm3u8']);
        break;
    }

    // For now, we'll use a text field to input the path
    // In a full implementation, this would use a native file picker
    final path = await _showPathInputDialog();
    if (path != null && path.isNotEmpty) {
      setState(() {
        _selectedFilePath = path;
        _errorMessage = null;
        _importResult = null;
      });
    }
  }

  Future<String?> _showPathInputDialog() async {
    final controller = TextEditingController(text: _selectedFilePath ?? '');
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: CartoMixColors.bgSecondary,
        title: Text(
          'Enter File Path',
          style: CartoMixTypography.headline,
        ),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: '/path/to/file.${_selectedFormat.extension}',
            prefixIcon: Icon(Icons.folder_open, size: 18),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: Text('Select'),
          ),
        ],
      ),
    );
  }

  Future<void> _performImport() async {
    if (_selectedFilePath == null || _selectedFilePath!.isEmpty) {
      setState(() => _errorMessage = 'Please select a file first');
      return;
    }

    // Verify file exists
    if (!File(_selectedFilePath!).existsSync()) {
      setState(() => _errorMessage = 'File not found: $_selectedFilePath');
      return;
    }

    setState(() {
      _isImporting = true;
      _errorMessage = null;
      _importResult = null;
    });

    try {
      ImportResult result;
      switch (_selectedFormat) {
        case ImportFormat.rekordbox:
          result = await NativeBridge.instance
              .importRekordbox(filePath: _selectedFilePath!);
          break;
        case ImportFormat.serato:
          result = await NativeBridge.instance
              .importSerato(filePath: _selectedFilePath!);
          break;
        case ImportFormat.traktor:
          result = await NativeBridge.instance
              .importTraktor(filePath: _selectedFilePath!);
          break;
        case ImportFormat.m3u:
          result = await NativeBridge.instance
              .importM3U(filePath: _selectedFilePath!);
          break;
      }

      setState(() {
        _importResult = result;
        _isImporting = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isImporting = false;
      });
    }
  }

  Future<void> _addToLibrary() async {
    if (_importResult == null || _importResult!.tracks.isEmpty) return;

    setState(() {
      _isAddingToLibrary = true;
      _errorMessage = null;
    });

    try {
      final count =
          await NativeBridge.instance.addImportedTracks(_importResult!.tracks);
      setState(() {
        _addedCount = count;
        _isAddingToLibrary = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isAddingToLibrary = false;
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
        width: 520,
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
                    color: CartoMixColors.accent.withValues(alpha: 0.1),
                    borderRadius:
                        BorderRadius.circular(CartoMixSpacing.radiusMd),
                  ),
                  child: Icon(
                    Icons.file_upload_outlined,
                    color: CartoMixColors.accent,
                    size: 24,
                  ),
                ),
                const SizedBox(width: CartoMixSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Import Tracks',
                        style: CartoMixTypography.headline,
                      ),
                      Text(
                        'Import from DJ software',
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

            // Format selection
            Text(
              'Import Format',
              style: CartoMixTypography.badge.copyWith(
                color: CartoMixColors.textSecondary,
              ),
            ),
            const SizedBox(height: CartoMixSpacing.sm),
            Wrap(
              spacing: CartoMixSpacing.sm,
              runSpacing: CartoMixSpacing.sm,
              children: ImportFormat.values.map((format) {
                final isSelected = format == _selectedFormat;
                return InkWell(
                  onTap: () => setState(() {
                    _selectedFormat = format;
                    _selectedFilePath = null;
                    _importResult = null;
                    _errorMessage = null;
                  }),
                  borderRadius:
                      BorderRadius.circular(CartoMixSpacing.radiusMd),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: CartoMixSpacing.md,
                      vertical: CartoMixSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? CartoMixColors.accent.withValues(alpha: 0.1)
                          : CartoMixColors.bgTertiary,
                      borderRadius:
                          BorderRadius.circular(CartoMixSpacing.radiusMd),
                      border: Border.all(
                        color: isSelected
                            ? CartoMixColors.accent
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
                              ? CartoMixColors.accent
                              : CartoMixColors.textSecondary,
                        ),
                        const SizedBox(width: CartoMixSpacing.xs),
                        Text(
                          format.displayName,
                          style: CartoMixTypography.badge.copyWith(
                            color: isSelected
                                ? CartoMixColors.accent
                                : CartoMixColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: CartoMixSpacing.lg),

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

            // File selection
            Text(
              'Select File',
              style: CartoMixTypography.badge.copyWith(
                color: CartoMixColors.textSecondary,
              ),
            ),
            const SizedBox(height: CartoMixSpacing.sm),
            InkWell(
              onTap: _selectFile,
              borderRadius: BorderRadius.circular(CartoMixSpacing.radiusMd),
              child: Container(
                padding: const EdgeInsets.all(CartoMixSpacing.md),
                decoration: BoxDecoration(
                  color: CartoMixColors.bgTertiary,
                  borderRadius:
                      BorderRadius.circular(CartoMixSpacing.radiusMd),
                  border: Border.all(
                    color: CartoMixColors.border,
                    style: BorderStyle.solid,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.folder_open,
                      size: 20,
                      color: CartoMixColors.textMuted,
                    ),
                    const SizedBox(width: CartoMixSpacing.sm),
                    Expanded(
                      child: Text(
                        _selectedFilePath ?? 'Click to select file...',
                        style: CartoMixTypography.body.copyWith(
                          color: _selectedFilePath != null
                              ? CartoMixColors.textPrimary
                              : CartoMixColors.textMuted,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      size: 20,
                      color: CartoMixColors.textMuted,
                    ),
                  ],
                ),
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

            // Import result
            if (_importResult != null)
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
                          'Found ${_importResult!.count} tracks',
                          style: CartoMixTypography.badge.copyWith(
                            color: CartoMixColors.success,
                          ),
                        ),
                      ],
                    ),
                    if (_addedCount > 0) ...[
                      const SizedBox(height: CartoMixSpacing.xs),
                      Text(
                        '$_addedCount tracks added to library',
                        style: CartoMixTypography.caption.copyWith(
                          color: CartoMixColors.textMuted,
                        ),
                      ),
                    ],
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
                const SizedBox(width: CartoMixSpacing.sm),
                if (_importResult == null)
                  ElevatedButton(
                    onPressed: _isImporting || _selectedFilePath == null
                        ? null
                        : _performImport,
                    child: _isImporting
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
                              Icon(Icons.search, size: 16),
                              const SizedBox(width: CartoMixSpacing.xs),
                              Text('Scan File'),
                            ],
                          ),
                  )
                else
                  ElevatedButton(
                    onPressed: _isAddingToLibrary || _addedCount > 0
                        ? null
                        : _addToLibrary,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: CartoMixColors.success,
                    ),
                    child: _isAddingToLibrary
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
                              Icon(Icons.add, size: 16),
                              const SizedBox(width: CartoMixSpacing.xs),
                              Text(_addedCount > 0 ? 'Done' : 'Add to Library'),
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

  String _getFormatDescription(ImportFormat format) {
    switch (format) {
      case ImportFormat.rekordbox:
        return 'Import from Pioneer Rekordbox XML library export. Includes track metadata, BPM, key, and cue points.';
      case ImportFormat.serato:
        return 'Import from Serato DJ crate files (.crate). Extracts track paths from your Serato library.';
      case ImportFormat.traktor:
        return 'Import from Native Instruments Traktor NML collection. Includes full track metadata.';
      case ImportFormat.m3u:
        return 'Import from M3U/M3U8 playlist files. Standard format compatible with most media players.';
    }
  }
}

/// Show the import dialog
Future<void> showImportDialog(BuildContext context) {
  return showDialog(
    context: context,
    builder: (context) => const ImportDialog(),
  );
}
