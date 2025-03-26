import Foundation
import FirebaseFirestore
import FirebaseFirestoreCombineSwift

struct UserModel: Codable, Identifiable {
    @DocumentID var id: String?

    // Basic Info
    var email: String
    var createdAt: Date?           // Changed to optional
    
    var isEmailVerified: Bool
    
    // NEW FIELDS
    var firstName: String?
    var lastName: String?
    /// Stored as a string (yyyy-MM-dd) for simplicity.
    var dateOfBirth: String?
    /// “Male”, “Female”, or “Other”
    var gender: String?
    
    // College & Living Info
    var gradeLevel: String?
    var major: String?
    var collegeName: String?
    
    // Roommate Preferences
    var dormType: String?
    var preferredDorm: String?
    var budgetRange: String?
    var cleanliness: Int?
    var sleepSchedule: String?
    var smoker: Bool?
    var petFriendly: Bool?
    var livingStyle: String?
    
    // Quiz & Interests
    var socialLevel: Int?
    var studyHabits: Int?
    var interests: [String]?
    
    // Profile Picture & Location
    var profileImageUrl: String?         // Legacy single image (fallback)
    var profileImageUrls: [String]?        // Array for multiple images (max 10)
    var location: GeoPoint?              // User location
    
    // Verification Fields
    var isVerified: Bool?
    var verificationImageUrl: String?
    
    // Blocked Users
    var blockedUserIDs: [String]?
    
    // Housing Details
    var housingStatus: String?
    var leaseDuration: String?
    
    init(
        email: String,
        isEmailVerified: Bool,
        // NEW FIELDS
        firstName: String? = nil,
        lastName: String? = nil,
        dateOfBirth: String? = nil,
        gender: String? = nil,
        // Existing fields
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
        createdAt: Date? = nil
    ) {
        self.email = email
        self.isEmailVerified = isEmailVerified
        // Only set createdAt if it wasn't provided.
        self.createdAt = createdAt ?? Date()
        
        // Assign new fields
        self.firstName = firstName
        self.lastName = lastName
        self.dateOfBirth = dateOfBirth
        self.gender = gender
        
        // Assign existing fields
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
    }
}
