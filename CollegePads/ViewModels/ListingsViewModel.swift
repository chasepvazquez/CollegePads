//
//  ListingsViewModel.swift
//  CollegePads
//
//  Created by [Your Name] on [Date]
//

import SwiftUI
import FirebaseFirestore
import FirebaseFirestoreCombineSwift
import Combine
import CoreLocation

class ListingsViewModel: ObservableObject {
    @Published var listings: [ListingModel] = []
    @Published var errorMessage: String?
    
    private var cancellables = Set<AnyCancellable>()
    private let db = Firestore.firestore()
    
    /// Fetches listings ordered by creation date.
    func fetchListings() {
        db.collection("listings")
            .order(by: "createdAt", descending: true)
            .snapshotPublisher()
            .map { snapshot -> [ListingModel] in
                snapshot.documents.compactMap { doc in
                    try? doc.data(as: ListingModel.self)
                }
            }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                if case let .failure(error) = completion {
                    self?.errorMessage = error.localizedDescription
                }
            } receiveValue: { [weak self] listings in
                self?.listings = listings
            }
            .store(in: &cancellables)
    }
}
