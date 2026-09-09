import CoreGraphics
import Foundation

/// 포즈 프레임 하나로부터 교정 피드백/점수화에 사용할 관절 각도 지표를 계산한다.
/// 지표명은 `swing_reference_ranges.metric_name`과 반드시 일치해야 한다.
enum AngleCalculator {
    static func summary(for frame: PoseFrame) -> AngleSummary {
        var metrics: [String: Double] = [:]

        if let shoulderRotation = lineAngleFromHorizontal(frame.joints[.leftShoulder], frame.joints[.rightShoulder]) {
            metrics["shoulder_rotation"] = shoulderRotation
        }
        if let hipRotation = lineAngleFromHorizontal(frame.joints[.leftHip], frame.joints[.rightHip]) {
            metrics["hip_rotation"] = hipRotation
        }
        if let spineAngle = lineAngleFromVertical(frame.joints[.neck], frame.joints[.root]) {
            metrics["spine_angle"] = spineAngle
        }

        return AngleSummary(metrics: metrics)
    }

    private static func lineAngleFromHorizontal(_ a: CGPoint?, _ b: CGPoint?) -> Double? {
        guard let a, let b else { return nil }
        let dx = Double(b.x - a.x)
        let dy = Double(b.y - a.y)
        return abs(atan2(dy, dx) * 180 / .pi)
    }

    private static func lineAngleFromVertical(_ a: CGPoint?, _ b: CGPoint?) -> Double? {
        guard let a, let b else { return nil }
        let dx = Double(b.x - a.x)
        let dy = Double(b.y - a.y)
        return abs(atan2(dx, dy) * 180 / .pi)
    }
}
