//
//  MatchingViewModel.swift
//  CollegePads
//
//  Created by [Your Name] on [Date].
//
//  This ViewModel fetches potential matches from Firestore and sorts them using the SmartMatchingEngine,
//  which combines the base compatibility score with bonus factors (e.g., verification, housing status, lease duration, and average ratings).
//  It also handles swipe actions (right, left, and super like) and mutual match checking to create chat documents.

import Foundation
import FirebaseFirestore
import FirebaseFirestoreCombineSwift
import FirebaseAuth
import Combine

enum SwipeDirection {
    case left, right
}

class MatchingViewModel: ObservableObject {
    @Published var potentialMatches: [UserModel] = []
    @Published var errorMessage: String?
    @Published var lastSwipedCandidate: UserModel?
    
    private var cancellables = Set<AnyCancellable>()
    private let db = Firestore.firestore()
    
    /// Returns the current user profile from the shared ProfileViewModel.
    var currentUser: UserModel? {
        ProfileViewModel.shared.userProfile
    }
    
    /// Fetches potential matches from Firestore, filters out the current user and any blocked users,
    /// then sorts them using the SmartMatchingEngine.
    func fetchPotentialMatches() {
        guard let currentUID = Auth.auth().currentUser?.uid else {
            self.errorMessage = "User not authenticated"
            return
        }
        
        // Fetch all users from Firestore.
        db.collection("users").getDocuments { [weak self] snapshot, error in
            guard let self = self else { return }
            
            if let error = error {
                DispatchQueue.main.async { self.errorMessage = error.localizedDescription }
                return
            }
            
            if let documents = snapshot?.documents {
                // Decode documents into UserModel instances.
                var users = documents.compactMap { try? $0.data(as: UserModel.self) }
                
                // Filter out the current user.
                users.removeAll { $0.id == currentUID }
                
                // Filter out blocked users if the current user's profile is loaded.
                if let current = self.currentUser, let blocked = current.blockedUserIDs {
                    users.removeAll { blocked.contains($0.id ?? "") }
                }
                
                // Sort the users using the SmartMatchingEngine.
                // For demonstration, we use a dummy average rating (3.0). Replace with real data if available.
                let sortedUsers = users.sorted { userA, userB in
                    let scoreA = SmartMatchingEngine.calculateSmartMatchScore(between: self.currentUser ?? userA, and: userA, averageRating: 3.0)
                    let scoreB = SmartMatchingEngine.calculateSmartMatchScore(between: self.currentUser ?? userB, and: userB, averageRating: 3.0)
                    return scoreA > scoreB
                }
                
                DispatchQueue.main.async {
                    self.potentialMatches = sortedUsers
                }
            }
        }
    }
    
    /// Handles a right swipe on a candidate.
    func swipeRight(on user: UserModel) {
        guard let currentUserID = Auth.auth().currentUser?.uid, let matchUserID = user.id else { return }
        let swipeData: [String: Any] = [
            "from": currentUserID,
            "to": matchUserID,
            "liked": true,
            "timestamp": FieldValue.serverTimestamp()
        ]
        db.collection("swipes").addDocument(data: swipeData) { [weak self] error in
            if let error = error {
                DispatchQueue.main.async {
                    self?.errorMessage = error.localizedDescription
                }
            } else {
                self?.lastSwipedCandidate = user
                self?.checkForMutualMatch(with: matchUserID)
            }
        }
    }
    
    /// Handles a left swipe on a candidate.
    func swipeLeft(on user: UserModel) {
        guard let currentUserID = Auth.auth().currentUser?.uid, let matchUserID = user.id else { return }
        let swipeData: [String: Any] = [
            "from": currentUserID,
            "to": matchUserID,
            "liked": false,
            "timestamp": FieldValue.serverTimestamp()
        ]
        db.collection("swipes").addDocument(data: swipeData) { [weak self] error in
            if let error = error {
                DispatchQueue.main.async {
                    self?.errorMessage = error.localizedDescription
                }
            } else {
                self?.lastSwipedCandidate = user
            }
        }
    }
    
    /// Initiates a super like action (treated as a right swipe).
    func superLike(on user: UserModel) {
        print("Super liked user: \(user.email)")
        swipeRight(on: user)
    }
    
    /// Checks if the swiped user has already liked the current user.
    private func checkForMutualMatch(with otherUserID: String) {
        guard let currentUserID = Auth.auth().currentUser?.uid else { return }
        let query = db.collection("swipes")
            .whereField("from", isEqualTo: otherUserID)
            .whereField("to", isEqualTo: currentUserID)
            .whereField("liked", isEqualTo: true)
        
        query.getDocuments { [weak self] snapshot, error in
            if let error = error {
                print("Error checking mutual match: \(error.localizedDescription)")
                return
            }
            if let snapshot = snapshot, !snapshot.documents.isEmpty {
                self?.createChatIfNotExists(userA: currentUserID, userB: otherUserID)
            }
        }
    }
    
    /// Creates a chat document if a mutual match is found.
    func createChatIfNotExists(userA: String, userB: String) {
        let chatsRef = db.collection("chats")
        chatsRef
            .whereField("participants", arrayContains: userA)
            .getDocuments { [weak self] snapshot, error in
                if let error = error {
                    print("Error searching for chat: \(error.localizedDescription)")
                    return
                }
                if let snapshot = snapshot {
                    for doc in snapshot.documents {
                        let participants = doc.data()["participants"] as? [String] ?? []
                        if participants.contains(userB) {
                            return  // Chat already exists.
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
                            self?.errorMessage = error.localizedDescription
                        }
                    }
                }
            }
    }
}
