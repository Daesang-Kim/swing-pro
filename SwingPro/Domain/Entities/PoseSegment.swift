import Foundation

struct PoseSegment: Codable, Identifiable, Equatable {
    var id: String
    var clipId: String
    var segmentType: SwingCheckpoint
    var timestampInVideo: Double
    var angleSummary: AngleSummary
}
