import Foundation
import CoreLocation

struct SmartMatchingEngine {
    
    /// 1) Compatibility + bonus
    static func calculateSmartMatchScore(
        between me: UserModel, and them: UserModel,
        averageRating: Double? = nil
    ) -> Double {
        let base = CompatibilityCalculator.calculateUserCompatibility(between: me, and: them)
        var bonus = 0.0
        if me.isVerified == true && them.isVerified == true { bonus += 10 }
        if me.housingStatus?.lowercased() == them.housingStatus?.lowercased() { bonus += 5 }
        if me.leaseDuration?.lowercased() == them.leaseDuration?.lowercased() { bonus += 5 }
        if let r = averageRating { bonus += r * 2 }
        return min(base + bonus, 100.0)
    }
    
    /// 2) Filter‐based match count
    static func calculateFilterMatchScore(
        filterSettings s: FilterSettings,
        otherUser u: UserModel,
        currentUser me: UserModel
    ) -> Int {
        var score = 0
        
        // 2‑a) housing pairing rules
        guard let mine = s.housingStatus else { return 0 }
        let theirsFS = u.filterSettings
        switch mine {
        case PrimaryHousingPreference.lookingForRoommate.rawValue:
            guard theirsFS?.housingStatus == PrimaryHousingPreference.lookingForLease.rawValue else { return 0 }
            if let rMin = theirsFS?.rentMin, let rMax = theirsFS?.rentMax,
               let wantMin = s.budgetMin, let wantMax = s.budgetMax,
               rMin >= wantMin && rMax <= wantMax { score += 1 }
            
        case PrimaryHousingPreference.lookingForLease.rawValue:
            guard theirsFS?.housingStatus == PrimaryHousingPreference.lookingForRoommate.rawValue else { return 0 }
            if let bMin = theirsFS?.budgetMin, let bMax = theirsFS?.budgetMax,
               let wantMin = s.rentMin, let wantMax = s.rentMax,
               bMin >= wantMin && bMax <= wantMax { score += 1 }
            
        case PrimaryHousingPreference.lookingToFindTogether.rawValue:
            let ok = [ PrimaryHousingPreference.lookingToFindTogether.rawValue,
                       PrimaryHousingPreference.lookingForLease.rawValue ]
            guard ok.contains(theirsFS?.housingStatus ?? "") else { return 0 }
            score += 1
            if let bMin = theirsFS?.budgetMin, let bMax = theirsFS?.budgetMax,
               let wantMin = s.budgetMin, let wantMax = s.budgetMax,
               bMin >= wantMin && bMax <= wantMax { score += 1 }
            
        default: return 0
        }
        
        // 2‑b) college
        if s.collegeName == u.collegeName { score += 1 }
        
        // 2‑c) distance
        if s.mode == FilterMode.distance.rawValue,
           let maxKm = s.maxDistance,
           let myGeo = me.location, let theirGeo = u.location {
            let dist = CLLocation(latitude: theirGeo.latitude,
                                  longitude: theirGeo.longitude)
                .distance(from: CLLocation(latitude: myGeo.latitude,
                                           longitude: myGeo.longitude)) / 1000
            if dist <= maxKm { score += 1 }
        }
        
        // 2‑d) grade
        if let g = s.gradeGroup?.lowercased(),
           let ug = u.gradeLevel?.lowercased() {
            switch g {
            case "freshman"      where ug == "freshman": score += 1
            case "underclassmen" where ["freshman","sophomore"].contains(ug): score += 1
            case "upperclassmen" where ["junior","senior"].contains(ug):        score += 1
            case "graduate"      where ug == "graduate": score += 1
            default: break
            }
        }
        
        // 2‑e) room type
        if s.roomType == u.roomType { score += 1 }
        
        // 2‑f) amenities
        if let want = s.amenities, let have = u.amenities,
           Set(want).isSubset(of: Set(have)) { score += 1 }
        
        // 2‑g) cleanliness & sleep
        if s.cleanliness == u.cleanliness { score += 1 }
        if s.sleepSchedule?.lowercased() == u.sleepSchedule?.lowercased() { score += 1 }
        
        // 2‑h) gender
        if s.preferredGender == u.gender { score += 1 }
        
        // 2‑i) age diff
        if let Δ = s.maxAgeDifference,
           let bd1 = me.dateOfBirth, let bd2 = u.dateOfBirth,
           let d1 = ISO8601DateFormatter().date(from: bd1),
           let d2 = ISO8601DateFormatter().date(from: bd2) {
            let yrs = abs(Calendar.current
                .dateComponents([.year], from: d2, to: d1).year ?? 0)
            if yrs <= Int(Δ) { score += 1 }
        }
        
        // 2‑j) toggles
        
        // Pet friendly & smoker are both Bool?
        if let wantPet = s.petFriendly,
           let hasPet  = u.petFriendly,
           wantPet == hasPet {
            score += 1
        }
        
        if let wantSmoke = s.smoker,
           let isSmoker  = u.smoker,
           wantSmoke == isSmoker {
            score += 1
        }
        
        // Drinker → user.drinking is String?
        if let wantDrink = s.drinker,
           let drinkVal  = u.drinking?.lowercased() {
            // wantDrink==true means user must *not* be "not for me"
            if wantDrink ? (drinkVal != "not for me")
                : (drinkVal == "not for me") {
                score += 1
            }
        }
        
        // Marijuana → user.cannabis is String?
        if let wantMj     = s.marijuana,
           let cannabisVal = u.cannabis?.lowercased() {
            if wantMj ? (cannabisVal != "never")
                : (cannabisVal == "never") {
                score += 1
            }
        }
        
        // Workout → user.workout is String?
        if let wantWorkout = s.workout,
           let workoutVal  = u.workout?.lowercased() {
            if wantWorkout ? (workoutVal != "never")
                : (workoutVal == "never") {
                score += 1
            }
        }
        
        // 2‑k) interests (comma‑split vs array intersection)
        if let wants = s.interests?
            .split(separator: ",")
            .map({ $0.trimmingCharacters(in: .whitespaces) }),
           let haves = u.interests,
           !Set(wants).isDisjoint(with: Set(haves)) {
            score += 1
        }
        
        return score
    }
    
    /// 3) churn out only those > 0, sorted by descending score
    static func generateSortedMatches(
      from all: [UserModel],
      currentUser me: UserModel
    ) -> [UserModel] {
      // delegate to the overload
      guard let fs = me.filterSettings else { return [] }
      return generateSortedMatches(from: all, currentUser: me, using: fs)
    }
}
// New overload that takes a pre‑built FilterSettings
extension SmartMatchingEngine {
  static func generateSortedMatches(
    from all: [UserModel],
    currentUser me: UserModel,
    using fs: FilterSettings
  ) -> [UserModel] {
    let blocked = Set(me.blockedUserIDs ?? [])
    return all
      .filter { $0.id != me.id && !blocked.contains($0.id ?? "") }
      .map    { ($0, calculateFilterMatchScore(filterSettings: fs, otherUser: $0, currentUser: me)) }
      .filter { $0.1 > 0 }
      .sorted { $0.1 > $1.1 }
      .map    { $0.0 }
  }
}
