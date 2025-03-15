//
//  CompatibilityCalculator.swift
//  CollegePads
//
//  Created by [Your Name] on [Date].
//

import Foundation

struct CompatibilityCalculator {
    /// Calculates a compatibility score (0-100) between two user profiles.
    /// Uses multiple weighted factors.
    static func calculateUserCompatibility(between user1: UserModel, and user2: UserModel) -> Double {
        var score = 0.0
        var totalWeight = 0.0

        // Weight factors (adjust as needed)
        let gradeWeight = 10.0
        let dormWeight = 15.0
        let cleanlinessWeight = 15.0
        let sleepWeight = 10.0
        let budgetWeight = 10.0
        let styleWeight = 10.0
        let collegeWeight = 10.0
        let majorWeight = 10.0

        // Grade Level: full points if equal
        totalWeight += gradeWeight
        if let grade1 = user1.gradeLevel, let grade2 = user2.gradeLevel, grade1 == grade2 {
            score += gradeWeight
        }
        
        // Dorm Type: full points if equal
        totalWeight += dormWeight
        if let dorm1 = user1.dormType, let dorm2 = user2.dormType, dorm1 == dorm2 {
            score += dormWeight
        }
        
        // Cleanliness: score decreases with difference
        totalWeight += cleanlinessWeight
        if let clean1 = user1.cleanliness, let clean2 = user2.cleanliness {
            let diff = abs(Double(clean1) - Double(clean2))
            let cleanlinessScore = max(0, (5 - diff) / 5 * cleanlinessWeight)
            score += cleanlinessScore
        }
        
        // Sleep Schedule: full points if equal
        totalWeight += sleepWeight
        if let sleep1 = user1.sleepSchedule, let sleep2 = user2.sleepSchedule, sleep1 == sleep2 {
            score += sleepWeight
        }
        
        // Budget Range: full points if equal
        totalWeight += budgetWeight
        if let budget1 = user1.budgetRange, let budget2 = user2.budgetRange, budget1 == budget2 {
            score += budgetWeight
        }
        
        // Living Style: full points if equal
        totalWeight += styleWeight
        if let style1 = user1.livingStyle, let style2 = user2.livingStyle, style1 == style2 {
            score += styleWeight
        }
        
        // College Name: full points if equal
        totalWeight += collegeWeight
        if let college1 = user1.collegeName, let college2 = user2.collegeName, college1 == college2 {
            score += collegeWeight
        }
        
        // Major: full points if equal
        totalWeight += majorWeight
        if let major1 = user1.major, let major2 = user2.major, major1 == major2 {
            score += majorWeight
        }
        
        return (score / totalWeight) * 100
    }
}
