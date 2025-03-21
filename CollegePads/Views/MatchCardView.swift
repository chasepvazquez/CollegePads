import SwiftUI
import FirebaseFirestore

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
                Text(candidate.email.components(separatedBy: "@").first ?? "User")
                    .font(AppTheme.bodyFont)
                    .lineLimit(1)
            } else {
                Circle()
                    .fill(AppTheme.cardBackground)
                    .frame(width: 60, height: 60)
                Text("Loading")
                    .font(AppTheme.bodyFont)
            }
        }
        .onAppear {
            loadCandidate()
        }
    }
    
    /// Provides a default circular placeholder with candidate initials.
    private func defaultPlaceholder(for candidate: UserModel) -> some View {
        let initials = candidate.email.components(separatedBy: "@").first?.prefix(2).uppercased() ?? "??"
        return Text(initials)
            .font(AppTheme.bodyFont.weight(.bold))
            .frame(width: 60, height: 60)
            .background(AppTheme.primaryColor.opacity(0.5))
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
