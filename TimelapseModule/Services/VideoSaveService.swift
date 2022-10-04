import Foundation
import Photos

final class VideoSaveService {

    func saveVideo(with url: URL, completionHandler: @escaping () -> ()) {
        PHPhotoLibrary.requestAuthorization { status in
            guard status == .authorized else {
                print("Error saving video: unauthorized access")
                return
            }
            
            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.creationRequestForAssetFromImage(atFileURL: url)
                completionHandler()
            })
        }
    }
}
