#if DEBUG
import SwiftUI
import Combine
import FirebaseFirestore
import FirebaseFirestoreCombineSwift
import CoreLocation

/// Holds per‐user debug info
struct DebugMatchExplanation: Identifiable {
    let id: String
    let user: UserModel
    let position: Int?                // nil if excluded
    let filterScore: Int
    let smartScore: Double
    let criteria: [String: Bool]      // e.g. ["HousingPairing": true, "College": false, …]
}

/// ViewModel to drive the inspector
@MainActor
class DebugInspectorViewModel: ObservableObject {
    @Published var explanations: [DebugMatchExplanation] = []
    private var cancellables = Set<AnyCancellable>()
    private let fs: FilterSettings
    private let me: UserModel
    private let db = Firestore.firestore()

    init(filterSettings: FilterSettings, currentUser: UserModel) {
        self.fs = filterSettings
        self.me = currentUser
        subscribe()
    }

    private func subscribe() {
        // Listen for ALL users
        db.collection("users")
          .snapshotPublisher()
          .map { snap in
            snap.documents.compactMap { try? $0.data(as: UserModel.self) }
          }
          .receive(on: DispatchQueue.global(qos: .userInitiated))
          .map { [weak self] allUsers -> [DebugMatchExplanation] in
            guard let self = self else { return [] }

            // 1) compute raw filter scores & smart scores
            let scored = allUsers.map { user -> (UserModel, Int, Double, [String:Bool]) in
              let filterScore = SmartMatchingEngine.calculateFilterMatchScore(
                filterSettings: self.fs,
                otherUser: user,
                currentUser: self.me
              )
              let smartScore = SmartMatchingEngine.calculateSmartMatchScore(
                between: self.me, and: user
              )
              // breakdown by criterion
              var crit: [String:Bool] = [:]
              crit["HousingPairing"] = {
                guard let mine = self.fs.housingStatus else { return false }
                switch mine {
                case PrimaryHousingPreference.lookingForRoommate.rawValue:
                  return user.filterSettings?.housingStatus == PrimaryHousingPreference.lookingForLease.rawValue
                case PrimaryHousingPreference.lookingForLease.rawValue:
                  return user.filterSettings?.housingStatus == PrimaryHousingPreference.lookingForRoommate.rawValue
                case PrimaryHousingPreference.lookingToFindTogether.rawValue:
                  return [ PrimaryHousingPreference.lookingToFindTogether.rawValue,
                           PrimaryHousingPreference.lookingForLease.rawValue
                         ].contains(user.filterSettings?.housingStatus ?? "")
                default: return false
                }
              }()
              crit["CollegeMatch"] = (self.fs.collegeName?.lowercased() ==
                                     user.collegeName?.lowercased())
              if self.fs.mode == FilterMode.distance.rawValue,
                 let maxKm = self.fs.maxDistance,
                 let myLoc = self.me.location,
                 let theirLoc = user.location {
                let dist = CLLocation(latitude: theirLoc.latitude, longitude: theirLoc.longitude)
                  .distance(from: CLLocation(latitude: myLoc.latitude, longitude: myLoc.longitude)) / 1000
                crit["Distance"] = (dist <= maxKm)
              } else {
                crit["Distance"] = true
              }
              crit["Grade"] = (self.fs.gradeGroup?.lowercased() == user.gradeLevel?.lowercased())
              crit["RoomType"] = (self.fs.roomType == user.roomType)
              crit["Amenities"] = Set(self.fs.amenities ?? []).isSubset(of: Set(user.amenities ?? []))
              crit["Cleanliness"] = (self.fs.cleanliness == user.cleanliness)
              crit["Sleep"] = (self.fs.sleepSchedule?.lowercased() == user.sleepSchedule?.lowercased())
              crit["Gender"] = (self.fs.preferredGender == user.gender)
              if let Δ = self.fs.maxAgeDifference,
                 let bd1 = self.me.dateOfBirth, let bd2 = user.dateOfBirth,
                 let d1 = ISO8601DateFormatter().date(from: bd1),
                 let d2 = ISO8601DateFormatter().date(from: bd2) {
                let yrs = abs(Calendar.current.dateComponents([.year], from: d2, to: d1).year ?? 0)
                crit["AgeDiff"] = (yrs <= Int(Δ))
              } else {
                crit["AgeDiff"] = true
              }
              crit["PetFriendly"] = (self.fs.petFriendly == user.petFriendly)
              crit["Smoker"] = (self.fs.smoker == user.smoker)
              crit["Drinker"] = {
                guard let want = self.fs.drinker, let drink = user.drinking?.lowercased()
                else { return true }
                return want ? (drink != "not for me") : (drink == "not for me")
              }()
              crit["Marijuana"] = {
                guard let want = self.fs.marijuana, let val = user.cannabis?.lowercased()
                else { return true }
                return want ? (val != "never") : (val == "never")
              }()
              crit["Workout"] = {
                guard let want = self.fs.workout, let val = user.workout?.lowercased()
                else { return true }
                return want ? (val != "never") : (val == "never")
              }()
              crit["Interests"] = {
                guard let wants = self.fs.interests?
                        .split(separator: ",").map({ $0.trimmingCharacters(in: .whitespaces) }),
                      let have = user.interests else { return true }
                return !Set(wants).isDisjoint(with: Set(have))
              }()
              return (user, filterScore, smartScore, crit)
            }

            // 2) sort by filterScore desc, then smartScore
            let sorted = scored
              .sorted {
                if $0.1 != $1.1 { return $0.1 > $1.1 }
                return $0.2 > $1.2
              }
            
            // 3) build explanations with positions
            return sorted.enumerated().map { idx, tuple in
              let (user, fScore, sScore, crit) = tuple
              return DebugMatchExplanation(
                id: user.id ?? UUID().uuidString,
                user: user,
                position: fScore > 0 ? idx + 1 : nil,
                filterScore: fScore,
                smartScore: sScore,
                criteria: crit
              )
            }
          }
          .receive(on: DispatchQueue.main)
          .replaceError(with: [])
          .assign(to: \.explanations, on: self)
          .store(in: &cancellables)
    }
}

/// The actual inspector view
struct DebugMatchInspectorView: View {
    @ObservedObject var vm: DebugInspectorViewModel

    var body: some View {
        NavigationView {
            List {
                ForEach(vm.explanations) { e in
                    Section(header: Text(e.user.firstName ?? e.user.id ?? "User"))
                    {
                        HStack { Text("Position:"); Spacer()
                                 Text(e.position.map(String.init) ?? "excluded") }
                        HStack { Text("FilterScore:"); Spacer()
                                 Text("\(e.filterScore)") }
                        HStack { Text("SmartScore:"); Spacer()
                                 Text("\(Int(e.smartScore))") }
                        ForEach(e.criteria.sorted(by: { $0.key < $1.key }), id: \.key) { k,v in
                            HStack {
                                Text(k.replacingOccurrences(of: "_", with: " "))
                                Spacer()
                                Text(v ? "✅" : "❌")
                            }
                        }
                    }
                }
            }
            .navigationTitle("Match Inspector")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { /* dismiss */ }
                }
            }
        }
    }
}
#endif
