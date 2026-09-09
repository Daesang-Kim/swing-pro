import SwiftUI

struct SwingClipCardView: View {
    let item: AnalysisFeedViewModel.CardItem

    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 12)
                .fill(.secondary.opacity(0.2))
                .frame(width: 72, height: 72)
                .overlay(Image(systemName: "play.fill").foregroundStyle(.secondary))

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(item.clip.recordedAt, style: .date)
                    Text(item.clip.recordedAt, style: .time)
                }
                .font(.footnote)
                .foregroundStyle(.secondary)

                HStack(spacing: 6) {
                    Label(item.session?.mode == .field ? "필드" : "연습장", systemImage: item.session?.mode == .field ? "flag.fill" : "figure.golf")
                    Text(item.clip.shotType == .fullSwing ? "풀스윙" : "어프로치")
                }
                .font(.caption)
                .foregroundStyle(.secondary)

                if let summary = item.topFeedbackSummary {
                    Text(summary)
                        .font(.caption)
                        .lineLimit(1)
                }
            }

            Spacer()

            if let score = item.clip.score {
                ScoreBadge(score: score)
            }
        }
        .padding(12)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}

private struct ScoreBadge: View {
    let score: Int

    var body: some View {
        VStack {
            Text("\(score)")
                .font(.headline)
            Text("점")
                .font(.caption2)
        }
        .frame(width: 44, height: 44)
        .background(Circle().fill(color.opacity(0.15)))
        .foregroundStyle(color)
    }

    private var color: Color {
        switch score {
        case 80...: return .green
        case 60..<80: return .orange
        default: return .red
        }
    }
}
