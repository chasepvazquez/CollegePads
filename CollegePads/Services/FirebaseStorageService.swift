//
//  FirebaseStorageService.swift
//  CollegePads
//
//  Created by [Your Name] on [Date].
//

import Foundation
import FirebaseStorage
import UIKit

class FirebaseStorageService {
    static let shared = FirebaseStorageService()
    private let storage = Storage.storage().reference()

    /// Uploads a profile image to Firebase Storage.
    /// - Parameters:
    ///   - image: The UIImage to upload.
    ///   - completion: Returns a URL string on success or an error.
    func uploadProfileImage(image: UIImage, completion: @escaping (Result<String, Error>) -> Void) {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            completion(.failure(NSError(domain: "ImageConversion", code: 0, userInfo: [NSLocalizedDescriptionKey: "Unable to convert image to JPEG data."])))
            return
        }
        let imageID = UUID().uuidString
        let imageRef = storage.child("profile_images/\(imageID).jpg")
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        imageRef.putData(imageData, metadata: metadata) { metadata, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            imageRef.downloadURL { url, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                guard let downloadURL = url else {
                    completion(.failure(NSError(domain: "DownloadURL", code: 0, userInfo: [NSLocalizedDescriptionKey: "Download URL not available."])))
                    return
                }
                completion(.success(downloadURL.absoluteString))
            }
        }
    }
}
