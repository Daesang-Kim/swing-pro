import SwiftUI

struct PracticeModeView: View {
    @EnvironmentObject private var appState: AppState
    @StateObject private var viewModel: PracticeModeViewModel

    init(appState: AppState) {
        _viewModel = StateObject(wrappedValue: PracticeModeViewModel(appState: appState))
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            if let session = viewModel.captureController.captureSession {
                CameraPreviewView(session: session)
                    .ignoresSafeArea()
            } else {
                Color.black.ignoresSafeArea()
            }

            VStack(spacing: 12) {
                SwingCaptureControlsView(
                    controller: viewModel.captureController,
                    cameraViewMode: appState.currentUser.cameraViewMode
                )

                if let clipId = viewModel.lastSavedClipId {
                    Button {
                        viewModel.viewLastSavedClip()
                    } label: {
                        Label("마지막 스윙 보기 (클립 \(clipId.prefix(6)))", systemImage: "play.rectangle.fill")
                    }
                    .buttonStyle(.borderedProminent)
                    .padding(.horizontal)
                }
            }
            .padding(.bottom, 24)
        }
        .navigationTitle("연습장 모드")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { viewModel.onAppear() }
        .onDisappear { viewModel.onDisappear() }
        .sheet(isPresented: $viewModel.isShowingSaveConfirmation) {
            SaveConfirmationView(controller: viewModel.captureController) {
                viewModel.isShowingSaveConfirmation = false
            }
        }
    }
}
