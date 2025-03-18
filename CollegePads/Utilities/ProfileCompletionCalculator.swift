//
//  ProfileCompletionCalculator.swift
//  CollegePads
//
//  Created by [Your Name] on [Date].
//
//  This utility calculates the profile completion percentage based on whether key fields are filled in.
//  Fields considered include email, grade level, major, college name, housing status, lease duration,
//  interests, and profile image. Adjust weights or add additional fields as needed.

import Foundation

struct ProfileCompletionCalculator {
    /// Calculates the profile completion percentage for a given UserModel.
    /// - Parameter user: The user model.
    /// - Returns: A value between 0.0 and 100.0 representing the completion percentage.
    static func calculateCompletion(for user: UserModel) -> Double {
        var score: Double = 0.0
        let totalWeight: Double = 100.0
        
        // Define weights for each field (adjust as needed)
        let emailWeight = 15.0      // Email should always be filled.
        let gradeWeight = 10.0      // Grade level.
        let majorWeight = 10.0      // Major field.
        let collegeWeight = 10.0    // College name.
        let housingStatusWeight = 10.0  // Housing status (if extended in the model)
        let leaseDurationWeight = 5.0   // Lease duration.
        let interestsWeight = 10.0      // Interests.
        let profileImageWeight = 10.0   // Profile image.
        let extraFieldsWeight = 20.0    // Other fields (dormType, cleanliness, sleep schedule, etc.)

        // Email: must be non-empty.
        if !user.email.isEmpty { score += emailWeight }
        
        // Grade Level
        if let grade = user.gradeLevel, !grade.isEmpty { score += gradeWeight }
        
        // Major
        if let major = user.major, !major.isEmpty { score += majorWeight }
        
        // College Name
        if let college = user.collegeName, !college.isEmpty { score += collegeWeight }
        
        // Housing Status (if extended)
        if let housing = user.housingStatus, !housing.isEmpty { score += housingStatusWeight }
        
        // Lease Duration (if extended)
        if let lease = user.leaseDuration, !lease.isEmpty { score += leaseDurationWeight }
        
        // Interests: count as complete if at least one interest is provided.
        if let interests = user.interests, !interests.isEmpty { score += interestsWeight }
        
        // Profile Image: check if URL is non-empty.
        if let imageUrl = user.profileImageUrl, !imageUrl.isEmpty { score += profileImageWeight }
        
        // Extra fields: check dormType, cleanliness, sleep schedule (at least one should be provided)
        if let dorm = user.dormType, !dorm.isEmpty {
            score += extraFieldsWeight / 3
        }
        if let cleanliness = user.cleanliness, cleanliness > 0 {
            score += extraFieldsWeight / 3
        }
        if let sleep = user.sleepSchedule, !sleep.isEmpty {
            score += extraFieldsWeight / 3
        }
        
        // Ensure score does not exceed 100.
        return min(score, totalWeight)
    }
}
