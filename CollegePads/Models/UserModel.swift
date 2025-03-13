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

    var email: String
    var createdAt: Date
    var isEmailVerified: Bool
    
    // New roommate preference fields:
    var dormType: String?
    var budgetRange: String?
    var cleanliness: Int?       // rating 1-5
    var sleepSchedule: String?
    var smoker: Bool?
    var petFriendly: Bool?
    
    // Basic initializer for new users
    init(email: String, isEmailVerified: Bool, dormType: String? = nil, budgetRange: String? = nil, cleanliness: Int? = nil, sleepSchedule: String? = nil, smoker: Bool? = nil, petFriendly: Bool? = nil) {
        self.email = email
        self.isEmailVerified = isEmailVerified
        self.createdAt = Date()
        self.dormType = dormType
        self.budgetRange = budgetRange
        self.cleanliness = cleanliness
        self.sleepSchedule = sleepSchedule
        self.smoker = smoker
        self.petFriendly = petFriendly
    }
}
