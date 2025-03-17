//
//  MessageBubble.swift
//  CollegePads
//
//  Created by [Your Name] on [Date].
//

import SwiftUI

struct MessageBubble: View {
    let message: MessageModel
    let isCurrentUser: Bool
    
    var body: some View {
        VStack(alignment: isCurrentUser ? .trailing : .leading, spacing: 4) {
            HStack {
                if isCurrentUser { Spacer() }
                Text(message.text)
                    .padding()
                    .foregroundColor(.white)
                    .background(isCurrentUser ? Color.blue : Color.gray)
                    .cornerRadius(8)
                if !isCurrentUser { Spacer() }
            }
            if isCurrentUser, let isRead = message.isRead, isRead {
                Text("Read")
                    .font(.caption)
                    .foregroundColor(.green)
                    .padding(.trailing, 8)
            }
        }
    }
}

struct MessageBubble_Previews: PreviewProvider {
    static var previews: some View {
        MessageBubble(message: MessageModel(id: "dummy", senderID: "123", text: "Hello!", timestamp: Date(), isRead: true), isCurrentUser: true)
            .previewLayout(.sizeThatFits)
    }
}
