//
//  AgreementViewModel.swift
//  CollegePads
//
//  Created by [Your Name] on [Date].
//
//  This ViewModel manages the creation and updating of roommate agreements,
//  including extended fields for review and verification options.
import Foundation
import FirebaseFirestore
import FirebaseAuth
import Combine

/// A model representing a roommate agreement with extended review and verification options.
struct RoommateAgreement: Codable, Identifiable {
    @DocumentID var id: String?
    var matchID: String           // The ID of the match/chat document.
    var userA: String             // UID of first participant.
    var userB: String             // UID of second participant.
    var moveInDate: Date
    var sharedResponsibilities: String
    var houseRules: String
    // Extended fields:
    var reviewMode: String        // e.g., "mutual", "anonymous", "one-sided"
    var verificationMethod: String // e.g., "none", "lease"
    var leaseDocumentURL: String? // URL of the uploaded lease document (if any)
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
}

class AgreementViewModel: ObservableObject {
    @Published var agreement: RoommateAgreement?
    @Published var errorMessage: String?
    
    private let db = Firestore.firestore()
    
    /// Saves a new roommate agreement document to Firestore.
    func saveAgreement(_ agreement: RoommateAgreement, completion: @escaping (Result<Void, Error>) -> Void) {
        do {
            _ = try db.collection("roommateAgreements").addDocument(from: agreement) { error in
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
    
    /// Loads an agreement by match ID.
    func loadAgreement(forMatchID matchID: String) {
        db.collection("roommateAgreements")
            .whereField("matchID", isEqualTo: matchID)
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    DispatchQueue.main.async {
                        self.errorMessage = error.localizedDescription
                    }
                    return
                }
                if let doc = snapshot?.documents.first {
                    do {
                        let loadedAgreement = try doc.data(as: RoommateAgreement.self)
                        DispatchQueue.main.async {
                            self.agreement = loadedAgreement
                        }
                    } catch {
                        DispatchQueue.main.async {
                            self.errorMessage = error.localizedDescription
                        }
                    }
                }
            }
    }
}
