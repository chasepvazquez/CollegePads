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
    var height: String?            // NEW: Height as a string (e.g., "5'9")
    
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
    
    // Verification
    var isVerified: Bool?
    var verificationImageUrl: String?
    
    // Blocked Users
    var blockedUserIDs: [String]?
    
    // Housing Details
    var housingStatus: String?
    var leaseDuration: String?
    
    // Advanced Filter Settings (grouped together)
    var filterSettings: FilterSettings?
    
    // NEW: Lifestyle fields (matching Tinder’s categories)
    var pets: [String]?
    var drinking: String?
    var smoking: String?
    var cannabis: String?
    var workout: String?
    var dietaryPreferences: [String]?
    var socialMedia: String?
    var sleepingHabits: String?
    
    init(
        email: String,
        isEmailVerified: Bool,
        aboutMe: String? = nil,
        firstName: String? = nil,
        lastName: String? = nil,
        dateOfBirth: String? = nil,
        gender: String? = nil,
        height: String? = nil,               // NEW
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
        verificationImageUrl: String? = nil,
        blockedUserIDs: [String]? = nil,
        housingStatus: String? = nil,
        leaseDuration: String? = nil,
        filterSettings: FilterSettings? = nil,
        createdAt: Date? = nil,
        pets: [String]? = nil,
        drinking: String? = nil,
        smoking: String? = nil,
        cannabis: String? = nil,
        workout: String? = nil,
        dietaryPreferences: [String]? = nil,
        socialMedia: String? = nil,
        sleepingHabits: String? = nil
    ) {
        self.email = email
        self.isEmailVerified = isEmailVerified
        self.createdAt = createdAt ?? Date()
        
        self.aboutMe = aboutMe
        self.firstName = firstName
        self.lastName = lastName
        self.dateOfBirth = dateOfBirth
        self.gender = gender
        self.height = height                      // NEW
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
        self.verificationImageUrl = verificationImageUrl
        self.blockedUserIDs = blockedUserIDs
        
        self.housingStatus = housingStatus
        self.leaseDuration = leaseDuration
        
        self.filterSettings = filterSettings
        
        // NEW: Lifestyle fields
        self.pets = pets
        self.drinking = drinking
        self.smoking = smoking
        self.cannabis = cannabis
        self.workout = workout
        self.dietaryPreferences = dietaryPreferences
        self.socialMedia = socialMedia
        self.sleepingHabits = sleepingHabits
    }
}
