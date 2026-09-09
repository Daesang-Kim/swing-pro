import simd
import CoreGraphics

enum PuttingMeasurementError: Error {
    case planeNotFound
    case hitTestFailed
}

protocol PuttingDistanceMeasuring: AnyObject {
    /// 화면 터치 지점(뷰 좌표)을 그린 평면 위 3D 좌표로 변환한다.
    func worldPosition(forScreenPoint point: CGPoint) throws -> SIMD3<Float>

    /// 두 3D 좌표 사이의 실제 거리(미터)를 계산한다.
    func distance(from ball: SIMD3<Float>, to hole: SIMD3<Float>) -> Double
}

extension PuttingDistanceMeasuring {
    func distance(from ball: SIMD3<Float>, to hole: SIMD3<Float>) -> Double {
        Double(simd_distance(ball, hole))
    }
}
