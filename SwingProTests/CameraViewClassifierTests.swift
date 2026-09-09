import XCTest
import CoreGraphics
@testable import SwingPro

final class CameraViewClassifierTests: XCTestCase {
    private func addressFrame(shoulderWidth: CGFloat) -> PoseFrame {
        let center: CGFloat = 0.5
        return PoseFrame(
            timestamp: 0,
            joints: [
                .leftShoulder: CGPoint(x: center - shoulderWidth / 2, y: 0.2),
                .rightShoulder: CGPoint(x: center + shoulderWidth / 2, y: 0.2),
                .neck: CGPoint(x: center, y: 0.2),
                .leftAnkle: CGPoint(x: center, y: 0.9),
            ],
            confidences: [:]
        )
    }

    func testWideShoulderWidthClassifiesAsFaceOn() {
        let result = CameraViewClassifier.classify(addressFrame: addressFrame(shoulderWidth: 0.4))

        XCTAssertEqual(result?.cameraView, .faceOn)
    }

    func testNarrowShoulderWidthClassifiesAsDownTheLine() {
        let result = CameraViewClassifier.classify(addressFrame: addressFrame(shoulderWidth: 0.04))

        XCTAssertEqual(result?.cameraView, .downTheLine)
    }

    func testMissingJointsReturnsNil() {
        let incompleteFrame = PoseFrame(timestamp: 0, joints: [.leftShoulder: CGPoint(x: 0.4, y: 0.2)], confidences: [:])

        XCTAssertNil(CameraViewClassifier.classify(addressFrame: incompleteFrame))
    }
}
