import AVFoundation
import Combine
import Foundation

@MainActor
final class ClipDetailViewModel: ObservableObject {
    @Published private(set) var clip: SwingClip?
    @Published private(set) var poseSegments: [PoseSegment] = []
    @Published private(set) var feedbackItems: [SwingFeedbackItem] = []
    @Published private(set) var player: AVPlayer?
    @Published var selectedCheckpoint: SwingCheckpoint?

    private let clipId: String
    private let clipRepository: SwingClipRepository
    private let photoLibraryStore: PhotoLibraryStoring

    init(
        clipId: String,
        clipRepository: SwingClipRepository = SwingClipRepository(),
        photoLibraryStore: PhotoLibraryStoring = PhotosPhotoLibraryStore()
    ) {
        self.clipId = clipId
        self.clipRepository = clipRepository
        self.photoLibraryStore = photoLibraryStore
    }

    func load() {
        guard let clips = try? clipRepository.fetchClips(), let clip = clips.first(where: { $0.id == clipId }) else { return }
        self.clip = clip
        self.poseSegments = (try? clipRepository.fetchPoseSegments(clipId: clipId))?.sorted { $0.timestampInVideo < $1.timestampInVideo } ?? []
        self.feedbackItems = (try? clipRepository.fetchFeedback(clipId: clipId)) ?? []
        selectedCheckpoint = poseSegments.first?.segmentType

        Task {
            if let url = try? await photoLibraryStore.videoURL(forAssetIdentifier: clip.videoPath) {
                player = AVPlayer(url: url)
            }
        }
    }

    func selectCheckpoint(_ checkpoint: SwingCheckpoint) {
        selectedCheckpoint = checkpoint
        guard let segment = poseSegments.first(where: { $0.segmentType == checkpoint }) else { return }
        let time = CMTime(seconds: segment.timestampInVideo, preferredTimescale: 600)
        player?.seek(to: time)
    }

    var selectedSegment: PoseSegment? {
        poseSegments.first { $0.segmentType == selectedCheckpoint }
    }

    var feedbackForSelectedCheckpoint: [SwingFeedbackItem] {
        guard let checkpoint = selectedCheckpoint else { return [] }
        return feedbackItems.filter { $0.deviationItem.split(separator: " ").first == Substring(checkpoint.label) }
    }
}
