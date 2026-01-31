/// Represents a similarity relationship between two tracks
class TrackSimilarity {
  final int trackIdA;
  final int trackIdB;
  final double score; // 0.0 to 10.0

  const TrackSimilarity({
    required this.trackIdA,
    required this.trackIdB,
    required this.score,
  });

  /// Returns the other track ID given one of the tracks
  int otherTrackId(int trackId) {
    if (trackId == trackIdA) return trackIdB;
    if (trackId == trackIdB) return trackIdA;
    throw ArgumentError('Track $trackId is not part of this similarity');
  }

  /// Check if this similarity involves a given track
  bool involvesTrack(int trackId) =>
      trackIdA == trackId || trackIdB == trackId;

  /// Create from JSON map
  factory TrackSimilarity.fromMap(Map<String, dynamic> map) {
    return TrackSimilarity(
      trackIdA: map['trackIdA'] as int,
      trackIdB: map['trackIdB'] as int,
      score: (map['score'] as num).toDouble(),
    );
  }

  /// Convert to JSON map
  Map<String, dynamic> toMap() {
    return {
      'trackIdA': trackIdA,
      'trackIdB': trackIdB,
      'score': score,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TrackSimilarity &&
        ((other.trackIdA == trackIdA && other.trackIdB == trackIdB) ||
            (other.trackIdA == trackIdB && other.trackIdB == trackIdA));
  }

  @override
  int get hashCode {
    // Order-independent hash
    final ids = [trackIdA, trackIdB]..sort();
    return Object.hash(ids[0], ids[1]);
  }

  @override
  String toString() =>
      'TrackSimilarity(trackIdA: $trackIdA, trackIdB: $trackIdB, score: $score)';
}
