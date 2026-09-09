import XCTest
@testable import SwingPro

final class SwingScorerTests: XCTestCase {
    private func makeRange(segment: SwingCheckpoint, metric: String, min: Double, max: Double) -> SwingReferenceRange {
        SwingReferenceRange(
            id: UUID().uuidString,
            shotType: .fullSwing,
            cameraView: .faceOn,
            segmentType: segment,
            metricName: metric,
            idealMin: min,
            idealMax: max
        )
    }

    private func makeSegment(_ segment: SwingCheckpoint, metrics: [String: Double]) -> PoseSegment {
        PoseSegment(
            id: UUID().uuidString,
            clipId: "clip-1",
            segmentType: segment,
            timestampInVideo: 0,
            angleSummary: AngleSummary(metrics: metrics)
        )
    }

    func testPerfectMatchScoresOneHundred() {
        let provider = SwingReferenceRangeProvider(ranges: [
            makeRange(segment: .p4, metric: "shoulder_rotation", min: 80, max: 95),
        ])
        let scorer = SwingScorer(referenceRangeProvider: provider)

        let score = scorer.score(
            shotType: .fullSwing,
            cameraView: .faceOn,
            poseSegments: [makeSegment(.p4, metrics: ["shoulder_rotation": 88])]
        )

        XCTAssertEqual(score, 100)
    }

    func testLargeDeviationScoresNearZero() {
        let provider = SwingReferenceRangeProvider(ranges: [
            makeRange(segment: .p7, metric: "hip_rotation", min: 35, max: 45),
        ])
        let scorer = SwingScorer(referenceRangeProvider: provider)

        let score = scorer.score(
            shotType: .fullSwing,
            cameraView: .faceOn,
            poseSegments: [makeSegment(.p7, metrics: ["hip_rotation": 90])]
        )

        XCTAssertEqual(score, 0)
    }

    func testNoMatchingReferenceReturnsZero() {
        let provider = SwingReferenceRangeProvider(ranges: [])
        let scorer = SwingScorer(referenceRangeProvider: provider)

        let score = scorer.score(
            shotType: .fullSwing,
            cameraView: .faceOn,
            poseSegments: [makeSegment(.p1, metrics: ["shoulder_rotation": 5])]
        )

        XCTAssertEqual(score, 0)
    }
}
