import AVFoundation
import Foundation

/// 스윙 감지 시점보다 1~2초 앞선 프레임까지 저장할 수 있도록,
/// 상시 촬영 중 최근 N초 분량의 샘플 버퍼를 순환 보관한다.
final class PreRollRingBuffer {
    private let maxDuration: TimeInterval
    private var buffer: [CMSampleBuffer] = []
    private let lock = NSLock()

    init(maxDuration: TimeInterval = 2.0) {
        self.maxDuration = maxDuration
    }

    func append(_ sampleBuffer: CMSampleBuffer) {
        lock.lock()
        defer { lock.unlock() }

        buffer.append(sampleBuffer)
        trimIfNeeded()
    }

    /// 현재 버퍼에 쌓인 프레임을 시간순으로 반환하고 비운다.
    func drain() -> [CMSampleBuffer] {
        lock.lock()
        defer { lock.unlock() }

        let drained = buffer
        buffer.removeAll()
        return drained
    }

    /// 버퍼를 비우지 않고 가장 오래된(=가장 먼저 기록될) 프레임만 확인한다.
    /// AVAssetWriter 설정(해상도/포맷)을 드레인 전에 미리 구성할 때 사용.
    func peekOldest() -> CMSampleBuffer? {
        lock.lock()
        defer { lock.unlock() }
        return buffer.first
    }

    func clear() {
        lock.lock()
        defer { lock.unlock() }
        buffer.removeAll()
    }

    private func trimIfNeeded() {
        guard let newest = buffer.last else { return }
        let newestTime = CMSampleBufferGetPresentationTimeStamp(newest).seconds
        while let oldest = buffer.first,
              newestTime - CMSampleBufferGetPresentationTimeStamp(oldest).seconds > maxDuration {
            buffer.removeFirst()
        }
    }
}
