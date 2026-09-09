import Foundation
import CoreGraphics
import CoreMedia

/// Vision `VNHumanBodyPoseObservation.JointName`과 대응하는, 프레임워크 독립적인 관절 키.
enum JointKey: String, CaseIterable {
    case leftShoulder, rightShoulder
    case leftElbow, rightElbow
    case leftWrist, rightWrist
    case leftHip, rightHip
    case leftKnee, rightKnee
    case leftAnkle, rightAnkle
    case neck, root
}

struct PoseFrame {
    /// 프레임 촬영 시각 (클립/세션 시작 기준 경과 시간, 초)
    let timestamp: TimeInterval
    /// 정규화 이미지 좌표(0...1) 기준 관절 위치. 신뢰도가 낮아 인식되지 않은 관절은 키가 없음.
    let joints: [JointKey: CGPoint]
    let confidences: [JointKey: Float]
}

protocol PoseEstimating: AnyObject {
    /// 카메라 프레임 하나에서 사람 포즈를 추정한다. 사람이 인식되지 않으면 nil.
    func estimatePose(in sampleBuffer: CMSampleBuffer, timestamp: TimeInterval) -> PoseFrame?
}
