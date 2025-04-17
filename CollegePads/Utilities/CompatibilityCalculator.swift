import Foundation
import CoreLocation
import FirebaseFirestore   // for GeoPoint

struct CompatibilityCalculator {

    /// Calculates overall compatibility (0–100) between two profiles.
    static func calculateUserCompatibility(between user1: UserModel,
                                            and user2: UserModel) -> Double {
        let result = calculateCompatibilityBreakdown(between: user1, and: user2)
        return result.overall
    }

    /// Returns both an overall percentage and the breakdown per factor.
    static func calculateCompatibilityBreakdown(between user1: UserModel,
                                                and user2: UserModel)
    -> (overall: Double, breakdown: [String: Double]) {
        var breakdown: [String: Double] = [:]
        var totalWeight: Double = 0
        var score: Double = 0

        // MARK: Grade Level (10)
        totalWeight += 10
        if let g1 = user1.gradeLevel, let g2 = user2.gradeLevel, g1 == g2 {
            breakdown["Grade"] = 10; score += 10
        } else {
            breakdown["Grade"] = 0
        }

        // MARK: Dorm Type (15)
        totalWeight += 15
        if let d1 = user1.dormType, let d2 = user2.dormType, d1 == d2 {
            breakdown["Dorm"] = 15; score += 15
        } else {
            breakdown["Dorm"] = 0
        }

        // MARK: Cleanliness (15)
        totalWeight += 15
        if let c1 = user1.cleanliness, let c2 = user2.cleanliness {
            let diff = abs(Double(c1) - Double(c2))
            let pts = max(0, (5 - diff) / 5 * 15)
            breakdown["Cleanliness"] = pts; score += pts
        } else {
            breakdown["Cleanliness"] = 0
        }

        // MARK: Sleep Schedule (10)
        totalWeight += 10
        if let s1 = user1.sleepSchedule, let s2 = user2.sleepSchedule, s1 == s2 {
            breakdown["Sleep"] = 10; score += 10
        } else {
            breakdown["Sleep"] = 0
        }

        // MARK: Budget Overlap (10)
        totalWeight += 10
        if let min1 = user1.budgetMin,
           let max1 = user1.budgetMax,
           let min2 = user2.budgetMin,
           let max2 = user2.budgetMax {
            let overlap = min(max1, max2) - max(min1, min2)
            if overlap > 0 {
                breakdown["Budget"] = 10; score += 10
            } else {
                breakdown["Budget"] = 0
            }
        } else {
            breakdown["Budget"] = 0
        }

        // MARK: College (10)
        totalWeight += 10
        if let c1 = user1.collegeName, let c2 = user2.collegeName, c1 == c2 {
            breakdown["College"] = 10; score += 10
        } else {
            breakdown["College"] = 0
        }

        // MARK: Major (10)
        totalWeight += 10
        if let m1 = user1.major, let m2 = user2.major, m1 == m2 {
            breakdown["Major"] = 10; score += 10
        } else {
            breakdown["Major"] = 0
        }

        // MARK: Distance (10)
        totalWeight += 10
        if let l1 = user1.location, let l2 = user2.location {
            let dist = haversineDistance(
                lat1: l1.latitude, lon1: l1.longitude,
                lat2: l2.latitude, lon2: l2.longitude
            )
            let pts: Double
            switch dist {
            case 0...5:   pts = 10
            case 20...:  pts = 0
            default:     pts = ((20 - dist) / 15) * 10
            }
            breakdown["Distance"] = pts; score += pts
        } else {
            breakdown["Distance"] = 0
        }

        // MARK: Common Interests (10)
        totalWeight += 10.0
                if let i1 = user1.interests, let i2 = user2.interests {
                let common = Set(i1.map { $0.lowercased() })
                               .intersection(Set(i2.map { $0.lowercased() }))
                    let pts: Double = common.isEmpty ? 0.0 : 10.0
                    breakdown["Interests"] = pts
                    score += pts
                } else {
                    breakdown["Interests"] = 0.0
                }

        // MARK: Gender (10)
        totalWeight += 10
        if let g1 = user1.gender, let g2 = user2.gender, g1 == g2 {
            breakdown["Gender"] = 10; score += 10
        } else {
            breakdown["Gender"] = 0
        }

        // MARK: Age Similarity (10)
        totalWeight += 10
        if let d1 = user1.dateOfBirth,
           let d2 = user2.dateOfBirth,
           let date1 = dateFromString(d1),
           let date2 = dateFromString(d2) {
            let a1 = calculateAge(birthDate: date1)
            let a2 = calculateAge(birthDate: date2)
            let diff = abs(a1 - a2)
            let pts: Double
            switch diff {
            case 0...2:   pts = 10
            case 5...:   pts = 0
            default:     pts = ((5 - Double(diff)) / 3) * 10
            }
            breakdown["Age"] = pts; score += pts
        } else {
            breakdown["Age"] = 0
        }

        let overall = (score / totalWeight) * 100
        return (overall, breakdown)
    }

    // MARK: – Helpers

    private static func dateFromString(_ str: String) -> Date? {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.date(from: str)
    }

    private static func calculateAge(birthDate: Date) -> Int {
        Calendar.current.dateComponents([.year], from: birthDate, to: Date()).year ?? 0
    }

    private static func haversineDistance(
        lat1: Double, lon1: Double,
        lat2: Double, lon2: Double
    ) -> Double {
        let R = 6371.0
        let dLat = radians(lat2 - lat1)
        let dLon = radians(lon2 - lon1)
        let a = sin(dLat/2)*sin(dLat/2)
              + cos(radians(lat1))*cos(radians(lat2))
              * sin(dLon/2)*sin(dLon/2)
        let c = 2 * atan2(sqrt(a), sqrt(1-a))
        return R * c
    }

    private static func radians(_ deg: Double) -> Double {
        deg * .pi / 180
    }
}
