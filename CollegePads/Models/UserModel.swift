import Foundation
import FirebaseFirestore
import FirebaseFirestoreCombineSwift

struct UserModel: Codable, Identifiable {
    @DocumentID var id: String?

    // Basic Info
    var email: String
    var createdAt: Date?           // optional creation date
    var isEmailVerified: Bool
    
    // NEW FIELD for “About Me”
    var aboutMe: String?           // short bio/description
    
    // Name & Demographics
    var firstName: String?
    var lastName: String?
    var dateOfBirth: String?
    var gender: String?            // "Male", "Female", or "Other"
    
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
    
    // Profile Pictures & Location
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
    
    init(
        email: String,
        isEmailVerified: Bool,
        aboutMe: String? = nil,
        firstName: String? = nil,
        lastName: String? = nil,
        dateOfBirth: String? = nil,
        gender: String? = nil,
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
        // If no createdAt was passed, use "now".
        self.createdAt = createdAt ?? Date()
        
        self.aboutMe = aboutMe
        self.firstName = firstName
        self.lastName = lastName
        self.dateOfBirth = dateOfBirth
        self.gender = gender
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
