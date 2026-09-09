import Foundation

struct SwingSession: Codable, Identifiable, Equatable {
    var id: String
    var userId: String
    var mode: SessionMode
    var courseName: String?
    var startedAt: Date
    var endedAt: Date?
}
