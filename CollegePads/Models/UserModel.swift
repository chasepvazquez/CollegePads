//
//  UserModel.swift
//  CollegePads
//
//  Created by [Your Name] on [Date].
//
//  This model represents a user profile for CollegePads, including basic info, roommate preferences,
//  verification, blocked users, and extended housing details.
import Foundation
import FirebaseFirestore
import FirebaseFirestoreCombineSwift

struct UserModel: Codable, Identifiable {
    @DocumentID var id: String?

    // Basic Info
    var email: String
    var createdAt: Date
    var isEmailVerified: Bool

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
    var profileImageUrl: String?
    var latitude: Double?
    var longitude: Double?
    
    // Verification Fields
    var isVerified: Bool?
    var verificationImageUrl: String?
    
    // Blocked Users
    var blockedUserIDs: [String]?
    
    // Housing Details (New)
    var housingStatus: String?       // e.g., "Dorm Resident", "Apartment Resident", etc.
    var leaseDuration: String?       // e.g., "Current Lease", "Short Term (<6 months)", etc.
    
    init(
        email: String,
        isEmailVerified: Bool,
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
        latitude: Double? = nil,
        longitude: Double? = nil,
        isVerified: Bool? = false,
        verificationImageUrl: String? = nil,
        blockedUserIDs: [String]? = nil,
        housingStatus: String? = nil,
        leaseDuration: String? = nil
    ) {
        self.email = email
        self.isEmailVerified = isEmailVerified
        self.createdAt = Date()
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
        self.latitude = latitude
        self.longitude = longitude
        self.isVerified = isVerified
        self.verificationImageUrl = verificationImageUrl
        self.blockedUserIDs = blockedUserIDs
        self.housingStatus = housingStatus
        self.leaseDuration = leaseDuration
    }
}
