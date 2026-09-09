import XCTest
@testable import SwingPro

final class SwingFeedbackEngineTests: XCTestCase {
    func testValueWithinRangeProducesNoFeedback() {
        let range = SwingReferenceRange(
            id: "r1", shotType: .fullSwing, cameraView: .faceOn,
            segmentType: .p4, metricName: "shoulder_rotation", idealMin: 80, idealMax: 95
        )
        let engine = SwingFeedbackEngine(referenceRangeProvider: SwingReferenceRangeProvider(ranges: [range]))

        let segment = PoseSegment(
            id: "s1", clipId: "c1", segmentType: .p4, timestampInVideo: 1.0,
            angleSummary: AngleSummary(metrics: ["shoulder_rotation": 88])
        )

        let feedback = engine.generateFeedback(
            clipId: "c1", shotType: .fullSwing, cameraView: .faceOn, poseSegments: [segment]
        )

        XCTAssertTrue(feedback.isEmpty)
    }

    func testValueBelowRangeProducesFeedback() {
        let range = SwingReferenceRange(
            id: "r1", shotType: .fullSwing, cameraView: .faceOn,
            segmentType: .p4, metricName: "shoulder_rotation", idealMin: 80, idealMax: 95
        )
        let engine = SwingFeedbackEngine(referenceRangeProvider: SwingReferenceRangeProvider(ranges: [range]))

        let segment = PoseSegment(
            id: "s1", clipId: "c1", segmentType: .p4, timestampInVideo: 1.0,
            angleSummary: AngleSummary(metrics: ["shoulder_rotation": 50])
        )

        let feedback = engine.generateFeedback(
            clipId: "c1", shotType: .fullSwing, cameraView: .faceOn, poseSegments: [segment]
        )

        XCTAssertEqual(feedback.count, 1)
        XCTAssertEqual(feedback.first?.deviationItem, "P4 shoulder_rotation")
        XCTAssertTrue(feedback.first?.message.contains("부족") ?? false)
    }

    func testSmallDeviationWithinToleranceProducesNoFeedback() {
        let range = SwingReferenceRange(
            id: "r1", shotType: .fullSwing, cameraView: .faceOn,
            segmentType: .p4, metricName: "shoulder_rotation", idealMin: 80, idealMax: 95
        )
        let engine = SwingFeedbackEngine(referenceRangeProvider: SwingReferenceRangeProvider(ranges: [range]))

        let segment = PoseSegment(
            id: "s1", clipId: "c1", segmentType: .p4, timestampInVideo: 1.0,
            angleSummary: AngleSummary(metrics: ["shoulder_rotation": 97])
        )

        let feedback = engine.generateFeedback(
            clipId: "c1", shotType: .fullSwing, cameraView: .faceOn, poseSegments: [segment]
        )

        XCTAssertTrue(feedback.isEmpty)
    }
}
