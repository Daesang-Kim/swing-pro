import CoreData

final class SessionRepository {
    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext = PersistenceController.shared.container.viewContext) {
        self.context = context
    }

    func startSession(userId: String, mode: SessionMode, courseName: String? = nil) throws -> SwingSession {
        let userFetch = CDUser.fetchRequest()
        userFetch.predicate = NSPredicate(format: "id == %@", userId)
        guard let cdUser = try context.fetch(userFetch).first else {
            throw RepositoryError.relatedObjectNotFound
        }

        let cdSession = CDSession(context: context)
        cdSession.id = UUID().uuidString
        cdSession.mode = mode.rawValue
        cdSession.courseName = courseName
        cdSession.startedAt = Date()
        cdSession.user = cdUser

        try context.save()
        return cdSession.toDomain()
    }

    func endSession(sessionId: String) throws {
        let fetch = CDSession.fetchRequest()
        fetch.predicate = NSPredicate(format: "id == %@", sessionId)
        guard let cdSession = try context.fetch(fetch).first else {
            throw RepositoryError.relatedObjectNotFound
        }
        cdSession.endedAt = Date()
        try context.save()
    }

    func fetchSessions(for userId: String) throws -> [SwingSession] {
        let fetch = CDSession.fetchRequest()
        fetch.predicate = NSPredicate(format: "user.id == %@", userId)
        fetch.sortDescriptors = [NSSortDescriptor(key: "startedAt", ascending: false)]
        return try context.fetch(fetch).map { $0.toDomain() }
    }
}

enum RepositoryError: Error {
    case relatedObjectNotFound
    case decodingFailed
}

private extension CDSession {
    func toDomain() -> SwingSession {
        SwingSession(
            id: id ?? "",
            userId: user?.id ?? "",
            mode: SessionMode(rawValue: mode ?? "") ?? .practice,
            courseName: courseName,
            startedAt: startedAt ?? Date(),
            endedAt: endedAt
        )
    }
}
