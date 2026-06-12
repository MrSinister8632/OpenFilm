import Photos
import PhotosUI
import UIKit
import CoreImage

/// Handles photo import from the user's library using PHPickerViewController.
/// Supported: HEIC, JPEG, PNG, Apple ProRAW.
/// Originals are never modified.
class PhotoImporter {

    enum ImportError: LocalizedError {
        case noImageData
        case unsupportedFormat
        case loadFailed(Error)

        var errorDescription: String? {
            switch self {
            case .noImageData:           return "No image data could be loaded."
            case .unsupportedFormat:     return "This image format is not supported."
            case .loadFailed(let error): return "Failed to load image: \(error.localizedDescription)"
            }
        }
    }

    /// Builds a PHPickerConfiguration that accepts all supported formats.
    static func pickerConfiguration() -> PHPickerConfiguration {
        var config = PHPickerConfiguration(photoLibrary: .shared())
        config.selectionLimit  = 1
        config.filter          = .images
        config.preferredAssetRepresentationMode = .current  // respects ProRAW
        return config
    }

    /// Loads a CIImage and the source asset's localIdentifier from a PHPickerResult.
    static func load(
        from result: PHPickerResult,
        completion: @escaping (Swift.Result<(CIImage, String?), ImportError>) -> Void
    ) {
        let provider = result.itemProvider
        let assetID  = result.assetIdentifier

        // Try ProRAW / RAW first
        if provider.hasItemConformingToTypeIdentifier("com.apple.rawimage") ||
           provider.hasItemConformingToTypeIdentifier("com.adobe.raw-image") {
            provider.loadDataRepresentation(forTypeIdentifier: "public.image") { data, error in
                DispatchQueue.main.async {
                    if let error { completion(.failure(.loadFailed(error))); return }
                    guard let data, let ciImage = CIImage(data: data) else {
                        completion(.failure(.noImageData)); return
                    }
                    completion(.success((ciImage, assetID)))
                }
            }
            return
        }

        // Standard image path (HEIC, JPEG, PNG)
        provider.loadDataRepresentation(forTypeIdentifier: "public.image") { data, error in
            DispatchQueue.main.async {
                if let error { completion(.failure(.loadFailed(error))); return }
                guard let data else { completion(.failure(.noImageData)); return }
                guard let ciImage = CIImage(data: data) else {
                    completion(.failure(.unsupportedFormat)); return
                }
                completion(.success((ciImage, assetID)))
            }
        }
    }

    /// Requests read-only photo library access if not already granted.
    static func requestAuthorizationIfNeeded(completion: @escaping (PHAuthorizationStatus) -> Void) {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        if status == .notDetermined {
            PHPhotoLibrary.requestAuthorization(for: .readWrite, handler: completion)
        } else {
            completion(status)
        }
    }
}
