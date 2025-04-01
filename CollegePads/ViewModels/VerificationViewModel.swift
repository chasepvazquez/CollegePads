import SwiftUI
import FirebaseFirestore
import FirebaseAuth
import FirebaseFirestoreCombineSwift
import Combine

class VerificationViewModel: ObservableObject {
    @Published var errorMessage: String?
    private let db = Firestore.firestore()
    
    /// Sends an email verification to the current user.
    func sendEmailVerification(completion: @escaping (Result<Void, Error>) -> Void) {
        guard let user = Auth.auth().currentUser else {
            let err = NSError(domain: "Verification", code: 0,
                              userInfo: [NSLocalizedDescriptionKey: "User not authenticated."])
            DispatchQueue.main.async {
                self.errorMessage = err.localizedDescription
                completion(.failure(err))
            }
            return
        }
        user.sendEmailVerification { error in
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
    
    /// Reloads the current user and updates Firestore if the email is verified.
    func refreshVerificationStatus(completion: @escaping (Result<Void, Error>) -> Void) {
        guard let user = Auth.auth().currentUser else {
            let err = NSError(domain: "Verification", code: 0,
                              userInfo: [NSLocalizedDescriptionKey: "User not authenticated."])
            DispatchQueue.main.async {
                self.errorMessage = err.localizedDescription
                completion(.failure(err))
            }
            return
        }
        user.reload { error in
            DispatchQueue.main.async {
                if let error = error {
                    self.errorMessage = error.localizedDescription
                    completion(.failure(error))
                } else if user.isEmailVerified {
                    self.updateUserAsVerified(completion: completion)
                } else {
                    let err = NSError(domain: "Verification", code: 0,
                                      userInfo: [NSLocalizedDescriptionKey: "Email not yet verified."])
                    self.errorMessage = err.localizedDescription
                    completion(.failure(err))
                }
            }
        }
    }
    
    /// Updates the current user's Firestore document to mark as verified (for email verification).
    func updateUserAsVerified(completion: @escaping (Result<Void, Error>) -> Void) {
        guard let currentUserID = Auth.auth().currentUser?.uid else {
            let err = NSError(domain: "Verification", code: 0,
                              userInfo: [NSLocalizedDescriptionKey: "User not authenticated."])
            DispatchQueue.main.async {
                self.errorMessage = err.localizedDescription
                completion(.failure(err))
            }
            return
        }
        let userRef = db.collection("users").document(currentUserID)
        userRef.updateData([
            "isVerified": true
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
