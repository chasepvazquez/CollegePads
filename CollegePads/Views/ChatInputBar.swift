import SwiftUI

struct ChatInputBar: View {
    @Binding var messageText: String
    var onSend: () -> Void

    var body: some View {
        HStack {
            TextEditor(text: $messageText)
                .frame(minHeight: 40, maxHeight: 100)
                .padding(8)
                .background(AppTheme.cardBackground)
                .cornerRadius(AppTheme.defaultCornerRadius)
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.defaultCornerRadius)
                        .stroke(AppTheme.secondaryColor.opacity(0.3), lineWidth: 1)
                )
            
            Button(action: {
                onSend()
                HapticFeedbackManager.shared.generateImpact(style: .medium)
            }) {
                Image(systemName: "paperplane.fill")
                    .foregroundColor(messageText.isEmpty ? AppTheme.secondaryColor : AppTheme.primaryColor)
                    .padding(10)
                    .background(Circle().fill(AppTheme.primaryColor.opacity(0.7)))
            }
            .disabled(messageText.isEmpty)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(AppTheme.backgroundGradient.ignoresSafeArea())
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
