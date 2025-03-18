//
//  RoommateReviewViewModel.swift
//  CollegePads
//
//  Created by [Your Name] on [Date].
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

/// Represents a roommate review.
struct RoommateReview: Codable, Identifiable {
    @DocumentID var id: String?
    var matchID: String         // The unique match identifier between the two users.
    var raterID: String         // UID of the reviewer.
    var ratedID: String         // UID of the person being reviewed.
    var rating: Int             // Rating from 1 to 5.
    var reviewText: String?     // Optional written review.
    /// Review mode: "mutual", "anonymous", or "one-sided"
    var reviewMode: String
    /// Verification method: "none", "lease", etc.
    var verificationMethod: String
    /// URL to the uploaded lease/document, if any.
    var leaseDocumentURL: String?
    var timestamp: Date = Date()
}

class RoommateReviewViewModel: ObservableObject {
    @Published var errorMessage: String?
    private let db = Firestore.firestore()
    
    /// Submits a roommate review to Firestore.
    /// - Parameters:
    ///   - matchID: The unique match identifier.
    ///   - ratedID: UID of the person being reviewed.
    ///   - rating: An integer rating (1–5).
    ///   - reviewText: Optional written review.
    ///   - reviewMode: "mutual", "anonymous", or "one-sided".
    ///   - verificationMethod: "none", "lease", etc.
    ///   - leaseDocumentURL: Optional URL of the uploaded document.
    ///   - completion: Completion handler with Result.
    func submitReview(matchID: String,
                      ratedID: String,
                      rating: Int,
                      reviewText: String?,
                      reviewMode: String,
                      verificationMethod: String,
                      leaseDocumentURL: String?,
                      completion: @escaping (Result<Void, Error>) -> Void) {
        
        guard let raterID = Auth.auth().currentUser?.uid else {
            let err = NSError(domain: "RoommateReview", code: 0, userInfo: [NSLocalizedDescriptionKey: "User not authenticated."])
            DispatchQueue.main.async {
                self.errorMessage = err.localizedDescription
                completion(.failure(err))
            }
            return
        }
        
        let review = RoommateReview(matchID: matchID,
                                    raterID: raterID,
                                    ratedID: ratedID,
                                    rating: rating,
                                    reviewText: reviewText,
                                    reviewMode: reviewMode,
                                    verificationMethod: verificationMethod,
                                    leaseDocumentURL: leaseDocumentURL)
        
        do {
            _ = try db.collection("roommateReviews").addDocument(from: review) { error in
                DispatchQueue.main.async {
                    if let error = error {
                        self.errorMessage = error.localizedDescription
                        completion(.failure(error))
                    } else {
                        completion(.success(()))
                    }
                }
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = error.localizedDescription
                completion(.failure(error))
            }
        }
    }
}
