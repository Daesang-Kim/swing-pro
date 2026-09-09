import XCTest
@testable import SwingPro

final class TrajectoryCurveFitterTests: XCTestCase {
    func testQuadraticFitRecoversExactCoefficients() {
        // y = 2t^2 - 3t + 1 위의 점들로부터 계수를 복원할 수 있어야 한다.
        let times: [Double] = [0, 1, 2, 3, 4]
        let values = times.map { 2 * $0 * $0 - 3 * $0 + 1 }

        let coefficients = TrajectoryCurveFitter.quadraticFit(times: times, values: values)

        XCTAssertNotNil(coefficients)
        XCTAssertEqual(coefficients?.a ?? 0, 2, accuracy: 1e-6)
        XCTAssertEqual(coefficients?.b ?? 0, -3, accuracy: 1e-6)
        XCTAssertEqual(coefficients?.c ?? 0, 1, accuracy: 1e-6)
    }

    func testExtrapolateContinuesPastLastDetectedPoint() {
        let points = (0..<5).map { i -> TrajectoryPoint in
            let t = Double(i) * 0.1
            return TrajectoryPoint(x: t * 10, y: -4.9 * t * t + 5 * t, timestamp: t)
        }

        let extrapolated = TrajectoryCurveFitter.extrapolate(
            detectedPoints: points,
            extraDuration: 0.2,
            sampleInterval: 0.05
        )

        XCTAssertFalse(extrapolated.isEmpty)
        XCTAssertTrue(extrapolated.allSatisfy { $0.timestamp > points.last!.timestamp })
    }

    func testExtrapolateWithTooFewPointsReturnsEmpty() {
        let points = [TrajectoryPoint(x: 0, y: 0, timestamp: 0), TrajectoryPoint(x: 1, y: 1, timestamp: 0.1)]

        let extrapolated = TrajectoryCurveFitter.extrapolate(detectedPoints: points, extraDuration: 0.5)

        XCTAssertTrue(extrapolated.isEmpty)
    }
}
