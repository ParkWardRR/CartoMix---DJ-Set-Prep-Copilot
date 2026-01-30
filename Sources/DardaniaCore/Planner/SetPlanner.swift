// Dardania - Set Planner
// Port of internal/planner/planner.go

import Foundation

/// Set planning modes
public enum SetMode: String, CaseIterable, Identifiable, Sendable {
    case warmUp = "warm_up"
    case peakTime = "peak_time"
    case openFormat = "open_format"

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .warmUp: return "Warm-up"
        case .peakTime: return "Peak Time"
        case .openFormat: return "Open Format"
        }
    }

    /// Energy progression preference for this mode
    var energyProgression: EnergyProgression {
        switch self {
        case .warmUp: return .gradualBuild
        case .peakTime: return .highMaintain
        case .openFormat: return .flexible
        }
    }
}

enum EnergyProgression: Sendable {
    case gradualBuild   // Energy should generally increase
    case highMaintain   // Keep energy high with controlled drops
    case flexible       // No strong energy preference
}

/// Result of set optimization
public struct SetPlanResult: Sendable {
    public let tracks: [Track]
    public let transitions: [TransitionPlan]
    public let totalScore: Double
    public let averageTransitionScore: Double
    public let energyFlow: [Int]
}

/// Planned transition between two tracks
public struct TransitionPlan: Sendable {
    public let fromTrack: Track
    public let toTrack: Track
    public let score: Double
    public let explanation: String
    public let bpmDelta: Double
    public let keyRelation: String
    public let energyDelta: Int
}

