import Foundation

/// 하나의 체크포인트 구간에서 계산된 관절 각도 요약값.
/// `swing_pose_segments.angle_summary` JSON 컬럼에 대응.
struct AngleSummary: Codable, Equatable {
    /// 지표명 → 각도(도) 매핑. 예: "shoulder_rotation" -> 92.5
    var metrics: [String: Double]

    subscript(metricName: String) -> Double? {
        metrics[metricName]
    }
}

/// 카메라 화면 좌표계 상의 한 점. ARKit 3D 좌표와 구분하기 위해 별도 타입 사용.
struct TrajectoryPoint: Codable, Equatable {
    var x: Double
    var y: Double
    /// 클립 시작 시점 기준 경과 시간(초)
    var timestamp: Double
}
