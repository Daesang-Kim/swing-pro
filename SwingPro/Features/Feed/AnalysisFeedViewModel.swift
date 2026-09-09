import Foundation

@MainActor
final class AnalysisFeedViewModel: ObservableObject {
    struct CardItem: Identifiable {
        let clip: SwingClip
        let session: SwingSession?
        let topFeedbackSummary: String?

        var id: String { clip.id }
    }

    @Published private(set) var items: [CardItem] = []

    private let clipRepository: SwingClipRepository
    private let sessionRepository: SessionRepository

    init(
        clipRepository: SwingClipRepository = SwingClipRepository(),
        sessionRepository: SessionRepository = SessionRepository()
    ) {
        self.clipRepository = clipRepository
        self.sessionRepository = sessionRepository
    }

    func load(userId: String) {
        guard let clips = try? clipRepository.fetchClips() else { return }
        let sessions = (try? sessionRepository.fetchSessions(for: userId)) ?? []
        let sessionsById = Dictionary(uniqueKeysWithValues: sessions.map { ($0.id, $0) })

        items = clips.map { clip in
            let feedback = (try? clipRepository.fetchFeedback(clipId: clip.id)) ?? []
            return CardItem(
                clip: clip,
                session: sessionsById[clip.sessionId],
                topFeedbackSummary: feedback.first?.message
            )
        }
    }
}
