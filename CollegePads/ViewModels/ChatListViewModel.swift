//
//  ChatsListViewModel.swift
//  CollegePads
//
//  Updated to include loading state and sort chats by creation date (newest first).
//

import Foundation
import FirebaseFirestore
import FirebaseFirestoreCombineSwift
import FirebaseAuth
import Combine

struct ChatListItem: Identifiable {
    let id: String
    let participants: [String]
    let createdAt: Date
}

class ChatsListViewModel: ObservableObject {
    @Published var chats: [ChatListItem] = []
    @Published var errorMessage: String?
    @Published var isLoading: Bool = false  // New loading state
    
    private var cancellables = Set<AnyCancellable>()
    private let db = Firestore.firestore()
    
    var currentUserID: String? {
        Auth.auth().currentUser?.uid
    }
    
    /// Fetches chats where the current user is a participant.
    /// Chats are sorted by creation date (newest first) and the loading state is managed.
    func fetchChats() {
        guard let uid = currentUserID else {
            self.errorMessage = "User not authenticated."
            return
        }
        
        isLoading = true
        db.collection("chats")
            .whereField("participants", arrayContains: uid)
            .snapshotPublisher()
            .map { snapshot -> [ChatListItem] in
                let items = snapshot.documents.compactMap { doc -> ChatListItem? in
                    let data = doc.data()
                    guard let participants = data["participants"] as? [String],
                          let timestamp = (data["createdAt"] as? Timestamp)?.dateValue() else {
                        return nil
                    }
                    return ChatListItem(id: doc.documentID, participants: participants, createdAt: timestamp)
                }
                // Sort chats with most recent first.
                return items.sorted { $0.createdAt > $1.createdAt }
            }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading = false
                if case let .failure(error) = completion {
                    self?.errorMessage = error.localizedDescription
                }
            } receiveValue: { [weak self] chats in
                self?.chats = chats
            }
            .store(in: &cancellables)
    }
}
