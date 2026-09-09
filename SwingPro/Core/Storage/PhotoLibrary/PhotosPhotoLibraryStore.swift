import Photos
import AVFoundation

/// `Photos` 프레임워크(PHAsset)를 이용해 스윙 클립 원본을 시스템 사진 라이브러리에 저장한다.
/// 저장 공간 관리는 OS/사진 앱이 담당하므로, 앱은 자산 식별자만 로컬 DB에 보관한다.
final class PhotosPhotoLibraryStore: PhotoLibraryStoring {
    func requestAuthorization() async -> Bool {
        let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
        return status == .authorized || status == .limited
    }

    func saveVideo(at fileURL: URL) async throws -> String {
        var placeholderIdentifier: String?

        try await PHPhotoLibrary.shared().performChanges {
            let request = PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: fileURL)
            placeholderIdentifier = request?.placeholderForCreatedAsset?.localIdentifier
        }

        guard let identifier = placeholderIdentifier else {
            throw PhotoLibraryError.saveFailed
        }
        return identifier
    }

    func videoURL(forAssetIdentifier identifier: String) async throws -> URL {
        let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: [identifier], options: nil)
        guard let asset = fetchResult.firstObject else {
            throw PhotoLibraryError.assetNotFound
        }

        return try await withCheckedThrowingContinuation { continuation in
            let options = PHVideoRequestOptions()
            options.deliveryMode = .highQualityFormat
            options.isNetworkAccessAllowed = false

            PHImageManager.default().requestAVAsset(forVideo: asset, options: options) { avAsset, _, _ in
                guard let urlAsset = avAsset as? AVURLAsset else {
                    continuation.resume(throwing: PhotoLibraryError.assetNotFound)
                    return
                }
                continuation.resume(returning: urlAsset.url)
            }
        }
    }
}
