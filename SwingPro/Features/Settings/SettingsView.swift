import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var appState: AppState
    @StateObject private var viewModel: SettingsViewModel

    init(appState: AppState) {
        _viewModel = StateObject(wrappedValue: SettingsViewModel(
            userProfile: appState.currentUser,
            repository: appState.settingsRepository
        ))
    }

    var body: some View {
        Form {
            Section("스윙 클립 저장 방식") {
                Picker("저장 방식", selection: Binding(
                    get: { viewModel.autoSaveMode },
                    set: { viewModel.updateAutoSaveMode($0) }
                )) {
                    Text("자동 저장").tag(AutoSaveMode.auto)
                    Text("확인 후 저장").tag(AutoSaveMode.confirm)
                }
                .pickerStyle(.inline)
            }

            Section("촬영 방향 감지 방식") {
                Picker("감지 방식", selection: Binding(
                    get: { viewModel.cameraViewMode },
                    set: { viewModel.updateCameraViewMode($0) }
                )) {
                    Text("자동 감지").tag(CameraViewMode.auto)
                    Text("직접 선택").tag(CameraViewMode.manual)
                }
                .pickerStyle(.inline)
            }
        }
        .navigationTitle("설정")
        .onDisappear {
            appState.refreshCurrentUser()
        }
    }
}
