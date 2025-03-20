//
//  CombinedMatchesChatView.swift
//  CollegePads
//
//  Created by [Your Name] on [Date]
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
                        // Button on the far left to show all matches.
                        Button(action: {
                            showAllMatches = true
                        }) {
                            HStack {
                                Image(systemName: "list.bullet")
                                Text("All Matches")
                            }
                            .padding(8)
                            .background(Color.brandPrimary.opacity(0.1))
                            .cornerRadius(8)
                        }
                        
                        // For each match, show a MatchCardView.
                        ForEach(matchesVM.matches) { match in
                            let candidateID = match.participants.first(where: { $0 != (matchesVM.currentUserID ?? "") }) ?? "unknown"
                            MatchCardView(candidateID: candidateID)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }
                .background(Color(UIColor.systemBackground).opacity(0.95))
                .sheet(isPresented: $showAllMatches) {
                    AllMatchesView() // Create this file if needed, or reuse your MatchesDashboardView.
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
