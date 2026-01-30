import 'package:flutter/material.dart';
import '../core/theme/colors.dart';
import 'enums.dart';

/// Represents a structural section within a track (intro, verse, drop, etc.)
class TrackSection {
  final String id;
  final SectionType type;
  final double startTime;
  final double endTime;
  final double confidence;

  const TrackSection({
    required this.id,
    required this.type,
    required this.startTime,
    required this.endTime,
    this.confidence = 1.0,
  });

  /// Duration of the section in seconds
  double get duration => endTime - startTime;

  /// Color for this section type
  Color get color => CartoMixColors.colorForSection(type.name);

  /// Create from JSON map
  factory TrackSection.fromMap(Map<String, dynamic> map) {
    return TrackSection(
      id: map['id'] as String? ?? '',
      type: SectionType.fromString(map['type'] as String? ?? 'verse'),
      startTime: (map['startTime'] as num?)?.toDouble() ?? 0.0,
      endTime: (map['endTime'] as num?)?.toDouble() ?? 0.0,
      confidence: (map['confidence'] as num?)?.toDouble() ?? 1.0,
    );
  }

  /// Convert to JSON map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.name,
      'startTime': startTime,
      'endTime': endTime,
      'confidence': confidence,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TrackSection &&
        other.id == id &&
        other.type == type &&
        other.startTime == startTime &&
        other.endTime == endTime;
  }

  @override
  int get hashCode => Object.hash(id, type, startTime, endTime);

  @override
  String toString() =>
      'TrackSection(type: $type, ${startTime.toStringAsFixed(1)}s - ${endTime.toStringAsFixed(1)}s)';
}
