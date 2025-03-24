import SwiftUI
import FirebaseAuth

struct ChatDetailView: View {
    @ObservedObject var viewModel: ChatViewModel
    /// The userID of the chat partner whose online status will be displayed.
    let chatPartnerID: String
    @State private var messageText: String = ""
    
    var body: some View {
        ZStack {
            AppTheme.backgroundGradient.ignoresSafeArea()
            
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
                                        .foregroundColor(AppTheme.secondaryColor)
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
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                VStack {
                    Text("Chat")
                        .font(AppTheme.titleFont)
                        .foregroundColor(.primary)
                    OnlineStatusView(userID: chatPartnerID)
                }
            }
        }
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
            ChatDetailView(viewModel: ChatViewModel(chatID: "dummyChatID"),
                           chatPartnerID: "dummyPartnerID")
        }
    }
}
