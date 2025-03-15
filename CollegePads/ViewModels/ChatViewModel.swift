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
    @Published var isTyping: Bool = false  // Local indicator for other user's typing status
    
    private let db = Firestore.firestore()
    private var cancellables = Set<AnyCancellable>()
    
    var chatID: String
    var currentUserID: String? {
        Auth.auth().currentUser?.uid
    }
    
    init(chatID: String) {
        self.chatID = chatID
        observeMessages()
        observeTypingStatus()
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
                        var message = try doc.data(as: MessageModel.self)
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
    
    /// Observes the typing status from the chat document.
    func observeTypingStatus() {
        db.collection("chats")
            .document(chatID)
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    print("Error observing typing status: \(error.localizedDescription)")
                    return
                }
                if let data = snapshot?.data(), let typing = data["isTyping"] as? Bool {
                    DispatchQueue.main.async {
                        self.isTyping = typing
                    }
                }
            }
    }
    
    /// Sends a new message.
    func sendMessage(text: String) {
        guard let userID = currentUserID else {
            self.errorMessage = "User not authenticated."
            return
        }
        let newMessage = MessageModel(
            id: nil,
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
                .setData(from: newMessage) { error in
                    if let error = error {
                        DispatchQueue.main.async {
                            self.errorMessage = error.localizedDescription
                        }
                    }
                }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = error.localizedDescription
            }
        }
        // Reset typing status after sending message
        setTypingStatus(isTyping: false)
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
    
    /// Updates the typing status in the chat document.
    func setTypingStatus(isTyping: Bool) {
        db.collection("chats").document(chatID).updateData(["isTyping": isTyping]) { error in
            if let error = error {
                print("Error updating typing status: \(error.localizedDescription)")
            }
        }
    }
}
