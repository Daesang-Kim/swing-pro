import Foundation

struct UserProfile: Codable, Identifiable, Equatable {
    var id: String
    var nickname: String
    var createdAt: Date
    var autoSaveMode: AutoSaveMode
    var cameraViewMode: CameraViewMode
}
