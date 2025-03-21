//
//  ChatDetailView.swift
//  CollegePads
//
//  New Feature: Enhanced Chat Detail View with Online Status and Global Theme
//  This view displays an individual chat conversation using your existing ChatViewModel,
//  adding auto-scroll to the latest message, a typing indicator, improved layout,
//  and displays the chat partner's online status in the navigation bar.
//  It now also applies the global background gradient and uses custom theme typography.
//

import SwiftUI
import FirebaseAuth

struct ChatDetailView: View {
    @ObservedObject var viewModel: ChatViewModel
    /// The userID of the chat partner whose online status will be displayed.
    let chatPartnerID: String
    @State private var messageText: String = ""
    
    var body: some View {
        VStack {
            // Messages ScrollView with auto-scroll to the latest message.
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 8) {
                        ForEach(viewModel.messages) { message in
                            MessageBubble(message: message,
                                          isCurrentUser: message.senderID == Auth.auth().currentUser?.uid)
                                .id(message.id)
                        }
                        if viewModel.isTyping {
                            HStack {
                                Spacer()
                                Text("Typing...")
                                    .font(AppTheme.bodyFont)
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
            
            // Chat input area.
            ChatInputBar(messageText: $messageText, onSend: sendMessage)
                .padding(.bottom, 4)
        }
        .background(AppTheme.backgroundGradient.ignoresSafeArea())
        .navigationTitle("Chat")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                VStack {
                    Text("Chat")
                        .font(AppTheme.titleFont)
                    // Display the chat partner's online status.
                    OnlineStatusView(userID: chatPartnerID)
                }
            }
        }
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
            // Provide dummy values for preview.
            ChatDetailView(viewModel: ChatViewModel(chatID: "dummyChatID"),
                           chatPartnerID: "dummyPartnerID")
        }
    }
}
