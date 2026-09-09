import XCTest
import CoreGraphics
@testable import SwingPro

final class SwingPhaseDetectorTests: XCTestCase {
    private func frame(timestamp: TimeInterval, wristY: CGFloat) -> PoseFrame {
        PoseFrame(
            timestamp: timestamp,
            joints: [.leftWrist: CGPoint(x: 0.5, y: wristY)],
            confidences: [.leftWrist: 1.0]
        )
    }

    func testStableWristTriggersAddressCheckpoint() {
        let detector = SwingPhaseDetector(addressStabilityWindow: 0.4, addressStabilityThreshold: 0.03)

        var allEvents: [SwingPhaseEvent] = []
        for i in 0...5 {
            let timestamp = Double(i) * 0.1
            allEvents += detector.ingest(frame(timestamp: timestamp, wristY: 0.5))
        }

        XCTAssertTrue(allEvents.contains(.checkpointReached(.p1, timestamp: 0.4)))
    }

    func testWristRisingAfterAddressTriggersSwingStart() {
        let detector = SwingPhaseDetector(addressStabilityWindow: 0.4, addressStabilityThreshold: 0.03)

        var allEvents: [SwingPhaseEvent] = []
        for i in 0...5 {
            allEvents += detector.ingest(frame(timestamp: Double(i) * 0.1, wristY: 0.5))
        }
        // 손목이 위로 올라감 (이미지 좌표계는 y가 작을수록 위쪽)
        allEvents += detector.ingest(frame(timestamp: 0.6, wristY: 0.3))

        XCTAssertTrue(allEvents.contains(.swingStarted(timestamp: 0.6)))
        XCTAssertTrue(allEvents.contains(.checkpointReached(.p2, timestamp: 0.6)))
    }

    func testNoWristJointProducesNoEvents() {
        let detector = SwingPhaseDetector()
        let emptyFrame = PoseFrame(timestamp: 0, joints: [:], confidences: [:])

        XCTAssertTrue(detector.ingest(emptyFrame).isEmpty)
    }
}
