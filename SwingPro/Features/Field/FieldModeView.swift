import SwiftUI

struct FieldModeView: View {
    @EnvironmentObject private var appState: AppState
    @StateObject private var viewModel: FieldModeViewModel

    init(appState: AppState) {
        _viewModel = StateObject(wrappedValue: FieldModeViewModel(appState: appState))
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            if viewModel.isPuttingModeActive {
                PuttingMeasurementView(viewModel: viewModel.puttingViewModel)
            } else if let session = viewModel.captureController.captureSession {
                CameraPreviewView(session: session)
                    .ignoresSafeArea()
            } else {
                Color.black.ignoresSafeArea()
            }

            if !viewModel.isPuttingModeActive {
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
                .padding(.bottom, 90)
            }

            VStack {
                Spacer()
                Button {
                    viewModel.togglePuttingMode()
                } label: {
                    Label(
                        viewModel.isPuttingModeActive ? "스윙 촬영으로 전환" : "퍼팅 거리 측정",
                        systemImage: viewModel.isPuttingModeActive ? "camera.fill" : "ruler.fill"
                    )
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(viewModel.isPuttingModeActive ? .gray : .green)
                .padding(.horizontal)
                .padding(.bottom, 24)
            }
        }
        .navigationTitle("필드 모드")
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
