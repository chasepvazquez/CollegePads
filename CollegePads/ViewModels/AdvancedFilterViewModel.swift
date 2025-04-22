import SwiftUI
import Combine
import CoreLocation
import FirebaseAuth
import FirebaseFirestore
import FirebaseFirestoreCombineSwift

enum FilterMode: String, CaseIterable, Identifiable {
    case university, distance
    var id: String { rawValue }
}

class AdvancedFilterViewModel: ObservableObject {
    // MARK: — Published Filter Inputs
    @Published var filterHousingPreference: PrimaryHousingPreference? = nil
    @Published var filterCollegeName: String = ""
    @Published var filterBudgetMin: Double? = nil
    @Published var filterBudgetMax: Double? = nil
    @Published var filterGradeGroup: String = ""
    @Published var filterInterests: String = ""
    @Published var filterRoomType: String = ""
    @Published var filterAmenities: [String] = []
    @Published var filterPetFriendly: Bool? = nil
    @Published var filterSmoker: Bool? = nil
    @Published var filterDrinker: Bool? = nil
    @Published var filterMarijuana: Bool? = nil
    @Published var filterWorkout: Bool? = nil
    @Published var filterCleanliness: Int? = nil
    @Published var filterSleepSchedule: String = ""
    @Published var filterMonthlyRentMin: Double? = nil
    @Published var filterMonthlyRentMax: Double? = nil
    @Published var maxDistance: Double = 10.0
    @Published var filterPreferredGender: String = ""
    @Published var maxAgeDifference: Double = 0.0
    @Published var filterMode: FilterMode = .university
    
    // MARK: — Published Results & Errors
    @Published var filteredUsers: [UserModel] = []
    @Published var errorMessage: String?
    
    // MARK: — Static Options (used by AdvancedFilterView)
    let propertyAmenitiesOptions = [
        "In-Unit Laundry", "On-Site Laundry", "Air Conditioning", "Heating",
        "Furnished", "Unfurnished", "High-Speed Internet", "Utilities Included",
        "Pet Friendly", "Parking Available", "Garage Parking", "Balcony / Patio",
        "Private Bathroom", "Shared Bathroom", "Gym / Fitness Center", "Common Area / Lounge",
        "Pool Access", "Rooftop Access", "Bike Storage", "Dishwasher", "Microwave",
        "Elevator Access", "Wheelchair Accessible", "24/7 Security", "Gated Community",
        "Study Rooms", "Game Room", "Smoke-Free", "Quiet Hours Enforced"
    ]
    let cleanlinessDescriptions = [
        1: "Very Messy", 2: "Messy", 3: "Average", 4: "Tidy", 5: "Very Tidy"
    ]
    
    private let db = Firestore.firestore()
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: — Public API
    /// Fetches *all* users, applies the active filters locally,
        /// and publishes the result (or sets `errorMessage` on failure).
        func applyFilters(currentLocation: CLLocation?) {
            // 1) grab the current user
            guard let me = ProfileViewModel.shared.userProfile else {
                self.errorMessage = "No current profile"
                return
            }
            
            // 2) assemble FilterSettings from all your @Published props
            let fs = FilterSettings(
                dormType:          nil,
                housingStatus:     filterHousingPreference?.rawValue,
                collegeName:       filterCollegeName.isEmpty ? nil : filterCollegeName,
                budgetMin:         (filterHousingPreference == .lookingToFindTogether ||
                                    filterHousingPreference == .lookingForLease)
                                        ? filterBudgetMin
                                        : nil,
                budgetMax:         (filterHousingPreference == .lookingToFindTogether ||
                                    filterHousingPreference == .lookingForLease)
                                        ? filterBudgetMax
                                        : nil,
                rentMin:           filterHousingPreference == .lookingForRoommate
                                        ? filterMonthlyRentMin
                                        : nil,
                rentMax:           filterHousingPreference == .lookingForRoommate
                                        ? filterMonthlyRentMax
                                        : nil,
                gradeGroup:        filterGradeGroup.isEmpty ? nil : filterGradeGroup,
                interests:         filterInterests.isEmpty   ? nil : filterInterests,
                maxDistance:       filterMode == .distance   ? maxDistance : nil,
                preferredGender:   filterPreferredGender.isEmpty
                                        ? nil : filterPreferredGender,
                maxAgeDifference:  maxAgeDifference,
                roomType:          filterRoomType.isEmpty ? nil : filterRoomType,
                amenities:         filterAmenities.isEmpty ? nil : filterAmenities,
                cleanliness:       filterCleanliness,
                sleepSchedule:     filterSleepSchedule.isEmpty
                                        ? nil : filterSleepSchedule,
                petFriendly:       filterPetFriendly,
                smoker:            filterSmoker,
                drinker:           filterDrinker,
                marijuana:         filterMarijuana,
                workout:           filterWorkout,
                mode:              filterMode.rawValue
            )
            
            // 3) fetch & score
            db.collection("users")
                .snapshotPublisher()
                .map { snapshot in
                    snapshot.documents.compactMap { try? $0.data(as: UserModel.self) }
                }
                .map { allUsers in
                    SmartMatchingEngine.generateSortedMatches(
                        from: allUsers,
                        currentUser: me,
                        using: fs
                    )
                }
                .receive(on: DispatchQueue.main)
                .sink(
                    receiveCompletion: { [weak self] completion in
                        if case let .failure(err) = completion {
                            self?.errorMessage = err.localizedDescription
                        }
                    },
                    receiveValue: { [weak self] users in
                        self?.filteredUsers = users
                    }
                )
                .store(in: &cancellables)
        }
        
    
    
