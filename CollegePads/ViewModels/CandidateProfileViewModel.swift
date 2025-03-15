//
//  CandidateProfileViewModel.swift
//  CollegePads
//
//  Created by [Your Name] on [Date].
//

import Foundation
import FirebaseFirestore
import FirebaseFirestoreCombineSwift
import Combine

class CandidateProfileViewModel: ObservableObject {
    @Published var candidate: UserModel?
    @Published var errorMessage: String?
    
    private let db = Firestore.firestore()
    
    func loadCandidate(with candidateID: String) {
        db.collection("users").document(candidateID).getDocument { snapshot, error in
            if let error = error {
                DispatchQueue.main.async {
                    self.errorMessage = error.localizedDescription
                }
                return
            }
            guard let snapshot = snapshot, snapshot.exists else {
                DispatchQueue.main.async {
                    self.errorMessage = "Candidate profile not found"
                }
                return
            }
            do {
                let candidate = try snapshot.data(as: UserModel.self)
                DispatchQueue.main.async {
                    self.candidate = candidate
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
}
