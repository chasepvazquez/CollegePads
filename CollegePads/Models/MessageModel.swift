//
//  MessageModel.swift
//  CollegePads
//
//  Created by [Your Name] on [Date].
//

import Foundation

/// A simple message model without @DocumentID.
struct MessageModel: Identifiable {
    var id: String?        // doc.documentID
    var senderID: String
    var text: String
    var timestamp: Date
}
