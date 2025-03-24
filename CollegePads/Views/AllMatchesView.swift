import SwiftUI
import FirebaseFirestore
import FirebaseFirestoreCombineSwift
import FirebaseAuth
import Combine

struct AllMatchesView: View {
    @StateObject private var viewModel = MatchesDashboardViewModel()
    
    var body: some View {
        ZStack {
            // Global background gradient.
            AppTheme.backgroundGradient.ignoresSafeArea()
            
            // Remove inner NavigationView for consistent background.
            List(viewModel.matches) { match in
                // Create participant text.
                let participantText = match.participants.filter { $0 != viewModel.currentUserID }.joined(separator: ", ")
                
                NavigationLink(destination: CandidateProfileView(candidateID: candidateID(for: match))) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Match with: \(participantText)")
                            .font(AppTheme.bodyFont)
                        Text("Matched on: \(match.createdAt, formatter: dateFormatter)")
                            .font(AppTheme.bodyFont)
                            .foregroundColor(AppTheme.secondaryColor)
                    }
                    .padding(.vertical, 4)
                }
            }
            .listStyle(PlainListStyle())
            .scrollContentBackground(.hidden)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("All Matches")
                        .font(AppTheme.titleFont)
                        .foregroundColor(.primary)
                }
            }
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
