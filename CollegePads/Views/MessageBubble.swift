//
//  MessageBubble.swift
//  CollegePads
//
//  Updated to include support for emoji reactions.
//  When the user long-presses a message, a reaction picker appears.
//  Tapping an emoji calls the onReact callback with the selected emoji.
//  This implementation does not change existing message display functionality.
//

import SwiftUI

struct MessageBubble: View {
    let message: MessageModel
    let isCurrentUser: Bool
    /// Optional callback to handle a reaction being added.
    var onReact: ((String) -> Void)? = nil
    
    @State private var showReactionPicker: Bool = false
    
    // Predefined emoji options for reactions.
    private let reactionEmojis = ["👍", "❤️", "😂", "😮", "😢", "👏"]
    
    var body: some View {
        VStack(alignment: isCurrentUser ? .trailing : .leading, spacing: 4) {
            // Message content with long press gesture.
            HStack {
                if isCurrentUser { Spacer() }
                Text(message.text)
                    .padding()
                    .foregroundColor(.white)
                    .background(isCurrentUser ? Color.blue : Color.gray)
                    .cornerRadius(8)
                    .onLongPressGesture {
                        // Show the reaction picker on long press.
                        withAnimation {
                            showReactionPicker = true
                        }
                    }
                if !isCurrentUser { Spacer() }
            }
            // Optional "Read" indicator.
            if isCurrentUser, let isRead = message.isRead, isRead {
                Text("Read")
                    .font(.caption)
                    .foregroundColor(.green)
                    .padding(.trailing, 8)
            }
            // Display reactions if any exist.
            if let reactions = message.reactions, !reactions.isEmpty {
                HStack(spacing: 4) {
                    ForEach(reactions.keys.sorted(), id: \.self) { emoji in
                        let count = reactions[emoji] ?? 0
                        Text("\(emoji) \(count)")
                            .font(.caption2)
                            .padding(4)
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(4)
                    }
                }
                .padding(.top, 2)
            }
        }
        .overlay(
            // Reaction picker overlay.
            Group {
                if showReactionPicker {
                    ReactionPicker(emojis: reactionEmojis) { selectedEmoji in
                        onReact?(selectedEmoji)
                        withAnimation {
                            showReactionPicker = false
                        }
                    }
                    // Dismiss picker if tapped outside.
                    .onTapGesture {
                        withAnimation {
                            showReactionPicker = false
                        }
                    }
                    .transition(.opacity)
                }
            }
        )
    }
}

/// A small view that displays a row of emoji buttons for reacting.
struct ReactionPicker: View {
    let emojis: [String]
    /// Callback with the emoji selected.
    let onSelect: (String) -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            ForEach(emojis, id: \.self) { emoji in
                Button(action: {
                    onSelect(emoji)
                }) {
                    Text(emoji)
                        .font(.title2)
                        .padding(6)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(8)
        .background(Color(UIColor.systemBackground).opacity(0.9))
        .cornerRadius(10)
        .shadow(radius: 4)
        .padding(.top, -40) // Adjust as needed to position above the message.
    }
}

struct MessageBubble_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            MessageBubble(message: MessageModel(id: "dummy1",
                                                senderID: "123",
                                                text: "Hello!",
                                                timestamp: Date(),
                                                isRead: true,
                                                reactions: ["👍": 2, "❤️": 1]),
                          isCurrentUser: true,
                          onReact: { emoji in print("Reacted with \(emoji)") })
            MessageBubble(message: MessageModel(id: "dummy2",
                                                senderID: "456",
                                                text: "Hi there!",
                                                timestamp: Date(),
                                                isRead: false,
                                                reactions: nil),
                          isCurrentUser: false,
                          onReact: { emoji in print("Reacted with \(emoji)") })
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
