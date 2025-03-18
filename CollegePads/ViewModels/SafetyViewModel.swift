//
//  SafetyViewModel.swift
//  CollegePads
//
//  Created by [Your Name] on [Date].
//

import Foundation
import FirebaseFirestore
import FirebaseAuth
import Combine

class SafetyViewModel: ObservableObject {
    @Published var errorMessage: String?
    private let db = Firestore.firestore()
    
    /// Submits a report against a user.
    /// - Parameters:
    ///   - reportedUserID: The UID of the reported user.
    ///   - reason: The reason provided by the reporter.
    ///   - completion: Completion handler with success or error.
    func reportUser(reportedUserID: String, reason: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let reporterID = Auth.auth().currentUser?.uid else {
            let error = NSError(domain: "SafetyViewModel", code: 0, userInfo: [NSLocalizedDescriptionKey: "User not authenticated."])
            DispatchQueue.main.async {
                self.errorMessage = error.localizedDescription
                completion(.failure(error))
            }
            return
        }
        
        let reportData: [String: Any] = [
            "reporterID": reporterID,
            "reportedUserID": reportedUserID,
            "reason": reason,
            "timestamp": FieldValue.serverTimestamp()
        ]
        
        db.collection("reports").addDocument(data: reportData) { error in
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
