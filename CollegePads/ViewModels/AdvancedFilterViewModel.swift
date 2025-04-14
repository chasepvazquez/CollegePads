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
    // MARK: - Filter Fields
    
    // Replace overloaded housing status with this enum-based field.
    @Published var filterHousingPreference: PrimaryHousingPreference? = nil
    
    // College filter (for university mode).
    @Published var filterCollegeName: String = ""
    
    // Budget Range (for both lease and find together).
    @Published var filterBudgetRange: String = ""
    
    // Grade Group filter.
    @Published var filterGradeGroup: String = ""
    
    // Interests – free text, comma-separated keywords.
    @Published var filterInterests: String = ""
    
    // New Filters:
    @Published var filterRoomType: String = ""          // "Private Room", "Shared Room", "Studio"
    @Published var filterAmenities: [String] = []        // Multi-select for amenities
    @Published var filterPetFriendly: Bool? = nil        // Toggle: Must be pet friendly
    @Published var filterSmoker: Bool? = nil             // Toggle: Smoker OK
    @Published var filterDrinker: Bool? = nil            // Toggle: Drinker OK
    @Published var filterMarijuana: Bool? = nil          // Toggle: Marijuana use OK
    @Published var filterWorkout: Bool? = nil            // Toggle: Workout regularly
    @Published var filterCleanliness: Int? = nil         // 1–5 slider/segmented picker
    @Published var filterSleepSchedule: String = ""      // e.g., "Early bird", "Night owl", "Flexible"
    
    // Monthly Rent range; only active if filtering by lease.
    @Published var filterMonthlyRentMin: Double? = nil
    @Published var filterMonthlyRentMax: Double? = nil

    // Distance filtering (only if mode is distance)
    @Published var maxDistance: Double = 10.0

    // Additional filter properties for preferred gender and max age difference.
    @Published var filterPreferredGender: String = ""
    @Published var maxAgeDifference: Double = 0.0

    // Filter mode – either by university or by distance.
    @Published var filterMode: FilterMode = .university

    // Filter results and errors.
    @Published var filteredUsers: [UserModel] = []
    @Published var errorMessage: String?

    private var cancellables = Set<AnyCancellable>()
    private let db = Firestore.firestore()

    // New constants to support filtering.
    let propertyAmenitiesOptions: [String] = [
        "In-Unit Laundry",
        "On-Site Laundry",
        "Air Conditioning",
        "Heating",
        "Furnished",
        "Unfurnished",
        "High-Speed Internet",
        "Utilities Included",
        "Pet Friendly",
        "Parking Available",
        "Garage Parking",
        "Balcony / Patio",
        "Private Bathroom",
        "Shared Bathroom",
        "Gym / Fitness Center",
        "Common Area / Lounge",
        "Pool Access",
        "Rooftop Access",
        "Bike Storage",
        "Dishwasher",
        "Microwave",
        "Elevator Access",
        "Wheelchair Accessible",
        "24/7 Security",
        "Gated Community",
        "Study Rooms",
        "Game Room",
        "Smoke-Free",
        "Quiet Hours Enforced"
    ]

    let cleanlinessDescriptions: [Int: String] = [
        1: "Very Messy",
        2: "Messy",
        3: "Average",
        4: "Tidy",
        5: "Very Tidy"
    ]


    // MARK: - Apply Filters

    /// Applies all filters by querying Firestore first and then applying local filtering.
    func applyFilters(currentLocation: CLLocation?) {
        var query: Query = db.collection("users")
        
        // Filter by primary housing preference if provided.
        if let housingPref = filterHousingPreference {
            query = query.whereField("housingStatus", isEqualTo: housingPref.rawValue)
        }
        
        // When in university mode, filter by college name.
        if filterMode == .university && !filterCollegeName.isEmpty {
            query = query.whereField("collegeName", isEqualTo: filterCollegeName)
        }
        
        // Budget Range filter.
        if !filterBudgetRange.isEmpty {
            query = query.whereField("budgetRange", isEqualTo: filterBudgetRange)
        }
        
        query
            .snapshotPublisher()
            .map { snapshot -> [UserModel] in
                snapshot.documents.compactMap { try? $0.data(as: UserModel.self) }
            }
            .map { users in
                var filtered = users
                
                // Grade Group filter.
                if !self.filterGradeGroup.isEmpty {
                    filtered = filtered.filter { user in
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
                }
                
                // Interests filter.
                if !self.filterInterests.isEmpty {
                    let keywords = self.filterInterests
                        .split(separator: ",")
                        .map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
                    filtered = filtered.filter { user in
                        guard let userInterests = user.interests else { return false }
                        let lowerInterests = userInterests.map { $0.lowercased() }
                        return !Set(keywords).intersection(lowerInterests).isEmpty
                    }
                }
                
                // Room Type filter.
                if !self.filterRoomType.isEmpty {
                    filtered = filtered.filter { user in
                        return user.roomType == self.filterRoomType
                    }
                }
                
                // Amenities filter: only include users who have all selected amenities.
                if !self.filterAmenities.isEmpty {
                    filtered = filtered.filter { user in
                        guard let userAmenities = user.amenities else { return false }
                        return Set(self.filterAmenities).isSubset(of: Set(userAmenities))
                    }
                }
                
                // Pet Friendly filter.
                if let petFriendly = self.filterPetFriendly {
                    filtered = filtered.filter { user in
                        return user.petFriendly == petFriendly
                    }
                }
                
                // Smoker filter.
                if let smoker = self.filterSmoker {
                    filtered = filtered.filter { user in
                        return user.smoker == smoker
                    }
                }
                
                // Drinker filter.
                if let drinker = self.filterDrinker {
                    filtered = filtered.filter { user in
                        if let drinking = user.drinking?.lowercased() {
                            if drinker {
                                // If filtering for drinkers, exclude users who indicate "not for me"
                                return drinking != "not for me"
                            } else {
                                return drinking == "not for me"
                            }
                        }
                        return false
                    }
                }
                
                // Marijuana filter.
                if let marijuana = self.filterMarijuana {
                    filtered = filtered.filter { user in
                        if let cannabis = user.cannabis?.lowercased() {
                            if marijuana {
                                return cannabis != "never"
                            } else {
                                return cannabis == "never"
                            }
                        }
                        return false
                    }
                }
                
                // Workout filter.
                if let workout = self.filterWorkout {
                    filtered = filtered.filter { user in
                        if let userWorkout = user.workout?.lowercased() {
                            if workout {
                                return userWorkout != "never"
                            } else {
                                return userWorkout == "never"
                            }
                        }
                        return false
                    }
                }
                
                // Cleanliness filter.
                if let cleanliness = self.filterCleanliness {
                    filtered = filtered.filter { user in
                        guard let userCleanliness = user.cleanliness else { return false }
                        return userCleanliness == cleanliness
                    }
                }
                
                // Sleep Schedule filter.
                if !self.filterSleepSchedule.isEmpty {
                    filtered = filtered.filter { user in
                        return user.sleepSchedule?.lowercased() == self.filterSleepSchedule.lowercased()
                    }
                }
                
                // Monthly Rent filter – applied only if filtering by lease.
                if self.filterHousingPreference == .lookingForLease,
                   let minRent = self.filterMonthlyRentMin,
                   let maxRent = self.filterMonthlyRentMax {
                    filtered = filtered.filter { user in
                        if let rent = user.monthlyRent {
                            return rent >= minRent && rent <= maxRent
                        }
                        return false
                    }
                }
                
                // Distance filter – only in distance mode.
                if self.filterMode == .distance, let currentLocation = currentLocation {
                    filtered = filtered.filter { user in
                        if let geoPoint = user.location {
                            let userLocation = CLLocation(latitude: geoPoint.latitude, longitude: geoPoint.longitude)
                            let distance = currentLocation.distance(from: userLocation) / 1000.0
                            return distance <= self.maxDistance
                        }
                        return false
                    }
                }
                
                return filtered
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
    
    // MARK: - Save and Load Filters
    
    func saveFiltersToUserDoc() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let docRef = db.collection("users").document(uid)
        
        var data: [String: Any] = [
            "filterHousingPreference": filterHousingPreference?.rawValue ?? "",
            "filterCollegeName": filterCollegeName,
            "filterBudgetRange": filterBudgetRange,
            "filterGradeGroup": filterGradeGroup,
            "filterInterests": filterInterests,
            "filterPreferredGender": filterPreferredGender,
            "maxAgeDifference": maxAgeDifference,
            "filterMode": filterMode.rawValue,
            "filterRoomType": filterRoomType,
            "filterAmenities": filterAmenities,
            "filterPetFriendly": filterPetFriendly as Any,
            "filterSmoker": filterSmoker as Any,
            "filterDrinker": filterDrinker as Any,
            "filterMarijuana": filterMarijuana as Any,
            "filterWorkout": filterWorkout as Any,
            "filterCleanliness": filterCleanliness as Any,
            "filterSleepSchedule": filterSleepSchedule
        ]
        if filterHousingPreference == .lookingForLease {
            data["filterMonthlyRentMin"] = filterMonthlyRentMin ?? FieldValue.delete()
            data["filterMonthlyRentMax"] = filterMonthlyRentMax ?? FieldValue.delete()
        } else {
            data["filterMonthlyRentMin"] = FieldValue.delete()
            data["filterMonthlyRentMax"] = FieldValue.delete()
        }
        
        if filterMode == .distance {
            data["filterMaxDistance"] = maxDistance
        } else {
            data["filterMaxDistance"] = FieldValue.delete()
        }
        
        docRef.setData(data, merge: true) { error in
            if let error = error {
                DispatchQueue.main.async {
                    self.errorMessage = "Failed to save filters: \(error.localizedDescription)"
                }
            } else {
                print("Filters saved successfully.")
            }
        }
    }
    
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
                self.filterHousingPreference = PrimaryHousingPreference(rawValue: data["filterHousingPreference"] as? String ?? "")
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
                self.filterRoomType = data["filterRoomType"] as? String ?? ""
                self.filterAmenities = data["filterAmenities"] as? [String] ?? []
                self.filterPetFriendly = data["filterPetFriendly"] as? Bool
                self.filterSmoker = data["filterSmoker"] as? Bool
                self.filterDrinker = data["filterDrinker"] as? Bool
                self.filterMarijuana = data["filterMarijuana"] as? Bool
                self.filterWorkout = data["filterWorkout"] as? Bool
                self.filterCleanliness = data["filterCleanliness"] as? Int
                self.filterSleepSchedule = data["filterSleepSchedule"] as? String ?? ""
                self.filterMonthlyRentMin = data["filterMonthlyRentMin"] as? Double
                self.filterMonthlyRentMax = data["filterMonthlyRentMax"] as? Double
            }
        }
    }
}
