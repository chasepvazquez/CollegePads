//
//  AllMatchesView.swift
//  CollegePads
//
//  Created by [Your Name] on [Date]
//
//  This view displays a full list of all matches. It uses the MatchesDashboardViewModel
//  to fetch matches and displays them in a list. Tapping a match navigates to the candidate’s profile.

import SwiftUI
import FirebaseFirestore
import FirebaseFirestoreCombineSwift
import FirebaseAuth
import Combine

struct AllMatchesView: View {
    @StateObject private var viewModel = MatchesDashboardViewModel()

    var body: some View {
        NavigationView {
            List(viewModel.matches) { match in
                NavigationLink(destination: CandidateProfileView(candidateID: candidateID(for: match))) {
                    VStack(alignment: .leading) {
                        Text("Match with: \(match.participants.filter { $0 != viewModel.currentUserID }.joined(separator: ", "))")
                            .font(.headline)
                        Text("Matched on: \(match.createdAt, formatter: dateFormatter)")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
            }
            .navigationTitle("All Matches")
            .onAppear {
                viewModel.loadMatches()
            }
        }
    }
    
    /// Helper function to extract the candidate ID (first participant that is not the current user).
    func candidateID(for match: MatchItem) -> String {
        guard let currentUID = viewModel.currentUserID else { return "" }
        return match.participants.first(where: { $0 != currentUID }) ?? ""
    }
    
    /// Date formatter for displaying match timestamps.
    var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }
}

struct AllMatchesView_Previews: PreviewProvider {
    static var previews: some View {
        AllMatchesView()
    }
}
