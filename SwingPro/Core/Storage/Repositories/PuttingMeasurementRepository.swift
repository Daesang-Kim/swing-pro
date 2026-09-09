import CoreData
import Foundation

final class PuttingMeasurementRepository {
    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext = PersistenceController.shared.container.viewContext) {
        self.context = context
    }

    func recordMeasurement(sessionId: String, distanceM: Double) throws -> PuttingMeasurement {
        let sessionFetch = CDSession.fetchRequest()
        sessionFetch.predicate = NSPredicate(format: "id == %@", sessionId)
        guard let cdSession = try context.fetch(sessionFetch).first else {
            throw RepositoryError.relatedObjectNotFound
        }

        let cdMeasurement = CDPuttingMeasurement(context: context)
        cdMeasurement.id = UUID().uuidString
        cdMeasurement.measuredAt = Date()
        cdMeasurement.distanceM = distanceM
        cdMeasurement.session = cdSession

        try context.save()
        return cdMeasurement.toDomain(sessionId: sessionId)
    }

    func fetchMeasurements(sessionId: String) throws -> [PuttingMeasurement] {
        let fetch = CDPuttingMeasurement.fetchRequest()
        fetch.predicate = NSPredicate(format: "session.id == %@", sessionId)
        fetch.sortDescriptors = [NSSortDescriptor(key: "measuredAt", ascending: false)]
        return try context.fetch(fetch).map { $0.toDomain(sessionId: sessionId) }
    }
}

private extension CDPuttingMeasurement {
    func toDomain(sessionId: String) -> PuttingMeasurement {
        PuttingMeasurement(
            id: id ?? "",
            sessionId: sessionId,
            measuredAt: measuredAt ?? Date(),
            distanceM: distanceM
        )
    }
}
