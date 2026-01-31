import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/models.dart';

/// Keys for shared preferences
class PrefsKeys {
  static const String onboardingComplete = 'onboarding_complete';
  static const String libraryPaths = 'library_paths';
  static const String lastScanDate = 'last_scan_date';
}

/// Provider for SharedPreferences instance
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences must be overridden in main()');
});

/// Provider to check if onboarding is complete
final onboardingCompleteProvider = StateNotifierProvider<OnboardingNotifier, bool>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return OnboardingNotifier(prefs);
});

class OnboardingNotifier extends StateNotifier<bool> {
  final SharedPreferences _prefs;

  OnboardingNotifier(this._prefs) : super(_prefs.getBool(PrefsKeys.onboardingComplete) ?? false);

  Future<void> completeOnboarding() async {
    await _prefs.setBool(PrefsKeys.onboardingComplete, true);
    state = true;
  }

  Future<void> resetOnboarding() async {
    await _prefs.setBool(PrefsKeys.onboardingComplete, false);
    state = false;
  }
}

/// Provider for library folder paths
final libraryPathsProvider = StateNotifierProvider<LibraryPathsNotifier, List<String>>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return LibraryPathsNotifier(prefs);
});

class LibraryPathsNotifier extends StateNotifier<List<String>> {
  final SharedPreferences _prefs;

  LibraryPathsNotifier(this._prefs) : super(_prefs.getStringList(PrefsKeys.libraryPaths) ?? []);

  Future<void> addPath(String path) async {
    if (!state.contains(path)) {
      final newPaths = [...state, path];
      await _prefs.setStringList(PrefsKeys.libraryPaths, newPaths);
      state = newPaths;
    }
  }

  Future<void> removePath(String path) async {
    final newPaths = state.where((p) => p != path).toList();
    await _prefs.setStringList(PrefsKeys.libraryPaths, newPaths);
    state = newPaths;
  }

  Future<void> clearPaths() async {
    await _prefs.setStringList(PrefsKeys.libraryPaths, []);
    state = [];
  }
}

/// Provider for the track library
final tracksProvider = StateNotifierProvider<TracksNotifier, AsyncValue<List<Track>>>((ref) {
  final libraryPaths = ref.watch(libraryPathsProvider);
  return TracksNotifier(libraryPaths);
});

class TracksNotifier extends StateNotifier<AsyncValue<List<Track>>> {
  final List<String> _libraryPaths;

  TracksNotifier(this._libraryPaths) : super(const AsyncValue.data([])) {
    if (_libraryPaths.isNotEmpty) {
      _scanLibrary();
    }
  }

  Future<void> _scanLibrary() async {
    state = const AsyncValue.loading();
    try {
      final tracks = <Track>[];
      int id = 1;

      for (final path in _libraryPaths) {
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
                final fileName = entity.path.split('/').last;
                final nameWithoutExt = fileName.replaceAll(RegExp(r'\.[^.]+$'), '');

                // Try to parse artist - title format
                String title = nameWithoutExt;
                String artist = 'Unknown Artist';

                if (nameWithoutExt.contains(' - ')) {
                  final parts = nameWithoutExt.split(' - ');
                  artist = parts[0].trim();
                  title = parts.sublist(1).join(' - ').trim();
                }

                final stat = await entity.stat();
                tracks.add(Track(
                  id: id++,
                  contentHash: entity.path.hashCode.toString(),
                  path: entity.path,
                  title: title,
                  artist: artist,
                  album: '',
                  fileSize: stat.size,
                  fileModifiedAt: stat.modified,
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                ));
              }
            }
          }
        }
      }

      state = AsyncValue.data(tracks);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> rescan() async {
    await _scanLibrary();
  }

  void addTrack(Track track) {
    state.whenData((tracks) {
      state = AsyncValue.data([...tracks, track]);
    });
  }

  void updateTrack(Track track) {
    state.whenData((tracks) {
      final index = tracks.indexWhere((t) => t.id == track.id);
      if (index >= 0) {
        final newTracks = [...tracks];
        newTracks[index] = track;
        state = AsyncValue.data(newTracks);
      }
    });
  }
}

/// Provider for currently selected track
final selectedTrackProvider = StateProvider<Track?>((ref) => null);

/// Provider for library view mode
enum LibraryViewMode { list, grid }
final libraryViewModeProvider = StateProvider<LibraryViewMode>((ref) => LibraryViewMode.list);

/// Provider for current set mode (uses SetMode from models/enums.dart)
final setModeProvider = StateProvider<SetMode>((ref) => SetMode.peakTime);

