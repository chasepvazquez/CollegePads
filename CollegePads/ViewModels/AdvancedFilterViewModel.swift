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
    @Published var filterGradeGroup: String = ""  // New: "", "Freshman", "Upperclassmen", "Graduate"
    @Published var filterInterests: String = ""
    @Published var maxDistance: Double = 10.0  // in kilometers
    
    @Published var filteredUsers: [UserModel] = []
    @Published var errorMessage: String?
    
    private var cancellables = Set<AnyCancellable>()
    private let db = Firestore.firestore()
    
    func applyFilters(currentLocation: CLLocation?) {
        var query: Query = db.collection("users")
        
        // Basic Firestore filtering
        if !filterDormType.isEmpty {
            query = query.whereField("dormType", isEqualTo: filterDormType)
        }
        if !filterCollegeName.isEmpty {
            query = query.whereField("collegeName", isEqualTo: filterCollegeName)
        }
        if !filterBudgetRange.isEmpty {
            query = query.whereField("budgetRange", isEqualTo: filterBudgetRange)
        }
        
        query
            .snapshotPublisher()
            .map { snapshot -> [UserModel] in
                snapshot.documents.compactMap { doc in
                    try? doc.data(as: UserModel.self)
                }
            }
            .map { users in
                // Post-query filtering: Grade Group & Interests
                let gradeFiltered: [UserModel]
                if !self.filterGradeGroup.isEmpty {
                    gradeFiltered = users.filter { user in
                        if let grade = user.gradeLevel?.lowercased() {
                            switch self.filterGradeGroup.lowercased() {
                            case "freshman":
                                return grade == "freshman"
                            case "upperclassmen":
                                return grade == "sophomore" || grade == "junior" || grade == "senior"
                            case "graduate":
                                return grade == "graduate"
                            default:
                                return true
                            }
                        }
                        return false
                    }
                } else {
                    gradeFiltered = users
                }
                
                let interestsFiltered: [UserModel]
                if !self.filterInterests.isEmpty {
                    let interestsToFilter = self.filterInterests
                        .split(separator: ",")
                        .map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
                    interestsFiltered = gradeFiltered.filter { user in
                        if let userInterests = user.interests {
                            let lowerUserInterests = userInterests.map { $0.lowercased() }
                            return !Set(interestsToFilter).intersection(lowerUserInterests).isEmpty
                        }
                        return false
                    }
                } else {
                    interestsFiltered = gradeFiltered
                }
                
                return interestsFiltered
            }
            .map { users in
                // Filter by location if available.
                if let currentLocation = currentLocation {
                    return users.filter { user in
                        if let lat = user.latitude, let lon = user.longitude {
                            let userLocation = CLLocation(latitude: lat, longitude: lon)
                            let distance = currentLocation.distance(from: userLocation) / 1000.0
                            return distance <= self.maxDistance
                        }
                        return true
                    }
                }
                return users
            }
            .sink { completion in
                if case let .failure(error) = completion {
                    DispatchQueue.main.async {
                        self.errorMessage = error.localizedDescription
                    }
                }
            } receiveValue: { users in
                DispatchQueue.main.async {
                    self.filteredUsers = users
                }
            }
            .store(in: &cancellables)
    }
}
