import 'package:flutter/material.dart';
import '../core/theme/colors.dart';
import 'enums.dart';

/// Represents a cue point marker in a track
class CuePoint {
  final int index;
  final String label;
  final CueType type;
  final double timeSeconds;
  final int? beatIndex;

  const CuePoint({
    required this.index,
    required this.label,
    required this.type,
    required this.timeSeconds,
    this.beatIndex,
  });

  /// Color for this cue point type
  Color get color {
    switch (type) {
      case CueType.intro:
        return CartoMixColors.sectionIntro;
      case CueType.drop:
        return CartoMixColors.sectionDrop;
      case CueType.build:
        return CartoMixColors.sectionBuild;
      case CueType.breakdown:
        return CartoMixColors.sectionBreakdown;
      case CueType.outro:
        return CartoMixColors.sectionOutro;
      case CueType.custom:
        return CartoMixColors.textSecondary;
    }
  }

  /// Create from JSON map
  factory CuePoint.fromMap(Map<String, dynamic> map) {
    return CuePoint(
      index: map['index'] as int? ?? 0,
      label: map['label'] as String? ?? '',
      type: CueType.fromString(map['type'] as String? ?? 'custom'),
      timeSeconds: (map['timeSeconds'] as num?)?.toDouble() ?? 0.0,
      beatIndex: map['beatIndex'] as int?,
    );
  }

  /// Convert to JSON map
  Map<String, dynamic> toMap() {
    return {
      'index': index,
      'label': label,
      'type': type.name,
      'timeSeconds': timeSeconds,
      if (beatIndex != null) 'beatIndex': beatIndex,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CuePoint &&
        other.index == index &&
        other.type == type &&
        other.timeSeconds == timeSeconds;
  }

  @override
  int get hashCode => Object.hash(index, type, timeSeconds);

  @override
  String toString() =>
      'CuePoint($index: $label @ ${timeSeconds.toStringAsFixed(1)}s)';
}
