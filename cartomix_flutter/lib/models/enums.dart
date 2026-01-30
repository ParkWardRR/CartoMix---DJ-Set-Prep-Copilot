/// Analysis status for tracks
enum AnalysisStatus {
  pending,
  analyzing,
  complete,
  failed;

  static AnalysisStatus fromString(String value) {
    return AnalysisStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => AnalysisStatus.pending,
    );
  }
}

/// Section types for track structure
enum SectionType {
  intro,
  verse,
  build,
  drop,
  breakdown,
  chorus,
  outro;

  String get displayName => name[0].toUpperCase() + name.substring(1);

  static SectionType fromString(String value) {
    return SectionType.values.firstWhere(
      (e) => e.name == value.toLowerCase(),
      orElse: () => SectionType.verse,
    );
  }
}

/// Cue point types
enum CueType {
  intro,
  drop,
  build,
  breakdown,
  outro,
  custom;

  static CueType fromString(String value) {
    return CueType.values.firstWhere(
      (e) => e.name == value.toLowerCase(),
      orElse: () => CueType.custom,
    );
  }
}

/// QA flag types for quality assurance
enum QAFlagType {
  needsReview('needs_review'),
  mixedContent('mixed_content'),
  speechDetected('speech_detected'),
  lowConfidence('low_confidence');

  final String rawValue;
  const QAFlagType(this.rawValue);

  static QAFlagType fromString(String value) {
    return QAFlagType.values.firstWhere(
      (e) => e.rawValue == value || e.name == value,
      orElse: () => QAFlagType.needsReview,
    );
  }
}

/// Section labels for training
enum SectionLabel {
  intro,
  build,
  drop,
  breakdown('break'),
  outro,
  verse,
  chorus;

  final String? rawValue;
  const SectionLabel([this.rawValue]);

  String get value => rawValue ?? name;

  static SectionLabel fromString(String value) {
    return SectionLabel.values.firstWhere(
      (e) => e.value == value || e.name == value,
      orElse: () => SectionLabel.verse,
    );
  }
}

/// Analysis progress stages
enum AnalysisStage {
  decoding,
  beatgrid,
  key,
  energy,
  loudness,
  sections,
  embedding,
  cues,
  complete,
  failed;

  static AnalysisStage fromString(String value) {
    return AnalysisStage.values.firstWhere(
      (e) => e.name == value.toLowerCase(),
      orElse: () => AnalysisStage.decoding,
    );
  }
}

/// Set planning modes
enum SetMode {
  warmup('Warm-up'),
  peakTime('Peak Time'),
  openFormat('Open Format');

  final String displayName;
  const SetMode(this.displayName);

  static SetMode fromString(String value) {
    return SetMode.values.firstWhere(
      (e) => e.name == value || e.displayName == value,
      orElse: () => SetMode.peakTime,
    );
  }
}

/// Export formats
enum ExportFormat {
  rekordbox('Rekordbox XML'),
  serato('Serato Crate'),
  traktor('Traktor NML'),
  json('JSON'),
  m3u('M3U Playlist'),
  csv('CSV');

  final String displayName;
  const ExportFormat(this.displayName);
}
