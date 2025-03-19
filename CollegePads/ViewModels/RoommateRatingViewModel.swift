//
//  RoommateReviewViewModel.swift
//  CollegePads
//
//  Created by [Your Name] on [Date].
//
//  This ViewModel handles the submission of roommate reviews and ratings to Firestore.
//  It writes a new document to the "roommateReviews" collection containing the matchID,
//  the IDs of both the rater and rated user, the rating, an optional review text, the selected review mode,
//  the selected verification method, and an optional lease document URL.
import Foundation
import FirebaseFirestore
import FirebaseAuth
import FirebaseFirestoreCombineSwift
import Combine

class RoommateReviewViewModel: ObservableObject {
    @Published var errorMessage: String?
    private let db = Firestore.firestore()
    
    /// Submits a roommate review to Firestore.
    /// - Parameters:
    ///   - matchID: The match identifier.
    ///   - ratedUserID: The UID of the user being reviewed.
    ///   - rating: An integer rating (1 to 5).
    ///   - reviewText: Optional review text.
    ///   - reviewMode: The review mode as a lowercase string (e.g., "mutual", "anonymous", "one-sided").
    ///   - verificationMethod: The verification method as a lowercase string (e.g., "none", "lease upload").
    ///   - leaseDocumentURL: An optional URL for the lease document if uploaded.
    ///   - completion: A completion handler returning success or error.
    func submitReview(matchID: String,
                      ratedUserID: String,
                      rating: Int,
                      reviewText: String,
                      reviewMode: String,
                      verificationMethod: String,
                      leaseDocumentURL: String?,
                      completion: @escaping (Result<Void, Error>) -> Void) {
        
        guard let currentUserID = Auth.auth().currentUser?.uid else {
            let error = NSError(domain: "RoommateReview", code: 0, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
            DispatchQueue.main.async {
                self.errorMessage = error.localizedDescription
                completion(.failure(error))
            }
            return
        }
        
        let reviewData: [String: Any] = [
            "matchID": matchID,
            "raterUserID": currentUserID,
            "ratedUserID": ratedUserID,
            "rating": rating,
            "review": reviewText,
            "reviewMode": reviewMode,
            "verificationMethod": verificationMethod,
            "leaseDocumentURL": leaseDocumentURL as Any,
            "timestamp": FieldValue.serverTimestamp()
        ]
        
        db.collection("roommateReviews").addDocument(data: reviewData) { error in
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
