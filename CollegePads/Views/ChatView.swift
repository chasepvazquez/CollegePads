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
        VStack(spacing: 0) {
            ScrollViewReader { scrollView in
                ScrollView {
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(viewModel.messages) { msg in
                            MessageBubble(message: msg, isCurrentUser: msg.senderID == viewModel.currentUserID)
                                .id(msg.id)  // For scrolling to the bottom
                        }
                    }
                    .padding()
                }
                .onChange(of: viewModel.messages.count) { _ in
                    if let lastMessage = viewModel.messages.last, let id = lastMessage.id {
                        withAnimation {
                            scrollView.scrollTo(id, anchor: .bottom)
                        }
                    }
                }
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
            
            ChatInputBar(messageText: $newMessageText, onSend: {
                guard !newMessageText.isEmpty else { return }
                viewModel.sendMessage(text: newMessageText)
                newMessageText = ""
            })
        }
        .navigationTitle("Chat")
        .onAppear {
            viewModel.markMessagesAsRead()
        }
        .alert(item: Binding(
            get: {
                if let errorMessage = viewModel.errorMessage {
                    return GenericAlertError(message: errorMessage)
                }
                return nil
            },
            set: { _ in viewModel.errorMessage = nil }
        )) { alertError in
            Alert(title: Text("Error"), message: Text(alertError.message), dismissButton: .default(Text("OK")))
        }
    }
}

struct ChatView_Previews: PreviewProvider {
    static var previews: some View {
        ChatView(viewModel: ChatViewModel(chatID: "dummyChatID"))
    }
}
