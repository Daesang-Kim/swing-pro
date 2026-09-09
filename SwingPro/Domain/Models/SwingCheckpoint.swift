import Foundation

/// P-system 스윙 체크포인트 (요구사양 6장 참고).
enum SwingCheckpoint: String, Codable, CaseIterable, Comparable {
    case p1, p2, p3, p4, p5, p6, p7, p8, p9, p10

    var displayName: String {
        switch self {
        case .p1: return "어드레스"
        case .p2: return "테이크어웨이"
        case .p3: return "백스윙 중간"
        case .p4: return "백스윙 탑"
        case .p5: return "다운스윙 초기"
        case .p6: return "딜리버리"
        case .p7: return "임팩트"
        case .p8: return "릴리즈"
        case .p9: return "팔로스루"
        case .p10: return "피니시"
        }
    }

    var label: String {
        switch self {
        case .p1: return "P1"
        case .p2: return "P2"
        case .p3: return "P3"
        case .p4: return "P4"
        case .p5: return "P5"
        case .p6: return "P6"
        case .p7: return "P7"
        case .p8: return "P8"
        case .p9: return "P9"
        case .p10: return "P10"
        }
    }

    private var order: Int {
        SwingCheckpoint.allCases.firstIndex(of: self) ?? 0
    }

    static func < (lhs: SwingCheckpoint, rhs: SwingCheckpoint) -> Bool {
        lhs.order < rhs.order
    }
}
