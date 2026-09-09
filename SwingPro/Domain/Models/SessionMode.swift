import Foundation

enum SessionMode: String, Codable, CaseIterable {
    case practice
    case field
}

enum ShotType: String, Codable, CaseIterable {
    case fullSwing = "full_swing"
    case approach
}

enum CameraView: String, Codable, CaseIterable {
    case faceOn = "face_on"
    case downTheLine = "down_the_line"
}

enum CameraViewSource: String, Codable {
    case auto
    case manual
}

enum AutoSaveMode: String, Codable, CaseIterable {
    case auto
    case confirm
}

enum CameraViewMode: String, Codable, CaseIterable {
    case auto
    case manual
}
