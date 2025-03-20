//
//  GlobalSearchViewModel.swift
//  CollegePads
//
//  This view model handles the logic for the Global Search feature.
//  It supports searching across users and listings using Firestore queries.
//  It updates published properties so the UI can react to changes in search state.
//

import SwiftUI
import FirebaseFirestore

/// Defines the types of searches available.
enum SearchType: String, CaseIterable, Identifiable {
    case users = "Users"
    case listings = "Listings"
    var id: String { self.rawValue }
}

/// ViewModel to manage global search queries and results.
class GlobalSearchViewModel: ObservableObject {
    @Published var query: String = ""
    @Published var searchType: SearchType = .users
    @Published var userResults: [UserModel] = []
    @Published var listingResults: [ListingModel] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private var db = Firestore.firestore()
    
    /// Performs the search based on the current query and selected search type.
    func performSearch() {
        // Clear results if query is empty.
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else {
            userResults = []
            listingResults = []
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        if searchType == .users {
            // Query the "users" collection by email.
            db.collection("users")
                .whereField("email", isGreaterThanOrEqualTo: query)
                .whereField("email", isLessThanOrEqualTo: query + "\u{f8ff}")
                .getDocuments { [weak self] snapshot, error in
                    DispatchQueue.main.async {
                        self?.isLoading = false
                        if let error = error {
                            self?.errorMessage = error.localizedDescription
                        } else if let documents = snapshot?.documents {
                            self?.userResults = documents.compactMap { doc in
                                try? doc.data(as: UserModel.self)
                            }
                        }
                    }
                }
        } else if searchType == .listings {
            // Query the "listings" collection by title.
            db.collection("listings")
                .whereField("title", isGreaterThanOrEqualTo: query)
                .whereField("title", isLessThanOrEqualTo: query + "\u{f8ff}")
                .getDocuments { [weak self] snapshot, error in
                    DispatchQueue.main.async {
                        self?.isLoading = false
                        if let error = error {
                            self?.errorMessage = error.localizedDescription
                        } else if let documents = snapshot?.documents {
                            self?.listingResults = documents.compactMap { doc in
                                try? doc.data(as: ListingModel.self)
                            }
                        }
                    }
                }
        }
    }
}
