//
//  ChatViewModel.swift
//  CollegePads
//
//  Created by [Your Name] on [Date].
//

import Foundation
import FirebaseFirestore
import FirebaseFirestoreCombineSwift // for snapshotPublisher()
import FirebaseAuth
import Combine

class ChatViewModel: ObservableObject {
    @Published var messages: [MessageModel] = []
    @Published var errorMessage: String?
    
    private let db = Firestore.firestore()
    private var cancellables = Set<AnyCancellable>()
    
    let chatID: String
    var currentUserID: String? {
        Auth.auth().currentUser?.uid
    }
    
    init(chatID: String) {
        self.chatID = chatID
        observeMessages()
    }
    
    /// Observes messages in real-time for this chat
    func observeMessages() {
        db.collection("chats")
            .document(chatID)
            .collection("messages")
            .order(by: "timestamp", descending: false)
            .snapshotPublisher()
            .map { querySnapshot -> [MessageModel] in
                querySnapshot.documents.compactMap { doc -> MessageModel? in
                    let data = doc.data()
                    let senderID = data["senderID"] as? String ?? ""
                    let text = data["text"] as? String ?? ""
                    let ts = data["timestamp"] as? Timestamp ?? Timestamp(date: Date())
                    return MessageModel(
                        id: doc.documentID,
                        senderID: senderID,
                        text: text,
                        timestamp: ts.dateValue()
                    )
                }
            }
            .sink { completion in
                if case let .failure(error) = completion {
                    DispatchQueue.main.async {
                        self.errorMessage = error.localizedDescription
                    }
                }
            } receiveValue: { fetchedMessages in
                DispatchQueue.main.async {
                    self.messages = fetchedMessages
                }
            }
            .store(in: &cancellables)
    }
    
    /// Sends a new message
    func sendMessage(text: String) {
        guard let userID = currentUserID else {
            self.errorMessage = "User not authenticated."
            return
        }
        let newMessage = [
            "senderID": userID,
            "text": text,
            "timestamp": FieldValue.serverTimestamp()
        ] as [String : Any]
        
        db.collection("chats")
            .document(chatID)
            .collection("messages")
            .addDocument(data: newMessage) { error in
                if let error = error {
                    DispatchQueue.main.async {
                        self.errorMessage = error.localizedDescription
                    }
                }
            }
    }
}
