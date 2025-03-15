//
//  UserModel.swift
//  CollegePads
//
//  Created by [Your Name] on [Date].
//

import Foundation
import FirebaseFirestore
import FirebaseFirestoreCombineSwift

/// A codable user model with advanced profile fields.
struct UserModel: Codable, Identifiable {
    /// Auto-populated Firestore document ID.
    @DocumentID var id: String?

    // Basic info
    var email: String
    var createdAt: Date
    var isEmailVerified: Bool

    // College / Living Info
    var gradeLevel: String?        // e.g., "Freshman", "Senior"
    var major: String?
    var collegeName: String?       // e.g., "College of Engineering"

    // Roommate Preferences
    var dormType: String?          // e.g., "On-Campus", "Off-Campus"
    var preferredDorm: String?     // e.g., "Dorm A", "Dorm B"
    var budgetRange: String?       // e.g., "$500 - $1000"
    var cleanliness: Int?          // rating 1-5
    var sleepSchedule: String?     // e.g., "Night Owl", "Early Bird", "Flexible"
    var smoker: Bool?
    var petFriendly: Bool?
    var livingStyle: String?       // e.g., "Quiet", "Social"

    // Profile Picture URL
    var profileImageUrl: String?

    // Location for matching (optional)
    var latitude: Double?
    var longitude: Double?

    // Basic initializer for new users
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
        profileImageUrl: String? = nil,
        latitude: Double? = nil,
        longitude: Double? = nil
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
        self.profileImageUrl = profileImageUrl
        self.latitude = latitude
        self.longitude = longitude
    }
}
