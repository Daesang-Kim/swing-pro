import Foundation

/// 샷 유형 × 촬영 방향 × 체크포인트 × 지표별 이상적 각도 범위.
struct SwingReferenceRange: Codable, Identifiable, Equatable {
    var id: String
    var shotType: ShotType
    var cameraView: CameraView
    var segmentType: SwingCheckpoint
    var metricName: String
    var idealMin: Double
    var idealMax: Double

    /// 0이면 범위 내, 그 외에는 벗어난 정도(도 단위, 항상 양수).
    func deviation(for value: Double) -> Double {
        if value < idealMin { return idealMin - value }
        if value > idealMax { return value - idealMax }
        return 0
    }
}
