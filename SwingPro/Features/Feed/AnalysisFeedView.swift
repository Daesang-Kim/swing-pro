import SwiftUI

struct AnalysisFeedView: View {
    @EnvironmentObject private var appState: AppState
    @StateObject private var viewModel = AnalysisFeedViewModel()

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(viewModel.items) { item in
                    Button {
                        appState.push(.clipDetail(clipId: item.clip.id))
                    } label: {
                        SwingClipCardView(item: item)
                    }
                    .buttonStyle(.plain)
                }

                if viewModel.items.isEmpty {
                    Text("아직 촬영된 스윙이 없습니다.")
                        .foregroundStyle(.secondary)
                        .padding(.top, 64)
                }
            }
            .padding()
        }
        .navigationTitle("분석 피드")
        .onAppear { viewModel.load(userId: appState.currentUser.id) }
    }
}
