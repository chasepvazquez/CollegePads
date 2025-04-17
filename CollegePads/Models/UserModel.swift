import Foundation
import FirebaseFirestore
import FirebaseFirestoreCombineSwift

struct FilterSettings: Codable {
    var dormType: String?
    var housingStatus: String?
    var collegeName: String?
    var budgetMin: Double?      // ← new
    var budgetMax: Double?      // ← new
    var gradeGroup: String?
    var interests: String?
    var maxDistance: Double?
    var preferredGender: String?
    var maxAgeDifference: Double?
    var mode: String?   // "university" or "distance"
}

struct UserModel: Codable, Identifiable {
    @DocumentID var id: String?
    
    // 1. Basic Info
    var email: String
    var createdAt: Date?           // optional creation date
    var isEmailVerified: Bool
    
    // 2. Personal Info
    var aboutMe: String?
    var firstName: String?
    var lastName: String?
    var dateOfBirth: String?
    var gender: String?            // "Male", "Female", or "Other"
    var height: String?            // e.g., "5'9"
    
    // 3. Academic Info
    var gradeLevel: String?
    var major: String?
    var collegeName: String?       // Selected via search
    
    // 4. Housing & Lease Info (for housing selection)
    var housingStatus: String?
    var dormType: String?          // restored dormType field
    var preferredDorm: String?     // restored preferredDorm field
    var desiredLeaseHousingType: String?
    var roommateCountNeeded: Int?
    var roommateCountExisting: Int?
    
    // 5. Property Details
    var propertyDetails: String?
    var propertyAddress: String?   // NEW: property address entered by the user
    var propertyImageUrls: [String]?
    var floorplanUrls: [String]?
    var documentUrls: [String]?
    
    // 6. Room Type Selector (available for both views)
    var roomType: String?
    
    // 7. Lease & Pricing Details (displayed only for Looking for Roommate view)
    var leaseStartDate: Date?
    var leaseDuration: String?     // reused for lease duration details
    var monthlyRentMin: Double? // ← new
    var monthlyRentMax: Double? // ← new
    var specialLeaseConditions: [String]?
    
    // 8. Amenities Multi-Select Field
    var amenities: [String]?
    
    // 9. Additional Housing Fields
    var budgetMin: Double?      // ← new
    var budgetMax: Double?
    var cleanliness: Int?
    var sleepSchedule: String?
    var smoker: Bool?
    var petFriendly: Bool?
    var livingStyle: String?
    
    // 10. Interests
    var socialLevel: Int?
    var studyHabits: Int?
    var interests: [String]?
    
    // 11. Media & Location
    var profileImageUrl: String?      // legacy single image
    var profileImageUrls: [String]?   // array for multiple images
    var location: GeoPoint?
    
    // 12. Verification
    var isVerified: Bool?
    
    // 13. Blocked Users
    var blockedUserIDs: [String]?
    
    // 14. Advanced Filter Settings
    var filterSettings: FilterSettings?
    
    // 15. Lifestyle Fields (matching Tinder’s categories)
    var pets: [String]?
    var drinking: String?
    var smoking: String?
    var cannabis: String?
    var workout: String?
    var dietaryPreferences: [String]?
    var socialMedia: String?
    var sleepingHabits: String?
    
    // 16. Quiz Answers
    var goingOutQuizAnswers: [String]?
    var weekendQuizAnswers: [String]?
    var phoneQuizAnswers: [String]?   // "+ My Phone" quiz answers
    
