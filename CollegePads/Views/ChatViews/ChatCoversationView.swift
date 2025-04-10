import SwiftUI
import FirebaseAuth

struct ChatConversationView: View {
    @StateObject var viewModel: ChatConversationViewModel
    var chatPartnerID: String?
    /// Optional match ID; only available after a match is made.
    var matchID: String? = nil
    
    @State private var messageText: String = ""
    @State private var showReviewSheet: Bool = false
    @State private var showAgreementSheet: Bool = false
    
    var body: some View {
        ZStack {
            AppTheme.backgroundGradient.ignoresSafeArea()
            
            VStack(spacing: 0) {
                messagesScrollView
                
                // New ChatInputBar now includes the plus-options button.
                ChatInputBar(messageText: $messageText, onSend: sendMessage, onOptionSelected: { option in
                    switch option {
                    case .rate:
                        if matchID != nil {
                            showReviewSheet = true
                        } // else: Optionally alert that this feature is not available until a match is made.
                    case .agreement:
                        if matchID != nil {
                            showAgreementSheet = true
                        }
                    }
                })
                .padding(.bottom, 4)
            }
        }
        .toolbar { toolbarContent }
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.markMessagesAsRead()
        }
        .alert(item: errorBinding, content: alertContent)
        // Present RoommateReviewView if option selected and match exists.
        .sheet(isPresented: $showReviewSheet) {
            if let matchID = matchID, let partnerID = chatPartnerID {
                RoommateReviewView(matchID: matchID, ratedUserID: partnerID)
            } else {
                Text("Roommate review is not available until a match is made.")
            }
        }
        // Present AgreementView if option selected and match exists.
        .sheet(isPresented: $showAgreementSheet) {
            if let matchID = matchID, let partnerID = chatPartnerID,
               let currentUserID = ProfileViewModel.shared.userProfile?.id {
                AgreementView(matchID: matchID, userA: currentUserID, userB: partnerID)
            } else {
                Text("Agreement is not available until a match is made.")
            }
        }
    }
}

extension ChatConversationView {
    private var messagesScrollView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(viewModel.messages) { msg in
                        MessageBubble(message: msg, isCurrentUser: msg.senderID == viewModel.currentUserID)
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
    
    private var errorBinding: Binding<GenericAlertError?> {
        Binding(
            get: {
                if let errorMessage = viewModel.errorMessage {
                    return GenericAlertError(message: errorMessage)
                }
                return nil
            },
            set: { _ in viewModel.errorMessage = nil }
        )
    }
    
    private func alertContent(_ alertError: GenericAlertError) -> Alert {
        Alert(
            title: Text("Error"),
            message: Text(alertError.message),
            dismissButton: .default(Text("OK"))
        )
    }
    
    private func sendMessage() {
        let trimmed = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        viewModel.sendMessage(text: trimmed)
        messageText = ""
    }
    
    private func scrollToLastMessage(proxy: ScrollViewProxy) {
        if let lastMessage = viewModel.messages.last, let id = lastMessage.id {
            withAnimation {
                proxy.scrollTo(id, anchor: .bottom)
            }
        }
    }
}

struct ChatConversationView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ChatConversationView(
                viewModel: ChatConversationViewModel(chatID: "dummyChatID"),
                chatPartnerID: "dummyPartnerID",
                matchID: "dummyMatchID"
            )
        }
    }
}
