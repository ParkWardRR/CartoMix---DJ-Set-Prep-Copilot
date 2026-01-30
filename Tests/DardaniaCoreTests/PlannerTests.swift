// Dardania - Set Planner Tests

import Testing
import Foundation
@testable import DardaniaCore

@Suite("Set Planner Tests")
struct PlannerTests {

    // MARK: - Helper: Create Test Tracks

    func makeTrack(id: Int64, bpm: Double, key: String, energy: Int) -> Track {
        var track = Track(
            id: id,
            contentHash: "hash\(id)",
            path: "/test/track\(id).mp3",
            title: "Track \(id)",
            artist: "Artist",
            fileSize: 10_000_000,
            fileModifiedAt: Date()
        )

        // Create mock analysis
        track.analysis = TrackAnalysis(
            id: id,
            trackId: id,
            version: 1,
            status: .complete,
            durationSeconds: 300,
            bpm: bpm,
            bpmConfidence: 1.0,
            keyValue: key,
            keyFormat: "camelot",
            keyConfidence: 1.0,
            energyGlobal: energy,
            integratedLUFS: -14.0,
            truePeakDB: -1.0,
            loudnessRange: 6.0,
            waveformPreview: [],
            sections: [],
            cuePoints: [],
            soundContext: "music",
            soundContextConfidence: 0.95,
            qaFlags: [],
            hasOpenL3Embedding: false,
            trainingLabels: [],
            createdAt: Date(),
            updatedAt: Date()
        )

        return track
    }

    // MARK: - Optimization Tests

    @Test("Empty set should return empty result")
    func optimizeSetEmpty() async throws {
        let database = DatabaseManager.shared
        let scorer = SimilarityScorer(database: database)
        let planner = SetPlanner(database: database, similarityScorer: scorer)

        let result = await planner.optimizeSet(tracks: [], mode: .peakTime)

        #expect(result.tracks.isEmpty)
        #expect(result.transitions.isEmpty)
        #expect(result.totalScore == 0)
    }

    @Test("Single track should return single track with no transitions")
    func optimizeSetSingleTrack() async throws {
        let database = DatabaseManager.shared
        let scorer = SimilarityScorer(database: database)
        let planner = SetPlanner(database: database, similarityScorer: scorer)

        let track = makeTrack(id: 1, bpm: 128, key: "8A", energy: 7)
        let result = await planner.optimizeSet(tracks: [track], mode: .peakTime)

        #expect(result.tracks.count == 1)
        #expect(result.transitions.isEmpty)
    }

    @Test("Should prefer BPM match")
    func optimizeSetPrefersBPMMatch() async throws {
        let database = DatabaseManager.shared
        let scorer = SimilarityScorer(database: database)
        let planner = SetPlanner(database: database, similarityScorer: scorer)

        // Track 1: 128 BPM
        // Track 2: 128 BPM (matches)
        // Track 3: 140 BPM (doesn't match)
        let track1 = makeTrack(id: 1, bpm: 128, key: "8A", energy: 5)
        let track2 = makeTrack(id: 2, bpm: 128, key: "8A", energy: 6)
        let track3 = makeTrack(id: 3, bpm: 140, key: "8A", energy: 7)

        let result = await planner.optimizeSet(
            tracks: [track1, track2, track3],
            mode: .peakTime,
            startTrack: track1
        )

        // After track1, track2 should come before track3 due to BPM match
        #expect(result.tracks[0].id == track1.id)
        #expect(result.tracks[1].id == track2.id)
    }

    @Test("Should prefer key match")
    func optimizeSetPrefersKeyMatch() async throws {
        let database = DatabaseManager.shared
        let scorer = SimilarityScorer(database: database)
        let planner = SetPlanner(database: database, similarityScorer: scorer)

        // Track 1: 8A
        // Track 2: 8A (same key)
        // Track 3: 3B (clash)
        let track1 = makeTrack(id: 1, bpm: 128, key: "8A", energy: 5)
        let track2 = makeTrack(id: 2, bpm: 128, key: "8A", energy: 6)
        let track3 = makeTrack(id: 3, bpm: 128, key: "3B", energy: 7)

        let result = await planner.optimizeSet(
            tracks: [track1, track2, track3],
            mode: .peakTime,
            startTrack: track1
        )

        // After track1, track2 should come before track3 due to key match
        #expect(result.tracks[0].id == track1.id)
        #expect(result.tracks[1].id == track2.id)
    }

