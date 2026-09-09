import Foundation

/// 구간별 각도 요약값을 기준값(`SwingReferenceRange`)과 비교해 규칙 기반 피드백을 생성한다.
/// LLM 없이 정형화된 문구 템플릿만 사용한다.
struct SwingFeedbackEngine {
    let referenceRangeProvider: SwingReferenceRangeProvider

    init(referenceRangeProvider: SwingReferenceRangeProvider = .shared) {
        self.referenceRangeProvider = referenceRangeProvider
    }

    /// 편차가 이 값(도) 이하이면 피드백을 생성하지 않는다.
    private let deviationTolerance: Double = 3.0

    func generateFeedback(
        clipId: String,
        shotType: ShotType,
        cameraView: CameraView,
        poseSegments: [PoseSegment],
        now: Date = Date()
    ) -> [SwingFeedbackItem] {
        poseSegments.flatMap { segment -> [SwingFeedbackItem] in
            let ranges = referenceRangeProvider.ranges(
                shotType: shotType,
                cameraView: cameraView,
                segmentType: segment.segmentType
            )

            return ranges.compactMap { range -> SwingFeedbackItem? in
                guard let value = segment.angleSummary[range.metricName] else { return nil }
                let deviation = range.deviation(for: value)
                guard deviation > deviationTolerance else { return nil }

                return SwingFeedbackItem(
                    id: UUID().uuidString,
                    clipId: clipId,
                    deviationItem: "\(segment.segmentType.label) \(range.metricName)",
                    message: message(
                        checkpoint: segment.segmentType,
                        metricName: range.metricName,
                        value: value,
                        range: range
                    ),
                    createdAt: now
                )
            }
        }
    }

    private func message(
        checkpoint: SwingCheckpoint,
        metricName: String,
        value: Double,
        range: SwingReferenceRange
    ) -> String {
        let direction = value < range.idealMin ? "부족" : "과다"
        return "\(checkpoint.displayName)(\(checkpoint.label)) 구간의 \(metricName)이(가) 이상 범위" +
            "(\(Int(range.idealMin))~\(Int(range.idealMax)))보다 \(direction)합니다. 측정값: \(Int(value))"
    }
}