    init(
        email: String,
        isEmailVerified: Bool,
        createdAt: Date? = nil,
        // 2. Personal Info
        aboutMe: String? = nil,
        firstName: String? = nil,
        lastName: String? = nil,
        dateOfBirth: String? = nil,
        gender: String? = nil,
        height: String? = nil,
        // 3. Academic Info
        gradeLevel: String? = nil,
        major: String? = nil,
        collegeName: String? = nil,
        // 4. Housing & Lease Info
        housingStatus: String? = nil,
        dormType: String? = nil,
        preferredDorm: String? = nil,
        desiredLeaseHousingType: String? = nil,
        roommateCountNeeded: Int? = nil,
        roommateCountExisting: Int? = nil,
        // 5. Property Details
        propertyDetails: String? = nil,
        propertyAddress: String? = nil,   // NEW: address parameter
        propertyImageUrls: [String]? = nil,
        floorplanUrls: [String]? = nil,
        documentUrls: [String]? = nil,
        // 6. Room Type Selector
        roomType: String? = nil,
        // 7. Lease & Pricing Details
        leaseStartDate: Date? = nil,
        leaseDuration: String? = nil,
        monthlyRentMin: Double? = nil,
        monthlyRentMax: Double? = nil,
        specialLeaseConditions: [String]? = nil,
        // 8. Amenities Multi-Select Field
        amenities: [String]? = nil,
        // 9. Additional Housing Fields
        budgetMin: Double? = nil,
        budgetMax: Double? = nil,
        cleanliness: Int? = nil,
        sleepSchedule: String? = nil,
        smoker: Bool? = nil,
        petFriendly: Bool? = nil,
        livingStyle: String? = nil,
        // 10. Interests
        socialLevel: Int? = nil,
        studyHabits: Int? = nil,
        interests: [String]? = nil,
        // 11. Media & Location
        profileImageUrl: String? = nil,
        profileImageUrls: [String]? = nil,
        location: GeoPoint? = nil,
        // 12. Verification
        isVerified: Bool? = false,
        // 13. Blocked Users
        blockedUserIDs: [String]? = nil,
        // 14. Advanced Filter Settings
        filterSettings: FilterSettings? = nil,
        // 15. Lifestyle Fields
        pets: [String]? = nil,
        drinking: String? = nil,
        smoking: String? = nil,
        cannabis: String? = nil,
        workout: String? = nil,
        dietaryPreferences: [String]? = nil,
        socialMedia: String? = nil,
        sleepingHabits: String? = nil,
        // 16. Quiz Answers
        goingOutQuizAnswers: [String]? = nil,
        weekendQuizAnswers: [String]? = nil,
        phoneQuizAnswers: [String]? = nil
    ) {
        self.email = email
        self.isEmailVerified = isEmailVerified
        self.createdAt = createdAt ?? Date()
        
        // Personal Info
        self.aboutMe = aboutMe
        self.firstName = firstName
        self.lastName = lastName
        self.dateOfBirth = dateOfBirth
        self.gender = gender
        self.height = height
        
        // Academic Info
        self.gradeLevel = gradeLevel
        self.major = major
        self.collegeName = collegeName
        
        // Housing & Lease Info
        self.housingStatus = housingStatus
        self.dormType = dormType
        self.preferredDorm = preferredDorm
        self.desiredLeaseHousingType = desiredLeaseHousingType
        self.roommateCountNeeded = roommateCountNeeded
        self.roommateCountExisting = roommateCountExisting
        
        // Property Details
        self.propertyDetails = propertyDetails
        self.propertyAddress = propertyAddress   // NEW: assign address
        self.propertyImageUrls = propertyImageUrls
        self.floorplanUrls = floorplanUrls
        self.documentUrls = documentUrls
        
        // Room Type Selector
        self.roomType = roomType
        
        // Lease & Pricing Details
        self.leaseStartDate = leaseStartDate
        self.leaseDuration = leaseDuration
        self.monthlyRentMin =  monthlyRentMin
        self.monthlyRentMax = monthlyRentMax
        self.specialLeaseConditions = specialLeaseConditions
        
        // Amenities Multi-Select Field
        self.amenities = amenities
        
        // Additional Housing Fields
        self.budgetMin = budgetMin
        self.budgetMax = budgetMax
        self.cleanliness = cleanliness
        self.sleepSchedule = sleepSchedule
        self.smoker = smoker
        self.petFriendly = petFriendly
        self.livingStyle = livingStyle
        
        // Interests
        self.socialLevel = socialLevel
        self.studyHabits = studyHabits
        self.interests = interests
        
        // Media & Location
        self.profileImageUrl = profileImageUrl
        self.profileImageUrls = profileImageUrls
        self.location = location
        
        // Verification
        self.isVerified = isVerified
        
        // Blocked Users
        self.blockedUserIDs = blockedUserIDs
        
        // Advanced Filter Settings
        self.filterSettings = filterSettings
        
        // Lifestyle Fields
        self.pets = pets
        self.drinking = drinking
        self.smoking = smoking
        self.cannabis = cannabis
        self.workout = workout
        self.dietaryPreferences = dietaryPreferences
        self.socialMedia = socialMedia
        self.sleepingHabits = sleepingHabits
        
        // Quiz Answers
        self.goingOutQuizAnswers = goingOutQuizAnswers
        self.weekendQuizAnswers = weekendQuizAnswers
        self.phoneQuizAnswers = phoneQuizAnswers
    }
}
