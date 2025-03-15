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
        
        db.collection("users")
            .snapshotPublisher()
            .map { querySnapshot -> [UserModel] in
                querySnapshot.documents.compactMap { doc in
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
                let filtered = userModels.filter { $0.id != currentUserID }
                DispatchQueue.main.async {
                    self.potentialMatches = filtered
                }
            }
            .store(in: &cancellables)
    }
    
    /// Records a right-swipe (like) in Firestore and checks for a mutual match.
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
            } else {
                self.checkForMutualMatch(with: matchUserID)
            }
        }
    }
    
    /// Checks if the other user has already swiped right on the current user.
    private func checkForMutualMatch(with otherUserID: String) {
        guard let currentUserID = currentUserID else { return }
        let query = db.collection("swipes")
            .whereField("from", isEqualTo: otherUserID)
            .whereField("to", isEqualTo: currentUserID)
            .whereField("liked", isEqualTo: true)
        
        query.getDocuments { snapshot, error in
            if let error = error {
                print("Error checking mutual match: \(error.localizedDescription)")
                return
            }
            if let snapshot = snapshot, !snapshot.documents.isEmpty {
                self.createChatIfNotExists(userA: currentUserID, userB: otherUserID)
            }
        }
    }
    
    /// Checks if a chat between userA and userB already exists; if not, creates one.
    func createChatIfNotExists(userA: String, userB: String) {
        let chatsRef = db.collection("chats")
        chatsRef
            .whereField("participants", arrayContains: userA)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error searching for chat: \(error.localizedDescription)")
                    return
                }
                // Check if any existing chat includes both userA and userB
                if let snapshot = snapshot {
                    for doc in snapshot.documents {
                        let participants = doc.data()["participants"] as? [String] ?? []
                        if participants.contains(userB) {
                            // Chat already exists – do nothing.
                            return
                        }
                    }
                }
                // No chat exists, create a new one.
                let chatData: [String: Any] = [
                    "participants": [userA, userB],
                    "createdAt": FieldValue.serverTimestamp(),
                    "isTyping": false // initial typing status
                ]
                chatsRef.addDocument(data: chatData) { error in
                    if let error = error {
                        DispatchQueue.main.async {
                            self.errorMessage = error.localizedDescription
                        }
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
