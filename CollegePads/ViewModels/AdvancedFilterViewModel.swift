import SwiftUI
import FirebaseFirestore
import FirebaseFirestoreCombineSwift
import Combine
import CoreLocation
import FirebaseAuth

// New enum for filtering mode.
enum FilterMode: String, CaseIterable, Identifiable {
    case university
    case distance
    var id: String { self.rawValue }
}

class AdvancedFilterViewModel: ObservableObject {
    // Filter fields
    @Published var filterDormType: String = ""
    @Published var filterHousingStatus: String = ""
    // This property now serves as the selected college (if filtering by college)
    @Published var filterCollegeName: String = ""
    @Published var filterBudgetRange: String = ""
    @Published var filterGradeGroup: String = ""
    @Published var filterInterests: String = ""
    // Only used when filtering by distance
    @Published var maxDistance: Double = 10.0 // in kilometers

    // NEW: Additional filter properties for gender and age difference.
    @Published var filterPreferredGender: String = ""
    @Published var maxAgeDifference: Double = 0.0

    // New: Filter mode – either by university or by distance.
    @Published var filterMode: FilterMode = .university
    
    // Filter results and errors
    @Published var filteredUsers: [UserModel] = []
    @Published var errorMessage: String?
    
    private var cancellables = Set<AnyCancellable>()
    private let db = Firestore.firestore()
    
    /// Main method to apply filters by querying Firestore and further refining the results.
    /// If filtering by college, we ignore distance.
    func applyFilters(currentLocation: CLLocation?) {
        var query: Query = db.collection("users")
        
        // 1. Apply direct Firestore queries for certain fields.
        if !filterDormType.isEmpty {
            query = query.whereField("dormType", isEqualTo: filterDormType)
        }
        if !filterHousingStatus.isEmpty {
            query = query.whereField("housingStatus", isEqualTo: filterHousingStatus)
        }
        // Only add this Firestore query when filtering by college.
        if filterMode == .university && !filterCollegeName.isEmpty {
            query = query.whereField("collegeName", isEqualTo: filterCollegeName)
        }
        if !filterBudgetRange.isEmpty {
            query = query.whereField("budgetRange", isEqualTo: filterBudgetRange)
        }
        
        // 2. Use Firestore's Combine publisher to fetch matching documents.
        query
            .snapshotPublisher()
            .map { snapshot -> [UserModel] in
                snapshot.documents.compactMap { try? $0.data(as: UserModel.self) }
            }
            .map { users in
                // 3. Filter by grade group
                let gradeFiltered: [UserModel]
                if !self.filterGradeGroup.isEmpty {
                    gradeFiltered = users.filter { user in
                        guard let grade = user.gradeLevel?.lowercased() else { return false }
                        let selected = self.filterGradeGroup.lowercased()
                        switch selected {
                        case "freshman":
                            return grade == "freshman"
                        case "underclassmen":
                            return grade == "freshman" || grade == "sophomore"
                        case "upperclassmen":
                            return grade == "junior" || grade == "senior"
                        case "graduate":
                            return grade == "graduate"
                        default:
                            return true
                        }
                    }
                } else {
                    gradeFiltered = users
                }
                
                // 4. Filter by interests
                let interestsFiltered: [UserModel]
                if !self.filterInterests.isEmpty {
                    let keywords = self.filterInterests
                        .split(separator: ",")
                        .map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
                    
                    interestsFiltered = gradeFiltered.filter { user in
                        guard let userInterests = user.interests else { return false }
                        let lowerUserInterests = userInterests.map { $0.lowercased() }
                        return !Set(keywords).intersection(lowerUserInterests).isEmpty
                    }
                } else {
                    interestsFiltered = gradeFiltered
                }
                
                // 5. Filter by distance only if not filtering by college.
                let finalFiltered: [UserModel]
                if self.filterMode == .university && !self.filterCollegeName.isEmpty {
                    finalFiltered = interestsFiltered
                } else if self.filterMode == .distance, let currentLocation = currentLocation {
                    finalFiltered = interestsFiltered.filter { user in
                        guard let geoPoint = user.location else { return true }
                        let userLocation = CLLocation(latitude: geoPoint.latitude, longitude: geoPoint.longitude)
                        let distance = currentLocation.distance(from: userLocation) / 1000.0
                        return distance <= self.maxDistance
                    }
                } else {
                    finalFiltered = interestsFiltered
                }
                
                return finalFiltered
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
    
    /// Saves the current filter fields to the Firestore user document so they're remembered.
    func saveFiltersToUserDoc() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let docRef = db.collection("users").document(uid)
        
        let data: [String: Any] = [
            "filterDormType": filterDormType,
            "filterHousingStatus": filterHousingStatus,
            "filterCollegeName": filterCollegeName,
            "filterBudgetRange": filterBudgetRange,
            "filterGradeGroup": filterGradeGroup,
            "filterInterests": filterInterests,
            "filterMaxDistance": maxDistance,
            "filterPreferredGender": filterPreferredGender,
            "maxAgeDifference": maxAgeDifference,
            "filterMode": filterMode.rawValue
        ]
        
        docRef.setData(data, merge: true) { error in
            if let error = error {
                DispatchQueue.main.async {
                    self.errorMessage = "Failed to save filters: \(error.localizedDescription)"
                }
            }
        }
    }
    
    /// Loads previously saved filter fields from the Firestore user document, if any.
    func loadFiltersFromUserDoc(completion: @escaping () -> Void = {}) {
        guard let uid = Auth.auth().currentUser?.uid else {
            completion()
            return
        }
        let docRef = db.collection("users").document(uid)
        
        docRef.getDocument { snapshot, error in
            defer { completion() }
            
            if let error = error {
                DispatchQueue.main.async {
                    self.errorMessage = "Failed to load filters: \(error.localizedDescription)"
                }
                return
            }
            guard let data = snapshot?.data() else { return }
            
            DispatchQueue.main.async {
                self.filterDormType = data["filterDormType"] as? String ?? ""
                self.filterHousingStatus = data["filterHousingStatus"] as? String ?? ""
                self.filterCollegeName = data["filterCollegeName"] as? String ?? ""
                self.filterBudgetRange = data["filterBudgetRange"] as? String ?? ""
                self.filterGradeGroup = data["filterGradeGroup"] as? String ?? ""
                self.filterInterests = data["filterInterests"] as? String ?? ""
                self.maxDistance = data["filterMaxDistance"] as? Double ?? 10.0
                self.filterPreferredGender = data["filterPreferredGender"] as? String ?? ""
                self.maxAgeDifference = data["maxAgeDifference"] as? Double ?? 0.0
                if let modeString = data["filterMode"] as? String,
                   let mode = FilterMode(rawValue: modeString) {
                    self.filterMode = mode
                }
            }
        }
    }
}
