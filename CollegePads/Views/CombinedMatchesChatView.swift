import SwiftUI
import FirebaseFirestore

struct CombinedMatchesChatView: View {
    @StateObject private var matchesVM = MatchesDashboardViewModel()
    @StateObject private var chatsVM = ChatsListViewModel()
    @State private var showAllMatches: Bool = false

    var body: some View {
        NavigationView {
            ZStack {
                AppTheme.backgroundGradient.ignoresSafeArea()
                VStack(spacing: 0) {
                    // Top Matches Bar
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            Button(action: {
                                showAllMatches = true
                            }) {
                                HStack {
                                    Image(systemName: "list.bullet")
                                    Text("All Matches")
                                }
                                .padding(8)
                                .background(AppTheme.primaryColor.opacity(0.1))
                                .cornerRadius(8)
                            }
                            
                            ForEach(matchesVM.matches) { match in
                                let candidateID = candidateID(for: match)
                                NavigationLink(
                                    destination: ChatConversationView(
                                        viewModel: ChatConversationViewModel(chatID: match.id),
                                        chatPartnerID: candidateID)
                                ) {
                                    // Use the unified SwipeCardView that loads candidate info using candidateID.
                                    SwipeCardView(candidateID: candidateID)
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                    }
                    .background(AppTheme.backgroundGradient.opacity(0.95))
                    .sheet(isPresented: $showAllMatches) {
                        AllMatchesView()
                    }
                    
                    Divider()
                    
                    // Chat List below.
                    ChatsListView()
                }
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        Text("Messages")
                            .font(AppTheme.titleFont)
                            .foregroundColor(.primary)
                    }
                }
                .onAppear {
                    matchesVM.loadMatches()
                    chatsVM.fetchChats()
                }
            }
        }
    }
    
    /// Helper to extract the candidateID from a MatchItem.
    private func candidateID(for match: MatchItem) -> String {
        return match.participants.first(where: { $0 != (matchesVM.currentUserID ?? "") }) ?? "unknown"
    }
}

struct CombinedMatchesChatView_Previews: PreviewProvider {
    static var previews: some View {
        CombinedMatchesChatView()
    }
}
