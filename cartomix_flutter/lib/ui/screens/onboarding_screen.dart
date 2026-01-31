import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/theme.dart';
import '../../core/providers/app_state.dart';

/// Onboarding screen shown on first launch
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  int _currentStep = 0;
  final List<String> _selectedPaths = [];
  int _tracksFound = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('onboarding.screen'),
      backgroundColor: CartoMixColors.bgPrimary,
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 600),
            padding: const EdgeInsets.all(CartoMixSpacing.xl),
            child: _buildCurrentStep(),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _buildWelcomeStep();
      case 1:
        return _buildAddLibraryStep();
      case 2:
        return _buildScanningStep();
      case 3:
        return _buildReadyStep();
      default:
        return _buildWelcomeStep();
    }
  }

  Widget _buildWelcomeStep() {
    return Column(
      key: const Key('onboarding.welcome'),
      mainAxisSize: MainAxisSize.min,
      children: [
        // Logo
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            gradient: CartoMixGradients.waveform,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: CartoMixColors.primary.withValues(alpha: 0.4),
                blurRadius: 30,
                spreadRadius: 5,
              ),
            ],
          ),
          child: const Icon(
            Icons.music_note,
            color: Colors.white,
            size: 56,
          ),
        ),
        const SizedBox(height: CartoMixSpacing.xl),
        Text(
          'Welcome to CartoMix',
          style: CartoMixTypography.title.copyWith(
            fontSize: 32,
          ),
        ),
        const SizedBox(height: CartoMixSpacing.md),
        Text(
          'Your AI-powered DJ set preparation copilot',
          style: CartoMixTypography.body.copyWith(
            color: CartoMixColors.textSecondary,
            fontSize: 18,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: CartoMixSpacing.xl * 2),
        // Features list
        _buildFeatureItem(
          icon: Icons.analytics_outlined,
          title: 'Analyze Your Tracks',
          description: 'AI-powered BPM, key, and energy detection',
        ),
        const SizedBox(height: CartoMixSpacing.lg),
        _buildFeatureItem(
          icon: Icons.auto_graph_outlined,
          title: 'Smart Transitions',
          description: 'Find harmonically compatible tracks instantly',
        ),
        const SizedBox(height: CartoMixSpacing.lg),
        _buildFeatureItem(
          icon: Icons.queue_music_outlined,
          title: 'Build Perfect Sets',
          description: 'Plan your DJ sets with energy flow visualization',
        ),
        const SizedBox(height: CartoMixSpacing.xl * 2),
        SizedBox(
          width: 200,
          height: 48,
          child: ElevatedButton(
            key: const Key('onboarding.getStarted'),
            onPressed: () => setState(() => _currentStep = 1),
            style: ElevatedButton.styleFrom(
              backgroundColor: CartoMixColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text(
              'Get Started',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: CartoMixColors.primary.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
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
                title,
                style: CartoMixTypography.headline,
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: CartoMixTypography.body.copyWith(
                  color: CartoMixColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAddLibraryStep() {
    return Column(
      key: const Key('onboarding.addLibrary'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.folder_open_outlined,
          size: 80,
          color: CartoMixColors.primary,
        ),
        const SizedBox(height: CartoMixSpacing.xl),
        Text(
          'Add Your Music Library',
          style: CartoMixTypography.title.copyWith(fontSize: 28),
        ),
        const SizedBox(height: CartoMixSpacing.md),
        Text(
          'Select folders containing your DJ music collection.\nCartoMix supports MP3, WAV, FLAC, AIFF, and M4A files.',
          style: CartoMixTypography.body.copyWith(
            color: CartoMixColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: CartoMixSpacing.xl),
        // Selected paths
        if (_selectedPaths.isNotEmpty) ...[
          Container(
            constraints: const BoxConstraints(maxHeight: 200),
            decoration: BoxDecoration(
              color: CartoMixColors.bgSecondary,
              borderRadius: BorderRadius.circular(CartoMixSpacing.radiusMd),
              border: Border.all(color: CartoMixColors.border),
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _selectedPaths.length,
              itemBuilder: (context, index) {
                final path = _selectedPaths[index];
                return ListTile(
                  dense: true,
                  leading: const Icon(Icons.folder, color: CartoMixColors.primary),
                  title: Text(
                    path.split('/').last,
                    style: CartoMixTypography.body,
                  ),
                  subtitle: Text(
                    path,
                    style: CartoMixTypography.caption.copyWith(
                      color: CartoMixColors.textMuted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () {
                      setState(() => _selectedPaths.removeAt(index));
                    },
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: CartoMixSpacing.lg),
        ],
        // Add folder button
        OutlinedButton.icon(
          key: const Key('onboarding.addFolder'),
          onPressed: _pickFolder,
          icon: const Icon(Icons.add),
          label: Text(_selectedPaths.isEmpty ? 'Select Music Folder' : 'Add Another Folder'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(
              horizontal: CartoMixSpacing.lg,
              vertical: CartoMixSpacing.md,
            ),
          ),
        ),
        const SizedBox(height: CartoMixSpacing.md),
        // Quick add ~/Music
        if (!_selectedPaths.any((p) => p.contains('/Music')))
          TextButton.icon(
            onPressed: () {
              final homeDir = Platform.environment['HOME'] ?? '';
              final musicPath = '$homeDir/Music';
              if (Directory(musicPath).existsSync()) {
                setState(() => _selectedPaths.add(musicPath));
              }
            },
            icon: const Icon(Icons.music_note, size: 18),
            label: const Text('Add ~/Music folder'),
          ),
        const SizedBox(height: CartoMixSpacing.xl * 2),
        // Navigation buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton(
              onPressed: () => setState(() => _currentStep = 0),
              child: const Text('Back'),
            ),
            const SizedBox(width: CartoMixSpacing.lg),
            SizedBox(
              width: 160,
              height: 44,
              child: ElevatedButton(
                key: const Key('onboarding.continue'),
                onPressed: _selectedPaths.isNotEmpty ? _startScanning : null,
                child: const Text('Continue'),
              ),
            ),
          ],
        ),
        const SizedBox(height: CartoMixSpacing.md),
        // Skip option
        TextButton(
          onPressed: _skipOnboarding,
          child: Text(
            'Skip for now',
            style: CartoMixTypography.caption.copyWith(
              color: CartoMixColors.textMuted,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildScanningStep() {
    return Column(
      key: const Key('onboarding.scanning'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 80,
          height: 80,
          child: CircularProgressIndicator(
            strokeWidth: 4,
            valueColor: AlwaysStoppedAnimation<Color>(CartoMixColors.primary),
          ),
        ),
        const SizedBox(height: CartoMixSpacing.xl),
        Text(
          'Scanning Your Library',
          style: CartoMixTypography.title.copyWith(fontSize: 28),
        ),
        const SizedBox(height: CartoMixSpacing.md),
        Text(
          'Found $_tracksFound tracks so far...',
          style: CartoMixTypography.body.copyWith(
            color: CartoMixColors.textSecondary,
          ),
        ),
        const SizedBox(height: CartoMixSpacing.lg),
        Text(
          'This may take a moment for large libraries.',
          style: CartoMixTypography.caption.copyWith(
            color: CartoMixColors.textMuted,
          ),
        ),
      ],
    );
  }

  Widget _buildReadyStep() {
    return Column(
      key: const Key('onboarding.ready'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: CartoMixColors.success.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check,
            size: 48,
            color: CartoMixColors.success,
          ),
        ),
        const SizedBox(height: CartoMixSpacing.xl),
        Text(
          'You\'re All Set!',
          style: CartoMixTypography.title.copyWith(fontSize: 28),
        ),
        const SizedBox(height: CartoMixSpacing.md),
        Text(
          'Found $_tracksFound tracks in your library.',
          style: CartoMixTypography.body.copyWith(
            color: CartoMixColors.textSecondary,
          ),
        ),
        const SizedBox(height: CartoMixSpacing.sm),
        Text(
          'Click "Analyze All" to process your tracks with AI.',
          style: CartoMixTypography.body.copyWith(
            color: CartoMixColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: CartoMixSpacing.xl * 2),
        SizedBox(
          width: 200,
          height: 48,
          child: ElevatedButton(
            key: const Key('onboarding.startUsing'),
            onPressed: _completeOnboarding,
            style: ElevatedButton.styleFrom(
              backgroundColor: CartoMixColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text(
              'Start Using CartoMix',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _pickFolder() async {
    // Use native macOS file picker via method channel
    const channel = MethodChannel('com.cartomix.filepicker');
    try {
      final result = await channel.invokeMethod<List<dynamic>>('pickFolders');
      if (result != null && result.isNotEmpty) {
        for (final path in result) {
          if (path is String && path.isNotEmpty && !_selectedPaths.contains(path)) {
            setState(() => _selectedPaths.add(path));
          }
        }
      }
    } on PlatformException catch (e) {
      // Fallback: show a dialog to enter path manually
      if (mounted) {
        _showManualPathDialog();
      }
      debugPrint('Error picking folder: $e');
    } on MissingPluginException {
      // Platform channel not implemented, show manual path dialog
      if (mounted) {
        _showManualPathDialog();
      }
    }
  }

  void _showManualPathDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enter Music Folder Path'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: '/Users/yourname/Music',
            labelText: 'Folder Path',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final path = controller.text.trim();
              if (path.isNotEmpty && Directory(path).existsSync()) {
                if (!_selectedPaths.contains(path)) {
                  setState(() => _selectedPaths.add(path));
                }
                Navigator.pop(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Invalid folder path')),
                );
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _startScanning() async {
    setState(() {
      _currentStep = 2;
      _tracksFound = 0;
    });

    // Add paths to provider
    final libraryPaths = ref.read(libraryPathsProvider.notifier);
    for (final path in _selectedPaths) {
      await libraryPaths.addPath(path);
    }

    // Count tracks
    int count = 0;
    for (final path in _selectedPaths) {
      final dir = Directory(path);
      if (await dir.exists()) {
        await for (final entity in dir.list(recursive: true)) {
          if (entity is File) {
            final ext = entity.path.toLowerCase();
            if (ext.endsWith('.mp3') ||
                ext.endsWith('.wav') ||
                ext.endsWith('.flac') ||
                ext.endsWith('.aiff') ||
                ext.endsWith('.m4a')) {
              count++;
              if (count % 10 == 0) {
                setState(() => _tracksFound = count);
                await Future.delayed(const Duration(milliseconds: 50));
              }
            }
          }
        }
      }
    }

    setState(() {
      _tracksFound = count;
      _currentStep = 3;
    });
  }

  Future<void> _skipOnboarding() async {
    await ref.read(onboardingCompleteProvider.notifier).completeOnboarding();
  }

  Future<void> _completeOnboarding() async {
    await ref.read(onboardingCompleteProvider.notifier).completeOnboarding();
  }
}
