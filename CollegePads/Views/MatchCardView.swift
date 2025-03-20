//
//  MatchCardView.swift
//  CollegePads
//
//  Created by [Your Name] on [Date]
//
//  This view displays a candidate’s small profile card (circular image and initials/name)
//  for use in the horizontal matches bar in the Combined Matches & Chat tab.

import SwiftUI
import FirebaseFirestore
import FirebaseFirestoreCombineSwift

struct MatchCardView: View {
    let candidateID: String
    @State private var candidate: UserModel?
    @State private var errorMessage: String?

    var body: some View {
        VStack {
            if let candidate = candidate {
                if let imageUrl = candidate.profileImageUrl, let url = URL(string: imageUrl) {
                    AsyncImage(url: url) { phase in
                        if let image = phase.image {
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 60, height: 60)
                                .clipShape(Circle())
                        } else {
                            defaultPlaceholder(for: candidate)
                        }
                    }
                } else {
                    defaultPlaceholder(for: candidate)
                }
                // Display a short name; if not available, use the first two letters of the email.
                Text(candidate.email.components(separatedBy: "@").first ?? "User")
                    .font(.caption)
                    .lineLimit(1)
            } else {
                // While loading, show a gray placeholder.
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 60, height: 60)
                Text("Loading")
                    .font(.caption)
            }
        }
        .onAppear {
            loadCandidate()
        }
    }
    
    /// Provides a default circular placeholder with initials.
    private func defaultPlaceholder(for candidate: UserModel) -> some View {
        // Extract the first two letters from the email (or fallback text)
        let initials = candidate.email.components(separatedBy: "@").first?.prefix(2).uppercased() ?? "??"
        return Text(initials)
            .font(.headline)
            .frame(width: 60, height: 60)
            .background(Color.blue.opacity(0.5))
            .foregroundColor(.white)
            .clipShape(Circle())
    }
    
    /// Loads candidate details from Firestore.
    private func loadCandidate() {
        let db = Firestore.firestore()
        db.collection("users").document(candidateID).getDocument { snapshot, error in
            if let error = error {
                errorMessage = error.localizedDescription
            } else if let snapshot = snapshot, snapshot.exists {
                do {
                    candidate = try snapshot.data(as: UserModel.self)
                } catch {
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}

struct MatchCardView_Previews: PreviewProvider {
    static var previews: some View {
        MatchCardView(candidateID: "dummyCandidateID")
    }
}
