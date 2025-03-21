//
//  CombinedMatchesChatView.swift
//  CollegePads
//
//  Updated to use AppTheme for backgrounds and colors consistently.
//
import SwiftUI

struct CombinedMatchesChatView: View {
    @StateObject private var matchesVM = MatchesDashboardViewModel()
    @StateObject private var chatsVM = ChatsListViewModel()
    @State private var showAllMatches: Bool = false

    var body: some View {
        NavigationView {
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
                            let candidateID = match.participants.first(where: {
                                $0 != (matchesVM.currentUserID ?? "")
                            }) ?? "unknown"
                            MatchCardView(candidateID: candidateID)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }
                // Updated background: use AppTheme.backgroundGradient for consistency.
                .background(AppTheme.backgroundGradient.opacity(0.95))
                .sheet(isPresented: $showAllMatches) {
                    AllMatchesView()
                }
                
                Divider()
                
                // Chat List below.
                ChatsListView()
            }
            .navigationTitle("Messages")
            .onAppear {
                matchesVM.loadMatches()
                chatsVM.fetchChats()
            }
        }
    }
}

struct CombinedMatchesChatView_Previews: PreviewProvider {
    static var previews: some View {
        CombinedMatchesChatView()
    }
}
