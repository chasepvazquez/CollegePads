//
//  BlockUserViewModel.swift
//  CollegePads
//
//  Created by [Your Name] on [Date].
//

import Foundation
import FirebaseFirestore
import FirebaseAuth
import FirebaseFirestoreCombineSwift
import Combine

class BlockUserViewModel: ObservableObject {
    @Published var errorMessage: String?
    private let db = Firestore.firestore()
    
    /// Blocks a user by adding their UID to the current user's blockedUserIDs array.
    /// - Parameters:
    ///   - candidateID: The UID of the user to block.
    ///   - completion: A completion handler with success or failure.
    func blockUser(candidateID: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let currentUserID = Auth.auth().currentUser?.uid else {
            let err = NSError(domain: "BlockUser", code: 0, userInfo: [NSLocalizedDescriptionKey: "User not authenticated."])
            DispatchQueue.main.async {
                self.errorMessage = err.localizedDescription
                completion(.failure(err))
            }
            return
        }
        
        let userRef = db.collection("users").document(currentUserID)
        userRef.updateData([
            "blockedUserIDs": FieldValue.arrayUnion([candidateID])
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
