import CoreData
import Foundation

/// 사용자 단위 설정(자동 저장 방식, 촬영 방향 감지 방식)을 관리한다.
final class SettingsRepository {
    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext = PersistenceController.shared.container.viewContext) {
        self.context = context
    }

    func fetchOrCreateUser(id: String, nickname: String) throws -> UserProfile {
        let fetch = CDUser.fetchRequest()
        fetch.predicate = NSPredicate(format: "id == %@", id)
        if let existing = try context.fetch(fetch).first {
            return existing.toDomain()
        }

        let cdUser = CDUser(context: context)
        cdUser.id = id
        cdUser.nickname = nickname
        cdUser.createdAt = Date()
        cdUser.autoSaveMode = AutoSaveMode.auto.rawValue
        cdUser.cameraViewMode = CameraViewMode.auto.rawValue

        try context.save()
        return cdUser.toDomain()
    }

    func updateAutoSaveMode(_ mode: AutoSaveMode, forUserId userId: String) throws {
        try updateUser(userId) { $0.autoSaveMode = mode.rawValue }
    }

    func updateCameraViewMode(_ mode: CameraViewMode, forUserId userId: String) throws {
        try updateUser(userId) { $0.cameraViewMode = mode.rawValue }
    }

    private func updateUser(_ userId: String, _ mutate: (CDUser) -> Void) throws {
        let fetch = CDUser.fetchRequest()
        fetch.predicate = NSPredicate(format: "id == %@", userId)
        guard let cdUser = try context.fetch(fetch).first else {
            throw RepositoryError.relatedObjectNotFound
        }
        mutate(cdUser)
        try context.save()
    }
}

private extension CDUser {
    func toDomain() -> UserProfile {
        UserProfile(
            id: id ?? "",
            nickname: nickname ?? "",
            createdAt: createdAt ?? Date(),
            autoSaveMode: AutoSaveMode(rawValue: autoSaveMode ?? "") ?? .auto,
            cameraViewMode: CameraViewMode(rawValue: cameraViewMode ?? "") ?? .auto
        )
    }
}
