import Foundation
import FirebaseFirestore

struct ProfileCompletionCalculator {
    /// Calculates profile completion for a UserModel.
    /// The function first assigns points to universal fields (common to every profile)
    /// and then branches based on the user's primary housing preference.
    /// - For “Looking for Lease”, only the budget range field is required in addition.
    /// - For “Looking for Roommate”, additional fields are required for:
    ///   • Roommate counts (needed and existing)
    ///   • Property details: property details text, property address, property media (if any)
    ///   • Lease pricing: lease start date, lease duration, monthly rent and special lease conditions.
    /// The final score is scaled by the maximum available points for that mode.
    static func calculateCompletion(for user: UserModel) -> Double {
        var universalScore: Double = 0.0

        // MARK: Universal Fields (Common to All Profiles)
        // Basic Info
        if !user.email.isEmpty { universalScore += 10 }
        if let first = user.firstName, !first.isEmpty { universalScore += 5 }
        if let last = user.lastName, !last.isEmpty { universalScore += 5 }
        if let dob = user.dateOfBirth, !dob.isEmpty { universalScore += 5 }
        if let gender = user.gender, !gender.isEmpty { universalScore += 5 }
        if let height = user.height, !height.isEmpty { universalScore += 5 }
        // Academic Info
        if let grade = user.gradeLevel, !grade.isEmpty { universalScore += 5 }
        if let major = user.major, !major.isEmpty { universalScore += 5 }
        if let college = user.collegeName, !college.isEmpty { universalScore += 5 }
        // About Me
        if let about = user.aboutMe, !about.isEmpty { universalScore += 10 }
        // Additional universal fields: Cleanliness, Sleep Schedule and Interests
        if let cleanliness = user.cleanliness, cleanliness > 0 { universalScore += 3 }
        if let sleep = user.sleepSchedule, !sleep.isEmpty { universalScore += 3 }
        if let interests = user.interests, !interests.isEmpty { universalScore += 5 }
        // Housing type (desiredLeaseHousingType is set via the picker in housing section)
        if let housingType = user.desiredLeaseHousingType, !housingType.isEmpty { universalScore += 5 }
        // Profile Images: Each image adds 2 points up to a maximum of 10.
        let imagesScore: Double
        if let images = user.profileImageUrls, !images.isEmpty {
            imagesScore = min(Double(images.count) * 2.0, 10.0)
        } else if let single = user.profileImageUrl, !single.isEmpty {
            imagesScore = 2.0
        } else {
            imagesScore = 0.0
        }
        universalScore += imagesScore
        // Quiz Answers: 3 points each for non-empty quiz responses.
        if let goingOut = user.goingOutQuizAnswers, !goingOut.isEmpty { universalScore += 3 }
        if let weekend = user.weekendQuizAnswers, !weekend.isEmpty { universalScore += 3 }
        if let phone = user.phoneQuizAnswers, !phone.isEmpty { universalScore += 3 }
        // Room Type (from picker)
        if let roomType = user.roomType, !roomType.isEmpty { universalScore += 5 }
        // Lifestyle Bonus:
        if ( (user.pets?.isEmpty == false) ||
             (user.drinking?.isEmpty == false) ||
             (user.smoking != nil) ||    // Boolean field: even false counts as set
             (user.cannabis?.isEmpty == false) ||
             (user.workout?.isEmpty == false) ||
             (user.dietaryPreferences?.isEmpty == false) ||
             (user.socialMedia?.isEmpty == false) ||
             (user.sleepingHabits?.isEmpty == false) ) {
            universalScore += 4
        }
        // Universal maximum points sum to 104.
        let universalMax = 104.0

        // MARK: Mode-Specific Fields
        var modeSpecificScore: Double = 0.0
        var modeSpecificMax: Double = 0.0

        // Check housing preference to branch into mode-specific scoring.
        if let housingStatus = user.housingStatus, let preference = PrimaryHousingPreference(rawValue: housingStatus) {
            switch preference {
            case .lookingForLease:
                // For "Looking for Lease", only the Budget Range field matters.
                modeSpecificMax = 5.0
                if let budget = user.budgetRange, !budget.isEmpty {
                    modeSpecificScore += 5.0
                }
            case .lookingForRoommate:
                // For "Looking for Roommate", there are three groups:
                // 1. Roommate counts: Needed (5) and Already (5) = 10 points.
                modeSpecificScore += (user.roommateCountNeeded != nil ? 5.0 : 0.0)
                modeSpecificScore += (user.roommateCountExisting != nil ? 5.0 : 0.0)
                // 2. Property Details Section: propertyDetails (5), propertyAddress (5), property media (5) = 15 points.
                if let details = user.propertyDetails, !details.isEmpty { modeSpecificScore += 5.0 }
                if let address = user.propertyAddress, !address.isEmpty { modeSpecificScore += 5.0 }
                if let propertyImages = user.propertyImageUrls, !propertyImages.isEmpty { modeSpecificScore += 5.0 }
                // 3. Lease Pricing Section: leaseStartDate (5), leaseDuration (5), monthlyRent (5), specialLeaseConditions (3) = 18 points.
                if user.leaseStartDate != nil { modeSpecificScore += 5.0 }
                if let duration = user.leaseDuration, !duration.isEmpty { modeSpecificScore += 5.0 }
                if user.monthlyRent != nil { modeSpecificScore += 5.0 }
                if let conditions = user.specialLeaseConditions, !conditions.isEmpty { modeSpecificScore += 3.0 }
                modeSpecificMax = 10.0 + 15.0 + 18.0  // Total 43 points.
            }
        } else {
            // If no housing preference is set, no mode-specific points are applied.
            modeSpecificMax = 0.0
        }

        // Overall score and maximum.
        let totalScore = universalScore + modeSpecificScore
        let maxScore = universalMax + modeSpecificMax

        let percentage = (totalScore / maxScore) * 100.0
        return min(percentage, 100.0)
    }
}
