import Foundation

enum PhotoLibraryError: Error {
    case permissionDenied
    case saveFailed
    case assetNotFound
}

protocol PhotoLibraryStoring {
    /// 사진 라이브러리 추가 권한을 요청한다.
    func requestAuthorization() async -> Bool

    /// 로컬 파일로 기록된 스윙 클립을 사진 라이브러리에 저장하고, 자산 식별자(PHAsset localIdentifier)를 반환한다.
    /// 이 식별자가 `swing_clips.video_path`에 저장된다.
    func saveVideo(at fileURL: URL) async throws -> String

    /// 자산 식별자로부터 재생 가능한 URL(또는 AVAsset)을 가져온다.
    func videoURL(forAssetIdentifier identifier: String) async throws -> URL
}
