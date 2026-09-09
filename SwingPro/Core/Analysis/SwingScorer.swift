import Foundation

/// 체크포인트별 기준값 대비 편차를 가중 평균해 0~100점 스코어로 환산한다.
struct SwingScorer {
    let referenceRangeProvider: SwingReferenceRangeProvider

    /// 핵심 체크포인트(P4 백스윙 탑, P7 임팩트)에 더 큰 가중치를 부여.
    private let checkpointWeights: [SwingCheckpoint: Double] = [
        .p1: 0.5, .p2: 0.7, .p3: 0.7, .p4: 1.5,
        .p5: 0.7, .p6: 1.0, .p7: 1.5, .p8: 0.8,
        .p9: 0.6, .p10: 0.5,
    ]

    /// 편차(도)가 이 값 이상이면 해당 지표는 0점으로 간주.
    private let maxToleratedDeviation: Double = 30.0

    init(referenceRangeProvider: SwingReferenceRangeProvider = .shared) {
        self.referenceRangeProvider = referenceRangeProvider
    }

    func score(shotType: ShotType, cameraView: CameraView, poseSegments: [PoseSegment]) -> Int {
        var weightedScoreSum = 0.0
        var weightSum = 0.0

        for segment in poseSegments {
            let ranges = referenceRangeProvider.ranges(
                shotType: shotType,
                cameraView: cameraView,
                segmentType: segment.segmentType
            )
            guard !ranges.isEmpty else { continue }

            let checkpointWeight = checkpointWeights[segment.segmentType] ?? 1.0

            for range in ranges {
                guard let value = segment.angleSummary[range.metricName] else { continue }
                let deviation = min(range.deviation(for: value), maxToleratedDeviation)
                let metricScore = 100.0 * (1.0 - deviation / maxToleratedDeviation)

                weightedScoreSum += metricScore * checkpointWeight
                weightSum += checkpointWeight
            }
        }

        guard weightSum > 0 else { return 0 }
        return Int((weightedScoreSum / weightSum).rounded())
    }
}
