import SwiftUI
import ARKit

/// ARSCNView를 감싸는 SwiftUI 래퍼. 생성된 뷰를 `PuttingMeasurementViewModel`에 연결해
/// 평면 인식을 시작하고, 사용자 터치 좌표를 뷰모델로 전달한다.
struct ARPuttingContainerView: UIViewRepresentable {
    @ObservedObject var viewModel: PuttingMeasurementViewModel

    func makeCoordinator() -> Coordinator {
        Coordinator(viewModel: viewModel)
    }

    func makeUIView(context: Context) -> ARSCNView {
        let arView = ARSCNView()
        viewModel.attach(arView: arView)

        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        arView.addGestureRecognizer(tapGesture)

        return arView
    }

    func updateUIView(_ uiView: ARSCNView, context: Context) {}

    static func dismantleUIView(_ uiView: ARSCNView, coordinator: Coordinator) {
        coordinator.viewModel.detach()
    }

    @MainActor
    final class Coordinator: NSObject {
        let viewModel: PuttingMeasurementViewModel

        init(viewModel: PuttingMeasurementViewModel) {
            self.viewModel = viewModel
        }

        @objc func handleTap(_ recognizer: UITapGestureRecognizer) {
            guard let view = recognizer.view else { return }
            viewModel.handleTap(at: recognizer.location(in: view))
        }
    }
}
