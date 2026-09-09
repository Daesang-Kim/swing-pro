import Vision
import CoreMedia

/// Apple Vision `VNDetectHumanBodyPoseRequest` 기반 온디바이스 포즈 추정.
final class VisionPoseEstimator: PoseEstimating {
    private let request = VNDetectHumanBodyPoseRequest()

    private static let jointMapping: [JointKey: VNHumanBodyPoseObservation.JointName] = [
        .leftShoulder: .leftShoulder, .rightShoulder: .rightShoulder,
        .leftElbow: .leftElbow, .rightElbow: .rightElbow,
        .leftWrist: .leftWrist, .rightWrist: .rightWrist,
        .leftHip: .leftHip, .rightHip: .rightHip,
        .leftKnee: .leftKnee, .rightKnee: .rightKnee,
        .leftAnkle: .leftAnkle, .rightAnkle: .rightAnkle,
        .neck: .neck, .root: .root,
    ]

    private static let minimumConfidence: Float = 0.3

    func estimatePose(in sampleBuffer: CMSampleBuffer, timestamp: TimeInterval) -> PoseFrame? {
        let handler = VNImageRequestHandler(cmSampleBuffer: sampleBuffer, orientation: .up, options: [:])
        do {
            try handler.perform([request])
        } catch {
            return nil
        }

        guard let observations = request.results as? [VNHumanBodyPoseObservation],
              let observation = observations.first else { return nil }

        var joints: [JointKey: CGPoint] = [:]
        var confidences: [JointKey: Float] = [:]

        for (key, visionName) in Self.jointMapping {
            guard let point = try? observation.recognizedPoint(visionName),
                  point.confidence >= Self.minimumConfidence else { continue }
            joints[key] = point.location
            confidences[key] = point.confidence
        }

        guard !joints.isEmpty else { return nil }
        return PoseFrame(timestamp: timestamp, joints: joints, confidences: confidences)
    }
}
