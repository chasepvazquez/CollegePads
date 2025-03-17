//
//  FavoritesView.swift
//  CollegePads
//
//  Created by [Your Name] on [Date].
//

import SwiftUI
import FirebaseFirestoreCombineSwift
import Combine

struct FavoritesView: View {
    @State private var favorites: [UserModel] = []
    @State private var errorMessage: String?
    @State private var cancellables = Set<AnyCancellable>()
    
    private let favoriteService = FavoriteService()
    
    var body: some View {
        NavigationView {
            List(favorites) { candidate in
                NavigationLink(destination: CandidateProfileView(candidateID: candidate.id ?? "")) {
                    VStack(alignment: .leading) {
                        Text(candidate.email)
                            .font(.headline)
                        if let dorm = candidate.dormType {
                            Text("Dorm: \(dorm)")
                        }
                        if let budget = candidate.budgetRange {
                            Text("Budget: \(budget)")
                        }
                    }
                }
            }
            .navigationTitle("Favorites")
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
                Alert(title: Text("Error"), message: Text(alertError.message), dismissButton: .default(Text("OK")))
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
