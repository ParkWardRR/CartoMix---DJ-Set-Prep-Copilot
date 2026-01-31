import 'dart:async';
import 'package:flutter/services.dart';
import '../../models/models.dart';

/// Main bridge for communicating with native Swift backend via platform channels
class NativeBridge {
  NativeBridge._();

  static final NativeBridge instance = NativeBridge._();

  // Method channels for each service
  static const _databaseChannel = MethodChannel('com.cartomix.database');
  static const _analyzerChannel = MethodChannel('com.cartomix.analyzer');
  static const _playerChannel = MethodChannel('com.cartomix.player');
  static const _similarityChannel = MethodChannel('com.cartomix.similarity');
  static const _plannerChannel = MethodChannel('com.cartomix.planner');
  static const _exporterChannel = MethodChannel('com.cartomix.exporter');
  static const _filePickerChannel = MethodChannel('com.cartomix.filepicker');

  // Event channels for streaming data
  static const _analyzerProgressChannel =
      EventChannel('com.cartomix.analyzer.progress');
  static const _playerStateChannel = EventChannel('com.cartomix.player.state');

  // MARK: - Database Operations

  /// Fetch all tracks from the database
  Future<List<Track>> fetchAllTracks() async {
    final result = await _databaseChannel.invokeMethod<List>('fetchAllTracks');
    if (result == null) return [];
    return result
        .map((e) => Track.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  /// Fetch a single track by ID
  Future<Track?> fetchTrack(int id) async {
    final result = await _databaseChannel.invokeMethod<Map>('fetchTrack', {
      'id': id,
    });
    if (result == null) return null;
    return Track.fromMap(Map<String, dynamic>.from(result));
  }

  /// Insert a new track
  Future<Track> insertTrack(Track track) async {
    final result = await _databaseChannel.invokeMethod<Map>('insertTrack', {
      'track': track.toMap(),
    });
    return Track.fromMap(Map<String, dynamic>.from(result!));
  }

  /// Upsert (insert or update) a track
  Future<Track> upsertTrack(Track track) async {
    final result = await _databaseChannel.invokeMethod<Map>('upsertTrack', {
      'track': track.toMap(),
    });
    return Track.fromMap(Map<String, dynamic>.from(result!));
  }

  /// Fetch music locations
  Future<List<Map<String, dynamic>>> fetchMusicLocations() async {
    final result =
        await _databaseChannel.invokeMethod<List>('fetchMusicLocations');
    if (result == null) return [];
    return result.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  /// Add a music location (opens native folder picker)
  Future<void> addMusicLocation() async {
    await _databaseChannel.invokeMethod('addMusicLocation');
  }

  /// Remove a music location
  Future<void> removeMusicLocation(int id) async {
    await _databaseChannel.invokeMethod('removeMusicLocation', {'id': id});
  }

  /// Get storage statistics
  Future<Map<String, dynamic>> getStorageStats() async {
    final result =
        await _databaseChannel.invokeMethod<Map>('getStorageStats');
    return Map<String, dynamic>.from(result ?? {});
  }

  // MARK: - Analyzer Operations

  /// Scan a directory for audio files
  Future<void> scanDirectory(String path) async {
    await _analyzerChannel.invokeMethod('scanDirectory', {'path': path});
  }

  /// Analyze a single track
  Future<void> analyzeTrack(int trackId) async {
    await _analyzerChannel.invokeMethod('analyzeTrack', {'trackId': trackId});
  }

  /// Analyze all pending tracks
  Future<void> analyzeAllPending() async {
    await _analyzerChannel.invokeMethod('analyzeAllPending');
  }

  /// Stream of analysis progress updates
  Stream<AnalysisProgress> get analyzerProgressStream {
    return _analyzerProgressChannel.receiveBroadcastStream().map((event) {
      final map = Map<String, dynamic>.from(event as Map);
      return AnalysisProgress(
        stage: AnalysisStage.fromString(map['stage'] as String? ?? 'decoding'),
        progress: (map['progress'] as num?)?.toDouble() ?? 0.0,
        message: map['message'] as String?,
        trackId: map['trackId'] as int?,
      );
    });
  }

  // MARK: - Player Operations

  /// Load a track for playback
  Future<void> loadTrack(String path, int trackId) async {
    await _playerChannel.invokeMethod('load', {
      'path': path,
      'trackId': trackId,
    });
  }

  /// Start playback
  Future<void> play() async {
    await _playerChannel.invokeMethod('play');
  }

  /// Pause playback
  Future<void> pause() async {
    await _playerChannel.invokeMethod('pause');
  }

  /// Stop playback
  Future<void> stop() async {
    await _playerChannel.invokeMethod('stop');
  }

  /// Seek to a position in seconds
  Future<void> seek(double timeSeconds) async {
    await _playerChannel.invokeMethod('seek', {'time': timeSeconds});
  }

  /// Set playback volume (0.0 - 1.0)
  Future<void> setVolume(double volume) async {
    await _playerChannel.invokeMethod('setVolume', {'volume': volume});
  }

  /// Set playback rate (0.5 - 2.0)
  Future<void> setRate(double rate) async {
    await _playerChannel.invokeMethod('setRate', {'rate': rate});
  }

  /// Stream of player state updates
  Stream<PlayerState> get playerStateStream {
    return _playerStateChannel.receiveBroadcastStream().map((event) {
      final map = Map<String, dynamic>.from(event as Map);
      return PlayerState.fromMap(map);
    });
  }

  // MARK: - Similarity Operations

  /// Compute similarity between two tracks
  Future<SimilarityResult> computeSimilarity(int trackAId, int trackBId) async {
    final result = await _similarityChannel.invokeMethod<Map>(
      'computeSimilarity',
      {'trackAId': trackAId, 'trackBId': trackBId},
    );
    return SimilarityResult.fromMap(Map<String, dynamic>.from(result!));
  }

  /// Find similar tracks to a given track
  Future<List<SimilarityResult>> findSimilarTracks(int trackId,
      {int limit = 10}) async {
    final result = await _similarityChannel.invokeMethod<List>(
      'findSimilarTracks',
      {'trackId': trackId, 'limit': limit},
    );
    if (result == null) return [];
    return result
        .map((e) => SimilarityResult.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  /// Compute all similarities (batch)
  Future<void> computeAllSimilarities() async {
    await _similarityChannel.invokeMethod('computeAllSimilarities');
  }

  // MARK: - Planner Operations

  /// Optimize set track order
  Future<SetPlanResult> optimizeSet({
    required List<int> trackIds,
    required SetMode mode,
    int? startTrackId,
    int? endTrackId,
  }) async {
    final result = await _plannerChannel.invokeMethod<Map>('optimizeSet', {
      'trackIds': trackIds,
      'mode': mode.name,
      'startTrackId': startTrackId,
      'endTrackId': endTrackId,
    });
    return SetPlanResult.fromMap(Map<String, dynamic>.from(result!));
  }

  // MARK: - Exporter Operations

  /// Export to Rekordbox XML format
  Future<String> exportRekordbox({
    required List<int> trackIds,
    required String playlistName,
    required String outputPath,
  }) async {
    final result = await _exporterChannel.invokeMethod<String>(
      'exportRekordbox',
      {
        'trackIds': trackIds,
        'playlistName': playlistName,
        'path': outputPath,
      },
    );
    return result ?? '';
  }

  /// Export to Serato crate format
  Future<String> exportSerato({
    required List<int> trackIds,
    required String playlistName,
    required String outputPath,
  }) async {
    final result = await _exporterChannel.invokeMethod<String>(
      'exportSerato',
      {
        'trackIds': trackIds,
        'playlistName': playlistName,
        'path': outputPath,
      },
    );
    return result ?? '';
  }

  /// Export to Traktor NML format
  Future<String> exportTraktor({
    required List<int> trackIds,
    required String playlistName,
    required String outputPath,
  }) async {
    final result = await _exporterChannel.invokeMethod<String>(
      'exportTraktor',
      {
        'trackIds': trackIds,
        'playlistName': playlistName,
        'path': outputPath,
      },
    );
    return result ?? '';
  }

  /// Export to JSON format
  Future<String> exportJSON({
    required List<int> trackIds,
    required String outputPath,
  }) async {
    final result = await _exporterChannel.invokeMethod<String>(
      'exportJSON',
      {'trackIds': trackIds, 'path': outputPath},
    );
    return result ?? '';
  }

  /// Export to M3U playlist format
  Future<String> exportM3U({
    required List<int> trackIds,
    required String outputPath,
  }) async {
    final result = await _exporterChannel.invokeMethod<String>(
      'exportM3U',
      {'trackIds': trackIds, 'path': outputPath},
    );
    return result ?? '';
  }

  /// Export to CSV format
  Future<String> exportCSV({
    required List<int> trackIds,
    required String outputPath,
  }) async {
    final result = await _exporterChannel.invokeMethod<String>(
      'exportCSV',
      {'trackIds': trackIds, 'path': outputPath},
    );
    return result ?? '';
  }

  // MARK: - File Picker

  /// Open native folder picker
  Future<List<String>> pickFolders() async {
    final result =
        await _filePickerChannel.invokeMethod<List>('pickFolders');
    return result?.cast<String>() ?? [];
  }
}

/// Analysis progress update
class AnalysisProgress {
  final AnalysisStage stage;
  final double progress;
  final String? message;
  final int? trackId;

  const AnalysisProgress({
    required this.stage,
    required this.progress,
    this.message,
    this.trackId,
  });
}

/// Player state
class PlayerState {
  final bool isPlaying;
  final double currentTime;
  final double duration;
  final double volume;
  final double rate;
  final int? currentTrackId;
  final String? error;

  const PlayerState({
    required this.isPlaying,
    required this.currentTime,
    required this.duration,
    required this.volume,
    required this.rate,
    this.currentTrackId,
    this.error,
  });

  factory PlayerState.initial() => const PlayerState(
        isPlaying: false,
        currentTime: 0,
        duration: 0,
        volume: 1.0,
        rate: 1.0,
      );

  factory PlayerState.fromMap(Map<String, dynamic> map) {
    return PlayerState(
      isPlaying: map['isPlaying'] as bool? ?? false,
      currentTime: (map['currentTime'] as num?)?.toDouble() ?? 0.0,
      duration: (map['duration'] as num?)?.toDouble() ?? 0.0,
      volume: (map['volume'] as num?)?.toDouble() ?? 1.0,
      rate: (map['rate'] as num?)?.toDouble() ?? 1.0,
      currentTrackId: map['trackId'] as int?,
      error: map['error'] as String?,
    );
  }

  /// Formatted current time (M:SS)
  String get currentTimeFormatted {
    final minutes = (currentTime / 60).floor();
    final seconds = (currentTime % 60).floor();
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  /// Formatted duration (M:SS)
  String get durationFormatted {
    final minutes = (duration / 60).floor();
    final seconds = (duration % 60).floor();
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  /// Progress percentage (0.0 - 1.0)
  double get progress => duration > 0 ? currentTime / duration : 0.0;
}

/// Similarity result between two tracks
class SimilarityResult {
  final int trackAId;
  final int trackBId;
  final double openl3Similarity;
  final double combinedScore;
  final double tempoSimilarity;
  final double keySimilarity;
  final double energySimilarity;
  final String explanation;

  const SimilarityResult({
    required this.trackAId,
    required this.trackBId,
    required this.openl3Similarity,
    required this.combinedScore,
    required this.tempoSimilarity,
    required this.keySimilarity,
    required this.energySimilarity,
    required this.explanation,
  });

  factory SimilarityResult.fromMap(Map<String, dynamic> map) {
    return SimilarityResult(
      trackAId: map['trackAId'] as int? ?? 0,
      trackBId: map['trackBId'] as int? ?? 0,
      openl3Similarity: (map['openl3Similarity'] as num?)?.toDouble() ?? 0.0,
      combinedScore: (map['combinedScore'] as num?)?.toDouble() ?? 0.0,
      tempoSimilarity: (map['tempoSimilarity'] as num?)?.toDouble() ?? 0.0,
      keySimilarity: (map['keySimilarity'] as num?)?.toDouble() ?? 0.0,
      energySimilarity: (map['energySimilarity'] as num?)?.toDouble() ?? 0.0,
      explanation: map['explanation'] as String? ?? '',
    );
  }
}

/// Set planning result
class SetPlanResult {
  final List<int> orderedTrackIds;
  final List<TransitionPlan> transitions;
  final double totalScore;

  const SetPlanResult({
    required this.orderedTrackIds,
    required this.transitions,
    required this.totalScore,
  });

  factory SetPlanResult.fromMap(Map<String, dynamic> map) {
    final transitions = (map['transitions'] as List?)
            ?.map((e) => TransitionPlan.fromMap(Map<String, dynamic>.from(e as Map)))
            .toList() ??
        [];

    return SetPlanResult(
      orderedTrackIds: (map['orderedTrackIds'] as List?)?.cast<int>() ?? [],
      transitions: transitions,
      totalScore: (map['totalScore'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

/// Transition plan between two tracks
class TransitionPlan {
  final int fromTrackId;
  final int toTrackId;
  final double score;
  final String reason;

  const TransitionPlan({
    required this.fromTrackId,
    required this.toTrackId,
    required this.score,
    required this.reason,
  });

  factory TransitionPlan.fromMap(Map<String, dynamic> map) {
    return TransitionPlan(
      fromTrackId: map['fromTrackId'] as int? ?? 0,
      toTrackId: map['toTrackId'] as int? ?? 0,
      score: (map['score'] as num?)?.toDouble() ?? 0.0,
      reason: map['reason'] as String? ?? '',
    );
  }
}
