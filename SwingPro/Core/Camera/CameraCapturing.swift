import AVFoundation
import Combine
import Foundation

enum SwingRecordingState: Equatable {
    case idle
    case waiting
    case recording
    case finalizing
}

protocol CameraCapturing: AnyObject {
    var recordingState: AnyPublisher<SwingRecordingState, Never> { get }
    /// 클립 저장이 끝날 때마다 최종 파일 URL을 방출.
    var savedClipURL: AnyPublisher<URL, Never> { get }

    func startSession() throws
    func stopSession()

    /// `SwingPhaseDetector`가 백스윙 시작(스윙 개시)을 감지했을 때 호출.
    /// 프리롤 버퍼에 이미 쌓여있던 프레임부터 이어서 기록을 시작한다.
    func beginSwingRecording(at swingStartTimestamp: TimeInterval)

    /// `SwingPhaseDetector`가 피니시(P10)를 감지했을 때 호출.
    /// 이후 `postRollDuration`만큼 더 녹화하고 자동 종료한다.
    func endSwingRecording(postRollDuration: TimeInterval)
}
