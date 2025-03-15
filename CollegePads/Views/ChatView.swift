//
//  ChatView.swift
//  CollegePads
//
//  Created by [Your Name] on [Date].
//

import SwiftUI

struct ChatView: View {
    @StateObject var viewModel: ChatViewModel
    @State private var newMessageText: String = ""
    @State private var isEditing: Bool = false

    var body: some View {
        VStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(viewModel.messages) { msg in
                        MessageBubble(message: msg, isCurrentUser: msg.senderID == viewModel.currentUserID)
                    }
                }
                .padding()
            }
            
            if viewModel.isTyping {
                HStack {
                    Text("User is typing...")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Spacer()
                }
                .padding(.horizontal)
            }
            
            HStack {
                TextField("Type a message...", text: $newMessageText, onEditingChanged: { editing in
                    isEditing = editing
                    // When editing begins, update typing status
                    if editing {
                        viewModel.setTypingStatus(isTyping: true)
                    } else {
                        viewModel.setTypingStatus(isTyping: false)
                    }
                })
                .textFieldStyle(RoundedBorderTextFieldStyle())
                
                Button("Send") {
                    guard !newMessageText.isEmpty else { return }
                    viewModel.sendMessage(text: newMessageText)
                    newMessageText = ""
                }
                .padding(.horizontal)
            }
            .padding()
        }
        .navigationTitle("Chat")
        .onAppear {
            viewModel.markMessagesAsRead()
        }
        .alert(item: Binding(
            get: { viewModel.errorMessage.map { ChatAlertError(message: $0) } },
            set: { _ in viewModel.errorMessage = nil }
        )) { alertError in
            Alert(title: Text("Error"), message: Text(alertError.message), dismissButton: .default(Text("OK")))
        }
    }
}

struct MessageBubble: View {
    let message: MessageModel
    let isCurrentUser: Bool
    
    var body: some View {
        VStack(alignment: isCurrentUser ? .trailing : .leading, spacing: 4) {
            HStack {
                if isCurrentUser { Spacer() }
                Text(message.text)
                    .padding()
                    .foregroundColor(.white)
                    .background(isCurrentUser ? Color.blue : Color.gray)
                    .cornerRadius(8)
                if !isCurrentUser { Spacer() }
            }
            if isCurrentUser, let isRead = message.isRead, isRead {
                Text("Read")
                    .font(.caption)
                    .foregroundColor(.green)
                    .padding(.trailing, 8)
            }
        }
    }
}

struct ChatAlertError: Identifiable {
    let id = UUID()
    let message: String
}

struct ChatView_Previews: PreviewProvider {
    static var previews: some View {
        ChatView(viewModel: ChatViewModel(chatID: "dummyChatID"))
    }
}
