import SwiftUI

enum ChatOption {
    case rate
    case agreement
}

struct ChatInputBar: View {
    @Binding var messageText: String
    var onSend: () -> Void
    var onOptionSelected: (ChatOption) -> Void
    
    @State private var showOptions: Bool = false
    
    var body: some View {
        HStack(spacing: 8) {
            // Plus icon to open the options menu.
            Button(action: {
                showOptions = true
            }) {
                Image(systemName: "plus.circle")
                    .font(.system(size: 24))
                    .foregroundColor(AppTheme.primaryColor)
            }
            .confirmationDialog("Options", isPresented: $showOptions, titleVisibility: .visible) {
                Button("Rate Roommate") {
                    onOptionSelected(.rate)
                }
                Button("Create Agreement") {
                    onOptionSelected(.agreement)
                }
                Button("Cancel", role: .cancel) { }
            }
            
            TextEditor(text: $messageText)
                .frame(minHeight: 40, maxHeight: 100)
                .padding(8)
                .background(AppTheme.cardBackground)
                .cornerRadius(AppTheme.defaultCornerRadius)
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.defaultCornerRadius)
                        .stroke(AppTheme.secondaryColor.opacity(0.3), lineWidth: 1)
                )
                .font(AppTheme.bodyFont)
            
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
        ChatInputBar(messageText: .constant("Type a message..."), onSend: {}, onOptionSelected: { _ in })
            .previewLayout(.sizeThatFits)
    }
}
