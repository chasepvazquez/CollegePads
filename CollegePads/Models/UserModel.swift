//
//  UserModel.swift
//  CollegePads
//
//  Created by [Your Name] on [Date].
//
//  This model represents a user profile for CollegePads. It includes all necessary
//  fields for basic user information, college/living details, roommate preferences,
//  quiz responses, interests, location data, verification status, blocked users,
//  and new housing-related fields: housingStatus and leaseDuration.

import Foundation
import FirebaseFirestore
import FirebaseFirestoreCombineSwift

/// A codable user model for CollegePads.
struct UserModel: Codable, Identifiable {
    /// The unique Firestore document ID.
    @DocumentID var id: String?

    // MARK: - Basic Info
    var email: String
    var createdAt: Date
    var isEmailVerified: Bool

    // MARK: - College & Living Info
    var gradeLevel: String?
    var major: String?
    var collegeName: String?

    // MARK: - Roommate Preferences
    var dormType: String?
    var preferredDorm: String?
    var budgetRange: String?
    var cleanliness: Int?
    var sleepSchedule: String?
    var smoker: Bool?
    var petFriendly: Bool?
    var livingStyle: String?

    // MARK: - Quiz & Interests
    var socialLevel: Int?
    var studyHabits: Int?
    var interests: [String]?

    // MARK: - Profile Picture & Location
    var profileImageUrl: String?
    var latitude: Double?
    var longitude: Double?
    
    // MARK: - Verification Fields
    var isVerified: Bool?         // true if the user has been verified
    var verificationImageUrl: String? // URL of the uploaded verification image
    
    // MARK: - Blocked Users
    var blockedUserIDs: [String]?   // UIDs of users blocked by this user
    
    // MARK: - Housing Details (New)
    /// Indicates the user's current living situation.
    /// Examples: "Dorm Resident", "Apartment Resident", "House Owner/Renter", "Subleasing", "Looking for Roommate", "Looking for Lease", "Other".
    var housingStatus: String?
    /// Specifies the lease duration or timing.
    /// Examples: "Current Lease", "Short Term (<6 months)", "Medium Term (6-12 months)", "Long Term (1 year+)", "Future: Next Year", "Future: 2+ Years", "Not Applicable".
    var leaseDuration: String?

    // MARK: - Initializer
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
        self.createdAt = Date()  // Set to current time on initialization.
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
