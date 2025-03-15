//
//  MessageModel.swift
//  CollegePads
//
//  Created by [Your Name] on [Date].
//

import Foundation
import FirebaseFirestoreCombineSwift

struct MessageModel: Codable, Identifiable {
    // Remove @DocumentID so we can satisfy Codable requirements.
    // We'll assign the document ID manually in our view model.
    var id: String?
    var senderID: String
    var text: String
    var timestamp: Date
    var isRead: Bool?
    
    enum CodingKeys: String, CodingKey {
        case senderID, text, timestamp, isRead
    }
}