/// Set planner using weighted graph optimization
public actor SetPlanner {
    private let similarityScorer: SimilarityScorer
    private let database: DatabaseManager

    // Scoring weights
    private let weights = PlannerWeights()

    public init(database: DatabaseManager, similarityScorer: SimilarityScorer) {
        self.database = database
        self.similarityScorer = similarityScorer
    }

    // MARK: - Optimization

    /// Optimize track order for a set
    public func optimizeSet(
        tracks: [Track],
        mode: SetMode,
        startTrack: Track? = nil,
        endTrack: Track? = nil
    ) async -> SetPlanResult {
        guard tracks.count >= 2 else {
            return SetPlanResult(
                tracks: tracks,
                transitions: [],
                totalScore: 0,
                averageTransitionScore: 0,
                energyFlow: tracks.compactMap { $0.analysis?.energyGlobal }
            )
        }

        // Build transition graph
        let graph = await buildTransitionGraph(tracks: tracks, mode: mode)

        // Find optimal path using greedy algorithm with lookahead
        let optimizedOrder = findOptimalPath(
            graph: graph,
            tracks: tracks,
            mode: mode,
            startTrack: startTrack,
            endTrack: endTrack
        )

        // Generate transition plans
        let transitions = generateTransitionPlans(tracks: optimizedOrder, graph: graph)

        // Calculate scores
        let totalScore = transitions.reduce(0) { $0 + $1.score }
        let avgScore = transitions.isEmpty ? 0 : totalScore / Double(transitions.count)

        return SetPlanResult(
            tracks: optimizedOrder,
            transitions: transitions,
            totalScore: totalScore,
            averageTransitionScore: avgScore,
            energyFlow: optimizedOrder.compactMap { $0.analysis?.energyGlobal }
        )
    }

    /// Build weighted transition graph
    private func buildTransitionGraph(tracks: [Track], mode: SetMode) async -> TransitionGraph {
        var graph = TransitionGraph()

        for i in 0..<tracks.count {
            for j in 0..<tracks.count where i != j {
                let fromTrack = tracks[i]
                let toTrack = tracks[j]

                // Fetch embeddings for similarity
                let embeddingA = try? await database.fetchEmbedding(trackId: fromTrack.id)?.embedding
                let embeddingB = try? await database.fetchEmbedding(trackId: toTrack.id)?.embedding

                // Calculate transition score
                let score = calculateTransitionScore(
                    from: fromTrack,
                    to: toTrack,
                    embeddingA: embeddingA,
                    embeddingB: embeddingB,
                    mode: mode
                )

                graph.addEdge(from: fromTrack.id, to: toTrack.id, weight: score)
            }
        }

        return graph
    }

    /// Calculate transition score between two tracks
    private func calculateTransitionScore(
        from: Track,
        to: Track,
        embeddingA: [Float]?,
        embeddingB: [Float]?,
        mode: SetMode
    ) -> Double {
        guard let analysisA = from.analysis, let analysisB = to.analysis else {
            return 0
        }

        var score = 0.0

        // 1. BPM compatibility
        let bpmDelta = abs(analysisA.bpm - analysisB.bpm)
        let halfDoubleDelta = min(
            abs(analysisA.bpm - analysisB.bpm * 2),
            abs(analysisA.bpm * 2 - analysisB.bpm)
        )
        let effectiveBpmDelta = min(bpmDelta, halfDoubleDelta)

        if effectiveBpmDelta <= 2 {
            score += weights.bpmMatch * 1.0
        } else if effectiveBpmDelta <= 5 {
            score += weights.bpmMatch * 0.7
        } else if effectiveBpmDelta <= 10 {
            score += weights.bpmMatch * 0.3
        }

        // 2. Key compatibility (Camelot wheel)
        let (keySimilarity, _) = similarityScorer.keySimilarity(
            keyA: analysisA.keyValue,
            keyB: analysisB.keyValue
        )
        score += weights.keyMatch * keySimilarity

        // 3. OpenL3 vibe similarity
        if let a = embeddingA, let b = embeddingB {
            let vibeSimilarity = Double(similarityScorer.cosineSimilarity(a, b))
            score += weights.vibeSimilarity * vibeSimilarity
        }

        // 4. Energy flow (mode-dependent)
        let energyDelta = analysisB.energyGlobal - analysisA.energyGlobal

        switch mode.energyProgression {
        case .gradualBuild:
            // Prefer energy increases
            if energyDelta >= 0 && energyDelta <= 2 {
                score += weights.energyFlow * 1.0
            } else if energyDelta > 2 {
                score += weights.energyFlow * 0.5
            } else if energyDelta >= -1 {
                score += weights.energyFlow * 0.3
            }

        case .highMaintain:
            // Prefer high energy with occasional drops
            if abs(energyDelta) <= 1 && analysisB.energyGlobal >= 7 {
                score += weights.energyFlow * 1.0
            } else if energyDelta <= -2 && analysisA.energyGlobal >= 8 {
                // Strategic drop from peak
                score += weights.energyFlow * 0.8
            }

        case .flexible:
            // Slight preference for smooth transitions
            if abs(energyDelta) <= 2 {
                score += weights.energyFlow * 1.0
            } else {
                score += weights.energyFlow * 0.5
            }
        }

        return score
    }

    /// Find optimal path through transition graph
    private func findOptimalPath(
        graph: TransitionGraph,
        tracks: [Track],
        mode: SetMode,
        startTrack: Track?,
        endTrack: Track?
    ) -> [Track] {
        guard !tracks.isEmpty else { return [] }

        var remaining = Set(tracks.map { $0.id })
        var result: [Track] = []
        let trackMap = Dictionary(uniqueKeysWithValues: tracks.map { ($0.id, $0) })

        // Start with specified track or best starting track
        let firstId: Int64
        if let start = startTrack {
            firstId = start.id
        } else {
            // For warm-up, start with lowest energy; for peak-time, start mid-high
            switch mode {
            case .warmUp:
                firstId = tracks.min(by: { ($0.analysis?.energyGlobal ?? 0) < ($1.analysis?.energyGlobal ?? 0) })?.id ?? tracks[0].id
            case .peakTime:
                firstId = tracks.sorted(by: { ($0.analysis?.energyGlobal ?? 0) > ($1.analysis?.energyGlobal ?? 0) })[tracks.count / 3].id
            case .openFormat:
                firstId = tracks[0].id
            }
        }

        remaining.remove(firstId)
        result.append(trackMap[firstId]!)

        // Greedy selection with 2-step lookahead
        while !remaining.isEmpty {
            let currentId = result.last!.id

            // If we need to end with a specific track and it's our last choice
            if let endId = endTrack?.id, remaining.count == 1 && remaining.contains(endId) {
                result.append(trackMap[endId]!)
                break
            }

            // Find best next track
            var bestNextId: Int64?
            var bestScore = -Double.infinity

            for candidateId in remaining {
                // Skip end track unless it's our last option
                if let endId = endTrack?.id, candidateId == endId && remaining.count > 1 {
                    continue
                }

                let immediateScore = graph.weight(from: currentId, to: candidateId)

                // Lookahead: consider best transition from candidate
                var lookaheadBonus = 0.0
                let futureRemaining = remaining.subtracting([candidateId])

                if !futureRemaining.isEmpty {
                    let bestFutureScore = futureRemaining
                        .map { graph.weight(from: candidateId, to: $0) }
                        .max() ?? 0

                    lookaheadBonus = bestFutureScore * 0.3 // Weight lookahead at 30%
                }

                let totalScore = immediateScore + lookaheadBonus

                if totalScore > bestScore {
                    bestScore = totalScore
                    bestNextId = candidateId
                }
            }

            if let nextId = bestNextId {
                remaining.remove(nextId)
                result.append(trackMap[nextId]!)
            } else {
                break
            }
        }

        return result
    }

    /// Generate transition plans for optimized order
    private func generateTransitionPlans(tracks: [Track], graph: TransitionGraph) -> [TransitionPlan] {
        guard tracks.count >= 2 else { return [] }

        var plans: [TransitionPlan] = []

        for i in 0..<(tracks.count - 1) {
            let fromTrack = tracks[i]
            let toTrack = tracks[i + 1]

            guard let analysisA = fromTrack.analysis, let analysisB = toTrack.analysis else {
                continue
            }

            let bpmDelta = analysisB.bpm - analysisA.bpm
            let energyDelta = analysisB.energyGlobal - analysisA.energyGlobal
            let (_, keyRelation) = similarityScorer.keySimilarity(
                keyA: analysisA.keyValue,
                keyB: analysisB.keyValue
            )

            // Generate explanation
            var parts: [String] = []

            if abs(bpmDelta) < 1 {
                parts.append("tempo match")
            } else {
                let sign = bpmDelta >= 0 ? "+" : ""
                parts.append("Δ\(sign)\(String(format: "%.1f", bpmDelta)) BPM")
            }

            parts.append("key: \(analysisA.keyValue)→\(analysisB.keyValue) (\(keyRelation))")

            if energyDelta != 0 {
                let sign = energyDelta > 0 ? "+" : ""
                parts.append("energy \(sign)\(energyDelta)")
            }

            plans.append(TransitionPlan(
                fromTrack: fromTrack,
                toTrack: toTrack,
                score: graph.weight(from: fromTrack.id, to: toTrack.id),
                explanation: parts.joined(separator: "; "),
                bpmDelta: bpmDelta,
                keyRelation: keyRelation,
                energyDelta: energyDelta
            ))
        }

        return plans
    }
}

// MARK: - Transition Graph

struct TransitionGraph: Sendable {
    private var edges: [Int64: [Int64: Double]] = [:]

    mutating func addEdge(from: Int64, to: Int64, weight: Double) {
        if edges[from] == nil {
            edges[from] = [:]
        }
        edges[from]![to] = weight
    }

    func weight(from: Int64, to: Int64) -> Double {
        edges[from]?[to] ?? 0
    }
}

// MARK: - Planner Weights

struct PlannerWeights: Sendable {
    let bpmMatch: Double = 0.25
    let keyMatch: Double = 0.25
    let vibeSimilarity: Double = 0.30
    let energyFlow: Double = 0.20
}
