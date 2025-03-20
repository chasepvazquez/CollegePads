//
//  ChatsListViewModel.swift
//  CollegePads
//
//  Created by [Your Name] on [Date]
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
    
    private var cancellables = Set<AnyCancellable>()
    private let db = Firestore.firestore()
    
    var currentUserID: String? {
        Auth.auth().currentUser?.uid
    }
    
    func fetchChats() {
        guard let uid = currentUserID else {
            self.errorMessage = "User not authenticated."
            return
        }
        
        db.collection("chats")
            .whereField("participants", arrayContains: uid)
            .snapshotPublisher()
            .map { snapshot -> [ChatListItem] in
                snapshot.documents.compactMap { doc in
                    let data = doc.data()
                    guard let participants = data["participants"] as? [String],
                          let timestamp = (data["createdAt"] as? Timestamp)?.dateValue() else {
                        return nil
                    }
                    return ChatListItem(id: doc.documentID, participants: participants, createdAt: timestamp)
                }
            }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                if case let .failure(error) = completion {
                    self?.errorMessage = error.localizedDescription
                }
            } receiveValue: { [weak self] chats in
                self?.chats = chats
            }
            .store(in: &cancellables)
    }
}
