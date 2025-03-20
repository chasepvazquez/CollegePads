//
//  ListingModel.swift
//  CollegePads
//
//  Created by [Your Name] on [Date]
//

import Foundation
import FirebaseFirestore
import FirebaseFirestoreCombineSwift
import CoreLocation

struct ListingModel: Codable, Identifiable {
    @DocumentID var id: String?
    var title: String
    var address: String
    var rent: String
    var imageUrl: String?
    var location: GeoPoint? // NEW: Single location field as GeoPoint
    var createdAt: Date = Date()
}

extension ListingModel {
    /// Computes a CLLocationCoordinate2D from the stored GeoPoint.
    var coordinate: CLLocationCoordinate2D {
        if let loc = location {
            return CLLocationCoordinate2D(latitude: loc.latitude, longitude: loc.longitude)
        }
        // Default coordinate if location is missing.
        return CLLocationCoordinate2D(latitude: 0, longitude: 0)
    }
}
