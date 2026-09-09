import ARKit
import simd

/// ARKit 평면 인식(그린 바닥) + hit-testing으로 사용자가 터치한 두 지점(공/홀) 간 거리를 계산한다.
/// 공/핀은 AI가 자동 인식하지 않고, 사용자가 직접 화면을 터치해 지정한 지점을 사용한다.
final class ARKitPuttingDistanceMeasurer: NSObject, PuttingDistanceMeasuring {
    let arView: ARSCNView

    init(arView: ARSCNView) {
        self.arView = arView
        super.init()
    }

    func startPlaneDetection() {
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal]
        if ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh) {
            configuration.sceneReconstruction = .mesh
        }
        arView.session.run(configuration)
    }

    func stopPlaneDetection() {
        arView.session.pause()
    }

    func worldPosition(forScreenPoint point: CGPoint) throws -> SIMD3<Float> {
        if #available(iOS 14.0, *) {
            let results = arView.raycastQuery(from: point, allowing: .estimatedPlane, alignment: .horizontal)
                .flatMap { arView.session.raycast($0) } ?? []
            guard let result = results.first else { throw PuttingMeasurementError.hitTestFailed }
            let column = result.worldTransform.columns.3
            return SIMD3<Float>(column.x, column.y, column.z)
        } else {
            let results = arView.hitTest(point, types: [.existingPlaneUsingExtent, .estimatedHorizontalPlane])
            guard let result = results.first else { throw PuttingMeasurementError.hitTestFailed }
            let column = result.worldTransform.columns.3
            return SIMD3<Float>(column.x, column.y, column.z)
        }
    }
}
