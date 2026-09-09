import ARKit
import Combine
import CoreGraphics

@MainActor
final class PuttingMeasurementViewModel: ObservableObject {
    enum TapTarget {
        case ball, hole
    }

    @Published private(set) var ballScreenPoint: CGPoint?
    @Published private(set) var holeScreenPoint: CGPoint?
    @Published private(set) var measuredDistanceM: Double?
    @Published var errorMessage: String?

    /// 다음 터치가 공/홀 중 어느 쪽을 지정할지. 사용자가 순서대로 두 지점을 찍는다.
    private(set) var nextTapTarget: TapTarget = .ball
    private var ballWorldPosition: SIMD3<Float>?
    private var holeWorldPosition: SIMD3<Float>?

    private var measurer: ARKitPuttingDistanceMeasurer?
    private let sessionId: String
    private let repository: PuttingMeasurementRepository

    init(sessionId: String, repository: PuttingMeasurementRepository = PuttingMeasurementRepository()) {
        self.sessionId = sessionId
        self.repository = repository
    }

    func attach(arView: ARSCNView) {
        let measurer = ARKitPuttingDistanceMeasurer(arView: arView)
        measurer.startPlaneDetection()
        self.measurer = measurer
    }

    func detach() {
        measurer?.stopPlaneDetection()
        measurer = nil
    }

    func handleTap(at point: CGPoint) {
        guard let measurer else { return }
        do {
            let worldPosition = try measurer.worldPosition(forScreenPoint: point)
            switch nextTapTarget {
            case .ball:
                ballScreenPoint = point
                ballWorldPosition = worldPosition
                nextTapTarget = .hole
            case .hole:
                holeScreenPoint = point
                holeWorldPosition = worldPosition
                nextTapTarget = .ball
                computeAndSaveDistance()
            }
            errorMessage = nil
        } catch {
            errorMessage = "평면을 인식하지 못했습니다. 그린 바닥을 천천히 비춰주세요."
        }
    }

    func reset() {
        ballScreenPoint = nil
        holeScreenPoint = nil
        ballWorldPosition = nil
        holeWorldPosition = nil
        measuredDistanceM = nil
        nextTapTarget = .ball
    }

    private func computeAndSaveDistance() {
        guard let ball = ballWorldPosition, let hole = holeWorldPosition, let measurer else { return }
        let distance = measurer.distance(from: ball, to: hole)
        measuredDistanceM = distance
        try? repository.recordMeasurement(sessionId: sessionId, distanceM: distance)
    }
}
