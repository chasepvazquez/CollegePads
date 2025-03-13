//
//  AdvancedFilterViewModel.swift
//  CollegePads
//
//  Created by [Your Name] on [Date].
//

import SwiftUI
import FirebaseFirestore
import FirebaseFirestoreCombineSwift
import FirebaseAuth
import Combine

class AdvancedFilterViewModel: ObservableObject {
    @Published var filterDormType: String = ""
    @Published var filterCollegeName: String = ""
    @Published var filterBudgetRange: String = ""
    @Published var filterGradeLevel: String = ""

    @Published var filteredUsers: [UserModel] = []
    @Published var errorMessage: String?

    private var cancellables = Set<AnyCancellable>()
    private let db = Firestore.firestore()

    func applyFilters() {
        var query: Query = db.collection("users")

        // Example: filter by dormType if user set one
        if !filterDormType.isEmpty {
            query = query.whereField("dormType", isEqualTo: filterDormType)
        }
        // Example: filter by collegeName
        if !filterCollegeName.isEmpty {
            query = query.whereField("collegeName", isEqualTo: filterCollegeName)
        }
        // Example: filter by budgetRange (exact match, or you could do partial parse)
        if !filterBudgetRange.isEmpty {
            query = query.whereField("budgetRange", isEqualTo: filterBudgetRange)
        }
        // Example: filter by gradeLevel
        if !filterGradeLevel.isEmpty {
            query = query.whereField("gradeLevel", isEqualTo: filterGradeLevel)
        }

        // Now run the query with snapshotPublisher
        query
            .snapshotPublisher()
            .map { snapshot -> [UserModel] in
                snapshot.documents.compactMap { doc in
                    do {
                        return try doc.data(as: UserModel.self)
                    } catch {
                        print("Error decoding user doc: \(error)")
                        return nil
                    }
                }
            }
            .sink { completion in
                switch completion {
                case .failure(let error):
                    DispatchQueue.main.async {
                        self.errorMessage = error.localizedDescription
                    }
                case .finished:
                    break
                }
            } receiveValue: { users in
                // Optionally exclude the current user
                let currentUID = Auth.auth().currentUser?.uid
                let filtered = users.filter { $0.id != currentUID }
                DispatchQueue.main.async {
                    self.filteredUsers = filtered
                }
            }
            .store(in: &cancellables)
    }
}
