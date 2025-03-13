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
            
            HStack {
                TextField("Type a message...", text: $newMessageText)
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
        .alert(item: Binding(
            get: { viewModel.errorMessage.map { ChatViewAlertError(message: $0) } },
            set: { _ in viewModel.errorMessage = nil }
        )) { alertError in
            Alert(
                title: Text("Error"),
                message: Text(alertError.message),
                dismissButton: .default(Text("OK"))
            )
        }
    }
}

struct MessageBubble: View {
    let message: MessageModel
    let isCurrentUser: Bool
    
    var body: some View {
        HStack {
            if isCurrentUser { Spacer() }
            Text(message.text)
                .padding()
                .foregroundColor(.white)
                .background(isCurrentUser ? Color.blue : Color.gray)
                .cornerRadius(8)
            if !isCurrentUser { Spacer() }
        }
    }
}

struct ChatViewAlertError: Identifiable {
    let id = UUID()
    let message: String
}

struct ChatView_Previews: PreviewProvider {
    static var previews: some View {
        ChatView(viewModel: ChatViewModel(chatID: "dummyChatID"))
    }
}
