import Vision
import CoreMedia

/// 프레임 간 밝기/색상 차분으로 골프공을 탐지하는 트래커.
///
/// 실제 탐지 알고리즘(배경 차분, 색상 임계값, 후보 원형도 검사 등)은 고프레임레이트(120~240fps)
/// 촬영 데이터로 튜닝이 필요해 TODO로 남겨두고, 여기서는 프레임 파이프라인 연결 지점만 정의한다.
final class VisionBallTrajectoryTracker: BallTrajectoryTracking {
    private var previousFrame: CVPixelBuffer?

    func detectBall(in sampleBuffer: CMSampleBuffer, timestamp: TimeInterval) -> TrajectoryPoint? {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return nil }
        defer { previousFrame = pixelBuffer }

        // TODO: previousFrame과의 차분 이미지에서 원형 후보를 찾아 정규화 좌표로 변환한다.
        return nil
    }
}
