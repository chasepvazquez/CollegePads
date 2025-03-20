import SwiftUI
import FirebaseFirestore
import FirebaseFirestoreCombineSwift
import FirebaseAuth
import Combine
import CoreLocation

class AdvancedFilterViewModel: ObservableObject {
    @Published var filterDormType: String = ""
    @Published var filterHousingStatus: String = ""
    @Published var filterCollegeName: String = ""
    @Published var filterBudgetRange: String = ""
    @Published var filterGradeGroup: String = ""
    @Published var filterInterests: String = ""
    @Published var maxDistance: Double = 10.0 // in kilometers
    
    @Published var filteredUsers: [UserModel] = []
    @Published var errorMessage: String?
    
    private var cancellables = Set<AnyCancellable>()
    private let db = Firestore.firestore()
    
    func applyFilters(currentLocation: CLLocation?) {
        var query: Query = db.collection("users")
        
        if !filterDormType.isEmpty {
            query = query.whereField("dormType", isEqualTo: filterDormType)
        }
        if !filterHousingStatus.isEmpty {
            query = query.whereField("housingStatus", isEqualTo: filterHousingStatus)
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
                snapshot.documents.compactMap { try? $0.data(as: UserModel.self) }
            }
            .map { users in
                // Filter by grade group.
                let gradeFiltered: [UserModel]
                if !self.filterGradeGroup.isEmpty {
                    gradeFiltered = users.filter { user in
                        if let grade = user.gradeLevel?.lowercased() {
                            let selected = self.filterGradeGroup.lowercased()
                            switch selected {
                            case "freshman":
                                return grade == "freshman"
                            case "underclassmen":
                                return grade == "sophomore" // adjust as needed
                            case "upperclassmen":
                                return grade == "junior" || grade == "senior"
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
                
                // Filter by interests.
                let interestsFiltered: [UserModel]
                if !self.filterInterests.isEmpty {
                    let keywords = self.filterInterests.split(separator: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
                    interestsFiltered = gradeFiltered.filter { user in
                        if let userInterests = user.interests {
                            let lowerUserInterests = userInterests.map { $0.lowercased() }
                            return !Set(keywords).intersection(lowerUserInterests).isEmpty
                        }
                        return false
                    }
                } else {
                    interestsFiltered = gradeFiltered
                }
                
                // Filter by distance.
                let locationFiltered: [UserModel]
                if let currentLocation = currentLocation {
                    locationFiltered = interestsFiltered.filter { user in
                        if let geoPoint = user.location {
                            let userLocation = CLLocation(latitude: geoPoint.latitude, longitude: geoPoint.longitude)
                            let distance = currentLocation.distance(from: userLocation) / 1000.0
                            return distance <= self.maxDistance
                        }
                        return true
                    }
                } else {
                    locationFiltered = interestsFiltered
                }
                
                return locationFiltered
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
    
    func loadMatches(matches: [UserModel]) {
        self.filteredUsers = matches
    }
}
