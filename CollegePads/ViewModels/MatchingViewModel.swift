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
import FirebaseFirestoreSwift
import Combine

enum SwipeDirection {
    case left, right
}

class MatchingViewModel: ObservableObject {
    @Published var potentialMatches: [UserModel] = []
    @Published var errorMessage: String?
    
    // Keep track of the last swiped candidate for potential rewind
    @Published var lastSwipedCandidate: UserModel?
    
    private var cancellables = Set<AnyCancellable>()
    private let db = Firestore.firestore()
    
    var currentUserID: String? {
        Auth.auth().currentUser?.uid
    }
    
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
                if case let .failure(error) = completion {
                    DispatchQueue.main.async {
                        self.errorMessage = error.localizedDescription
                    }
                }
            } receiveValue: { userModels in
                let filtered = userModels.filter { $0.id != currentUserID }
                DispatchQueue.main.async {
                    self.potentialMatches = filtered
                }
            }
            .store(in: &cancellables)
    }
    
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
                self.lastSwipedCandidate = user
                self.checkForMutualMatch(with: matchUserID)
            }
        }
    }
    
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
            } else {
                self.lastSwipedCandidate = user
            }
        }
    }
    
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
    
    func createChatIfNotExists(userA: String, userB: String) {
        let chatsRef = db.collection("chats")
        chatsRef
            .whereField("participants", arrayContains: userA)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error searching for chat: \(error.localizedDescription)")
                    return
                }
                if let snapshot = snapshot {
                    for doc in snapshot.documents {
                        let participants = doc.data()["participants"] as? [String] ?? []
                        if participants.contains(userB) {
                            return
                        }
                    }
                }
                let chatData: [String: Any] = [
                    "participants": [userA, userB],
                    "createdAt": FieldValue.serverTimestamp(),
                    "isTyping": false
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
    
    func superLike(on user: UserModel) {
        print("Super liked user: \(user.email)")
        swipeRight(on: user)
    }
}
