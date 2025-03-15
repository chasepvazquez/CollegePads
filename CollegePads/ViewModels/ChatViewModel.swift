//
//  ChatViewModel.swift
//  CollegePads
//
//  Created by [Your Name] on [Date].
//

import Foundation
import FirebaseFirestore
import FirebaseFirestoreCombineSwift
import Combine
import FirebaseAuth

class ChatViewModel: ObservableObject {
    @Published var messages: [MessageModel] = []
    @Published var errorMessage: String?
    
    private let db = Firestore.firestore()
    private var cancellables = Set<AnyCancellable>()
    
    var chatID: String
    var currentUserID: String? {
        Auth.auth().currentUser?.uid
    }
    
    init(chatID: String) {
        self.chatID = chatID
        observeMessages()
    }
    
    /// Observes messages in real-time for this chat.
    func observeMessages() {
        db.collection("chats")
            .document(chatID)
            .collection("messages")
            .order(by: "timestamp", descending: false)
            .snapshotPublisher()
            .map { querySnapshot -> [MessageModel] in
                querySnapshot.documents.compactMap { doc in
                    do {
                        // Decode document into MessageModel
                        var message = try doc.data(as: MessageModel.self)
                        // Manually assign document ID if not present
                        if message.id == nil {
                            message.id = doc.documentID
                        }
                        return message
                    } catch {
                        print("Error decoding message doc: \(error)")
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
            } receiveValue: { fetchedMessages in
                DispatchQueue.main.async {
                    self.messages = fetchedMessages
                    self.markMessagesAsRead()
                }
            }
            .store(in: &cancellables)
    }
    
    /// Sends a new message.
    func sendMessage(text: String) {
        guard let userID = currentUserID else {
            self.errorMessage = "User not authenticated."
            return
        }
        let newMessage = MessageModel(
            id: nil,  // id will be set when read back from Firestore
            senderID: userID,
            text: text,
            timestamp: Date(),
            isRead: false
        )
        do {
            try db.collection("chats")
                .document(chatID)
                .collection("messages")
                .document()
                .setData(from: newMessage)
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }
    
    /// Marks unread messages (not sent by the current user) as read.
    func markMessagesAsRead() {
        guard let currentUserID = currentUserID else { return }
        for message in messages where message.senderID != currentUserID && (message.isRead == nil || message.isRead == false) {
            guard let messageID = message.id else { continue }
            let messageRef = db.collection("chats").document(chatID).collection("messages").document(messageID)
            messageRef.updateData(["isRead": true]) { error in
                if let error = error {
                    print("Error marking message as read: \(error.localizedDescription)")
                }
            }
        }
    }
}
