import Foundation

struct ProfileCompletionCalculator {
    /// Calculates the profile completion percentage for a given UserModel.
    /// - Returns: A value between 0.0 and 100.0 representing the completion percentage.
    static func calculateCompletion(for user: UserModel) -> Double {
        var score: Double = 0.0
        let totalWeight: Double = 100.0
        
        // Weights for each field
        let emailWeight = 10.0
        let gradeWeight = 5.0
        let majorWeight = 5.0
        let collegeWeight = 5.0
        let housingStatusWeight = 5.0
        let leaseDurationWeight = 5.0
        let interestsWeight = 10.0
        let picturesWeight = 10.0
        let aboutMeWeight = 10.0
        
        // Additional "lifestyle" fields
        let cleanlinessWeight = 5.0
        let sleepScheduleWeight = 5.0
        let dormTypeWeight = 5.0
        let leftoverWeight = 20.0 // For any other small fields (gender, smoker, etc.)
        
        // Email
        if !user.email.isEmpty {
            score += emailWeight
        }
        
        // Grade
        if let grade = user.gradeLevel, !grade.isEmpty {
            score += gradeWeight
        }
        
        // Major
        if let major = user.major, !major.isEmpty {
            score += majorWeight
        }
        
        // College
        if let college = user.collegeName, !college.isEmpty {
            score += collegeWeight
        }
        
        // Housing Status
        if let housing = user.housingStatus, !housing.isEmpty {
            score += housingStatusWeight
        }
        
        // Lease Duration
        if let lease = user.leaseDuration, !lease.isEmpty {
            score += leaseDurationWeight
        }
        
        // Interests
        if let interests = user.interests, !interests.isEmpty {
            score += interestsWeight
        }
        
        // Pictures: if at least 1 in profileImageUrls
        if let images = user.profileImageUrls, !images.isEmpty {
            score += picturesWeight
        } else if let singleUrl = user.profileImageUrl, !singleUrl.isEmpty {
            // fallback if only single image used
            score += picturesWeight / 2
        }
        
        // About Me
        if let aboutMe = user.aboutMe, !aboutMe.isEmpty {
            score += aboutMeWeight
        }
        
        // Cleanliness
        if let c = user.cleanliness, c > 0 {
            score += cleanlinessWeight
        }
        
        // Sleep Schedule
        if let sleep = user.sleepSchedule, !sleep.isEmpty {
            score += sleepScheduleWeight
        }
        
        // Dorm Type
        if let dorm = user.dormType, !dorm.isEmpty {
            score += dormTypeWeight
        }
        
        // Some leftover weight for smaller fields: gender, smoker, petFriendly, etc.
        // If user has a few of them set, add partial points.
        var leftoverPoints = 0.0
        if let g = user.gender, !g.isEmpty { leftoverPoints += 5 }
        if let smoker = user.smoker { leftoverPoints += 5 }
        if let pet = user.petFriendly { leftoverPoints += 5 }
        // Cap leftover at leftoverWeight
        leftoverPoints = min(leftoverPoints, leftoverWeight)
        score += leftoverPoints
        
        return min(score, totalWeight)
    }
}
