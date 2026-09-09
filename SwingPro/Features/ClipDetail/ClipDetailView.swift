import SwiftUI
import AVKit

struct ClipDetailView: View {
    @StateObject private var viewModel: ClipDetailViewModel

    init(clipId: String) {
        _viewModel = StateObject(wrappedValue: ClipDetailViewModel(clipId: clipId))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if let player = viewModel.player {
                    VideoPlayer(player: player)
                        .frame(height: 320)
                } else {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.secondary.opacity(0.2))
                        .frame(height: 320)
                        .overlay(ProgressView())
                }

                if let score = viewModel.clip?.score {
                    HStack {
                        Text("종합 점수")
                            .font(.headline)
                        Spacer()
                        Text("\(score)점")
                            .font(.title.bold())
                    }
                    .padding(.horizontal)
                }

                CheckpointMarkerBar(
                    availableCheckpoints: viewModel.poseSegments.map(\.segmentType),
                    selected: viewModel.selectedCheckpoint
                ) { checkpoint in
                    viewModel.selectCheckpoint(checkpoint)
                }

                if let segment = viewModel.selectedSegment {
                    SegmentDetailView(segment: segment, feedback: viewModel.feedbackForSelectedCheckpoint)
                        .padding(.horizontal)
                }

                Spacer(minLength: 24)
            }
            .padding(.top)
        }
        .navigationTitle("클립 상세")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { viewModel.load() }
    }
}

private struct SegmentDetailView: View {
    let segment: PoseSegment
    let feedback: [SwingFeedbackItem]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("\(segment.segmentType.label) · \(segment.segmentType.displayName)")
                .font(.title3.bold())

            ForEach(segment.angleSummary.metrics.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
                HStack {
                    Text(key)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(String(format: "%.1f°", value))
                        .monospacedDigit()
                }
                .font(.subheadline)
            }

            if !feedback.isEmpty {
                Divider()
                ForEach(feedback) { item in
                    Label(item.message, systemImage: "exclamationmark.triangle.fill")
                        .font(.footnote)
                        .foregroundStyle(.orange)
                }
            }
        }
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}
