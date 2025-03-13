//
//  UserModel.swift
//  CollegePads
//
//  Created by [Your Name] on [Date].
//

import Foundation
import FirebaseFirestoreSwift

struct UserModel: Codable, Identifiable {
    @DocumentID var id: String?    // Firestore document ID
    var email: String
    var createdAt: Date           // Or a Firestore Timestamp, if you prefer
    var isEmailVerified: Bool
    
    // Add more fields as needed (e.g., name, major, etc.)
    
    init(email: String, isEmailVerified: Bool) {
        self.email = email
        self.isEmailVerified = isEmailVerified
        self.createdAt = Date()
    }
}

