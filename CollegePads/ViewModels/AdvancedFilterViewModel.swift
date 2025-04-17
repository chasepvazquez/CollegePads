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
        db.collection("users")
            .snapshotPublisher()
            //  ⇩ here we silently skip any document that fails to decode
            .map { snapshot in
                snapshot.documents.compactMap { doc in
                    try? doc.data(as: UserModel.self)
                }
            }
            .map { [weak self] all in
                guard let self = self else { return [] }
                if self.activeFilterCount == 0 { return all }
                return all.filter { self.matchesAnyFilter(user: $0, location: currentLocation) }
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
        guard let uid = Auth.auth().currentUser?.uid else {
            self.errorMessage = "Not signed in"
            return
        }
        var data: [String: Any] = [
            "filterHousingPreference": filterHousingPreference?.rawValue ?? "",
            "filterCollegeName":       filterCollegeName,
            "filterGradeGroup":        filterGradeGroup,
            "filterInterests":         filterInterests,
            "filterPreferredGender":   filterPreferredGender,
            "maxAgeDifference":        maxAgeDifference,
            "filterMode":              filterMode.rawValue,
            "filterRoomType":          filterRoomType,
            "filterAmenities":         filterAmenities,
            "filterPetFriendly":       filterPetFriendly as Any,
            "filterSmoker":            filterSmoker as Any,
            "filterDrinker":           filterDrinker as Any,
            "filterMarijuana":         filterMarijuana as Any,
            "filterWorkout":           filterWorkout as Any,
            "filterCleanliness":       filterCleanliness as Any,
            "filterSleepSchedule":     filterSleepSchedule
        ]
        if filterHousingPreference == .lookingToFindTogether {
            data["filterBudgetMin"]     = filterBudgetMin as Any
            data["filterBudgetMax"]     = filterBudgetMax as Any
        }
        if filterHousingPreference == .lookingForLease {
            data["filterMonthlyRentMin"] = filterMonthlyRentMin as Any
            data["filterMonthlyRentMax"] = filterMonthlyRentMax as Any
        }
        if filterMode == .distance {
            data["filterMaxDistance"] = maxDistance
        }
        db.collection("users").document(uid)
            .setData(data, merge: true) { [weak self] err in
                if let err = err {
                    DispatchQueue.main.async {
                        self?.errorMessage = "Save failed: \(err.localizedDescription)"
                    }
                }
            }
    }

    // MARK: — Internals

    /// How many filters are currently active?
    private var activeFilterCount: Int {
        [
            filterHousingPreference != nil,
            filterMode == .university && !filterCollegeName.isEmpty,
            filterHousingPreference == .lookingToFindTogether
              && filterBudgetMin != nil && filterBudgetMax != nil,
            !filterGradeGroup.isEmpty,
            !filterInterests.isEmpty,
            !filterRoomType.isEmpty,
            !filterAmenities.isEmpty,
            filterPetFriendly != nil,
            filterSmoker != nil,
            filterDrinker != nil,
            filterMarijuana != nil,
            filterWorkout != nil,
            filterCleanliness != nil,
            !filterSleepSchedule.isEmpty,
            filterHousingPreference == .lookingForLease
              && filterMonthlyRentMin != nil && filterMonthlyRentMax != nil,
            filterMode == .distance
        ].filter { $0 }.count
    }

    /// Returns `true` if the given `user` matches **any** of the active filters.
    private func matchesAnyFilter(user: UserModel, location: CLLocation?) -> Bool {
        // Housing
        if let pref = filterHousingPreference,
           user.housingStatus == pref.rawValue {
            return true
        }
        // By College
        if filterMode == .university,
           !filterCollegeName.isEmpty,
           user.collegeName == filterCollegeName {
            return true
        }
        // Find‑Together Budget
        if filterHousingPreference == .lookingToFindTogether,
           let minB = filterBudgetMin, let maxB = filterBudgetMax,
           let uMin = user.budgetMin, let uMax = user.budgetMax,
           uMin >= minB && uMax <= maxB {
            return true
        }
        // Lease Rent
        if filterHousingPreference == .lookingForLease,
           let minR = filterMonthlyRentMin, let maxR = filterMonthlyRentMax,
           let uMin = user.monthlyRentMin, let uMax = user.monthlyRentMax,
           uMin >= minR && uMax <= maxR {
            return true
        }
        // Grade
        if !filterGradeGroup.isEmpty,
           let grade = user.gradeLevel?.lowercased() {
            let sel = filterGradeGroup.lowercased()
            switch sel {
            case "freshman"      where grade == "freshman": return true
            case "underclassmen" where ["freshman","sophomore"].contains(grade): return true
            case "upperclassmen" where ["junior","senior"].contains(grade): return true
            case "graduate"      where grade == "graduate": return true
            default: break
            }
        }
        // Room type & amenities & toggles
        if !filterRoomType.isEmpty, user.roomType == filterRoomType { return true }
        if !filterAmenities.isEmpty,
           let ua = user.amenities,
           Set(filterAmenities).isSubset(of: Set(ua)) { return true }
        if let pet = filterPetFriendly, user.petFriendly == pet { return true }
        if let smoke = filterSmoker,       user.smoker == smoke { return true }
        if let drink = filterDrinker,
           let d = user.drinking?.lowercased() {
            if drink ? (d != "not for me") : (d == "not for me") {
                return true
            }
        }
        if let mj = filterMarijuana,
           let c = user.cannabis?.lowercased() {
            if mj ? (c != "never") : (c == "never") {
                return true
            }
        }
        if let w = filterWorkout,
           let wv = user.workout?.lowercased() {
            if w ? (wv != "never") : (wv == "never") {
                return true
            }
        }
        if let cl = filterCleanliness, user.cleanliness == cl { return true }
        if !filterSleepSchedule.isEmpty,
           user.sleepSchedule?.lowercased() == filterSleepSchedule.lowercased() {
            return true
        }
        // Distance
        if filterMode == .distance,
           let loc = location,
           let uGeo = user.location {
            let distanceKm = CLLocation(latitude: uGeo.latitude, longitude: uGeo.longitude)
                .distance(from: loc) / 1000.0
            if distanceKm <= maxDistance {
                return true
            }
        }
        return false
    }

    /// Restore filter values from Firestore data dictionary.
    private func restoreFilters(from data: [String: Any]) {
        filterHousingPreference = PrimaryHousingPreference(rawValue: data["filterHousingPreference"] as? String ?? "")
        filterCollegeName       = data["filterCollegeName"]       as? String ?? ""
        filterBudgetMin         = data["filterBudgetMin"]         as? Double
        filterBudgetMax         = data["filterBudgetMax"]         as? Double
        filterGradeGroup        = data["filterGradeGroup"]        as? String ?? ""
        filterInterests         = data["filterInterests"]         as? String ?? ""
        filterPreferredGender   = data["filterPreferredGender"]   as? String ?? ""
        maxAgeDifference        = data["maxAgeDifference"]        as? Double ?? 0
        if let mode = data["filterMode"] as? String {
            filterMode = FilterMode(rawValue: mode) ?? .university
        }
        filterRoomType          = data["filterRoomType"]          as? String ?? ""
        filterAmenities         = data["filterAmenities"]         as? [String] ?? []
        filterPetFriendly       = data["filterPetFriendly"]       as? Bool
        filterSmoker            = data["filterSmoker"]            as? Bool
        filterDrinker           = data["filterDrinker"]           as? Bool
        filterMarijuana         = data["filterMarijuana"]         as? Bool
        filterWorkout           = data["filterWorkout"]           as? Bool
        filterCleanliness       = data["filterCleanliness"]       as? Int
        filterSleepSchedule     = data["filterSleepSchedule"]     as? String ?? ""
        filterMonthlyRentMin    = data["filterMonthlyRentMin"]    as? Double
        filterMonthlyRentMax    = data["filterMonthlyRentMax"]    as? Double
        maxDistance             = data["filterMaxDistance"]       as? Double ?? 10.0
    }
}
