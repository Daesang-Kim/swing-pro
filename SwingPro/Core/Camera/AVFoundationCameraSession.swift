import AVFoundation
import Combine

/// AVFoundation 기반 카메라 세션. 상시 프리뷰 + 프리롤 버퍼링 + 스윙 구간 자동 녹화를 담당한다.
///
/// 실제 캡처 파이프라인(AVCaptureSession 구성, AVAssetWriter를 이용한
/// 프리롤 버퍼 프레임 + 이후 프레임의 파일 기록, 사진 라이브러리 저장 트리거)은
/// Xcode/실기기 환경에서 구현·검증이 필요한 부분이라 TODO로 남겨둔다.
final class AVFoundationCameraSession: NSObject, CameraCapturing {
    private let recordingStateSubject = CurrentValueSubject<SwingRecordingState, Never>(.idle)
    private let savedClipURLSubject = PassthroughSubject<URL, Never>()

    var recordingState: AnyPublisher<SwingRecordingState, Never> {
        recordingStateSubject.eraseToAnyPublisher()
    }
    var savedClipURL: AnyPublisher<URL, Never> {
        savedClipURLSubject.eraseToAnyPublisher()
    }

    let captureSession = AVCaptureSession()
    private let videoOutput = AVCaptureVideoDataOutput()
    private let preRollBuffer: PreRollRingBuffer
    private let sessionQueue = DispatchQueue(label: "com.swingpro.camera.session")
    private let dataOutputQueue = DispatchQueue(label: "com.swingpro.camera.output")

    /// 포즈 추정/공 트래킹 등 프레임 단위 분석이 필요한 상위 레이어(뷰모델)가 구독하는 훅.
    var onFrame: ((CMSampleBuffer, TimeInterval) -> Void)?

    init(preRollDuration: TimeInterval = 2.0) {
        self.preRollBuffer = PreRollRingBuffer(maxDuration: preRollDuration)
        super.init()
    }

    func startSession() throws {
        sessionQueue.async { [weak self] in
            guard let self else { return }
            guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
                  let input = try? AVCaptureDeviceInput(device: device) else {
                return
            }

            self.captureSession.beginConfiguration()
            if self.captureSession.canAddInput(input) {
                self.captureSession.addInput(input)
            }
            self.videoOutput.setSampleBufferDelegate(self, queue: self.dataOutputQueue)
            if self.captureSession.canAddOutput(self.videoOutput) {
                self.captureSession.addOutput(self.videoOutput)
            }
            self.captureSession.commitConfiguration()
            self.captureSession.startRunning()
            self.recordingStateSubject.send(.waiting)
        }
    }

    func stopSession() {
        sessionQueue.async { [weak self] in
            self?.captureSession.stopRunning()
            self?.preRollBuffer.clear()
            self?.recordingStateSubject.send(.idle)
        }
    }

    func beginSwingRecording(at swingStartTimestamp: TimeInterval) {
        // TODO: preRollBuffer.drain()으로 얻은 프레임을 AVAssetWriter에 먼저 기록한 뒤,
        // 이후 들어오는 실시간 프레임을 계속 이어서 기록하도록 전환한다.
        recordingStateSubject.send(.recording)
    }

    func endSwingRecording(postRollDuration: TimeInterval) {
        // TODO: postRollDuration만큼 더 기록한 뒤 AVAssetWriter를 finish하고,
        // 결과 파일 URL을 savedClipURLSubject로 방출한다.
        recordingStateSubject.send(.finalizing)
    }
}

extension AVFoundationCameraSession: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        if recordingStateSubject.value == .waiting {
            preRollBuffer.append(sampleBuffer)
        }

        let timestamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer).seconds
        onFrame?(sampleBuffer, timestamp)
    }
}
