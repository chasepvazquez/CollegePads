import SwiftUI
import FirebaseFirestore
import FirebaseFirestoreCombineSwift
import FirebaseAuth
import Combine

struct AllMatchesView: View {
    @StateObject private var viewModel = MatchesDashboardViewModel()
    
    var body: some View {
        ZStack {
            AppTheme.backgroundGradient.ignoresSafeArea()
            List(viewModel.matches) { match in
                let participantText = match.participants
                    .filter { $0 != viewModel.currentUserID }
                    .joined(separator: ", ")
                
                NavigationLink(destination:
                    // ← new inline loader
                    CandidateDetailView(candidateID: candidateID(for: match))
                ) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Match with: \(participantText)")
                            .font(AppTheme.bodyFont)
                            .foregroundColor(.primary)
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
    
    private func candidateID(for match: MatchItem) -> String {
        guard let currentUID = viewModel.currentUserID else { return "" }
        return match.participants.first(where: { $0 != currentUID }) ?? ""
    }
    
    private var dateFormatter: DateFormatter {
        let f = DateFormatter()
        f.dateStyle = .short
        f.timeStyle = .short
        return f
    }
}

// ————————————————————————————————————————————————————————
// MARK: - Candidate loader & detail view
// We no longer need UserPreviewLoaderView.swift.

private struct CandidateDetailView: View {
    let candidateID: String
    @StateObject private var vm = CandidateViewModel()
    
    var body: some View {
        Group {
            if let user = vm.user {
                ProfilePreviewView(user: user)   // your existing preview
            } else if let error = vm.errorMessage {
                Text("Error: \(error)")
                    .font(AppTheme.bodyFont)
                    .foregroundColor(.red)
                    .padding()
            } else {
                ProgressView("Loading…")
                    .font(AppTheme.bodyFont)
            }
        }
        .onAppear { vm.load(id: candidateID) }
    }
}

private class CandidateViewModel: ObservableObject {
    @Published var user: UserModel?
    @Published var errorMessage: String?
    
    private let db = Firestore.firestore()
    
    func load(id: String) {
        db.collection("users").document(id).getDocument { snap, err in
            if let err = err {
                DispatchQueue.main.async {
                    self.errorMessage = err.localizedDescription
                }
                return
            }
            guard let data = snap?.data() else {
                DispatchQueue.main.async {
                    self.errorMessage = "No data"
                }
                return
            }
            do {
                let candidate = try Firestore.Decoder().decode(UserModel.self, from: data)
                DispatchQueue.main.async {
                    self.user = candidate
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
}
