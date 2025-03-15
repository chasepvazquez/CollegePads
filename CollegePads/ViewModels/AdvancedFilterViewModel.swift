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
import CoreLocation

class AdvancedFilterViewModel: ObservableObject {
    @Published var filterDormType: String = ""
    @Published var filterCollegeName: String = ""
    @Published var filterBudgetRange: String = ""
    @Published var filterGradeLevel: String = ""
    @Published var maxDistance: Double = 10.0  // in kilometers; default value

    @Published var filteredUsers: [UserModel] = []
    @Published var errorMessage: String?

    private var cancellables = Set<AnyCancellable>()
    private let db = Firestore.firestore()

    func applyFilters(currentLocation: CLLocation?) {
        var query: Query = db.collection("users")

        // Apply Firestore filters first
        if !filterDormType.isEmpty {
            query = query.whereField("dormType", isEqualTo: filterDormType)
        }
        if !filterCollegeName.isEmpty {
            query = query.whereField("collegeName", isEqualTo: filterCollegeName)
        }
        if !filterBudgetRange.isEmpty {
            query = query.whereField("budgetRange", isEqualTo: filterBudgetRange)
        }
        if !filterGradeLevel.isEmpty {
            query = query.whereField("gradeLevel", isEqualTo: filterGradeLevel)
        }
        
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
            .map { users in
                // Optionally filter by distance if currentLocation is provided
                if let currentLocation = currentLocation {
                    return users.filter { user in
                        if let lat = user.latitude, let lon = user.longitude {
                            let userLocation = CLLocation(latitude: lat, longitude: lon)
                            let distance = currentLocation.distance(from: userLocation) / 1000.0 // km
                            return distance <= self.maxDistance
                        }
                        return true
                    }
                }
                return users
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
                // Exclude current user
                let currentUID = Auth.auth().currentUser?.uid
                let filtered = users.filter { $0.id != currentUID }
                DispatchQueue.main.async {
                    self.filteredUsers = filtered
                }
            }
            .store(in: &cancellables)
    }
}
