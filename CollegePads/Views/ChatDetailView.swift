//
//  ChatDetailView.swift
//  CollegePads
//
//  New Feature: Enhanced Chat Detail View
//  This view displays an individual chat conversation using your existing ChatViewModel,
//  adding auto-scroll to the latest message, a typing indicator, and improved layout.
//
//  Note: Ensure that ChatViewModel contains a `sendMessage(text:)` method for sending messages.
//  If not, please integrate the send functionality accordingly.
//

import SwiftUI
import FirebaseAuth

struct ChatDetailView: View {
    @ObservedObject var viewModel: ChatViewModel
    @State private var messageText: String = ""
    
    var body: some View {
        VStack {
            // Messages ScrollView with auto-scroll
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 8) {
                        ForEach(viewModel.messages) { message in
                            MessageBubble(message: message, isCurrentUser: message.senderID == Auth.auth().currentUser?.uid)
                                .id(message.id)
                        }
                        if viewModel.isTyping {
                            HStack {
                                Spacer()
                                Text("Typing...")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                Spacer()
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .padding()
                }
                .onChange(of: viewModel.messages.count) { _ in
                    if let lastMessage = viewModel.messages.last {
                        withAnimation {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
            }
            
            // Chat input area
            ChatInputBar(messageText: $messageText, onSend: sendMessage)
                .padding(.bottom, 4)
        }
        .navigationTitle("Chat")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    /// Sends the message using the chat view model.
    private func sendMessage() {
        guard !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        viewModel.sendMessage(text: messageText)
        messageText = ""
    }
}

struct ChatDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            // Provide a dummy chatID for preview purposes.
            ChatDetailView(viewModel: ChatViewModel(chatID: "dummyChatID"))
        }
    }
}
