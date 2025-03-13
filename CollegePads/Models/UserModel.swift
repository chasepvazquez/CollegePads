//
//  UserModel.swift
//  CollegePads
//
//  Created by [Your Name] on [Date].
//

import Foundation
import FirebaseFirestore
import FirebaseFirestoreCombineSwift

/// A codable user model that uses Firestore's Swift/Combine features.
struct UserModel: Codable, Identifiable {
    /// The Firestore document ID, auto-populated via @DocumentID
    @DocumentID var id: String?

    var email: String
    var createdAt: Date
    var isEmailVerified: Bool

    /// Basic initializer for new users
    init(email: String, isEmailVerified: Bool) {
        self.email = email
        self.isEmailVerified = isEmailVerified
        self.createdAt = Date()
    }
}
