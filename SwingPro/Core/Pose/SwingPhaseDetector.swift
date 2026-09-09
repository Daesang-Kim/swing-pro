import CoreGraphics
import Foundation

enum SwingPhaseEvent: Equatable {
    /// 테이크어웨이(P2) 감지 — 프리롤 버퍼 시점부터 녹화를 시작해야 함.
    case swingStarted(timestamp: TimeInterval)
    /// 특정 체크포인트 도달.
    case checkpointReached(SwingCheckpoint, timestamp: TimeInterval)
    /// 피니시(P10) 감지 — 포스트롤 이후 녹화를 종료해야 함.
    case swingFinished(timestamp: TimeInterval)
}

/// 손목 관절의 수직 위치·속도 변화를 기준으로 스윙 구간(P1~P10)을 규칙 기반으로 추정한다.
///
/// 실제 프로덕션 정확도를 위해서는 임계값(threshold) 튜닝과 실기기 촬영 데이터 기반 보정이 필요하며,
/// 이 구현은 온디바이스에서 동작 가능한 기준선(baseline) 로직을 제공하는 것이 목적이다.
final class SwingPhaseDetector {
    private enum State {
        case idle
        case address
        case backswing
        case downswing
        case followThrough
    }

    /// 어드레스로 판단하기 위해 손목이 안정적으로 머물러야 하는 최소 시간(초)
    private let addressStabilityWindow: TimeInterval
    /// 어드레스 판단 시 허용하는 손목 위치 변동 폭(정규화 좌표 기준)
    private let addressStabilityThreshold: CGFloat

    private var state: State = .idle
    private var recentWristHeights: [(timestamp: TimeInterval, height: CGFloat)] = []
    private var addressWristHeight: CGFloat?
    private var topOfBackswingHeight: CGFloat?
    private var lastEmittedCheckpoint: SwingCheckpoint?

    init(addressStabilityWindow: TimeInterval = 0.4, addressStabilityThreshold: CGFloat = 0.03) {
        self.addressStabilityWindow = addressStabilityWindow
        self.addressStabilityThreshold = addressStabilityThreshold
    }

    func reset() {
        state = .idle
        recentWristHeights.removeAll()
        addressWristHeight = nil
        topOfBackswingHeight = nil
        lastEmittedCheckpoint = nil
    }

    /// 새 포즈 프레임을 주입하고, 상태 전이가 발생했다면 이벤트를 반환한다.
    func ingest(_ frame: PoseFrame) -> [SwingPhaseEvent] {
        guard let wristHeight = leadWristHeight(in: frame) else { return [] }

        recentWristHeights.append((frame.timestamp, wristHeight))
        recentWristHeights.removeAll { frame.timestamp - $0.timestamp > addressStabilityWindow }

        switch state {
        case .idle:
            return evaluateForAddress(at: frame.timestamp, wristHeight: wristHeight)
        case .address:
            return evaluateForBackswingStart(at: frame.timestamp, wristHeight: wristHeight)
        case .backswing:
            return evaluateForDownswing(at: frame.timestamp, wristHeight: wristHeight)
        case .downswing:
            return evaluateForFollowThrough(at: frame.timestamp, wristHeight: wristHeight)
        case .followThrough:
            return evaluateForFinish(at: frame.timestamp, wristHeight: wristHeight)
        }
    }

    private func leadWristHeight(in frame: PoseFrame) -> CGFloat? {
        (frame.joints[.leftWrist] ?? frame.joints[.rightWrist])?.y
    }

    private func evaluateForAddress(at timestamp: TimeInterval, wristHeight: CGFloat) -> [SwingPhaseEvent] {
        guard recentWristHeights.count >= 2,
              let oldest = recentWristHeights.first else { return [] }

        let spread = recentWristHeights.map(\.height).max()! - recentWristHeights.map(\.height).min()!
        guard spread <= addressStabilityThreshold,
              timestamp - oldest.timestamp >= addressStabilityWindow else { return [] }

        state = .address
        addressWristHeight = wristHeight
        lastEmittedCheckpoint = .p1
        return [.checkpointReached(.p1, timestamp: timestamp)]
    }

    private func evaluateForBackswingStart(at timestamp: TimeInterval, wristHeight: CGFloat) -> [SwingPhaseEvent] {
        guard let addressHeight = addressWristHeight else { return [] }
        // 이미지 좌표계는 위로 갈수록 y가 작아짐 → 손목이 올라가면 backswing 시작으로 간주.
        guard addressHeight - wristHeight > addressStabilityThreshold * 2 else { return [] }

        state = .backswing
        topOfBackswingHeight = wristHeight
        lastEmittedCheckpoint = .p2
        return [
            .swingStarted(timestamp: timestamp),
            .checkpointReached(.p2, timestamp: timestamp),
        ]
    }

    private func evaluateForDownswing(at timestamp: TimeInterval, wristHeight: CGFloat) -> [SwingPhaseEvent] {
        if let top = topOfBackswingHeight, wristHeight < top {
            topOfBackswingHeight = wristHeight
            return []
        }

        // 정점을 찍고 다시 낮아지기 시작하면 백스윙 탑(P4) → 다운스윙 전환.
        state = .downswing
        lastEmittedCheckpoint = .p4
        return [.checkpointReached(.p4, timestamp: timestamp)]
    }

    private func evaluateForFollowThrough(at timestamp: TimeInterval, wristHeight: CGFloat) -> [SwingPhaseEvent] {
        guard let addressHeight = addressWristHeight else { return [] }
        // 손목이 다시 어드레스 높이 부근으로 내려오면 임팩트(P7) 근접으로 간주.
        guard abs(wristHeight - addressHeight) <= addressStabilityThreshold * 3 else { return [] }

        state = .followThrough
        lastEmittedCheckpoint = .p7
        return [.checkpointReached(.p7, timestamp: timestamp)]
    }

    private func evaluateForFinish(at timestamp: TimeInterval, wristHeight: CGFloat) -> [SwingPhaseEvent] {
        guard let addressHeight = addressWristHeight else { return [] }
        // 손목이 어드레스보다 충분히 높은 곳(반대쪽 팔로스루)에서 안정되면 피니시(P10)로 간주.
        guard addressHeight - wristHeight > addressStabilityThreshold * 2,
              recentWristHeights.count >= 2 else { return [] }

        let spread = recentWristHeights.map(\.height).max()! - recentWristHeights.map(\.height).min()!
        guard spread <= addressStabilityThreshold else { return [] }

        state = .idle
        lastEmittedCheckpoint = .p10
        let events: [SwingPhaseEvent] = [
            .checkpointReached(.p10, timestamp: timestamp),
            .swingFinished(timestamp: timestamp),
        ]
        reset()
        return events
    }
}
