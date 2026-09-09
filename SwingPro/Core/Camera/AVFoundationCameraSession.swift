import AVFoundation
import Combine

/// AVFoundation 기반 카메라 세션. 상시 프리뷰 + 프리롤 버퍼링 + 스윙 구간 자동 녹화를 담당한다.
///
/// 녹화 파이프라인: 항상 최근 N초의 비디오/오디오 프레임을 순환 버퍼에 유지하다가,
/// 스윙이 감지되면(`beginSwingRecording`) 그 버퍼를 `AVAssetWriter`에 먼저 흘려보낸 뒤
/// 이후 들어오는 실시간 프레임을 이어서 기록한다. 스윙 종료(`endSwingRecording`) 후에는
/// `postRollDuration`만큼 더 기록하고 파일을 마무리해 `savedClipURL`로 방출한다.
///
/// 모든 녹화 상태(`assetWriter` 등)는 `dataOutputQueue`에서만 읽고 쓴다 — 카메라 프레임 콜백과
/// `beginSwingRecording`/`endSwingRecording` 호출이 같은 큐에서 직렬화되어 경쟁 상태를 피한다.
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
    private let audioOutput = AVCaptureAudioDataOutput()
    private let videoPreRollBuffer: PreRollRingBuffer
    private let audioPreRollBuffer: PreRollRingBuffer
    private let sessionQueue = DispatchQueue(label: "com.swingpro.camera.session")
    /// 카메라 프레임 콜백과 녹화 상태 변경(begin/end)을 모두 이 큐 하나로 직렬화한다.
    private let dataOutputQueue = DispatchQueue(label: "com.swingpro.camera.output")

    /// 포즈 추정/공 트래킹 등 프레임 단위 분석이 필요한 상위 레이어(뷰모델)가 구독하는 훅.
    var onFrame: ((CMSampleBuffer, TimeInterval) -> Void)?

    // MARK: - dataOutputQueue에서만 접근하는 녹화 상태

    private var assetWriter: AVAssetWriter?
    private var videoWriterInput: AVAssetWriterInput?
    private var audioWriterInput: AVAssetWriterInput?
    private var outputURL: URL?
    private var postRollWorkItem: DispatchWorkItem?
    /// `finishWriting`이 이미 진행 중일 때 `cancelWriting`을 겹쳐 호출하지 않기 위한 플래그.
    private var isFinishing = false

    init(preRollDuration: TimeInterval = 2.0) {
        self.videoPreRollBuffer = PreRollRingBuffer(maxDuration: preRollDuration)
        self.audioPreRollBuffer = PreRollRingBuffer(maxDuration: preRollDuration)
        super.init()
    }

    func startSession() throws {
        sessionQueue.async { [weak self] in
            guard let self else { return }
            guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
                  let videoInput = try? AVCaptureDeviceInput(device: videoDevice) else {
                return
            }

            self.captureSession.beginConfiguration()

            if self.captureSession.canAddInput(videoInput) {
                self.captureSession.addInput(videoInput)
            }
            if let audioDevice = AVCaptureDevice.default(for: .audio),
               let audioInput = try? AVCaptureDeviceInput(device: audioDevice),
               self.captureSession.canAddInput(audioInput) {
                self.captureSession.addInput(audioInput)
            }

            self.videoOutput.setSampleBufferDelegate(self, queue: self.dataOutputQueue)
            if self.captureSession.canAddOutput(self.videoOutput) {
                self.captureSession.addOutput(self.videoOutput)
            }
            // 앱이 세로 모드로 고정되어 있으므로(Info.plist), 녹화 결과도 세로로 기록되도록 명시.
            self.videoOutput.connection(with: .video)?.videoOrientation = .portrait

            self.audioOutput.setSampleBufferDelegate(self, queue: self.dataOutputQueue)
            if self.captureSession.canAddOutput(self.audioOutput) {
                self.captureSession.addOutput(self.audioOutput)
            }

            self.captureSession.commitConfiguration()
            self.captureSession.startRunning()
            self.recordingStateSubject.send(.waiting)
        }
    }

    func stopSession() {
        sessionQueue.async { [weak self] in
            self?.captureSession.stopRunning()
        }
        dataOutputQueue.async { [weak self] in
            guard let self else { return }
            self.cancelRecording()
            self.videoPreRollBuffer.clear()
            self.audioPreRollBuffer.clear()
            self.recordingStateSubject.send(.idle)
        }
    }

    func beginSwingRecording(at swingStartTimestamp: TimeInterval) {
        dataOutputQueue.async { [weak self] in
            self?.startRecording()
        }
    }

    func endSwingRecording(postRollDuration: TimeInterval) {
        dataOutputQueue.async { [weak self] in
            self?.scheduleFinish(after: postRollDuration)
        }
    }

    // MARK: - 녹화 파이프라인 (dataOutputQueue 전용)

    private func startRecording() {
        guard assetWriter == nil,
              let firstVideoSample = videoPreRollBuffer.peekOldest(),
              let videoFormat = CMSampleBufferGetFormatDescription(firstVideoSample) else { return }

        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("mov")
        guard let writer = try? AVAssetWriter(outputURL: url, fileType: .mov) else { return }

        let dimensions = CMVideoFormatDescriptionGetDimensions(videoFormat)
        let videoInput = AVAssetWriterInput(mediaType: .video, outputSettings: [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: dimensions.width,
            AVVideoHeightKey: dimensions.height,
        ])
        videoInput.expectsMediaDataInRealTime = true
        guard writer.canAdd(videoInput) else { return }
        writer.add(videoInput)

        var audioInput: AVAssetWriterInput?
        if let firstAudioSample = audioPreRollBuffer.peekOldest(),
           let audioFormat = CMSampleBufferGetFormatDescription(firstAudioSample),
           let asbd = CMAudioFormatDescriptionGetStreamBasicDescription(audioFormat)?.pointee {
            let input = AVAssetWriterInput(mediaType: .audio, outputSettings: [
                AVFormatIDKey: kAudioFormatMPEG4AAC,
                AVSampleRateKey: asbd.mSampleRate,
                AVNumberOfChannelsKey: Int(asbd.mChannelsPerFrame),
                AVEncoderBitRateKey: 128_000,
            ])
            input.expectsMediaDataInRealTime = true
            if writer.canAdd(input) {
                writer.add(input)
                audioInput = input
            }
        }

        guard writer.startWriting() else { return }
        writer.startSession(atSourceTime: CMSampleBufferGetPresentationTimeStamp(firstVideoSample))

        assetWriter = writer
        videoWriterInput = videoInput
        audioWriterInput = audioInput
        outputURL = url

        for sample in videoPreRollBuffer.drain() {
            appendVideo(sample)
        }
        for sample in audioPreRollBuffer.drain() {
            appendAudio(sample)
        }

        recordingStateSubject.send(.recording)
    }

    private func scheduleFinish(after postRollDuration: TimeInterval) {
        guard assetWriter != nil else { return }
        recordingStateSubject.send(.finalizing)

        postRollWorkItem?.cancel()
        let workItem = DispatchWorkItem { [weak self] in
            self?.finishRecording()
        }
        postRollWorkItem = workItem
        dataOutputQueue.asyncAfter(deadline: .now() + postRollDuration, execute: workItem)
    }

    private func finishRecording() {
        guard let writer = assetWriter, let url = outputURL else { return }

        videoWriterInput?.markAsFinished()
        audioWriterInput?.markAsFinished()
        postRollWorkItem = nil
        isFinishing = true

        writer.finishWriting { [weak self] in
            guard let self else { return }
            self.dataOutputQueue.async {
                let wasCancelled = !self.isFinishing
                self.assetWriter = nil
                self.videoWriterInput = nil
                self.audioWriterInput = nil
                self.outputURL = nil
                self.isFinishing = false
                self.recordingStateSubject.send(.waiting)
                if writer.status == .completed, !wasCancelled {
                    self.savedClipURLSubject.send(url)
                } else {
                    try? FileManager.default.removeItem(at: url)
                }
            }
        }
    }

    /// 세션 종료 시 진행 중이던 녹화를 파일로 남기지 않고 취소한다.
    private func cancelRecording() {
        postRollWorkItem?.cancel()
        postRollWorkItem = nil

        if isFinishing {
            // finishWriting이 이미 진행 중 — cancelWriting을 겹쳐 호출하면 안 되므로,
            // isFinishing을 false로 내려 완료 콜백이 결과 파일을 버리도록 표시만 한다.
            isFinishing = false
            return
        }

        if let writer = assetWriter {
            videoWriterInput?.markAsFinished()
            audioWriterInput?.markAsFinished()
            writer.cancelWriting()
        }
        assetWriter = nil
        videoWriterInput = nil
        audioWriterInput = nil

        if let url = outputURL {
            try? FileManager.default.removeItem(at: url)
        }
        outputURL = nil
    }

    private func appendVideo(_ sample: CMSampleBuffer) {
        guard let input = videoWriterInput, input.isReadyForMoreMediaData else { return }
        input.append(sample)
    }

    private func appendAudio(_ sample: CMSampleBuffer) {
        guard let input = audioWriterInput, input.isReadyForMoreMediaData else { return }
        input.append(sample)
    }
}

extension AVFoundationCameraSession: AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate {
    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        let isVideo = output === videoOutput

        if assetWriter != nil {
            isVideo ? appendVideo(sampleBuffer) : appendAudio(sampleBuffer)
        } else if recordingStateSubject.value == .waiting {
            isVideo ? videoPreRollBuffer.append(sampleBuffer) : audioPreRollBuffer.append(sampleBuffer)
        }

        if isVideo {
            let timestamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer).seconds
            onFrame?(sampleBuffer, timestamp)
        }
    }
}
