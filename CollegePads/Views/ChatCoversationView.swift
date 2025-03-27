import SwiftUI
import FirebaseAuth

/// A unified conversation view that displays messages, a chat input bar,
/// and optionally the online status of the chat partner.
struct ChatConversationView: View {
    @StateObject var viewModel: ChatConversationViewModel
    /// Optionally, provide the chat partner's ID to show their online status.
    var chatPartnerID: String?
    
    @State private var messageText: String = ""
    
    var body: some View {
        ZStack {
            AppTheme.backgroundGradient.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Messages list with auto-scroll
                messagesScrollView
                // Input bar at the bottom
                ChatInputBar(messageText: $messageText, onSend: sendMessage)
                    .padding(.bottom, 4)
            }
        }
        .toolbar { toolbarContent }
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.markMessagesAsRead()
        }
        .alert(item: errorBinding, content: alertContent)
    }
}

// MARK: - Subviews & Helpers
extension ChatConversationView {
    
    /// The scrolling list of messages + typing indicator
    private var messagesScrollView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(viewModel.messages) { msg in
                        MessageBubble(message: msg,
                                      isCurrentUser: msg.senderID == viewModel.currentUserID)
                            .id(msg.id)
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
                scrollToLastMessage(proxy: proxy)
            }
        }
    }
    
    /// The custom toolbar (title + optional partner status)
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .principal) {
            VStack {
                Text("Chat")
                    .font(AppTheme.titleFont)
                    .foregroundColor(.primary)
                if let partnerID = chatPartnerID {
                    OnlineStatusView(userID: partnerID)
                }
            }
        }
    }
    
    /// Binding for the alert triggered by `viewModel.errorMessage`
    private var errorBinding: Binding<GenericAlertError?> {
        Binding(
            get: {
                if let errorMessage = viewModel.errorMessage {
                    return GenericAlertError(message: errorMessage)
                }
                return nil
            },
            set: { _ in
                // Clear the error once dismissed
                viewModel.errorMessage = nil
            }
        )
    }
    
    /// Creates the alert from a `GenericAlertError`
    private func alertContent(_ alertError: GenericAlertError) -> Alert {
        Alert(
            title: Text("Error"),
            message: Text(alertError.message),
            dismissButton: .default(Text("OK"))
        )
    }
    
    /// Sends a message if it's non-empty
    private func sendMessage() {
        let trimmed = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        viewModel.sendMessage(text: trimmed)
        messageText = ""
    }
    
    /// Scrolls to the last message in the list (animated)
    private func scrollToLastMessage(proxy: ScrollViewProxy) {
        if let lastMessage = viewModel.messages.last, let id = lastMessage.id {
            withAnimation {
                proxy.scrollTo(id, anchor: .bottom)
            }
        }
    }
}

// MARK: - Preview
struct ChatConversationView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ChatConversationView(
                viewModel: ChatConversationViewModel(chatID: "dummyChatID"),
                chatPartnerID: "dummyPartnerID"
            )
        }
    }
}
