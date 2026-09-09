import CoreGraphics

/// 어드레스(P1) 시점의 어깨/골반 폭으로 촬영 방향(정면/다운더라인)을 규칙 기반으로 추정한다.
///
/// 아이디어: 카메라를 정면(face-on)에서 향하면 어깨-어깨, 골반-골반의 좌우 폭이 넓게 관측되고,
/// 다운더라인(카메라가 타겟 라인 뒤/앞에서 스윙 진행 방향을 바라보는 구도)에서는
/// 신체가 카메라와 거의 수직으로 겹쳐 보여 어깨/골반 폭이 좁게 관측된다.
enum CameraViewClassifier {
    /// 폭 비율이 이 값보다 작으면(어깨 폭이 신장 대비 좁으면) down-the-line으로 판단.
    private static let widthToHeightThreshold: CGFloat = 0.18

    struct Result {
        let cameraView: CameraView
        /// 0...1. 낮으면 수동 보정을 권장.
        let confidence: Double
    }

    static func classify(addressFrame frame: PoseFrame) -> Result? {
        guard let leftShoulder = frame.joints[.leftShoulder],
              let rightShoulder = frame.joints[.rightShoulder],
              let leftAnkle = frame.joints[.leftAnkle] ?? frame.joints[.rightAnkle],
              let neck = frame.joints[.neck] else { return nil }

        let shoulderWidth = abs(leftShoulder.x - rightShoulder.x)
        let bodyHeight = abs(neck.y - leftAnkle.y)
        guard bodyHeight > 0 else { return nil }

        let ratio = shoulderWidth / bodyHeight
        let isFaceOn = ratio >= widthToHeightThreshold
        let confidence = min(1.0, Double(abs(ratio - widthToHeightThreshold) / widthToHeightThreshold))

        return Result(cameraView: isFaceOn ? .faceOn : .downTheLine, confidence: confidence)
    }

    /// 자동 감지 신뢰도가 낮아 수동 보정을 권장해야 하는지 여부.
    static let manualOverrideConfidenceThreshold: Double = 0.25
}
