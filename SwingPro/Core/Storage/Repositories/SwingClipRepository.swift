import CoreData
import Foundation

/// Core Data 엔티티와 도메인 모델(`SwingClip` 등) 사이를 매핑하는 저장소.
/// 분석 로직(`SwingFeedbackEngine`, `SwingScorer`)은 이 저장소가 반환하는 순수 도메인 모델만 알면 된다.
final class SwingClipRepository {
    private let context: NSManagedObjectContext
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(context: NSManagedObjectContext = PersistenceController.shared.container.viewContext) {
        self.context = context
    }

    func createClip(
        sessionId: String,
        videoAssetIdentifier: String,
        durationSec: Double,
        shotType: ShotType,
        cameraView: CameraView,
        cameraViewSource: CameraViewSource,
        clubTag: String? = nil
    ) throws -> SwingClip {
        let sessionFetch = CDSession.fetchRequest()
        sessionFetch.predicate = NSPredicate(format: "id == %@", sessionId)
        guard let cdSession = try context.fetch(sessionFetch).first else {
            throw RepositoryError.relatedObjectNotFound
        }

        let cdClip = CDSwingClip(context: context)
        cdClip.id = UUID().uuidString
        cdClip.recordedAt = Date()
        cdClip.videoPath = videoAssetIdentifier
        cdClip.durationSec = durationSec
        cdClip.clubTag = clubTag
        cdClip.shotType = shotType.rawValue
        cdClip.cameraView = cameraView.rawValue
        cdClip.cameraViewSource = cameraViewSource.rawValue
        cdClip.session = cdSession

        try context.save()
        return try cdClip.toDomain(decoder: decoder)
    }

    func addPoseSegments(_ segments: [PoseSegment], toClipId clipId: String) throws {
        guard let cdClip = try fetchManagedClip(id: clipId) else {
            throw RepositoryError.relatedObjectNotFound
        }

        for segment in segments {
            let cdSegment = CDPoseSegment(context: context)
            cdSegment.id = segment.id
            cdSegment.segmentType = segment.segmentType.rawValue
            cdSegment.timestampInVideo = segment.timestampInVideo
            cdSegment.angleSummaryJSON = try String(data: encoder.encode(segment.angleSummary), encoding: .utf8) ?? "{}"
            cdSegment.clip = cdClip
        }

        try context.save()
    }

    func addFeedback(_ items: [SwingFeedbackItem], toClipId clipId: String) throws {
        guard let cdClip = try fetchManagedClip(id: clipId) else {
            throw RepositoryError.relatedObjectNotFound
        }

        for item in items {
            let cdFeedback = CDSwingFeedback(context: context)
            cdFeedback.id = item.id
            cdFeedback.deviationItem = item.deviationItem
            cdFeedback.message = item.message
            cdFeedback.createdAt = item.createdAt
            cdFeedback.clip = cdClip
        }

        try context.save()
    }

    func updateScore(_ score: Int, forClipId clipId: String) throws {
        guard let cdClip = try fetchManagedClip(id: clipId) else {
            throw RepositoryError.relatedObjectNotFound
        }
        cdClip.score = NSNumber(value: score)
        try context.save()
    }

    func fetchClips(sessionId: String? = nil) throws -> [SwingClip] {
        let fetch = CDSwingClip.fetchRequest()
        if let sessionId {
            fetch.predicate = NSPredicate(format: "session.id == %@", sessionId)
        }
        fetch.sortDescriptors = [NSSortDescriptor(keyPath: \CDSwingClip.recordedAt, ascending: false)]
        return try context.fetch(fetch).map { try $0.toDomain(decoder: decoder) }
    }

    func fetchPoseSegments(clipId: String) throws -> [PoseSegment] {
        guard let cdClip = try fetchManagedClip(id: clipId) else { return [] }
        let segments = (cdClip.poseSegments as? Set<CDPoseSegment>) ?? []
        return try segments
            .map { try $0.toDomain(decoder: decoder) }
            .sorted { $0.timestampInVideo < $1.timestampInVideo }
    }

