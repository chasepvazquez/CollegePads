import Foundation
import FirebaseFirestore
import FirebaseFirestoreCombineSwift
import FirebaseAuth
import Combine
import CoreLocation

enum SwipeDirection {
    case left, right
}

class MatchingViewModel: ObservableObject {
    @Published var potentialMatches: [UserModel] = []
    @Published var errorMessage: String?
    @Published var lastSwipedCandidate: UserModel?
    @Published var rightSwipesCount: Int = 0
    @Published var mutualMatchesCount: Int = 0
    
    private var matchedUserIDs: Set<String> = []
    private var cancellables = Set<AnyCancellable>()
    private let db = Firestore.firestore()
    
    var currentUser: UserModel? {
        ProfileViewModel.shared.userProfile
    }
    
    /// Fetches potential matches from Firestore, filtering out the current user and blocked users,
    /// then sorts them using SmartMatchingEngine.
    func fetchPotentialMatches() {
        guard let currentUID = Auth.auth().currentUser?.uid else {
            self.errorMessage = "User not authenticated"
            return
        }
        
        db.collection("users").getDocuments { [weak self] snapshot, error in
            guard let self = self else { return }
            if let error = error {
                DispatchQueue.main.async { self.errorMessage = error.localizedDescription }
                return
            }
            if let documents = snapshot?.documents {
                var users = documents.compactMap { try? $0.data(as: UserModel.self) }
                // Remove the current user.
                users.removeAll { $0.id == currentUID }
                // Remove blocked users.
                if let current = self.currentUser, let blocked = current.blockedUserIDs {
                    users.removeAll { blocked.contains($0.id ?? "") }
                }
                // Sort using SmartMatchingEngine (dummy average rating used here)
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
    
    func swipeRight(on user: UserModel) {
        guard let currentUserID = Auth.auth().currentUser?.uid,
              let matchUserID = user.id else { return }
        let swipeData: [String: Any] = [
            "from": currentUserID,
            "to": matchUserID,
            "liked": true,
            "timestamp": FieldValue.serverTimestamp()
        ]
        db.collection("swipes").addDocument(data: swipeData) { [weak self] error in
            if let error = error {
                DispatchQueue.main.async { self?.errorMessage = error.localizedDescription }
            } else {
                DispatchQueue.main.async {
                    self?.rightSwipesCount += 1
                    self?.lastSwipedCandidate = user
                }
                self?.checkForMutualMatch(with: matchUserID)
            }
        }
    }
    
    func swipeLeft(on user: UserModel) {
        guard let currentUserID = Auth.auth().currentUser?.uid,
              let matchUserID = user.id else { return }
        let swipeData: [String: Any] = [
            "from": currentUserID,
            "to": matchUserID,
            "liked": false,
            "timestamp": FieldValue.serverTimestamp()
        ]
        db.collection("swipes").addDocument(data: swipeData) { [weak self] error in
            if let error = error {
                DispatchQueue.main.async { self?.errorMessage = error.localizedDescription }
            } else {
                DispatchQueue.main.async {
                    self?.lastSwipedCandidate = user
                }
            }
        }
    }
    
    func superLike(on user: UserModel) {
        print("Super liked user: \(user.email)")
        swipeRight(on: user)
    }
    
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
                guard let self = self else { return }
                if !self.matchedUserIDs.contains(otherUserID) {
                    self.matchedUserIDs.insert(otherUserID)
                    DispatchQueue.main.async {
                        self.mutualMatchesCount += 1
                    }
                }
                self.createChatIfNotExists(userA: currentUserID, userB: otherUserID)
            }
        }
    }
    
    func createChatIfNotExists(userA: String, userB: String) {
        let chatsRef = db.collection("chats")
        chatsRef.whereField("participants", arrayContains: userA)
            .getDocuments { [weak self] snapshot, error in
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
                            self?.errorMessage = error.localizedDescription
                        }
                    }
                }
            }
    }
}
