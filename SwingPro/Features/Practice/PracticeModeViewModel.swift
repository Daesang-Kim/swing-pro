import Combine
import Foundation

@MainActor
final class PracticeModeViewModel: ObservableObject {
    @Published private(set) var sessionId: String?
    @Published var lastSavedClipId: String?
    @Published var isShowingSaveConfirmation = false

    let captureController: SwingAutoCaptureController

    private let appState: AppState
    private var cancellables: Set<AnyCancellable> = []

    init(appState: AppState) {
        self.appState = appState
        self.captureController = SwingAutoCaptureController(
            sessionId: "",
            autoSaveMode: appState.currentUser.autoSaveMode,
            cameraViewMode: appState.currentUser.cameraViewMode,
            clipRepository: appState.clipRepository
        )

        if let session = try? appState.sessionRepository.startSession(
            userId: appState.currentUser.id,
            mode: .practice
        ) {
            sessionId = session.id
            captureController.attach(sessionId: session.id)
        }

        captureController.didSaveClip
            .receive(on: DispatchQueue.main)
            .sink { [weak self] clipId in self?.lastSavedClipId = clipId }
            .store(in: &cancellables)

        captureController.awaitingConfirmation
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.isShowingSaveConfirmation = true }
            .store(in: &cancellables)
    }

    func onAppear() {
        captureController.start()
    }

    func onDisappear() {
        captureController.stop()
        if let sessionId {
            try? appState.sessionRepository.endSession(sessionId: sessionId)
        }
    }

    func viewLastSavedClip() {
        guard let clipId = lastSavedClipId else { return }
        appState.push(.clipDetail(clipId: clipId))
    }
}
