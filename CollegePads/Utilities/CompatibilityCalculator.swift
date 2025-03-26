import Foundation
import CoreLocation

struct CompatibilityCalculator {
    
    /// Calculates an overall compatibility score (0-100) between two user profiles.
    static func calculateUserCompatibility(between user1: UserModel, and user2: UserModel) -> Double {
        let result = calculateCompatibilityBreakdown(between: user1, and: user2)
        return result.overall
    }
    
    /// Calculates a compatibility breakdown, including the overall score and each factor’s contribution.
    /// Factors include: Grade, Dorm, Cleanliness, Sleep, Budget, LivingStyle, College, Major, Distance, Social, Study, Interests, Gender, and Age.
    static func calculateCompatibilityBreakdown(between user1: UserModel, and user2: UserModel) -> (overall: Double, breakdown: [String: Double]) {
        var breakdown: [String: Double] = [:]
        var totalWeight = 0.0
        var score = 0.0
        
        // Grade Level: 10 points
        totalWeight += 10.0
        if let grade1 = user1.gradeLevel, let grade2 = user2.gradeLevel, grade1 == grade2 {
            breakdown["Grade"] = 10.0
            score += 10.0
        } else {
            breakdown["Grade"] = 0
        }
        
        // Dorm Type: 15 points
        totalWeight += 15.0
        if let dorm1 = user1.dormType, let dorm2 = user2.dormType, dorm1 == dorm2 {
            breakdown["Dorm"] = 15.0
            score += 15.0
        } else {
            breakdown["Dorm"] = 0
        }
        
        // Cleanliness: 15 points
        totalWeight += 15.0
        if let clean1 = user1.cleanliness, let clean2 = user2.cleanliness {
            let diff = abs(Double(clean1) - Double(clean2))
            let cleanlinessScore = max(0, (5 - diff) / 5 * 15.0)
            breakdown["Cleanliness"] = cleanlinessScore
            score += cleanlinessScore
        } else {
            breakdown["Cleanliness"] = 0
        }
        
        // Sleep Schedule: 10 points
        totalWeight += 10.0
        if let sleep1 = user1.sleepSchedule, let sleep2 = user2.sleepSchedule, sleep1 == sleep2 {
            breakdown["Sleep"] = 10.0
            score += 10.0
        } else {
            breakdown["Sleep"] = 0
        }
        
        // Budget Range: 10 points
        totalWeight += 10.0
        if let budget1 = user1.budgetRange, let budget2 = user2.budgetRange, budget1 == budget2 {
            breakdown["Budget"] = 10.0
            score += 10.0
        } else {
            breakdown["Budget"] = 0
        }
        
        // Living Style: 10 points
        totalWeight += 10.0
        if let style1 = user1.livingStyle, let style2 = user2.livingStyle, style1 == style2 {
            breakdown["LivingStyle"] = 10.0
            score += 10.0
        } else {
            breakdown["LivingStyle"] = 0
        }
        
        // College Name: 10 points
        totalWeight += 10.0
        if let college1 = user1.collegeName, let college2 = user2.collegeName, college1 == college2 {
            breakdown["College"] = 10.0
            score += 10.0
        } else {
            breakdown["College"] = 0
        }
        
        // Major: 10 points
        totalWeight += 10.0
        if let major1 = user1.major, let major2 = user2.major, major1 == major2 {
            breakdown["Major"] = 10.0
            score += 10.0
        } else {
            breakdown["Major"] = 0
        }
        
        // Distance Factor: 10 points
        totalWeight += 10.0
        if let geo1 = user1.location, let geo2 = user2.location {
            let distance = haversineDistance(lat1: geo1.latitude, lon1: geo1.longitude, lat2: geo2.latitude, lon2: geo2.longitude)
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
        
        // Social Level (Quiz): 10 points
        totalWeight += 10.0
        if let social1 = user1.socialLevel, let social2 = user2.socialLevel {
            breakdown["Social"] = (social1 == social2 ? 10.0 : 0)
            score += (social1 == social2 ? 10.0 : 0)
        } else {
            breakdown["Social"] = 0
        }
        
        // Study Habits (Quiz): 10 points
        totalWeight += 10.0
        if let study1 = user1.studyHabits, let study2 = user2.studyHabits {
            breakdown["Study"] = (study1 == study2 ? 10.0 : 0)
            score += (study1 == study2 ? 10.0 : 0)
        } else {
            breakdown["Study"] = 0
        }
        
        // Common Interests: 10 points
        totalWeight += 10.0
        if let interests1 = user1.interests, let interests2 = user2.interests {
            let lowerInterests1 = interests1.map { $0.lowercased() }
            let lowerInterests2 = interests2.map { $0.lowercased() }
            let common = lowerInterests1.filter { lowerInterests2.contains($0) }
            let commonScore = common.isEmpty ? 0.0 : 10.0
            breakdown["Interests"] = commonScore
            score += commonScore
        } else {
            breakdown["Interests"] = 0
        }
        
        // Gender Compatibility: 10 points
        totalWeight += 10.0
        if let gender1 = user1.gender, let gender2 = user2.gender, gender1 == gender2 {
            breakdown["Gender"] = 10.0
            score += 10.0
        } else {
            breakdown["Gender"] = 0
        }
        
        // Age Similarity: 10 points
        totalWeight += 10.0
        if let dob1 = user1.dateOfBirth, let dob2 = user2.dateOfBirth,
           let date1 = dateFromString(dob1), let date2 = dateFromString(dob2) {
            let age1 = calculateAge(birthDate: date1)
            let age2 = calculateAge(birthDate: date2)
            let ageDiff = abs(age1 - age2)
            let ageScore: Double
            if ageDiff <= 2 {
                ageScore = 10.0
            } else if ageDiff >= 5 {
                ageScore = 0.0
            } else {
                ageScore = ((5 - Double(ageDiff)) / 3) * 10.0
            }
            breakdown["Age"] = ageScore
            score += ageScore
        } else {
            breakdown["Age"] = 0
        }
        
        let overall = (score / totalWeight) * 100
        return (overall, breakdown)
    }
    
    // Helper functions for age calculations.
    private static func dateFromString(_ str: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: str)
    }
    
    private static func calculateAge(birthDate: Date) -> Int {
        let now = Date()
        let calendar = Calendar.current
        let ageComponents = calendar.dateComponents([.year], from: birthDate, to: now)
        return ageComponents.year ?? 0
    }
    
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
