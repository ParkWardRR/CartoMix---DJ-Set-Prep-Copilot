import 'dart:typed_data';
import 'enums.dart';
import 'track_section.dart';
import 'cue_point.dart';

/// QA flag for quality assurance
class QAFlag {
  final QAFlagType type;
  final String reason;
  final bool dismissed;

  const QAFlag({
    required this.type,
    required this.reason,
    this.dismissed = false,
  });

  factory QAFlag.fromMap(Map<String, dynamic> map) {
    return QAFlag(
      type: QAFlagType.fromString(map['type'] as String? ?? 'needs_review'),
      reason: map['reason'] as String? ?? '',
      dismissed: map['dismissed'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() => {
        'type': type.rawValue,
        'reason': reason,
        'dismissed': dismissed,
      };
}

/// Training label for ML
class TrainingLabel {
  final SectionLabel label;
  final double startTime;
  final double endTime;
  final int? startBeat;
  final int? endBeat;

  const TrainingLabel({
    required this.label,
    required this.startTime,
    required this.endTime,
    this.startBeat,
    this.endBeat,
  });

  factory TrainingLabel.fromMap(Map<String, dynamic> map) {
    return TrainingLabel(
      label: SectionLabel.fromString(map['label'] as String? ?? 'verse'),
      startTime: (map['startTime'] as num?)?.toDouble() ?? 0.0,
      endTime: (map['endTime'] as num?)?.toDouble() ?? 0.0,
      startBeat: map['startBeat'] as int?,
      endBeat: map['endBeat'] as int?,
    );
  }

  Map<String, dynamic> toMap() => {
        'label': label.value,
        'startTime': startTime,
        'endTime': endTime,
        if (startBeat != null) 'startBeat': startBeat,
        if (endBeat != null) 'endBeat': endBeat,
      };
}

/// Complete analysis data for a track
class TrackAnalysis {
  final int id;
  final int trackId;
  final int version;
  final AnalysisStatus status;
  final double durationSeconds;
  final double bpm;
  final double bpmConfidence;
  final String keyValue;
  final String keyFormat;
  final double keyConfidence;
  final int energyGlobal;
  final double integratedLUFS;
  final double truePeakDB;
  final double loudnessRange;
  final Float32List waveformPreview;
  final List<TrackSection> sections;
  final List<CuePoint> cuePoints;
  final String? soundContext;
  final double? soundContextConfidence;
  final List<QAFlag> qaFlags;
  final bool hasOpenL3Embedding;
  final List<TrainingLabel> trainingLabels;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TrackAnalysis({
    required this.id,
    required this.trackId,
    required this.version,
    required this.status,
    required this.durationSeconds,
    required this.bpm,
    required this.bpmConfidence,
    required this.keyValue,
    required this.keyFormat,
    required this.keyConfidence,
    required this.energyGlobal,
    required this.integratedLUFS,
    required this.truePeakDB,
    required this.loudnessRange,
    required this.waveformPreview,
    required this.sections,
    required this.cuePoints,
    this.soundContext,
    this.soundContextConfidence,
    required this.qaFlags,
    required this.hasOpenL3Embedding,
    required this.trainingLabels,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Formatted duration string (M:SS)
  String get durationFormatted {
    final minutes = (durationSeconds / 60).floor();
    final seconds = (durationSeconds % 60).floor();
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  /// Formatted BPM string
  String get bpmFormatted => bpm.toStringAsFixed(1);

  /// Create from JSON map
  factory TrackAnalysis.fromMap(Map<String, dynamic> map) {
    // Parse waveform preview
    Float32List waveform;
    if (map['waveformPreview'] is List) {
      final list = (map['waveformPreview'] as List)
          .map((e) => (e as num).toDouble())
          .toList();
      waveform = Float32List.fromList(list.cast<double>());
    } else {
      waveform = Float32List(0);
    }

    // Parse sections
    final sections = (map['sections'] as List?)
            ?.map((e) => TrackSection.fromMap(e as Map<String, dynamic>))
            .toList() ??
        [];

    // Parse cue points
    final cuePoints = (map['cuePoints'] as List?)
            ?.map((e) => CuePoint.fromMap(e as Map<String, dynamic>))
            .toList() ??
        [];

    // Parse QA flags
    final qaFlags = (map['qaFlags'] as List?)
            ?.map((e) => QAFlag.fromMap(e as Map<String, dynamic>))
            .toList() ??
        [];

    // Parse training labels
    final trainingLabels = (map['trainingLabels'] as List?)
            ?.map((e) => TrainingLabel.fromMap(e as Map<String, dynamic>))
            .toList() ??
        [];

    return TrackAnalysis(
      id: map['id'] as int? ?? 0,
      trackId: map['trackId'] as int? ?? 0,
      version: map['version'] as int? ?? 1,
      status: AnalysisStatus.fromString(map['status'] as String? ?? 'pending'),
      durationSeconds: (map['durationSeconds'] as num?)?.toDouble() ?? 0.0,
      bpm: (map['bpm'] as num?)?.toDouble() ?? 0.0,
      bpmConfidence: (map['bpmConfidence'] as num?)?.toDouble() ?? 0.0,
      keyValue: map['keyValue'] as String? ?? '',
      keyFormat: map['keyFormat'] as String? ?? 'camelot',
      keyConfidence: (map['keyConfidence'] as num?)?.toDouble() ?? 0.0,
      energyGlobal: map['energyGlobal'] as int? ?? 5,
      integratedLUFS: (map['integratedLUFS'] as num?)?.toDouble() ?? 0.0,
      truePeakDB: (map['truePeakDB'] as num?)?.toDouble() ?? 0.0,
      loudnessRange: (map['loudnessRange'] as num?)?.toDouble() ?? 0.0,
      waveformPreview: waveform,
      sections: sections,
      cuePoints: cuePoints,
      soundContext: map['soundContext'] as String?,
      soundContextConfidence:
          (map['soundContextConfidence'] as num?)?.toDouble(),
      qaFlags: qaFlags,
      hasOpenL3Embedding: map['hasOpenL3Embedding'] as bool? ?? false,
      trainingLabels: trainingLabels,
      createdAt: map['createdAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              ((map['createdAt'] as num) * 1000).round())
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              ((map['updatedAt'] as num) * 1000).round())
          : DateTime.now(),
    );
  }

  /// Convert to JSON map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'trackId': trackId,
      'version': version,
      'status': status.name,
      'durationSeconds': durationSeconds,
      'bpm': bpm,
      'bpmConfidence': bpmConfidence,
      'keyValue': keyValue,
      'keyFormat': keyFormat,
      'keyConfidence': keyConfidence,
      'energyGlobal': energyGlobal,
      'integratedLUFS': integratedLUFS,
      'truePeakDB': truePeakDB,
      'loudnessRange': loudnessRange,
      'waveformPreview': waveformPreview.toList(),
      'sections': sections.map((e) => e.toMap()).toList(),
      'cuePoints': cuePoints.map((e) => e.toMap()).toList(),
      'soundContext': soundContext,
      'soundContextConfidence': soundContextConfidence,
      'qaFlags': qaFlags.map((e) => e.toMap()).toList(),
      'hasOpenL3Embedding': hasOpenL3Embedding,
      'trainingLabels': trainingLabels.map((e) => e.toMap()).toList(),
      'createdAt': createdAt.millisecondsSinceEpoch / 1000,
      'updatedAt': updatedAt.millisecondsSinceEpoch / 1000,
    };
  }
}
