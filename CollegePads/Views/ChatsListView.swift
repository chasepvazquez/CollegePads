//
//  ChatsListView.swift
//  CollegePads
//
//  Created by [Your Name] on [Date].
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import FirebaseFirestoreCombineSwift
import Combine

struct ChatListItem: Identifiable {
    let id: String
    let participants: [String]
    let createdAt: Date
}

struct ChatsListView: View {
    @State private var chats: [ChatListItem] = []
    @State private var errorMessage: String?
    
    private let db = Firestore.firestore()
    private var currentUserID: String? {
        Auth.auth().currentUser?.uid
    }
    
    // Store local cancellables
    @State private var cancellables = Set<AnyCancellable>()
    
    var body: some View {
        NavigationView {
            List(chats) { chat in
                NavigationLink(destination: ChatView(viewModel: ChatViewModel(chatID: chat.id))) {
                    Text("Chat: \(chat.id)")
                }
            }
            .navigationTitle("My Chats")
            .onAppear {
                loadChats()
            }
            .alert(item: Binding(
                get: {
                    if let errorMessage = errorMessage {
                        return ChatsListAlertError(message: errorMessage)
                    }
                    return nil
                },
                set: { _ in errorMessage = nil }
            )) { alertError in
                Alert(
                    title: Text("Error"),
                    message: Text(alertError.message),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }
    
    func loadChats() {
        guard let uid = currentUserID else {
            errorMessage = "User not authenticated."
            return
        }
        
        db.collection("chats")
            .whereField("participants", arrayContains: uid)
            .snapshotPublisher()
            .map { querySnapshot -> [ChatListItem] in
                querySnapshot.documents.compactMap { doc in
                    let data = doc.data()
                    let participants = data["participants"] as? [String] ?? []
                    let timestamp = data["createdAt"] as? Timestamp ?? Timestamp(date: Date())
                    return ChatListItem(
                        id: doc.documentID,
                        participants: participants,
                        createdAt: timestamp.dateValue()
                    )
                }
            }
            .sink { completion in
                if case let .failure(error) = completion {
                    self.errorMessage = error.localizedDescription
                }
            } receiveValue: { chatItems in
                self.chats = chatItems
            }
            .store(in: &cancellables)
    }
}

struct ChatsListAlertError: Identifiable {
    let id = UUID()
    let message: String
}

struct ChatsListView_Previews: PreviewProvider {
    static var previews: some View {
        ChatsListView()
    }
}
