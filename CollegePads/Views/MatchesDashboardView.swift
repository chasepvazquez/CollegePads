//
//  MatchesDashboardView.swift
//  CollegePads
//
//  Created by [Your Name] on [Date].
//

import SwiftUI
import FirebaseFirestore
import FirebaseFirestoreCombineSwift
import FirebaseAuth
import Combine

struct MatchItem: Identifiable {
    let id: String
    let participants: [String]
    let createdAt: Date
}

class MatchesDashboardViewModel: ObservableObject {
    @Published var matches: [MatchItem] = []
    @Published var errorMessage: String?
    
    private var cancellables = Set<AnyCancellable>()
    private let db = Firestore.firestore()
    
    var currentUserID: String? {
        Auth.auth().currentUser?.uid
    }
    
    func loadMatches() {
        guard let uid = currentUserID else {
            self.errorMessage = "User not authenticated"
            return
        }
        
        db.collection("matches")
            .whereField("participants", arrayContains: uid)
            .snapshotPublisher()
            .map { querySnapshot -> [MatchItem] in
                querySnapshot.documents.compactMap { doc in
                    let data = doc.data()
                    let id = doc.documentID
                    let participants = data["participants"] as? [String] ?? []
                    let timestamp = (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
                    return MatchItem(id: id, participants: participants, createdAt: timestamp)
                }
            }
            .sink { completion in
                if case let .failure(error) = completion {
                    DispatchQueue.main.async {
                        self.errorMessage = error.localizedDescription
                    }
                }
            } receiveValue: { matches in
                DispatchQueue.main.async {
                    self.matches = matches
                }
            }
            .store(in: &cancellables)
    }
}

struct MatchesDashboardView: View {
    @StateObject private var viewModel = MatchesDashboardViewModel()
    
    // Compute candidateID: choose the first participant that's not the current user.
    func candidateID(for match: MatchItem) -> String {
        guard let currentUID = viewModel.currentUserID else { return "" }
        return match.participants.first(where: { $0 != currentUID }) ?? ""
    }
    
    var body: some View {
        NavigationView {
            List(viewModel.matches) { match in
                let candidateIDValue = candidateID(for: match)
                NavigationLink(destination: CandidateProfileView(candidateID: candidateIDValue)) {
                    VStack(alignment: .leading) {
                        Text("Match with: \(match.participants.filter { $0 != viewModel.currentUserID }.joined(separator: ", "))")
                            .font(.headline)
                        Text("Matched on: \(match.createdAt, formatter: dateFormatter)")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
            }
            .navigationTitle("My Matches")
            .onAppear {
                viewModel.loadMatches()
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
                Alert(title: Text("Error"), message: Text(alertError.message), dismissButton: .default(Text("OK")))
            }
        }
    }
    
    var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }
}

struct MatchesDashboardView_Previews: PreviewProvider {
    static var previews: some View {
        MatchesDashboardView()
    }
}
