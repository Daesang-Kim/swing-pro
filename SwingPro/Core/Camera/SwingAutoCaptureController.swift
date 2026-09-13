import AVFoundation
import Combine
import Foundation

/// 연습장/필드 모드가 공통으로 사용하는 "스윙 인식 → 자동 녹화 → 클립 저장" 파이프라인.
/// 카메라, 포즈 추정, 스윙 구간 판별, 저장(사진 라이브러리 + 로컬 DB)을 하나로 엮는다.
@MainActor
final class SwingAutoCaptureController: ObservableObject {
    @Published private(set) var recordingState: SwingRecordingState = .idle
    @Published var shotType: ShotType = .fullSwing
    @Published var cameraView: CameraView = .faceOn
    @Published var cameraViewSource: CameraViewSource = .auto

    /// 클립 저장(사진 라이브러리 + 로컬 DB)이 끝났을 때 방출되는 클립 ID.
    let didSaveClip = PassthroughSubject<String, Never>()
    /// 확인 후 저장 모드에서, 저장 확인 화면으로 이동해야 할 때 방출.
    let awaitingConfirmation = PassthroughSubject<Void, Never>()

    /// 확인 후 저장 모드에서 미리보기로 보여줄 임시 파일. 확인 화면이 구독한다.
    private(set) var pendingPreviewURL: URL?

    private let camera: CameraCapturing & AnyObject
    private let poseEstimator: PoseEstimating
    private let phaseDetector = SwingPhaseDetector()
    private let photoLibraryStore: PhotoLibraryStoring
    private let clipRepository: SwingClipRepository
    private let feedbackEngine = SwingFeedbackEngine()
    private let scorer = SwingScorer()

    private var sessionId: String
    private var autoSaveMode: AutoSaveMode
    private var cameraViewMode: CameraViewMode
    private var collectedSegments: [PoseSegment] = []
    private var pendingSegments: [PoseSegment] = []
    private var cancellables: Set<AnyCancellable> = []

    var captureSession: AVCaptureSession? {
        (camera as? AVFoundationCameraSession)?.captureSession
    }

    init(
        sessionId: String,
        autoSaveMode: AutoSaveMode,
        cameraViewMode: CameraViewMode,
        camera: (CameraCapturing & AnyObject)? = nil,
        poseEstimator: PoseEstimating = VisionPoseEstimator(),
        photoLibraryStore: PhotoLibraryStoring = PhotosPhotoLibraryStore(),
        clipRepository: SwingClipRepository = SwingClipRepository()
    ) {
        self.sessionId = sessionId
        self.autoSaveMode = autoSaveMode
        self.cameraViewMode = cameraViewMode
        self.camera = camera ?? AVFoundationCameraSession()
        self.poseEstimator = poseEstimator
        self.photoLibraryStore = photoLibraryStore
        self.clipRepository = clipRepository
        self.cameraViewSource = cameraViewMode == .auto ? .auto : .manual

        (self.camera as? AVFoundationCameraSession)?.onFrame = { [weak self] sampleBuffer, timestamp in
            self?.handleFrame(sampleBuffer, timestamp: timestamp)
        }

        self.camera.recordingState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in self?.recordingState = state }
            .store(in: &cancellables)

