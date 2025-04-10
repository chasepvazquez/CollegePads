import SwiftUI

struct MessageBubble: View {
    let message: MessageModel
    let isCurrentUser: Bool
    var onReact: ((String) -> Void)? = nil
    
    @State private var showReactionPicker: Bool = false
    private let reactionEmojis = ["👍", "❤️", "😂", "😮", "😢", "👏"]
    
    var body: some View {
        VStack(alignment: isCurrentUser ? .trailing : .leading, spacing: 4) {
            HStack {
                if isCurrentUser { Spacer() }
                Text(message.text)
                    .padding()
                    .foregroundColor(.white)
                    .background(isCurrentUser ? AppTheme.primaryColor : AppTheme.secondaryColor)
                    .cornerRadius(8)
                    .onLongPressGesture {
                        withAnimation {
                            showReactionPicker = true
                        }
                    }
                if !isCurrentUser { Spacer() }
            }
            if isCurrentUser, let isRead = message.isRead, isRead {
                Text("Read")
                    .font(AppTheme.bodyFont)
                    .foregroundColor(AppTheme.accentColor)
                    .padding(.trailing, 8)
            }
            if let reactions = message.reactions, !reactions.isEmpty {
                HStack(spacing: 4) {
                    ForEach(reactions.keys.sorted(), id: \.self) { emoji in
                        let count = reactions[emoji] ?? 0
                        Text("\(emoji) \(count)")
                            .font(AppTheme.bodyFont)
                            .padding(4)
                            .background(AppTheme.secondaryColor.opacity(0.2))
                            .cornerRadius(4)
                    }
                }
                .padding(.top, 2)
            }
        }
        .overlay(
            Group {
                if showReactionPicker {
                    ReactionPicker(emojis: reactionEmojis) { selectedEmoji in
                        onReact?(selectedEmoji)
                        withAnimation {
                            showReactionPicker = false
                        }
                    }
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

struct ReactionPicker: View {
    let emojis: [String]
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
        .background(AppTheme.cardBackground.opacity(0.9))
        .cornerRadius(10)
        .shadow(radius: 4)
        .padding(.top, -40)
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
