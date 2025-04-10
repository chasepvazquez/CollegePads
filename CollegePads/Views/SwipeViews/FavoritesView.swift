import SwiftUI
import FirebaseFirestoreCombineSwift
import Combine

struct FavoritesView: View {
    @State private var favorites: [UserModel] = []
    @State private var errorMessage: String?
    
    private let favoriteService = FavoriteService()
    
    var body: some View {
        NavigationView {
            List(favorites) { candidate in
                NavigationLink(destination: ProfilePreviewView(user: candidate)) {
                    VStack(alignment: .leading, spacing: 4) {
                        // Instead of showing candidate.email, display a name if available.
                        if let firstName = candidate.firstName, let lastName = candidate.lastName {
                            Text("\(firstName) \(lastName)")
                                .font(AppTheme.bodyFont)
                        }
                        if let dorm = candidate.dormType {
                            Text("Dorm: \(dorm)")
                                .font(AppTheme.bodyFont)
                        }
                        if let budget = candidate.budgetRange {
                            Text("Budget: \(budget)")
                                .font(AppTheme.bodyFont)
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .listStyle(PlainListStyle())
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Favorites")
                        .font(AppTheme.titleFont)
                        .foregroundColor(.primary)
                }
            }
            .onAppear {
                loadFavorites()
            }
            .alert(item: Binding(
                get: {
                    if let errorMessage = errorMessage {
                        return GenericAlertError(message: errorMessage)
                    }
                    return nil
                },
                set: { _ in errorMessage = nil }
            )) { alertError in
                Alert(title: Text("Error"),
                      message: Text(alertError.message),
                      dismissButton: .default(Text("OK")))
            }
        }
    }
    
    private func loadFavorites() {
        favoriteService.loadFavorites { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let candidates):
                    self.favorites = candidates
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
}

struct FavoritesView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            FavoritesView()
        }
    }
}