    @Test("Warm-up mode should prefer energy build")
    func optimizeSetWarmUpPrefersEnergyBuild() async throws {
        let database = DatabaseManager.shared
        let scorer = SimilarityScorer(database: database)
        let planner = SetPlanner(database: database, similarityScorer: scorer)

        // Create tracks with different energies
        let track1 = makeTrack(id: 1, bpm: 128, key: "8A", energy: 3)  // Low
        let track2 = makeTrack(id: 2, bpm: 128, key: "8A", energy: 5)  // Medium
        let track3 = makeTrack(id: 3, bpm: 128, key: "8A", energy: 8)  // High

        let result = await planner.optimizeSet(
            tracks: [track3, track1, track2],  // Scrambled order
            mode: .warmUp
        )

        // Warm-up mode should start with lowest energy
        #expect(result.tracks[0].id == track1.id)  // Energy 3

        // Should build energy gradually
        let energyFlow = result.energyFlow
        #expect(energyFlow[0] <= energyFlow[1], "Energy should increase")
    }

    @Test("Should respect start track")
    func optimizeSetRespectsStartTrack() async throws {
        let database = DatabaseManager.shared
        let scorer = SimilarityScorer(database: database)
        let planner = SetPlanner(database: database, similarityScorer: scorer)

        let track1 = makeTrack(id: 1, bpm: 128, key: "8A", energy: 5)
        let track2 = makeTrack(id: 2, bpm: 130, key: "9A", energy: 6)
        let track3 = makeTrack(id: 3, bpm: 125, key: "7A", energy: 7)

        let result = await planner.optimizeSet(
            tracks: [track1, track2, track3],
            mode: .peakTime,
            startTrack: track3  // Force start with track3
        )

        #expect(result.tracks.first?.id == track3.id)
    }

    @Test("Should respect end track")
    func optimizeSetRespectsEndTrack() async throws {
        let database = DatabaseManager.shared
        let scorer = SimilarityScorer(database: database)
        let planner = SetPlanner(database: database, similarityScorer: scorer)

        let track1 = makeTrack(id: 1, bpm: 128, key: "8A", energy: 5)
        let track2 = makeTrack(id: 2, bpm: 130, key: "9A", energy: 6)
        let track3 = makeTrack(id: 3, bpm: 125, key: "7A", energy: 7)

        let result = await planner.optimizeSet(
            tracks: [track1, track2, track3],
            mode: .peakTime,
            endTrack: track1  // Force end with track1
        )

        #expect(result.tracks.last?.id == track1.id)
    }

    // MARK: - Transition Plan Tests

    @Test("Should generate transition plans")
    func transitionPlanGeneration() async throws {
        let database = DatabaseManager.shared
        let scorer = SimilarityScorer(database: database)
        let planner = SetPlanner(database: database, similarityScorer: scorer)

        let track1 = makeTrack(id: 1, bpm: 128, key: "8A", energy: 5)
        let track2 = makeTrack(id: 2, bpm: 130, key: "9A", energy: 7)

        let result = await planner.optimizeSet(
            tracks: [track1, track2],
            mode: .peakTime,
            startTrack: track1
        )

        #expect(result.transitions.count == 1)

        let transition = result.transitions[0]
        #expect(transition.fromTrack.id == track1.id)
        #expect(transition.toTrack.id == track2.id)
        #expect(abs(transition.bpmDelta - 2.0) < 0.001)
        #expect(transition.energyDelta == 2)
        #expect(transition.keyRelation == "compatible")
    }

    // MARK: - Property Tests

    @Test("All tracks should be included in result")
    func monotonicityAllTracksIncluded() async throws {
        let database = DatabaseManager.shared
        let scorer = SimilarityScorer(database: database)
        let planner = SetPlanner(database: database, similarityScorer: scorer)

        // Create random tracks
        var tracks: [Track] = []
        for i in 1...10 {
            let bpm = Double.random(in: 120...140)
            let key = "\(Int.random(in: 1...12))\(Bool.random() ? "A" : "B")"
            let energy = Int.random(in: 1...10)
            tracks.append(makeTrack(id: Int64(i), bpm: bpm, key: key, energy: energy))
        }

        let result = await planner.optimizeSet(tracks: tracks, mode: .peakTime)

        // All tracks should be in the result
        #expect(result.tracks.count == tracks.count)

        // All original track IDs should be present
        let resultIds = Set(result.tracks.map { $0.id })
        let originalIds = Set(tracks.map { $0.id })
        #expect(resultIds == originalIds)
    }

    @Test("Transition count should be n-1 for n tracks")
    func monotonicityTransitionCountCorrect() async throws {
        let database = DatabaseManager.shared
        let scorer = SimilarityScorer(database: database)
        let planner = SetPlanner(database: database, similarityScorer: scorer)

        // Create 5 tracks
        var tracks: [Track] = []
        for i in 1...5 {
            tracks.append(makeTrack(id: Int64(i), bpm: 128, key: "8A", energy: 5))
        }

        let result = await planner.optimizeSet(tracks: tracks, mode: .peakTime)

        // n tracks should have n-1 transitions
        #expect(result.transitions.count == tracks.count - 1)
    }
}
