import Foundation

struct ProfileCompletionCalculator {
    /// Calculates the profile completion percentage for a given UserModel.
    /// The calculation uses weighted points for each field, including:
    /// - Basic Info (email, first/last name, DOB, gender, height)
    /// - Academic Info (grade, major, college)
    /// - Housing Info (dorm, housing status, lease duration, budget)
    /// - Other fields (cleanliness, sleep schedule, about me, interests)
    /// - Lifestyle fields (if any of pets, drinking, smoking, cannabis, workout, dietary preferences, social media, sleeping habits are filled)
    /// - Quiz answers (each non-empty quiz array gives points)
    /// - Profile images (each image adds a small amount, capped at a maximum)
    ///
    /// - Parameter user: The UserModel instance.
    /// - Returns: A value between 0.0 and 100.0 representing the profile completion percentage.
    static func calculateCompletion(for user: UserModel) -> Double {
        var score: Double = 0.0
        
        // Define weights for each group of fields.
        let emailWeight = 10.0
        let firstNameWeight = 5.0
        let lastNameWeight = 5.0
        let dobWeight = 5.0
        let genderWeight = 5.0
        let heightWeight = 5.0
        
        let gradeWeight = 5.0
        let majorWeight = 5.0
        let collegeWeight = 5.0
        
        let dormWeight = 5.0
        let housingStatusWeight = 5.0
        let leaseWeight = 5.0
        let budgetWeight = 5.0
        
        let cleanlinessWeight = 3.0
        let sleepScheduleWeight = 3.0
        let aboutMeWeight = 10.0
        let interestsWeight = 5.0
        
        // Lifestyle fields (if any are set, add a flat weight)
        let lifestyleWeight = 4.0
        
        // Quiz answers – each category contributes if answered.
        let goingOutQuizWeight = 3.0
        let weekendQuizWeight = 3.0
        let phoneQuizWeight = 3.0
        
        // Profile images: each image contributes 2 points up to a maximum of 10.
        let perImageScore = 2.0
        let maxImagesScore = 10.0
        
        // Calculate points for basic info
        if !user.email.isEmpty { score += emailWeight }
        if let first = user.firstName, !first.isEmpty { score += firstNameWeight }
        if let last = user.lastName, !last.isEmpty { score += lastNameWeight }
        if let dob = user.dateOfBirth, !dob.isEmpty { score += dobWeight }
        if let gender = user.gender, !gender.isEmpty { score += genderWeight }
        if let height = user.height, !height.isEmpty { score += heightWeight }
        
        // Academic info
        if let grade = user.gradeLevel, !grade.isEmpty { score += gradeWeight }
        if let major = user.major, !major.isEmpty { score += majorWeight }
        if let college = user.collegeName, !college.isEmpty { score += collegeWeight }
        
        // Housing info
        if let dorm = user.dormType, !dorm.isEmpty { score += dormWeight }
        if let housing = user.housingStatus, !housing.isEmpty { score += housingStatusWeight }
        if let lease = user.leaseDuration, !lease.isEmpty { score += leaseWeight }
        if let budget = user.budgetRange, !budget.isEmpty { score += budgetWeight }
        
        // Other fields
        if let cleanliness = user.cleanliness, cleanliness > 0 { score += cleanlinessWeight }
        if let sleep = user.sleepSchedule, !sleep.isEmpty { score += sleepScheduleWeight }
        if let about = user.aboutMe, !about.isEmpty { score += aboutMeWeight }
        if let interests = user.interests, !interests.isEmpty { score += interestsWeight }
        
        // Lifestyle: if at least one field among these is set, add the weight.
        if (user.pets?.isEmpty == false ||
            (user.drinking?.isEmpty == false) ||
            (user.smoking != nil) ||
            (user.cannabis?.isEmpty == false) ||
            (user.workout?.isEmpty == false) ||
            (user.dietaryPreferences?.isEmpty == false) ||
            (user.socialMedia?.isEmpty == false) ||
            (user.sleepingHabits?.isEmpty == false)) {
            score += lifestyleWeight
        }
        
        // Quiz answers: add weight if each quiz category has answers.
        if let goingOut = user.goingOutQuizAnswers, !goingOut.isEmpty { score += goingOutQuizWeight }
        if let weekend = user.weekendQuizAnswers, !weekend.isEmpty { score += weekendQuizWeight }
        if let phone = user.phoneQuizAnswers, !phone.isEmpty { score += phoneQuizWeight }
        
        // Profile images: add points per image (capped)
        if let images = user.profileImageUrls, !images.isEmpty {
            let imageScore = min(Double(images.count) * perImageScore, maxImagesScore)
            score += imageScore
        } else if let single = user.profileImageUrl, !single.isEmpty {
            score += perImageScore
        }
        
        // Calculate the maximum possible score.
        let maxScore = emailWeight +
            firstNameWeight +
            lastNameWeight +
            dobWeight +
            genderWeight +
            heightWeight +
            gradeWeight +
            majorWeight +
            collegeWeight +
            dormWeight +
            housingStatusWeight +
            leaseWeight +
            budgetWeight +
            cleanlinessWeight +
            sleepScheduleWeight +
            aboutMeWeight +
            interestsWeight +
            lifestyleWeight +
            goingOutQuizWeight +
            weekendQuizWeight +
            phoneQuizWeight +
            maxImagesScore
        
        // Compute percentage and cap at 100%
        let percent = (score / maxScore) * 100.0
        return min(percent, 100.0)
    }
}
