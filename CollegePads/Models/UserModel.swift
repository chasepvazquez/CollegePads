import Foundation
import FirebaseFirestore
import FirebaseFirestoreCombineSwift

struct FilterSettings: Codable {
    var dormType: String?
    var housingStatus: String?
    var collegeName: String?
    var budgetRange: String?
    var gradeGroup: String?
    var interests: String?
    var maxDistance: Double?
    var preferredGender: String?
    var maxAgeDifference: Double?
    var mode: String?   // "university" or "distance"
}

struct UserModel: Codable, Identifiable {
    @DocumentID var id: String?
    
    // Basic Info
    var email: String
    var createdAt: Date?           // optional creation date
    var isEmailVerified: Bool
    
    // Personal Info
    var aboutMe: String?
    var firstName: String?
    var lastName: String?
    var dateOfBirth: String?
    var gender: String?            // "Male", "Female", or "Other"
    var height: String?            // e.g., "5'9"
    
    // Academic Info
    var gradeLevel: String?
    var major: String?
    var collegeName: String?       // Selected via search
    
    // Roommate Preferences
    var dormType: String?
    var preferredDorm: String?
    var budgetRange: String?
    var cleanliness: Int?
    var sleepSchedule: String?
    var smoker: Bool?
    var petFriendly: Bool?
    var livingStyle: String?
    
    // Interests
    var socialLevel: Int?
    var studyHabits: Int?
    var interests: [String]?
    
    // Media & Location
    var profileImageUrl: String?      // legacy single image
    var profileImageUrls: [String]?   // array for multiple images
    var location: GeoPoint?
    
    // Verification – Only using email verification now.
    var isVerified: Bool?
    
    // Blocked Users
    var blockedUserIDs: [String]?
    
    // Housing Details
    // (Legacy) Single housing status field for compatibility
    var housingStatus: String?
    // New multi-selector field
    var housingStatuses: [String]?
    var leaseDuration: String?
    
    // New Roommate Count Fields
    var roommateCountNeeded: Int?
    var roommateCountExisting: Int?
    
    // New Desired Lease Housing Type Field
    var desiredLeaseHousingType: String?
    
    // Advanced Filter Settings
    var filterSettings: FilterSettings?
    
    // Lifestyle fields (matching Tinder’s categories)
    var pets: [String]?
    var drinking: String?
    var smoking: String?
    var cannabis: String?
    var workout: String?
    var dietaryPreferences: [String]?
    var socialMedia: String?
    var sleepingHabits: String?
    
    // Quiz Answers
    var goingOutQuizAnswers: [String]?
    var weekendQuizAnswers: [String]?
    var phoneQuizAnswers: [String]?   // "+ My Phone" quiz answers
    
    // NEW: Property Details & Media Upload
    var propertyDetails: String?
    var propertyImageUrls: [String]?
    var floorplanUrls: [String]?
    var documentUrls: [String]?

    init(
        email: String,
        isEmailVerified: Bool,
        aboutMe: String? = nil,
        firstName: String? = nil,
        lastName: String? = nil,
        dateOfBirth: String? = nil,
        gender: String? = nil,
        height: String? = nil,
        gradeLevel: String? = nil,
        major: String? = nil,
        collegeName: String? = nil,
        dormType: String? = nil,
        preferredDorm: String? = nil,
        budgetRange: String? = nil,
        cleanliness: Int? = nil,
        sleepSchedule: String? = nil,
        smoker: Bool? = nil,
        petFriendly: Bool? = nil,
        livingStyle: String? = nil,
        socialLevel: Int? = nil,
        studyHabits: Int? = nil,
        interests: [String]? = nil,
        profileImageUrl: String? = nil,
        profileImageUrls: [String]? = nil,
        location: GeoPoint? = nil,
        isVerified: Bool? = false,
        blockedUserIDs: [String]? = nil,
        housingStatus: String? = nil,
        housingStatuses: [String]? = nil,
        leaseDuration: String? = nil,
        filterSettings: FilterSettings? = nil,
        createdAt: Date? = nil,
        roommateCountNeeded: Int? = nil,
        roommateCountExisting: Int? = nil,
        desiredLeaseHousingType: String? = nil,
        pets: [String]? = nil,
        drinking: String? = nil,
        smoking: String? = nil,
        cannabis: String? = nil,
        workout: String? = nil,
        dietaryPreferences: [String]? = nil,
        socialMedia: String? = nil,
        sleepingHabits: String? = nil,
        goingOutQuizAnswers: [String]? = nil,
        weekendQuizAnswers: [String]? = nil,
        phoneQuizAnswers: [String]? = nil,
        // NEW property details parameters:
        propertyDetails: String? = nil,
        propertyImageUrls: [String]? = nil,
        floorplanUrls: [String]? = nil,
        documentUrls: [String]? = nil
    ) {
        self.email = email
        self.isEmailVerified = isEmailVerified
        self.createdAt = createdAt ?? Date()
        
        self.aboutMe = aboutMe
        self.firstName = firstName
        self.lastName = lastName
        self.dateOfBirth = dateOfBirth
        self.gender = gender
        self.height = height
        
        self.gradeLevel = gradeLevel
        self.major = major
        self.collegeName = collegeName
        
        self.dormType = dormType
        self.preferredDorm = preferredDorm
        self.budgetRange = budgetRange
        self.cleanliness = cleanliness
        self.sleepSchedule = sleepSchedule
        self.smoker = smoker
        self.petFriendly = petFriendly
        self.livingStyle = livingStyle
        
        self.socialLevel = socialLevel
        self.studyHabits = studyHabits
        self.interests = interests
        
        self.profileImageUrl = profileImageUrl
        self.profileImageUrls = profileImageUrls
        self.location = location
        
        self.isVerified = isVerified
        
        self.blockedUserIDs = blockedUserIDs
        
        self.housingStatus = housingStatus
        self.housingStatuses = housingStatuses
        self.leaseDuration = leaseDuration
        
        self.roommateCountNeeded = roommateCountNeeded
        self.roommateCountExisting = roommateCountExisting
        
        self.desiredLeaseHousingType = desiredLeaseHousingType
        
        self.filterSettings = filterSettings
        
        self.pets = pets
        self.drinking = drinking
        self.smoking = smoking
        self.cannabis = cannabis
        self.workout = workout
        self.dietaryPreferences = dietaryPreferences
        self.socialMedia = socialMedia
        self.sleepingHabits = sleepingHabits
        
        self.goingOutQuizAnswers = goingOutQuizAnswers
        self.weekendQuizAnswers = weekendQuizAnswers
        self.phoneQuizAnswers = phoneQuizAnswers
        
        // New property details fields
        self.propertyDetails = propertyDetails
        self.propertyImageUrls = propertyImageUrls
        self.floorplanUrls = floorplanUrls
        self.documentUrls = documentUrls
    }
}