    func fetchFeedback(clipId: String) throws -> [SwingFeedbackItem] {
        guard let cdClip = try fetchManagedClip(id: clipId) else { return [] }
        let feedbacks = (cdClip.feedbacks as? Set<CDSwingFeedback>) ?? []
        return feedbacks.map { $0.toDomain() }.sorted { $0.createdAt < $1.createdAt }
    }

    /// 필드 모드에서만 존재하는(있는 경우만) 공 궤적 데이터를 저장한다.
    func setTrajectory(_ trajectory: BallTrajectory, forClipId clipId: String) throws {
        guard let cdClip = try fetchManagedClip(id: clipId) else {
            throw RepositoryError.relatedObjectNotFound
        }

        let cdTrajectory = cdClip.trajectory ?? CDBallTrajectory(context: context)
        cdTrajectory.id = trajectory.id
        cdTrajectory.detectedPointsJSON = try String(data: encoder.encode(trajectory.detectedPoints), encoding: .utf8) ?? "[]"
        cdTrajectory.detectionEndPointJSON = try trajectory.detectionEndPoint.map {
            try String(data: encoder.encode($0), encoding: .utf8)
        } ?? nil
        cdTrajectory.clip = cdClip

        try context.save()
    }

    func fetchTrajectory(clipId: String) throws -> BallTrajectory? {
        guard let cdClip = try fetchManagedClip(id: clipId), let cdTrajectory = cdClip.trajectory else { return nil }

        guard let pointsData = cdTrajectory.detectedPointsJSON?.data(using: .utf8),
              let points = try? decoder.decode([TrajectoryPoint].self, from: pointsData) else {
            throw RepositoryError.decodingFailed
        }

        let endPoint: TrajectoryPoint? = try cdTrajectory.detectionEndPointJSON
            .flatMap { $0.data(using: .utf8) }
            .map { try decoder.decode(TrajectoryPoint.self, from: $0) }

        return BallTrajectory(
            id: cdTrajectory.id ?? "",
            clipId: clipId,
            detectedPoints: points,
            detectionEndPoint: endPoint
        )
    }

    private func fetchManagedClip(id: String) throws -> CDSwingClip? {
        let fetch = CDSwingClip.fetchRequest()
        fetch.predicate = NSPredicate(format: "id == %@", id)
        fetch.fetchLimit = 1
        return try context.fetch(fetch).first
    }
}

private extension CDSwingClip {
    func toDomain(decoder: JSONDecoder) throws -> SwingClip {
        SwingClip(
            id: id ?? "",
            sessionId: session?.id ?? "",
            recordedAt: recordedAt ?? Date(),
            videoPath: videoPath ?? "",
            durationSec: durationSec,
            clubTag: clubTag,
            shotType: ShotType(rawValue: shotType ?? "") ?? .fullSwing,
            cameraView: CameraView(rawValue: cameraView ?? "") ?? .faceOn,
            cameraViewSource: CameraViewSource(rawValue: cameraViewSource ?? "") ?? .auto,
            score: score?.intValue
        )
    }
}

private extension CDPoseSegment {
    func toDomain(decoder: JSONDecoder) throws -> PoseSegment {
        guard let json = angleSummaryJSON, let data = json.data(using: .utf8),
              let summary = try? decoder.decode(AngleSummary.self, from: data) else {
            throw RepositoryError.decodingFailed
        }
        return PoseSegment(
            id: id ?? "",
            clipId: clip?.id ?? "",
            segmentType: SwingCheckpoint(rawValue: segmentType ?? "") ?? .p1,
            timestampInVideo: timestampInVideo,
            angleSummary: summary
        )
    }
}

private extension CDSwingFeedback {
    func toDomain() -> SwingFeedbackItem {
        SwingFeedbackItem(
            id: id ?? "",
            clipId: clip?.id ?? "",
            deviationItem: deviationItem ?? "",
            message: message ?? "",
            createdAt: createdAt ?? Date()
        )
    }
}
