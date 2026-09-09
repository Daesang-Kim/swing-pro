import SwiftUI

/// 연습장/필드 모드 공통: 스윙 감지 상태 인디케이터 + 풀스윙/어프로치 + 촬영 방향 선택.
struct SwingCaptureControlsView: View {
    @ObservedObject var controller: SwingAutoCaptureController
    let cameraViewMode: CameraViewMode

    var body: some View {
        VStack(spacing: 12) {
            RecordingStateBadge(state: controller.recordingState)

            Picker("샷 유형", selection: $controller.shotType) {
                Text("풀스윙").tag(ShotType.fullSwing)
                Text("어프로치").tag(ShotType.approach)
            }
            .pickerStyle(.segmented)

            if cameraViewMode == .manual {
                Picker("촬영 방향", selection: $controller.cameraView) {
                    Text("정면").tag(CameraView.faceOn)
                    Text("다운더라인").tag(CameraView.downTheLine)
                }
                .pickerStyle(.segmented)
                .onChange(of: controller.cameraView) { _ in
                    controller.cameraViewSource = .manual
                }
            } else {
                HStack {
                    Image(systemName: "wand.and.stars")
                    Text("촬영 방향 자동 감지: \(controller.cameraView == .faceOn ? "정면" : "다운더라인")")
                    Spacer()
                }
                .font(.footnote)
                .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
    }
}

private struct RecordingStateBadge: View {
    let state: SwingRecordingState

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(text)
                .font(.footnote.weight(.medium))
        }
    }

    private var text: String {
        switch state {
        case .idle: return "대기 중"
        case .waiting: return "스윙을 기다리는 중"
        case .recording: return "스윙 감지됨 · 녹화 중"
        case .finalizing: return "저장 중"
        }
    }

    private var color: Color {
        switch state {
        case .idle: return .gray
        case .waiting: return .yellow
        case .recording: return .red
        case .finalizing: return .blue
        }
    }
}
