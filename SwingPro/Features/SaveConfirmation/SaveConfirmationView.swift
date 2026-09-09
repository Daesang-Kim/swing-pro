import SwiftUI
import AVKit

/// 설정이 '확인 후 저장'일 때, 스윙 감지 직후 짧은 미리보기와 저장/삭제 버튼을 보여주는 시트.
struct SaveConfirmationView: View {
    @ObservedObject var controller: SwingAutoCaptureController
    let onFinished: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Text("이 스윙을 저장할까요?")
                .font(.title2.bold())
                .padding(.top, 24)

            if let url = controller.pendingPreviewURL {
                VideoPlayer(player: AVPlayer(url: url))
                    .frame(height: 320)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal)
            } else {
                RoundedRectangle(cornerRadius: 16)
                    .fill(.secondary.opacity(0.2))
                    .frame(height: 320)
                    .padding(.horizontal)
            }

            HStack(spacing: 16) {
                Button(role: .destructive) {
                    controller.discardPendingClip()
                    onFinished()
                } label: {
                    Label("삭제", systemImage: "trash")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)

                Button {
                    controller.confirmPendingSave()
                    onFinished()
                } label: {
                    Label("저장", systemImage: "checkmark")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(.horizontal)
            .padding(.bottom, 24)
        }
    }
}
