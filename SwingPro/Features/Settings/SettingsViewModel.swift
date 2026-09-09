import Foundation

@MainActor
final class SettingsViewModel: ObservableObject {
    @Published var autoSaveMode: AutoSaveMode
    @Published var cameraViewMode: CameraViewMode

    private let userId: String
    private let repository: SettingsRepository

    init(userProfile: UserProfile, repository: SettingsRepository) {
        self.userId = userProfile.id
        self.repository = repository
        self.autoSaveMode = userProfile.autoSaveMode
        self.cameraViewMode = userProfile.cameraViewMode
    }

    func updateAutoSaveMode(_ mode: AutoSaveMode) {
        autoSaveMode = mode
        try? repository.updateAutoSaveMode(mode, forUserId: userId)
    }

    func updateCameraViewMode(_ mode: CameraViewMode) {
        cameraViewMode = mode
        try? repository.updateCameraViewMode(mode, forUserId: userId)
    }
}
