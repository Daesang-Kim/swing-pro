import Foundation

struct SwingFeedbackItem: Codable, Identifiable, Equatable {
    var id: String
    var clipId: String
    var deviationItem: String
    var message: String
    var createdAt: Date
}
