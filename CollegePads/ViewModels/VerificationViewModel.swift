//
//  VerificationViewModel.swift
//  CollegePads
//
//  Created by [Your Name] on [Date].
//

import SwiftUI
import FirebaseFirestore
import FirebaseAuth
import FirebaseFirestoreCombineSwift
import Combine

class VerificationViewModel: ObservableObject {
    @Published var errorMessage: String?
    private let db = Firestore.firestore()
    
    /// Uploads the verification image and updates the user's profile as verified.
    func submitVerification(image: UIImage, completion: @escaping (Result<Void, Error>) -> Void) {
        // Assume FirebaseStorageService.shared.uploadVerificationImage(image:) is implemented similarly to profile image uploads.
        FirebaseStorageService.shared.uploadVerificationImage(image: image) { result in
            switch result {
            case .success(let urlString):
                self.updateUserVerificationStatus(imageUrl: urlString, completion: completion)
            case .failure(let error):
                DispatchQueue.main.async {
                    self.errorMessage = error.localizedDescription
                    completion(.failure(error))
                }
            }
        }
    }
    
    /// Updates the current user's profile to mark as verified.
    private func updateUserVerificationStatus(imageUrl: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let currentUserID = Auth.auth().currentUser?.uid else {
            let err = NSError(domain: "Verification", code: 0, userInfo: [NSLocalizedDescriptionKey: "User not authenticated."])
            DispatchQueue.main.async {
                self.errorMessage = err.localizedDescription
                completion(.failure(err))
            }
            return
        }
        let userRef = db.collection("users").document(currentUserID)
        userRef.updateData([
            "isVerified": true,
            "verificationImageUrl": imageUrl
        ]) { error in
            DispatchQueue.main.async {
                if let error = error {
                    self.errorMessage = error.localizedDescription
                    completion(.failure(error))
                } else {
                    completion(.success(()))
                }
            }
        }
    }
}
