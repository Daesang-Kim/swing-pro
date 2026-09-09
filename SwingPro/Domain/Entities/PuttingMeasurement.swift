import Foundation

struct PuttingMeasurement: Codable, Identifiable, Equatable {
    var id: String
    var sessionId: String
    var measuredAt: Date
    var distanceM: Double
}
