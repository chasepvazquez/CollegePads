//
//  ChatInputBar.swift
//  CollegePads
//
//  Created by [Your Name] on [Date].
//

import SwiftUI

struct ChatInputBar: View {
    @Binding var messageText: String
    var onSend: () -> Void

    var body: some View {
        HStack {
            TextEditor(text: $messageText)
                .frame(minHeight: 40, maxHeight: 100)
                .padding(8)
                .background(Color(UIColor.systemGray6))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(UIColor.systemGray4), lineWidth: 1)
                )
            
            Button(action: {
                onSend()
            }) {
                Image(systemName: "paperplane.fill")
                    .foregroundColor(messageText.isEmpty ? Color.gray : Color.blue)
                    .padding(10)
                    .background(Circle().fill(Color(UIColor.systemGray5)))
            }
            .disabled(messageText.isEmpty)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(UIColor.systemBackground).opacity(0.95))
    }
}

struct ChatInputBar_Previews: PreviewProvider {
    static var previews: some View {
        ChatInputBar(messageText: .constant("Type a message...")) {
            print("Send tapped")
        }
        .previewLayout(.sizeThatFits)
    }
}
