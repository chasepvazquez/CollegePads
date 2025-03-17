//
//  CompatibilityCalculator.swift
//  CollegePads
//
//  Created by [Your Name] on [Date].
//

import Foundation
import CoreLocation

struct CompatibilityCalculator {
    
    /// Calculates an overall compatibility score (0-100) between two user profiles.
    static func calculateUserCompatibility(between user1: UserModel, and user2: UserModel) -> Double {
        let result = calculateCompatibilityBreakdown(between: user1, and: user2)
        return result.overall
    }
    
    /// Calculates a compatibility score along with a breakdown for each factor.
    /// Returns a tuple with overall score and a dictionary of individual factor scores.
    static func calculateCompatibilityBreakdown(between user1: UserModel, and user2: UserModel) -> (overall: Double, breakdown: [String: Double]) {
        var breakdown: [String: Double] = [:]
        var totalWeight = 0.0
        var score = 0.0
        
        // Define weights for each factor.
        let factors: [(key: String, weight: Double)] = [
            ("Grade", 10.0),
            ("Dorm", 15.0),
            ("Cleanliness", 15.0),
            ("Sleep", 10.0),
            ("Budget", 10.0),
            ("LivingStyle", 10.0),
            ("College", 10.0),
            ("Major", 10.0),
            ("Distance", 10.0)
        ]
        
        // Grade Level
        totalWeight += 10.0
        if let grade1 = user1.gradeLevel, let grade2 = user2.gradeLevel, grade1 == grade2 {
            breakdown["Grade"] = 10.0
            score += 10.0
        } else {
            breakdown["Grade"] = 0
        }
        
        // Dorm Type
        totalWeight += 15.0
        if let dorm1 = user1.dormType, let dorm2 = user2.dormType, dorm1 == dorm2 {
            breakdown["Dorm"] = 15.0
            score += 15.0
        } else {
            breakdown["Dorm"] = 0
        }
        
        // Cleanliness (numeric difference: 0 difference gets full weight, linear decay)
        totalWeight += 15.0
        if let clean1 = user1.cleanliness, let clean2 = user2.cleanliness {
            let diff = abs(Double(clean1) - Double(clean2))
            let cleanlinessScore = max(0, (5 - diff) / 5 * 15.0)
            breakdown["Cleanliness"] = cleanlinessScore
            score += cleanlinessScore
        } else {
            breakdown["Cleanliness"] = 0
        }
        
        // Sleep Schedule
        totalWeight += 10.0
        if let sleep1 = user1.sleepSchedule, let sleep2 = user2.sleepSchedule, sleep1 == sleep2 {
            breakdown["Sleep"] = 10.0
            score += 10.0
        } else {
            breakdown["Sleep"] = 0
        }
        
        // Budget Range
        totalWeight += 10.0
        if let budget1 = user1.budgetRange, let budget2 = user2.budgetRange, budget1 == budget2 {
            breakdown["Budget"] = 10.0
            score += 10.0
        } else {
            breakdown["Budget"] = 0
        }
        
        // Living Style
        totalWeight += 10.0
        if let style1 = user1.livingStyle, let style2 = user2.livingStyle, style1 == style2 {
            breakdown["LivingStyle"] = 10.0
            score += 10.0
        } else {
            breakdown["LivingStyle"] = 0
        }
        
        // College Name
        totalWeight += 10.0
        if let college1 = user1.collegeName, let college2 = user2.collegeName, college1 == college2 {
            breakdown["College"] = 10.0
            score += 10.0
        } else {
            breakdown["College"] = 0
        }
        
        // Major
        totalWeight += 10.0
        if let major1 = user1.major, let major2 = user2.major, major1 == major2 {
            breakdown["Major"] = 10.0
            score += 10.0
        } else {
            breakdown["Major"] = 0
        }
        
        // Distance factor: if both users have location data, use Haversine.
        totalWeight += 10.0
        if let lat1 = user1.latitude, let lon1 = user1.longitude,
           let lat2 = user2.latitude, let lon2 = user2.longitude {
            let distance = haversineDistance(lat1: lat1, lon1: lon1, lat2: lat2, lon2: lon2)
            // Full points if within 5 km, linearly drop to 0 at 20 km.
            let distanceScore: Double
            if distance <= 5 {
                distanceScore = 10.0
            } else if distance >= 20 {
                distanceScore = 0
            } else {
                distanceScore = ((20 - distance) / 15) * 10.0
            }
            breakdown["Distance"] = distanceScore
            score += distanceScore
        } else {
            breakdown["Distance"] = 0
        }
        
        let overall = (score / totalWeight) * 100
        return (overall, breakdown)
    }
    
    /// Calculates the Haversine distance (in kilometers) between two coordinate points.
    private static func haversineDistance(lat1: Double, lon1: Double, lat2: Double, lon2: Double) -> Double {
        let earthRadiusKm = 6371.0
        let dLat = degreesToRadians(lat2 - lat1)
        let dLon = degreesToRadians(lon2 - lon1)
        let a = sin(dLat / 2) * sin(dLat / 2) +
                cos(degreesToRadians(lat1)) * cos(degreesToRadians(lat2)) *
                sin(dLon / 2) * sin(dLon / 2)
        let c = 2 * atan2(sqrt(a), sqrt(1 - a))
        return earthRadiusKm * c
    }
    
    private static func degreesToRadians(_ degrees: Double) -> Double {
        return degrees * .pi / 180
    }
}
