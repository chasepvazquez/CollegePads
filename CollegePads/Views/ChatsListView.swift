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
import Combine  // For AnyCancellable

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
    
    @State private var cancellables = Set<AnyCancellable>()
    
    var body: some View {
        NavigationView {
            List(chats) { chat in
                NavigationLink(destination: ChatView(viewModel: ChatViewModel(chatID: chat.id))) {
                    VStack(alignment: .leading) {
                        Text("Chat with: \(chat.participants.filter { $0 != currentUserID }.joined(separator: ", "))")
                        Text("Created at: \(chat.createdAt, formatter: dateFormatter)")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
            }
            .navigationTitle("My Chats")
            .onAppear {
                loadChats()
            }
            .alert(item: Binding(
                get: {
                    if let errorMessage = errorMessage {
                        return GenericAlertError(message: errorMessage)
                    }
                    return nil
                },
                set: { _ in errorMessage = nil }
            )) { alertError in
                Alert(title: Text("Error"), message: Text(alertError.message), dismissButton: .default(Text("OK")))
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
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    self.errorMessage = error.localizedDescription
                    return
                }
                if let snapshot = snapshot {
                    self.chats = snapshot.documents.compactMap { doc in
                        let data = doc.data()
                        let id = doc.documentID
                        let participants = data["participants"] as? [String] ?? []
                        let timestamp = (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
                        return ChatListItem(id: id, participants: participants, createdAt: timestamp)
                    }
                }
            }
    }
    
    var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }
}

struct ChatsListView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ChatsListView()
        }
    }
}
