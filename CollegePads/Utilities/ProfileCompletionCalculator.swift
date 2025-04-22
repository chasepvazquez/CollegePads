import Foundation
import FirebaseFirestore

struct ProfileCompletionCalculator {
    /// Calculates profile completion for a UserModel,
    /// with universal fields plus mode‑specific checks on budget/rent sliders.
    static func calculateCompletion(for user: UserModel) -> Double {
        // MARK: Universal Fields
        var score: Double = 0

        // Basic Info
        if !user.email.isEmpty                 { score += 10 }
        if let f = user.firstName, !f.isEmpty  { score += 5 }
        if let l = user.lastName,  !l.isEmpty  { score += 5 }
        if let d = user.dateOfBirth, !d.isEmpty{ score += 5 }
        if let g = user.gender, !g.isEmpty     { score += 5 }
        if let h = user.height, !h.isEmpty     { score += 5 }

        // Academics
        if let gr = user.gradeLevel, !gr.isEmpty   { score += 5 }
        if let mj = user.major, !mj.isEmpty         { score += 5 }
        if let co = user.collegeName, !co.isEmpty   { score += 5 }

        // About Me
        if let about = user.aboutMe, !about.isEmpty { score += 10 }

        // Extras
        if let cl = user.cleanliness, cl > 0        { score += 3 }
        if let ss = user.sleepSchedule, !ss.isEmpty { score += 3 }
        if let intr = user.interests, !intr.isEmpty { score += 5 }

        // Desired housing type
        if let ht = user.desiredLeaseHousingType, !ht.isEmpty { score += 5 }

        // Profile Images (up to 10 pts)
        let imgCount = user.profileImageUrls?.count ?? (user.profileImageUrl != nil ? 1 : 0)
        score += min(Double(imgCount) * 2.0, 10.0)

        // Quizzes (3 pts each)
        if let a = user.goingOutQuizAnswers, !a.isEmpty   { score += 3 }
        if let b = user.weekendQuizAnswers, !b.isEmpty    { score += 3 }
        if let c = user.phoneQuizAnswers, !c.isEmpty      { score += 3 }

        // Room Type (not for Find‑Together)
        if user.housingStatus != PrimaryHousingPreference.lookingToFindTogether.rawValue,
           let rt = user.roomType, !rt.isEmpty {
            score += 5
        }

        // Lifestyle bonus (any one set)
        let hasLifestyle =
            (user.pets?.isEmpty == false) ||
            (user.drinking?.isEmpty == false) ||
            (user.smoking?.isEmpty == false) ||
            (user.cannabis?.isEmpty == false) ||
            (user.workout?.isEmpty == false) ||
            (user.dietaryPreferences?.isEmpty == false) ||
            (user.socialMedia?.isEmpty == false) ||
            (user.sleepingHabits?.isEmpty == false)
        if hasLifestyle { score += 4 }

        let universalMax: Double = 104.0

        // MARK: Mode‑Specific Fields
        var modeScore: Double = 0
        var modeMax: Double = 0

        if let status = user.housingStatus,
           let pref = PrimaryHousingPreference(rawValue: status)
        {
            switch pref {
            case .lookingForLease, .lookingToFindTogether:
                // Only budget slider matters here (5 pts)
                modeMax = 5
                if let min = user.budgetMin,
                   let max = user.budgetMax,
                   max > min {
                    modeScore += 5
                }

            case .lookingForRoommate:
                // 1) Roommate counts (5 + 5)
                modeMax += 10
                if let needed = user.roommateCountNeeded, needed > 0 {
                    modeScore += 5
                }
                if let existing = user.roommateCountExisting, existing > 0 {
                    modeScore += 5
                }

                // 2) Property details (5 + 5 + 5)
                modeMax += 15
                if let details = user.propertyDetails, !details.isEmpty {
                    modeScore += 5
                }
                if let addr = user.propertyAddress, !addr.isEmpty {
                    modeScore += 5
                }
                if let media = user.propertyImageUrls, !media.isEmpty {
                    modeScore += 5
                }

                // 3) Lease pricing (5 + 5 + 5 + 3)
                modeMax += 18
                if user.leaseStartDate != nil {
                    modeScore += 5
                }
                if let dur = user.leaseDuration, !dur.isEmpty {
                    modeScore += 5
                }
                if let rmin = user.monthlyRentMin,
                   let rmax = user.monthlyRentMax,
                   rmax > rmin {
                    modeScore += 5
                }
                if let cond = user.specialLeaseConditions, !cond.isEmpty {
                    modeScore += 3
                }
            }
        }

        // Combine and scale
        let total = score + modeScore
        let maxTotal = universalMax + modeMax
        let pct = (total / maxTotal) * 100
        return min(pct, 100.0)
    }
}