/// Provider for tracks in the current set
final setTracksProvider = StateNotifierProvider<SetTracksNotifier, List<Track>>((ref) {
  return SetTracksNotifier();
});

class SetTracksNotifier extends StateNotifier<List<Track>> {
  SetTracksNotifier() : super([]);

  void addTrack(Track track) {
    if (!state.any((t) => t.id == track.id)) {
      state = [...state, track];
    }
  }

  void removeTrack(int trackId) {
    state = state.where((t) => t.id != trackId).toList();
  }

  void reorderTracks(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final track = state[oldIndex];
    final newList = [...state]..removeAt(oldIndex)..insert(newIndex, track);
    state = newList;
  }

  void clearSet() {
    state = [];
  }

  void setTracks(List<Track> tracks) {
    state = tracks;
  }
}

/// Provider for energy values of tracks in set
final setEnergyValuesProvider = Provider<List<int>>((ref) {
  final tracks = ref.watch(setTracksProvider);
  return tracks.map((t) => t.energy ?? 5).toList();
});

/// Provider for selected track in set builder
final selectedSetTrackIndexProvider = StateProvider<int?>((ref) => null);

/// Provider for set statistics
final setStatsProvider = Provider<Map<String, dynamic>>((ref) {
  final tracks = ref.watch(setTracksProvider);

  if (tracks.isEmpty) {
    return {
      'avgBpm': null,
      'bpmRange': null,
      'avgEnergy': null,
      'keysUsed': <String>{},
      'totalDuration': 0.0,
    };
  }

  final bpms = tracks.where((t) => t.bpm != null).map((t) => t.bpm!).toList();
  final energies = tracks.where((t) => t.energy != null).map((t) => t.energy!).toList();
  final keys = tracks.where((t) => t.key != null).map((t) => t.key!).toSet();
  final durations = tracks.where((t) => t.durationSeconds != null).map((t) => t.durationSeconds!).toList();

  return {
    'avgBpm': bpms.isEmpty ? null : bpms.reduce((a, b) => a + b) / bpms.length,
    'bpmRange': bpms.isEmpty ? null : '${bpms.reduce((a, b) => a < b ? a : b).round()}-${bpms.reduce((a, b) => a > b ? a : b).round()}',
    'avgEnergy': energies.isEmpty ? null : energies.reduce((a, b) => a + b) / energies.length,
    'keysUsed': keys,
    'totalDuration': durations.isEmpty ? 0.0 : durations.reduce((a, b) => a + b),
  };
});

/// Provider for search query
final searchQueryProvider = StateProvider<String>((ref) => '');

/// Provider for sort mode
final sortModeProvider = StateProvider<String>((ref) => 'title');

/// Provider for filter states
final showAnalyzedOnlyProvider = StateProvider<bool>((ref) => false);
final showHighEnergyOnlyProvider = StateProvider<bool>((ref) => false);

/// Filtered and sorted tracks provider
final filteredTracksProvider = Provider<List<Track>>((ref) {
  final tracksAsync = ref.watch(tracksProvider);
  final searchQuery = ref.watch(searchQueryProvider);
  final sortBy = ref.watch(sortModeProvider);
  final showAnalyzedOnly = ref.watch(showAnalyzedOnlyProvider);
  final showHighEnergyOnly = ref.watch(showHighEnergyOnlyProvider);

  return tracksAsync.when(
    data: (tracks) {
      var filtered = tracks.where((track) {
        // Search filter
        if (searchQuery.isNotEmpty) {
          final query = searchQuery.toLowerCase();
          if (!track.title.toLowerCase().contains(query) &&
              !track.artist.toLowerCase().contains(query)) {
            return false;
          }
        }
        // Analyzed filter
        if (showAnalyzedOnly && !track.isAnalyzed) {
          return false;
        }
        // High energy filter
        if (showHighEnergyOnly && (track.energy ?? 0) < 7) {
          return false;
        }
        return true;
      }).toList();

      // Sort
      switch (sortBy) {
        case 'title':
          filtered.sort((a, b) => a.title.compareTo(b.title));
          break;
        case 'artist':
          filtered.sort((a, b) => a.artist.compareTo(b.artist));
          break;
        case 'bpm_asc':
          filtered.sort((a, b) => (a.bpm ?? 0).compareTo(b.bpm ?? 0));
          break;
        case 'bpm_desc':
          filtered.sort((a, b) => (b.bpm ?? 0).compareTo(a.bpm ?? 0));
          break;
        case 'energy_desc':
          filtered.sort((a, b) => (b.energy ?? 0).compareTo(a.energy ?? 0));
          break;
      }

      return filtered;
    },
    loading: () => [],
    error: (_, __) => [],
  );
});
