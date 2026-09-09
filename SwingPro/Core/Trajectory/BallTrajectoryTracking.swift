import CoreMedia

protocol BallTrajectoryTracking: AnyObject {
    /// 프레임에서 공을 탐지해 정규화 좌표를 반환한다. 탐지 실패 시 nil.
    func detectBall(in sampleBuffer: CMSampleBuffer, timestamp: TimeInterval) -> TrajectoryPoint?
}
