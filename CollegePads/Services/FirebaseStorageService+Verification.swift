//
//  FirebaseStorageService+Verification.swift
//  CollegePads
//
//  Created by [Your Name] on [Date].
//

import UIKit
import FirebaseStorage

extension FirebaseStorageService {
    /// Uploads a verification image (e.g., student ID) and returns its download URL.
    /// - Parameters:
    ///   - image: The UIImage to upload.
    ///   - completion: A completion handler that returns a Result containing the download URL String or an Error.
    func uploadVerificationImage(image: UIImage, completion: @escaping (Result<String, Error>) -> Void) {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            let error = NSError(domain: "FirebaseStorageService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Unable to convert image to data."])
            completion(.failure(error))
            return
        }
        
        let filename = UUID().uuidString + ".jpg"
        let storageRef = Storage.storage().reference().child("verification").child(filename)
        
        storageRef.putData(imageData, metadata: nil) { metadata, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            storageRef.downloadURL { url, error in
                if let error = error {
                    completion(.failure(error))
                } else if let downloadURL = url {
                    completion(.success(downloadURL.absoluteString))
                } else {
                    let error = NSError(domain: "FirebaseStorageService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Download URL not available."])
                    completion(.failure(error))
                }
            }
        }
    }
}
