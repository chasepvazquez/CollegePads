//
//  MessageModel.swift
//  CollegePads
//
//  Created by [Your Name] on [Date].
//

import Foundation
import FirebaseFirestoreCombineSwift

struct MessageModel: Identifiable, Codable {
    var id: String?
    let senderID: String
    let text: String
    let timestamp: Date
    var isRead: Bool?
    var reactions: [String: Int]? = nil
    
    enum CodingKeys: String, CodingKey {
        case senderID, text, timestamp, isRead
    }
}
