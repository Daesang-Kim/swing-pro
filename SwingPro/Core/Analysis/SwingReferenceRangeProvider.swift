import Foundation

/// 번들에 포함된 `swing_reference_ranges.json` 시드 데이터를 로드해
/// (샷 유형, 촬영 방향, 체크포인트) 조합으로 기준값을 조회할 수 있게 한다.
final class SwingReferenceRangeProvider {
    static let shared = SwingReferenceRangeProvider()

    private let rangesByKey: [Key: [SwingReferenceRange]]

    private struct Key: Hashable {
        let shotType: ShotType
        let cameraView: CameraView
        let segmentType: SwingCheckpoint
    }

    init(bundle: Bundle = .main, resourceName: String = "swing_reference_ranges") {
        let ranges = Self.loadRanges(bundle: bundle, resourceName: resourceName)
        self.rangesByKey = Self.group(ranges)
    }

    /// 테스트나 미리보기 등, 번들 리소스 없이 메모리 상의 값으로 구성할 때 사용.
    init(ranges: [SwingReferenceRange]) {
        self.rangesByKey = Self.group(ranges)
    }

    private static func group(_ ranges: [SwingReferenceRange]) -> [Key: [SwingReferenceRange]] {
        Dictionary(grouping: ranges) { range in
            Key(shotType: range.shotType, cameraView: range.cameraView, segmentType: range.segmentType)
        }
    }

    func ranges(shotType: ShotType, cameraView: CameraView, segmentType: SwingCheckpoint) -> [SwingReferenceRange] {
        rangesByKey[Key(shotType: shotType, cameraView: cameraView, segmentType: segmentType)] ?? []
    }

    private static func loadRanges(bundle: Bundle, resourceName: String) -> [SwingReferenceRange] {
        guard let url = bundle.url(forResource: resourceName, withExtension: "json"),
              let data = try? Data(contentsOf: url) else {
            return []
        }
        let decoder = JSONDecoder()
        return (try? decoder.decode([SwingReferenceRange].self, from: data)) ?? []
    }
}
