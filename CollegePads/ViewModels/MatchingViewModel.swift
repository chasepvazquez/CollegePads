//
//  MatchingViewModel.swift
//  CollegePads
//
//  Created by [Your Name] on [Date].
//

import Foundation
import FirebaseFirestore
import FirebaseAuth
import FirebaseFirestoreCombineSwift
import Combine

enum SwipeDirection {
    case left, right
}

class MatchingViewModel: ObservableObject {
    @Published var potentialMatches: [UserModel] = []
    @Published var errorMessage: String?
    
    private var cancellables = Set<AnyCancellable>()
    private let db = Firestore.firestore()
    
    var currentUserID: String? {
        Auth.auth().currentUser?.uid
    }
    
    /// Fetches all user profiles from Firestore, excluding the current user.
    func fetchPotentialMatches() {
        guard let currentUserID = currentUserID else {
            self.errorMessage = "User not authenticated"
            return
        }
        
        // snapshotPublisher() returns a publisher of QuerySnapshot
        db.collection("users")
            .snapshotPublisher()   // Provided by FirebaseFirestoreCombineSwift
            .map { querySnapshot -> [UserModel] in
                // Convert each document into a UserModel using FirestoreSwift's Codable
                querySnapshot.documents.compactMap { doc -> UserModel? in
                    do {
                        return try doc.data(as: UserModel.self)
                    } catch {
                        print("Error decoding user doc: \(error)")
                        return nil
                    }
                }
            }
            .sink { completion in
                switch completion {
                case .failure(let error):
                    DispatchQueue.main.async {
                        self.errorMessage = error.localizedDescription
                    }
                case .finished:
                    break
                }
            } receiveValue: { userModels in
                // Filter out the current user
                let filtered = userModels.filter { $0.id != currentUserID }
                DispatchQueue.main.async {
                    self.potentialMatches = filtered
                }
            }
            .store(in: &cancellables)
    }
    
    /// Records a right-swipe (like) in Firestore.
    func swipeRight(on user: UserModel) {
        guard let currentUserID = currentUserID, let matchUserID = user.id else { return }
        
        let swipeData: [String: Any] = [
            "from": currentUserID,
            "to": matchUserID,
            "liked": true,
            "timestamp": FieldValue.serverTimestamp()
        ]
        
        db.collection("swipes").addDocument(data: swipeData) { error in
            if let error = error {
                DispatchQueue.main.async {
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    /// Records a left-swipe (dislike) in Firestore.
    func swipeLeft(on user: UserModel) {
        guard let currentUserID = currentUserID, let matchUserID = user.id else { return }
        
        let swipeData: [String: Any] = [
            "from": currentUserID,
            "to": matchUserID,
            "liked": false,
            "timestamp": FieldValue.serverTimestamp()
        ]
        
        db.collection("swipes").addDocument(data: swipeData) { error in
            if let error = error {
                DispatchQueue.main.async {
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
}
