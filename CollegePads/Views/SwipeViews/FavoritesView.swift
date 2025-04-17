import SwiftUI
import Combine

struct FavoritesView: View {
    @State private var favorites: [UserModel] = []
    @State private var errorMessage: String?

    private let favoriteService = FavoriteService()

    /// Convert our `String?` into a `Binding<GenericAlertError?>` for `.alert(item:)`
    private var alertBinding: Binding<GenericAlertError?> {
        Binding<GenericAlertError?>(
            get: {
                if let msg = errorMessage {
                    return GenericAlertError(message: msg)
                }
                return nil
            },
            set: { _ in errorMessage = nil }
        )
    }

    var body: some View {
        NavigationView {
            List(favorites) { candidate in
                NavigationLink(destination: ProfilePreviewView(user: candidate)) {
                    favoriteRow(for: candidate)
                }
            }
            .listStyle(PlainListStyle())
            .scrollContentBackground(.hidden)
            .navigationTitle("Favorites")
            .onAppear(perform: loadFavorites)
            .alert(item: alertBinding) { alertError in
                Alert(
                    title: Text("Error"),
                    message: Text(alertError.message),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }

    /// A tiny helper to keep the List row simple
    @ViewBuilder
    private func favoriteRow(for candidate: UserModel) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            // Show full name if available, otherwise fall back to email
            if let first = candidate.firstName,
               let last  = candidate.lastName,
               (!first.isEmpty || !last.isEmpty) {
                Text("\(first) \(last)")
                    .font(AppTheme.bodyFont)
            } else {
                // candidate.email is non‑optional String
                Text(candidate.email)
                    .font(AppTheme.bodyFont)
            }

            // Dorm (if set)
            if let dorm = candidate.dormType {
                Text("Dorm: \(dorm)")
                    .font(AppTheme.bodyFont)
            }

            // Budget (from your new min/max fields)
            if let min = candidate.budgetMin,
               let max = candidate.budgetMax {
                Text("Budget: \(Int(min))–\(Int(max)) USD")
                    .font(AppTheme.bodyFont)
            }
        }
        .padding(.vertical, 4)
    }

    /// Kick off the FavoriteService call and handle its result
    private func loadFavorites() {
        favoriteService.loadFavorites { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let users):
                    self.favorites = users
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
}

struct FavoritesView_Previews: PreviewProvider {
    static var previews: some View {
        FavoritesView()
    }
}
