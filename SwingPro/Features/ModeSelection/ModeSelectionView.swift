import SwiftUI

struct ModeSelectionView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        VStack(spacing: 24) {
            Text("Swing Pro")
                .font(.largeTitle.bold())
                .padding(.top, 48)

            Spacer()

            ModeCardButton(
                title: "연습장 모드",
                subtitle: "스윙 자동 촬영",
                systemImage: "figure.golf"
            ) {
                appState.push(.practice)
            }

            ModeCardButton(
                title: "필드 모드",
                subtitle: "스윙 자동 촬영 + 퍼팅 거리 측정",
                systemImage: "flag.fill"
            ) {
                appState.push(.field)
            }

            Spacer()

            HStack(spacing: 32) {
                Button {
                    appState.push(.feed)
                } label: {
                    Label("분석 피드", systemImage: "list.bullet.rectangle")
                }

                Button {
                    appState.push(.settings)
                } label: {
                    Label("설정", systemImage: "gearshape")
                }
            }
            .padding(.bottom, 32)
        }
        .padding(.horizontal, 24)
    }
}

private struct ModeCardButton: View {
    let title: String
    let subtitle: String
    let systemImage: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: systemImage)
                    .font(.system(size: 32))
                    .frame(width: 48)

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.title2.bold())
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(.secondary)
            }
            .padding(20)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
        .foregroundStyle(.primary)
    }
}

#Preview {
    ModeSelectionView()
        .environmentObject(AppState())
}
