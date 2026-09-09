import SwiftUI
import Combine

enum AppRoute: Hashable {
    case practice
    case field
    case feed
    case clipDetail(clipId: String)
    case settings
}

@MainActor
final class AppState: ObservableObject {
    @Published var path = NavigationPath()
    @Published var currentUser: UserProfile

    let settingsRepository: SettingsRepository
    let sessionRepository: SessionRepository
    let clipRepository: SwingClipRepository
    let puttingRepository: PuttingMeasurementRepository

    /// 데모/개발 초기 단계에서는 단일 로컬 사용자만 가정한다. 로그인/멀티 프로필은 범위 밖.
    static let defaultUserId = "local-user"

    init(
        settingsRepository: SettingsRepository = SettingsRepository(),
        sessionRepository: SessionRepository = SessionRepository(),
        clipRepository: SwingClipRepository = SwingClipRepository(),
        puttingRepository: PuttingMeasurementRepository = PuttingMeasurementRepository()
    ) {
        self.settingsRepository = settingsRepository
        self.sessionRepository = sessionRepository
        self.clipRepository = clipRepository
        self.puttingRepository = puttingRepository
        self.currentUser = (try? settingsRepository.fetchOrCreateUser(
            id: Self.defaultUserId,
            nickname: "골퍼"
        )) ?? UserProfile(
            id: Self.defaultUserId,
            nickname: "골퍼",
            createdAt: Date(),
            autoSaveMode: .auto,
            cameraViewMode: .auto
        )
    }

    func push(_ route: AppRoute) {
        path.append(route)
    }

    func popToRoot() {
        path.removeLast(path.count)
    }

    func refreshCurrentUser() {
        if let updated = try? settingsRepository.fetchOrCreateUser(id: currentUser.id, nickname: currentUser.nickname) {
            currentUser = updated
        }
    }
}
