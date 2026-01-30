import 'package:flutter/material.dart';
import '../core/theme/colors.dart';
import 'track_analysis.dart';
import 'enums.dart';

/// Represents an audio track in the library
class Track {
  final int id;
  final String contentHash;
  final String path;
  final String title;
  final String artist;
  final String? album;
  final int fileSize;
  final DateTime fileModifiedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final TrackAnalysis? analysis;

  const Track({
    required this.id,
    required this.contentHash,
    required this.path,
    required this.title,
    required this.artist,
    this.album,
    required this.fileSize,
    required this.fileModifiedAt,
    required this.createdAt,
    required this.updatedAt,
    this.analysis,
  });

  /// Whether the track has been analyzed
  bool get isAnalyzed =>
      analysis != null && analysis!.status == AnalysisStatus.complete;

  /// Whether analysis is in progress
  bool get isAnalyzing =>
      analysis != null && analysis!.status == AnalysisStatus.analyzing;

  /// Whether analysis has failed
  bool get hasFailed =>
      analysis != null && analysis!.status == AnalysisStatus.failed;

  /// Analysis status
  AnalysisStatus get analysisStatus =>
      analysis?.status ?? AnalysisStatus.pending;

  /// BPM (from analysis)
  double? get bpm => analysis?.bpm;

  /// Formatted BPM string
  String? get bpmFormatted => analysis?.bpmFormatted;

  /// Key (from analysis)
  String? get key => analysis?.keyValue;

  /// Energy level (from analysis)
  int? get energy => analysis?.energyGlobal;

  /// Duration in seconds (from analysis)
  double? get durationSeconds => analysis?.durationSeconds;

  /// Formatted duration string
  String? get durationFormatted => analysis?.durationFormatted;

  /// Color for the key
  Color get keyColor =>
      analysis != null ? CartoMixColors.colorForKey(analysis!.keyValue) : CartoMixColors.textMuted;

  /// Color for the energy level
  Color get energyColor =>
      analysis != null ? CartoMixColors.colorForEnergy(analysis!.energyGlobal) : CartoMixColors.textMuted;

  /// Filename from path
  String get filename => path.split('/').last;

  /// File extension
  String get extension => filename.split('.').last.toLowerCase();

  /// Formatted file size
  String get fileSizeFormatted {
    if (fileSize < 1024) return '$fileSize B';
    if (fileSize < 1024 * 1024) return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  /// Create from JSON map
  factory Track.fromMap(Map<String, dynamic> map) {
    return Track(
      id: map['id'] as int? ?? 0,
      contentHash: map['contentHash'] as String? ?? '',
      path: map['path'] as String? ?? '',
      title: map['title'] as String? ?? 'Unknown Title',
      artist: map['artist'] as String? ?? 'Unknown Artist',
      album: map['album'] as String?,
      fileSize: map['fileSize'] as int? ?? 0,
      fileModifiedAt: map['fileModifiedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              ((map['fileModifiedAt'] as num) * 1000).round())
          : DateTime.now(),
      createdAt: map['createdAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              ((map['createdAt'] as num) * 1000).round())
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              ((map['updatedAt'] as num) * 1000).round())
          : DateTime.now(),
      analysis: map['analysis'] != null
          ? TrackAnalysis.fromMap(map['analysis'] as Map<String, dynamic>)
          : null,
    );
  }

  /// Convert to JSON map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'contentHash': contentHash,
      'path': path,
      'title': title,
      'artist': artist,
      'album': album,
      'fileSize': fileSize,
      'fileModifiedAt': fileModifiedAt.millisecondsSinceEpoch / 1000,
      'createdAt': createdAt.millisecondsSinceEpoch / 1000,
      'updatedAt': updatedAt.millisecondsSinceEpoch / 1000,
      if (analysis != null) 'analysis': analysis!.toMap(),
    };
  }

  /// Copy with new values
  Track copyWith({
    int? id,
    String? contentHash,
    String? path,
    String? title,
    String? artist,
    String? album,
    int? fileSize,
    DateTime? fileModifiedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    TrackAnalysis? analysis,
  }) {
    return Track(
      id: id ?? this.id,
      contentHash: contentHash ?? this.contentHash,
      path: path ?? this.path,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      fileSize: fileSize ?? this.fileSize,
      fileModifiedAt: fileModifiedAt ?? this.fileModifiedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      analysis: analysis ?? this.analysis,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Track && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Track($id: $title by $artist)';

  /// Preview track for testing
  static Track get preview => Track(
        id: 1,
        contentHash: 'abc123',
        path: '/Music/track.mp3',
        title: 'Sample Track',
        artist: 'Test Artist',
        album: 'Test Album',
        fileSize: 10000000,
        fileModifiedAt: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
}
