//
//  UserModel.swift
//  CollegePads
//
//  Created by [Your Name] on [Date].
//

import Foundation
import FirebaseFirestore
import FirebaseFirestoreCombineSwift

/// A codable user model that uses Firestore's Combine features.
struct UserModel: Codable, Identifiable {
    /// The Firestore document ID, auto-populated via @DocumentID
    @DocumentID var id: String?

    // Basic user info
    var email: String
    var createdAt: Date
    var isEmailVerified: Bool

    // College/living info
    var gradeLevel: String?        // e.g., "Freshman", "Sophomore", "Junior", "Senior", "Grad"
    var major: String?            // e.g., "Computer Science", "Business"
    var collegeName: String?      // e.g., "College of Engineering", "College of Arts & Sciences"

    // Preferences
    var dormType: String?         // e.g., "On-Campus", "Off-Campus"
    var preferredDorm: String?    // e.g., "Dorm A", "Dorm B"
    var budgetRange: String?      // e.g., "$500 - $1000"
    var cleanliness: Int?         // rating 1-5
    var sleepSchedule: String?    // e.g., "Night Owl", "Early Bird", "Flexible"
    var smoker: Bool?
    var petFriendly: Bool?
    var livingStyle: String?      // e.g., "Quiet", "Social", "Party-Friendly"

    // Potential location data for future geofire or geospatial queries
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
        self.latitude = latitude
        self.longitude = longitude
    }
}
