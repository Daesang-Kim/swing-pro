import SwiftUI

/// 그린 위 퍼팅 거리 측정 화면. 공 위치 → 홀 위치 순서로 터치하면 실제 거리를 계산해 표시한다.
struct PuttingMeasurementView: View {
    @StateObject var viewModel: PuttingMeasurementViewModel

    var body: some View {
        ZStack {
            ARPuttingContainerView(viewModel: viewModel)
                .ignoresSafeArea()

            if let point = viewModel.ballScreenPoint {
                MarkerView(label: "공", color: .yellow).position(point)
            }
            if let point = viewModel.holeScreenPoint {
                MarkerView(label: "홀", color: .red).position(point)
            }

            VStack {
                instructionBanner
                Spacer()
                if let distance = viewModel.measuredDistanceM {
                    resultBanner(distance: distance)
                }
            }
            .padding()
        }
    }

    private var instructionBanner: some View {
        Text(
            viewModel.nextTapTarget == .ball
                ? "그린 위 공 위치를 터치하세요"
                : "홀(컵) 위치를 터치하세요"
        )
        .font(.subheadline.weight(.medium))
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(.thinMaterial, in: Capsule())
    }

    private func resultBanner(distance: Double) -> some View {
        HStack {
            Text(String(format: "퍼팅 거리: %.2fm", distance))
                .font(.title3.bold())
            Spacer()
            Button("다시 측정") { viewModel.reset() }
                .buttonStyle(.bordered)
        }
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}

private struct MarkerView: View {
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 2) {
            Image(systemName: "mappin.circle.fill")
                .foregroundStyle(color)
                .font(.title2)
            Text(label)
                .font(.caption2.weight(.bold))
        }
    }
}
