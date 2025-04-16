import SwiftUI
import FirebaseFirestore
import FirebaseFirestoreCombineSwift
import Combine
import CoreLocation
import FirebaseAuth

enum FilterMode: String, CaseIterable, Identifiable {
    case university, distance
    var id: String { rawValue }
}

class AdvancedFilterViewModel: ObservableObject {
    // MARK: - Filters
    @Published var filterHousingPreference: PrimaryHousingPreference? = nil
    @Published var filterCollegeName: String = ""
    
    // ↓ NEW numeric budget sliders for “Find Together”
    @Published var filterBudgetMin: Double? = nil
    @Published var filterBudgetMax: Double? = nil

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
        // 1) Fetch *all* users
        db.collection("users")
        .snapshotPublisher()
        .map { $0.documents.compactMap { try? $0.data(as: UserModel.self) } }
        .map { users in
              // Determine which filters are “active”
              let hasHousing     = self.filterHousingPreference != nil
              let hasCollege     = self.filterMode == .university && !self.filterCollegeName.isEmpty
              let hasFindBudget = (self.filterHousingPreference == .lookingToFindTogether)
                                                 && self.filterBudgetMin != nil
                                                 && self.filterBudgetMax != nil
              let hasGrade       = !self.filterGradeGroup.isEmpty
              let hasInterests   = !self.filterInterests.isEmpty
              let hasRoomType    = !self.filterRoomType.isEmpty
              let hasAmenities   = !self.filterAmenities.isEmpty
              let hasPetFilter   = self.filterPetFriendly != nil
              let hasSmokerFilter = self.filterSmoker != nil
              let hasDrinker     = self.filterDrinker != nil
              let hasMJ          = self.filterMarijuana != nil
              let hasWorkout     = self.filterWorkout != nil
              let hasCleanliness = self.filterCleanliness != nil
              let hasSleepSched  = !self.filterSleepSchedule.isEmpty
              let hasLeaseRent   = (self.filterHousingPreference == .lookingForLease)
                                   && self.filterMonthlyRentMin != nil
                                   && self.filterMonthlyRentMax != nil
              let hasDistance    = self.filterMode == .distance && currentLocation != nil

              let totalActive = [
                  hasHousing, hasCollege, hasFindBudget, hasGrade, hasInterests,
                  hasRoomType, hasAmenities, hasPetFilter, hasSmokerFilter,
                  hasDrinker, hasMJ, hasWorkout, hasCleanliness, hasSleepSched,
                  hasLeaseRent, hasDistance
              ].filter { $0 }.count

              // If *no* filters are set, just show everyone:
              guard totalActive > 0 else { return users }

              // 2) Keep any user matching *at least one* active filter:
              return users.filter { user in
                  var matched = false

                  if hasHousing,
                     user.housingStatus == self.filterHousingPreference?.rawValue {
                      matched = true
                  }
                  if hasCollege,
                     user.collegeName == self.filterCollegeName {
                      matched = true
                  }
                  if hasFindBudget,
                                      let rent = user.monthlyRent,
                                      let minB = self.filterBudgetMin,
                                      let maxB = self.filterBudgetMax,
                     rent >= minB && rent <= maxB {
                      matched = true
                  }
                  if hasGrade {
                      let grade = user.gradeLevel?.lowercased() ?? ""
                      let sel   = self.filterGradeGroup.lowercased()
                      switch sel {
                      case "freshman":
                          matched = matched || grade == "freshman"
                      case "underclassmen":
                          matched = matched || (grade == "freshman" || grade == "sophomore")
                      case "upperclassmen":
                          matched = matched || (grade == "junior"  || grade == "senior")
                      case "graduate":
                          matched = matched || grade == "graduate"
                      default: break
                      }
                  }
                  if hasInterests,
                     let ui = user.interests?.map({ $0.lowercased() }) {
                      let keys = self.filterInterests
                                    .split(separator: ",")
                                    .map { $0.trimmingCharacters(in: .whitespaces).lowercased() }
                      if !Set(keys).intersection(ui).isEmpty {
                          matched = true
                      }
                  }
                  if hasRoomType,
                     user.roomType == self.filterRoomType {
                      matched = true
                  }
                  if hasAmenities,
                     let ua = user.amenities,
                     Set(self.filterAmenities).isSubset(of: Set(ua)) {
                      matched = true
                  }
                  if hasPetFilter,
                     user.petFriendly == self.filterPetFriendly {
                      matched = true
                  }
                  if hasSmokerFilter,
                     user.smoker == self.filterSmoker {
                      matched = true
                  }
                  if hasDrinker,
                     let d = user.drinking?.lowercased() {
                      if self.filterDrinker! {
                          matched = matched || (d != "not for me")
                      } else {
                          matched = matched || (d == "not for me")
                      }
                  }
                  if hasMJ,
                     let c = user.cannabis?.lowercased() {
                      if self.filterMarijuana! {
                          matched = matched || (c != "never")
                      } else {
                          matched = matched || (c == "never")
                      }
                  }
                  if hasWorkout,
                     let w = user.workout?.lowercased() {
                      if self.filterWorkout! {
                          matched = matched || (w != "never")
                      } else {
                          matched = matched || (w == "never")
                      }
                  }
                  if hasCleanliness,
                     let cl = user.cleanliness,
                     cl == self.filterCleanliness {
                      matched = true
                  }
                  if hasSleepSched,
                     user.sleepSchedule?.lowercased() == self.filterSleepSchedule.lowercased() {
                      matched = true
                  }
                  if hasLeaseRent,
                     let rent = user.monthlyRent,
                     let minR = self.filterMonthlyRentMin,
                     let maxR = self.filterMonthlyRentMax,
                     rent >= minR && rent <= maxR {
                      matched = true
                  }
                  if hasDistance,
                     let cp = user.location,
                     let loc = currentLocation {
                      let uloc = CLLocation(latitude: cp.latitude, longitude: cp.longitude)
                      let km = loc.distance(from: uloc) / 1000.0
                      if km <= self.maxDistance {
                          matched = true
                      }
                  }

                  return matched
              }
          }
          .sink(
            receiveCompletion: { completion in
              if case let .failure(err) = completion {
                DispatchQueue.main.async { self.errorMessage = err.localizedDescription }
              }
            },
            receiveValue: { users in
              DispatchQueue.main.async { self.filteredUsers = users }
            }
          )
          .store(in: &cancellables)
    }

    
    // MARK: - Save and Load Filters
    
    func saveFiltersToUserDoc() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let docRef = db.collection("users").document(uid)
        
        var data: [String: Any] = [
            "filterHousingPreference": filterHousingPreference?.rawValue ?? "",
            "filterCollegeName": filterCollegeName,
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
        if filterHousingPreference == .lookingToFindTogether {
                    data["filterBudgetMin"] = filterBudgetMin ?? FieldValue.delete()
                    data["filterBudgetMax"] = filterBudgetMax ?? FieldValue.delete()
                } else {
                    data["filterBudgetMin"] = FieldValue.delete()
                    data["filterBudgetMax"] = FieldValue.delete()
                }
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
                self.filterBudgetMin     = data["filterBudgetMin"] as? Double
                self.filterBudgetMax     = data["filterBudgetMax"] as? Double
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
