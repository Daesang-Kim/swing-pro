import SwiftUI

/// 영상 하단에 P1~P10 체크포인트를 탭으로 표시. 탭하면 해당 시점으로 영상이 이동한다.
struct CheckpointMarkerBar: View {
    let availableCheckpoints: [SwingCheckpoint]
    let selected: SwingCheckpoint?
    let onSelect: (SwingCheckpoint) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(SwingCheckpoint.allCases, id: \.self) { checkpoint in
                    let isAvailable = availableCheckpoints.contains(checkpoint)
                    Button {
                        onSelect(checkpoint)
                    } label: {
                        Text(checkpoint.label)
                            .font(.caption.weight(.semibold))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                Capsule().fill(checkpoint == selected ? Color.accentColor : Color.secondary.opacity(0.15))
                            )
                            .foregroundStyle(checkpoint == selected ? .white : .primary)
                    }
                    .disabled(!isAvailable)
                    .opacity(isAvailable ? 1 : 0.3)
                }
            }
            .padding(.horizontal)
        }
    }
}
