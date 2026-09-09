import Combine
import Foundation

@MainActor
final class FieldModeViewModel: ObservableObject {
    @Published private(set) var sessionId: String?
    @Published var lastSavedClipId: String?
    @Published var isShowingSaveConfirmation = false
    @Published var isPuttingModeActive = false

    let captureController: SwingAutoCaptureController
    let puttingViewModel: PuttingMeasurementViewModel
    let appState: AppState

    private var cancellables: Set<AnyCancellable> = []

    init(appState: AppState) {
        self.appState = appState
        self.captureController = SwingAutoCaptureController(
            sessionId: "",
            autoSaveMode: appState.currentUser.autoSaveMode,
            cameraViewMode: appState.currentUser.cameraViewMode,
            clipRepository: appState.clipRepository
        )

        var resolvedSessionId = ""
        if let session = try? appState.sessionRepository.startSession(
            userId: appState.currentUser.id,
            mode: .field
        ) {
            resolvedSessionId = session.id
            captureController.attach(sessionId: session.id)
        }
        sessionId = resolvedSessionId
        puttingViewModel = PuttingMeasurementViewModel(sessionId: resolvedSessionId)

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
        if !isPuttingModeActive {
            captureController.start()
        }
    }

    func onDisappear() {
        captureController.stop()
        if let sessionId {
            try? appState.sessionRepository.endSession(sessionId: sessionId)
        }
    }

    func togglePuttingMode() {
        isPuttingModeActive.toggle()
        if isPuttingModeActive {
            captureController.stop()
        } else {
            captureController.start()
        }
    }

    func viewLastSavedClip() {
        guard let clipId = lastSavedClipId else { return }
        appState.push(.clipDetail(clipId: clipId))
    }
}
