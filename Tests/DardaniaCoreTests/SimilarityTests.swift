// Dardania - Similarity Scoring Tests

import Testing
@testable import DardaniaCore

@Suite("Similarity Scoring Tests")
struct SimilarityTests {

    // MARK: - Cosine Similarity Tests

    @Test("Identical vectors should have similarity 1.0")
    func cosineSimilarityIdenticalVectors() async throws {
        let scorer = SimilarityScorer(database: DatabaseManager.shared)
        let vector = [Float](repeating: 1.0, count: 512)

        // cosineSimilarity is nonisolated, no await needed
        let similarity = scorer.cosineSimilarity(vector, vector)

        #expect(abs(similarity - 1.0) < 0.001)
    }

    @Test("Orthogonal vectors should have similarity 0.5")
    func cosineSimilarityOrthogonalVectors() async throws {
        let scorer = SimilarityScorer(database: DatabaseManager.shared)

        // Create orthogonal vectors
        var vectorA = [Float](repeating: 0, count: 512)
        var vectorB = [Float](repeating: 0, count: 512)

        for i in 0..<256 {
            vectorA[i] = 1.0
        }
        for i in 256..<512 {
            vectorB[i] = 1.0
        }

        let similarity = scorer.cosineSimilarity(vectorA, vectorB)

        // Orthogonal vectors have cosine similarity of 0, normalized to 0.5
        #expect(abs(similarity - 0.5) < 0.001)
    }

    @Test("Opposite vectors should have similarity 0.0")
    func cosineSimilarityOppositeVectors() async throws {
        let scorer = SimilarityScorer(database: DatabaseManager.shared)
        let vectorA = [Float](repeating: 1.0, count: 512)
        let vectorB = [Float](repeating: -1.0, count: 512)

        let similarity = scorer.cosineSimilarity(vectorA, vectorB)

        // Opposite vectors have cosine similarity of -1, normalized to 0
        #expect(abs(similarity - 0.0) < 0.001)
    }

    // MARK: - Tempo Similarity Tests

    @Test("Exact BPM match should have similarity 1.0")
    func tempoSimilarityExactMatch() async throws {
        let scorer = SimilarityScorer(database: DatabaseManager.shared)

        // tempoSimilarity is actor-isolated, needs await
        let similarity = await scorer.tempoSimilarity(bpmA: 128.0, bpmB: 128.0)

        #expect(similarity == 1.0)
    }

    @Test("BPM within 1 should have similarity 1.0")
    func tempoSimilarityWithinOneBPM() async throws {
        let scorer = SimilarityScorer(database: DatabaseManager.shared)

        let similarity = await scorer.tempoSimilarity(bpmA: 128.0, bpmB: 128.5)

        #expect(similarity == 1.0)
    }

    @Test("5 BPM difference should have similarity 0.5")
    func tempoSimilarityFiveBPMDiff() async throws {
        let scorer = SimilarityScorer(database: DatabaseManager.shared)

        let similarity = await scorer.tempoSimilarity(bpmA: 128.0, bpmB: 133.0)

        #expect(abs(similarity - 0.5) < 0.001)
    }

    @Test("10 BPM difference should have similarity 0.0")
    func tempoSimilarityTenBPMDiff() async throws {
        let scorer = SimilarityScorer(database: DatabaseManager.shared)

        let similarity = await scorer.tempoSimilarity(bpmA: 128.0, bpmB: 138.0)

        #expect(similarity == 0.0)
    }

    @Test("Half tempo should match")
    func tempoSimilarityHalfTempo() async throws {
        let scorer = SimilarityScorer(database: DatabaseManager.shared)

        // Half tempo should match (64 BPM ≈ 128 BPM)
        let similarity = await scorer.tempoSimilarity(bpmA: 128.0, bpmB: 64.0)

        #expect(similarity == 1.0)
    }

    @Test("Double tempo should match")
    func tempoSimilarityDoubleTempo() async throws {
        let scorer = SimilarityScorer(database: DatabaseManager.shared)

        // Double tempo should match (128 BPM ≈ 256 BPM)
        let similarity = await scorer.tempoSimilarity(bpmA: 128.0, bpmB: 256.0)

        #expect(similarity == 1.0)
    }

