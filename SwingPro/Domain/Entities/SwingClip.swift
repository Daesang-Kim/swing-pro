import Foundation

/// `swing_clips` 테이블 미러링. `videoPath`는 실제 파일 경로가 아니라
/// 사진 라이브러리 자산 식별자(PHAsset localIdentifier)를 담는다.
struct SwingClip: Codable, Identifiable, Equatable {
    var id: String
    var sessionId: String
    var recordedAt: Date
    var videoPath: String
    var durationSec: Double
    var clubTag: String?
    var shotType: ShotType
    var cameraView: CameraView
    var cameraViewSource: CameraViewSource
    var score: Int?
}
