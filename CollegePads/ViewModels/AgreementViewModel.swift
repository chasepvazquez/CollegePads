//
//  AgreementViewModel.swift
//  CollegePads
//
//  Created by [Your Name] on [Date].
//

import Foundation
import FirebaseFirestore
import FirebaseAuth
import Combine

struct RoommateAgreement: Codable, Identifiable {
    @DocumentID var id: String?
    var matchID: String // The ID of the match/chat document
    var userA: String
    var userB: String
    var moveInDate: Date
    var sharedResponsibilities: String
    var houseRules: String
    var createdAt: Date = Date()
}

class AgreementViewModel: ObservableObject {
    @Published var agreement: RoommateAgreement?
    @Published var errorMessage: String?
    
    private let db = Firestore.firestore()
    
    /// Saves a new agreement for a given match.
    func saveAgreement(_ agreement: RoommateAgreement, completion: @escaping (Result<Void, Error>) -> Void) {
        do {
            _ = try db.collection("agreements").addDocument(from: agreement) { error in
                if let error = error {
                    DispatchQueue.main.async {
                        self.errorMessage = error.localizedDescription
                        completion(.failure(error))
                    }
                } else {
                    DispatchQueue.main.async {
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
        db.collection("agreements")
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