    // MARK: - Key Similarity Tests

    @Test("Same key should have similarity 1.0")
    func keySimilaritySameKey() async throws {
        let scorer = SimilarityScorer(database: DatabaseManager.shared)

        // keySimilarity is nonisolated, no await needed
        let (similarity, relation) = scorer.keySimilarity(keyA: "8A", keyB: "8A")

        #expect(similarity == 1.0)
        #expect(relation == "same")
    }

    @Test("Relative key should have similarity 0.9")
    func keySimilarityRelativeKey() async throws {
        let scorer = SimilarityScorer(database: DatabaseManager.shared)

        // Same number, different mode = relative major/minor
        let (similarity, relation) = scorer.keySimilarity(keyA: "8A", keyB: "8B")

        #expect(abs(similarity - 0.9) < 0.001)
        #expect(relation == "relative")
    }

    @Test("Compatible key (+1) should have similarity 0.85")
    func keySimilarityCompatibleKey() async throws {
        let scorer = SimilarityScorer(database: DatabaseManager.shared)

        // Adjacent on wheel (+1)
        let (similarity, relation) = scorer.keySimilarity(keyA: "8A", keyB: "9A")

        #expect(abs(similarity - 0.85) < 0.001)
        #expect(relation == "compatible")
    }

    @Test("Compatible key (-1) should have similarity 0.85")
    func keySimilarityCompatibleKeyMinus() async throws {
        let scorer = SimilarityScorer(database: DatabaseManager.shared)

        // Adjacent on wheel (-1)
        let (similarity, relation) = scorer.keySimilarity(keyA: "8A", keyB: "7A")

        #expect(abs(similarity - 0.85) < 0.001)
        #expect(relation == "compatible")
    }

    @Test("Key wrap-around (12A to 1A) should be compatible")
    func keySimilarityWrapAround() async throws {
        let scorer = SimilarityScorer(database: DatabaseManager.shared)

        // 12A -> 1A should be compatible (wrap around)
        let (similarity, relation) = scorer.keySimilarity(keyA: "12A", keyB: "1A")

        #expect(abs(similarity - 0.85) < 0.001)
        #expect(relation == "compatible")
    }

    @Test("Distant keys should clash")
    func keySimilarityClash() async throws {
        let scorer = SimilarityScorer(database: DatabaseManager.shared)

        // Distant keys should clash
        let (similarity, relation) = scorer.keySimilarity(keyA: "8A", keyB: "3B")

        #expect(abs(similarity - 0.2) < 0.001)
        #expect(relation == "clash")
    }

    // MARK: - Energy Similarity Tests

    @Test("Same energy level should have similarity 1.0")
    func energySimilaritySameLevel() async throws {
        let scorer = SimilarityScorer(database: DatabaseManager.shared)

        // energySimilarity is actor-isolated, needs await
        let similarity = await scorer.energySimilarity(energyA: 7, energyB: 7)

        #expect(similarity == 1.0)
    }

    @Test("One level difference should have similarity 0.9")
    func energySimilarityOneLevelDiff() async throws {
        let scorer = SimilarityScorer(database: DatabaseManager.shared)

        let similarity = await scorer.energySimilarity(energyA: 7, energyB: 8)

        #expect(abs(similarity - 0.9) < 0.001)
    }

    @Test("Five level difference should have similarity 0.5")
    func energySimilarityFiveLevelDiff() async throws {
        let scorer = SimilarityScorer(database: DatabaseManager.shared)

        let similarity = await scorer.energySimilarity(energyA: 3, energyB: 8)

        #expect(abs(similarity - 0.5) < 0.001)
    }

    @Test("Max energy difference should have similarity 0.1")
    func energySimilarityMaxDiff() async throws {
        let scorer = SimilarityScorer(database: DatabaseManager.shared)

        let similarity = await scorer.energySimilarity(energyA: 1, energyB: 10)

        #expect(abs(similarity - 0.1) < 0.001)
    }
}
