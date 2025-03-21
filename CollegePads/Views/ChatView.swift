//
//  ChatView.swift
//  CollegePads
//
//  Updated to include the global theme and improved layout.
//  This view displays a chat conversation with auto-scrolling, a typing indicator, and uses custom theme typography and background.
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
                            MessageBubble(message: msg,
                                          isCurrentUser: msg.senderID == viewModel.currentUserID)
                                .id(msg.id)
                        }
                    }
                    .padding()
                }
                .onChange(of: viewModel.messages.count) { _, _ in
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
                        .font(AppTheme.bodyFont)
                        .foregroundColor(.gray)
                    Spacer()
                }
                .padding(.horizontal)
            }
            
            ChatInputBar(messageText: $newMessageText, onSend: {
                guard !newMessageText.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                viewModel.sendMessage(text: newMessageText)
                newMessageText = ""
            })
        }
        .background(AppTheme.backgroundGradient.ignoresSafeArea())
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
            Alert(title: Text("Error"),
                  message: Text(alertError.message),
                  dismissButton: .default(Text("OK")))
        }
    }
}

struct ChatView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ChatView(viewModel: ChatViewModel(chatID: "dummyChatID"))
        }
    }
}