        self.camera.savedClipURL
            .receive(on: DispatchQueue.main)
            .sink { [weak self] url in self?.handleRecordedClip(at: url) }
            .store(in: &cancellables)
    }

    func attach(sessionId: String) {
        self.sessionId = sessionId
    }

    func start() {
        try? camera.startSession()
        phaseDetector.reset()
        collectedSegments.removeAll()
    }

    func stop() {
        camera.stopSession()
    }

    private func handleFrame(_ sampleBuffer: CMSampleBuffer, timestamp: TimeInterval) {
        // 이미 녹화/포스트롤 중이면 새 스윙 감지를 멈춘다. 그렇지 않으면 포스트롤 도중 골퍼의
        // 움직임(공을 줍거나 자세를 다시 잡는 등)이 두 번째 스윙으로 오인식되어, 아직 첫 클립을
        // 쓰고 있는 AVAssetWriter에 begin이 씹히고 상태머신만 한 사이클 소비해버리는 문제가 있었다.
        guard recordingState == .waiting else { return }
        guard let poseFrame = poseEstimator.estimatePose(in: sampleBuffer, timestamp: timestamp) else { return }
        let events = phaseDetector.ingest(poseFrame)

        for event in events {
            switch event {
            case .swingStarted(let ts):
                camera.beginSwingRecording(at: ts)

            case .checkpointReached(let checkpoint, let ts):
                if checkpoint == .p1, cameraViewMode == .auto {
                    applyAutoCameraViewIfNeeded(from: poseFrame)
                }
                collectedSegments.append(
                    PoseSegment(
                        id: UUID().uuidString,
                        clipId: "",
                        segmentType: checkpoint,
                        timestampInVideo: ts,
                        angleSummary: AngleCalculator.summary(for: poseFrame)
                    )
                )

            case .swingFinished(let ts):
                camera.endSwingRecording(postRollDuration: 4.0)
                _ = ts
            }
        }
    }

    private func applyAutoCameraViewIfNeeded(from frame: PoseFrame) {
        guard let result = CameraViewClassifier.classify(addressFrame: frame) else { return }
        guard result.confidence >= CameraViewClassifier.manualOverrideConfidenceThreshold else { return }
        cameraView = result.cameraView
        cameraViewSource = .auto
    }

    private func handleRecordedClip(at fileURL: URL) {
        let segments = collectedSegments
        collectedSegments.removeAll()

        switch autoSaveMode {
        case .auto:
            Task { await persistClip(at: fileURL, segments: segments) }
        case .confirm:
            pendingPreviewURL = fileURL
            pendingSegments = segments
            awaitingConfirmation.send(())
        }
    }

    /// 저장 확인 화면에서 사용자가 "저장"을 선택했을 때 호출.
    func confirmPendingSave() {
        guard let fileURL = pendingPreviewURL else { return }
        let segments = pendingSegments
        pendingPreviewURL = nil
        pendingSegments = []
        Task { await persistClip(at: fileURL, segments: segments) }
    }

    /// 저장 확인 화면에서 사용자가 "삭제"를 선택했을 때 호출.
    func discardPendingClip() {
        if let fileURL = pendingPreviewURL {
            try? FileManager.default.removeItem(at: fileURL)
        }
        pendingPreviewURL = nil
        pendingSegments = []
    }

    private func persistClip(at fileURL: URL, segments: [PoseSegment]) async {
        do {
            let durationSec = (try? await AVURLAsset(url: fileURL).load(.duration).seconds) ?? 0
            let assetIdentifier = try await photoLibraryStore.saveVideo(at: fileURL)
            let clip = try clipRepository.createClip(
                sessionId: sessionId,
                videoAssetIdentifier: assetIdentifier,
                durationSec: durationSec,
                shotType: shotType,
                cameraView: cameraView,
                cameraViewSource: cameraViewSource
            )

            let clipSegments = segments.map { segment in
                PoseSegment(
                    id: segment.id,
                    clipId: clip.id,
                    segmentType: segment.segmentType,
                    timestampInVideo: segment.timestampInVideo,
                    angleSummary: segment.angleSummary
                )
            }
            try clipRepository.addPoseSegments(clipSegments, toClipId: clip.id)

            let feedback = feedbackEngine.generateFeedback(
                clipId: clip.id,
                shotType: shotType,
                cameraView: cameraView,
                poseSegments: clipSegments
            )
            try clipRepository.addFeedback(feedback, toClipId: clip.id)

            let score = scorer.score(shotType: shotType, cameraView: cameraView, poseSegments: clipSegments)
            try clipRepository.updateScore(score, forClipId: clip.id)

            didSaveClip.send(clip.id)
        } catch {
            // TODO: 저장 실패 UX(재시도/알림) 처리.
        }
    }
}