    /// Loads saved filters from Firestore into this view model.
    /// Calls the optional completion on the main thread when done (or on error).
    func loadFiltersFromUserDoc(completion: @escaping () -> Void = {}) {
        guard let uid = Auth.auth().currentUser?.uid else {
            self.errorMessage = "Not signed in"
            completion()
            return
        }
        db.collection("users").document(uid)
            .getDocument { [weak self] snap, err in
                DispatchQueue.main.async {
                    defer { completion() }
                    if let err = err {
                        self?.errorMessage = "Load failed: \(err.localizedDescription)"
                        return
                    }
                    guard let data = snap?.data() else { return }
                    self?.restoreFilters(from: data)
                }
            }
    }
    
    /// Persists the current filters back to Firestore under the user's document.
    func saveFiltersToUserDoc() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        // Build a single FilterSettings struct, applying your mode‑specific logic
        let fs = FilterSettings(
            dormType:       nil,
            housingStatus:  filterHousingPreference?.rawValue,
            collegeName:    filterCollegeName.isEmpty ? nil : filterCollegeName,
            
            // only supply budgetMin/budgetMax if in FTogether or Lease modes
            budgetMin:      (filterHousingPreference == .lookingToFindTogether ||
                             filterHousingPreference == .lookingForLease)
            ? filterBudgetMin : nil,
            budgetMax:      (filterHousingPreference == .lookingToFindTogether ||
                             filterHousingPreference == .lookingForLease)
            ? filterBudgetMax : nil,
            
            // only supply rentMin/rentMax if in Roommate mode
            rentMin:        filterHousingPreference == .lookingForRoommate
            ? filterMonthlyRentMin : nil,
            rentMax:        filterHousingPreference == .lookingForRoommate
            ? filterMonthlyRentMax : nil,
            
            gradeGroup:     filterGradeGroup.isEmpty ? nil : filterGradeGroup,
            interests:      filterInterests.isEmpty   ? nil : filterInterests,
            maxDistance:    filterMode == .distance   ? maxDistance : nil,
            preferredGender: filterPreferredGender.isEmpty ? nil : filterPreferredGender,
            maxAgeDifference: maxAgeDifference,
            
            // the rest of your flags
            roomType:       filterRoomType.isEmpty ? nil : filterRoomType,
            amenities:      filterAmenities.isEmpty ? nil : filterAmenities,
            cleanliness:    filterCleanliness,
            sleepSchedule:  filterSleepSchedule.isEmpty ? nil : filterSleepSchedule,
            petFriendly:    filterPetFriendly,
            smoker:         filterSmoker,
            drinker:        filterDrinker,
            marijuana:      filterMarijuana,
            workout:        filterWorkout,
            
            mode:           filterMode.rawValue
        )
        
        // Encode & write just that one field
        do {
                    let fsData = try Firestore.Encoder().encode(fs)
                    // ✅ merge ensures your filterSettings is replaced, not partially updated
                    db.collection("users").document(uid)
                      .setData(["filterSettings": fsData], merge: true) { err in
                        if let err = err {
                          self.errorMessage = "Save filters failed: \(err)"
                        }
                      }
                } catch {
                    self.errorMessage = "Save filters failed: \(error)"
                }
            }
    
    /// Restore filter values from Firestore data dictionary.
    private func restoreFilters(from data: [String:Any]) {
        if let fsDict = data["filterSettings"] as? [String:Any],
           let fs = try? Firestore.Decoder().decode(FilterSettings.self, from: fsDict) {
            filterHousingPreference = fs.housingStatus.flatMap(PrimaryHousingPreference.init)
            filterCollegeName       = fs.collegeName ?? ""
            filterBudgetMin         = fs.budgetMin
            filterBudgetMax         = fs.budgetMax
            filterMonthlyRentMin    = fs.rentMin
            filterMonthlyRentMax    = fs.rentMax
            filterGradeGroup        = fs.gradeGroup ?? ""
            filterInterests         = fs.interests ?? ""
            filterMode              = fs.mode.flatMap(FilterMode.init) ?? .university
            maxDistance             = fs.maxDistance ?? maxDistance
            filterPreferredGender   = fs.preferredGender ?? ""
            maxAgeDifference        = fs.maxAgeDifference ?? 0.0
            filterRoomType          = fs.roomType ?? ""
            filterAmenities         = fs.amenities ?? []
            filterCleanliness       = fs.cleanliness
            filterSleepSchedule     = fs.sleepSchedule ?? ""
            filterPetFriendly       = fs.petFriendly
            filterSmoker            = fs.smoker
            filterDrinker           = fs.drinker
            filterMarijuana         = fs.marijuana
            filterWorkout           = fs.workout
            return
        }
    }
}
