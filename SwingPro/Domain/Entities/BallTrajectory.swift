import Foundation

struct BallTrajectory: Codable, Identifiable, Equatable {
    var id: String
    var clipId: String
    /// 실제 탐지된 좌표 시퀀스 (탐지 성공 구간)
    var detectedPoints: [TrajectoryPoint]
    /// 탐지가 끊긴 지점. 이후 구간은 이 지점부터 외삽 곡선으로 이어 그린다.
    var detectionEndPoint: TrajectoryPoint?
}
