//
//  SmartMatchingEngine.swift
//  CollegePads
//
//  Created by [Your Name] on [Date].
//
//  This utility calculates a comprehensive match score between two UserModel instances.
//  It leverages your existing CompatibilityCalculator and adds bonus points based on:
//    • Verification status (+10 points if both are verified)
//    • Housing status match (+5 points if both have the same housingStatus)
//    • Lease duration compatibility (+5 points if both share the same leaseDuration)
//    • Optional average roommate rating (normalized to a 10‑point bonus scale)
//
//  The final score is normalized to a scale of 0 to 100.

import Foundation

struct SmartMatchingEngine {
    
    /// Calculates an overall smart match score between two user profiles.
    /// - Parameters:
    ///   - user1: The current user.
    ///   - user2: A potential match.
    ///   - averageRating: An optional average roommate rating for user2 (from 1 to 5).
    /// - Returns: A composite match score (0–100).
    static func calculateSmartMatchScore(between user1: UserModel, and user2: UserModel, averageRating: Double? = nil) -> Double {
        // Base compatibility from the existing CompatibilityCalculator
        let baseScore = CompatibilityCalculator.calculateUserCompatibility(between: user1, and: user2)
        
        var bonus: Double = 0.0
        
        // Bonus for both being verified.
        if let v1 = user1.isVerified, let v2 = user2.isVerified, v1 && v2 {
            bonus += 10.0
        }
        
        // Bonus if housing status matches (assuming non-empty strings; adjust logic as needed).
        if let housing1 = user1.housingStatus?.lowercased(), let housing2 = user2.housingStatus?.lowercased(), housing1 == housing2 {
            bonus += 5.0
        }
        
        // Bonus if lease duration matches (if provided).
        if let lease1 = user1.leaseDuration?.lowercased(), let lease2 = user2.leaseDuration?.lowercased(), lease1 == lease2 {
            bonus += 5.0
        }
        
        // Optional: bonus based on average roommate rating.
        // Normalize average rating (1-5) to a 0-10 scale: multiply by 2.
        if let avgRating = averageRating {
            bonus += (avgRating * 2.0)
        }
        
        // Calculate final score and normalize to 100.
        let finalScore = baseScore + bonus
        
        // Cap the final score to 100.
        return min(finalScore, 100.0)
    }
}
