//
//  CompatibilityCalculator.swift
//  CollegePads
//
//  Created by [Your Name] on [Date].
//

import Foundation
import CoreLocation

struct CompatibilityCalculator {
    /// Calculates a compatibility score (0-100) between two user profiles.
    /// Uses multiple weighted factors, including an optional distance factor.
    static func calculateUserCompatibility(between user1: UserModel, and user2: UserModel) -> Double {
        var score = 0.0
        var totalWeight = 0.0

        // Weight factors (adjust these as needed)
        let gradeWeight = 10.0
        let dormWeight = 15.0
        let cleanlinessWeight = 15.0
        let sleepWeight = 10.0
        let budgetWeight = 10.0
        let styleWeight = 10.0
        let collegeWeight = 10.0
        let majorWeight = 10.0
        let distanceWeight = 10.0  // New: weight for distance compatibility

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
        
        // Distance factor: if both users have location data, calculate distance.
        if let lat1 = user1.latitude, let lon1 = user1.longitude,
           let lat2 = user2.latitude, let lon2 = user2.longitude {
            let distanceInKm = haversineDistance(lat1: lat1, lon1: lon1, lat2: lat2, lon2: lon2)
            totalWeight += distanceWeight
            // For this example, if the distance is 0-5 km, full points; 5-20 km linearly decreased; >20 km gets 0.
            let distanceScore: Double
            if distanceInKm <= 5 {
                distanceScore = distanceWeight
            } else if distanceInKm >= 20 {
                distanceScore = 0
            } else {
                distanceScore = ((20 - distanceInKm) / 15) * distanceWeight
            }
            score += distanceScore
        }
        
        // Return a percentage score (0-100)
        let percentage = (score / totalWeight) * 100
        return percentage
    }
    
    /// Calculates the Haversine distance (in kilometers) between two latitude/longitude pairs.
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
