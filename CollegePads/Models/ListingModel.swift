//
//  ListingModel.swift
//  CollegePads
//
//  Created by [Your Name] on [Date].
//

import Foundation
import FirebaseFirestore
import FirebaseFirestoreCombineSwift

struct ListingModel: Codable, Identifiable {
    @DocumentID var id: String?
    var title: String
    var address: String
    var rent: String
    var imageUrl: String?
    var latitude: Double?
    var longitude: Double?
    var createdAt: Date = Date()
}
