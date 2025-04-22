import Foundation
import FirebaseFirestore
import FirebaseFirestoreCombineSwift
import FirebaseAuth
import Combine
import CoreLocation

enum SwipeDirection {
    case left, right, up
}

@MainActor
class MatchingViewModel: ObservableObject {
    @Published var potentialMatches: [UserModel] = []
    @Published var errorMessage: String?
    @Published var lastSwipedCandidate: UserModel?
    @Published var rightSwipesCount: Int = 0
    @Published var mutualMatchesCount: Int = 0
    @Published var superLikedUserIDs: Set<String> = []
    @Published var matchedUserIDs: Set<String> = []
    @Published var isLoading: Bool = false

    /// Convenience to avoid repeated Auth lookups
    private var currentUID: String? {
        Auth.auth().currentUser?.uid
    }

    private let db = Firestore.firestore()
    private var cancellables = Set<AnyCancellable>()

    init() {
        // reload matches after profile changes
        ProfileViewModel.shared.$userProfile
          .compactMap { $0 }
          .sink { [weak self] _ in
            self?.fetchPotentialMatches()
          }
          .store(in: &cancellables)

        loadSuperLikes()
      }
    
    private func loadSuperLikes() {
        guard let currentUserID = self.currentUID else { return }
      db.collection("swipes")
        .whereField("from", isEqualTo: currentUserID)
        .whereField("superLiked", isEqualTo: true)
        .getDocuments { [weak self] snapshot, _ in
          guard let docs = snapshot?.documents else { return }
          let ids = docs.compactMap { $0.data()["to"] as? String }
          DispatchQueue.main.async {
            self?.superLikedUserIDs = Set(ids)
          }
        }
    }

  var currentUser: UserModel? {
    ProfileViewModel.shared.userProfile
  }

    func fetchPotentialMatches() {
      guard let uid = currentUID else {
        self.errorMessage = "User not authenticated"
        return
      }

      // Ensure "me" is loaded
      if ProfileViewModel.shared.userProfile?.id == nil {
        ProfileViewModel.shared.loadUserProfile { [weak self] _ in
          self?.fetchPotentialMatches()
        }
        return
      }

      isLoading = true   // <-- show spinner

      // 1) Publisher for all swipes from me
        let swipesPub = db
          .collection("swipes")
          .whereField("from", isEqualTo: uid)
          .snapshotPublisher()
          .map { snap in
            Set(snap.documents.compactMap { $0.data()["to"] as? String })
          }
          .replaceError(with: [])          // ← on error, assume no swipes

        let usersPub = db
          .collection("users")
          .snapshotPublisher()
          .map { snap in
            snap.documents.compactMap { try? $0.data(as: UserModel.self) }
          }
          .replaceError(with: [])          // ← on error, assume no users

      // 3) Zip them, filter & sort
      Publishers
        .Zip(swipesPub, usersPub)
        .receive(on: DispatchQueue.global(qos: .userInitiated))
        .map { swipedIDs, allUsers -> [UserModel] in
          let blocked = Set(ProfileViewModel.shared.userProfile?.blockedUserIDs ?? [])
          let candidates = allUsers.filter {
            guard let id = $0.id else { return false }
            return id != uid
                && !swipedIDs.contains(id)
                && !blocked.contains(id)
          }

          guard let me = self.currentUser else { return candidates }
          return SmartMatchingEngine.generateSortedMatches(
            from: candidates,
            currentUser: me
          )
        }
        .receive(on: DispatchQueue.main)
        .sink(
          receiveCompletion: { [weak self] compl in
            self?.isLoading = false
            if case let .failure(err) = compl {
              self?.errorMessage = err.localizedDescription
            }
          },
          receiveValue: { [weak self] sorted in
            self?.potentialMatches = sorted
          }
        )
        .store(in: &cancellables)
    }

    
    /// Consolidated Firestore write + local state update for any swipe type.
    private func recordSwipe(
      on user: UserModel,
      liked: Bool,
      superLiked: Bool = false
    ) {
        guard let currentUID = self.currentUID,
              let matchUID   = user.id else { return }
      let data: [String: Any] = [
        "from":       currentUID,
        "to":         matchUID,
        "liked":      liked,
        "superLiked": superLiked,
        "timestamp":  FieldValue.serverTimestamp()
      ]

      db.collection("swipes").addDocument(data: data) { [weak self] error in
        if let err = error {
          DispatchQueue.main.async {
            self?.errorMessage = err.localizedDescription
          }
          return
        }

        DispatchQueue.main.async {
          // Shared update logic
          if liked {
            self?.rightSwipesCount += 1
            self?.lastSwipedCandidate = user
          } else {
            self?.lastSwipedCandidate = user
          }
          if superLiked {
            self?.superLikedUserIDs.insert(matchUID)
          }
        }

        // Only check for mutual if a positive swipe
        if liked {
          self?.checkForMutualMatch(with: matchUID)
        }
      }
    }

    func swipeRight(on user: UserModel) {
      recordSwipe(on: user, liked: true)
    }

    func swipeLeft(on user: UserModel) {
      recordSwipe(on: user, liked: false)
    }

    func superLike(on user: UserModel) {
      // skip duplicates
      guard let matchUID = user.id,
            !superLikedUserIDs.contains(matchUID)
      else { return }
      recordSwipe(on: user, liked: true, superLiked: true)
    }
    
    private func checkForMutualMatch(with otherUserID: String) {
        guard let currentUserID = self.currentUID else { return }
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
