import SwiftUI

struct PrimaryButtonStyle: ButtonStyle {
    var backgroundColor: Color = AppTheme.primaryColor
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppTheme.bodyFont.weight(.semibold))
            .padding()
            .frame(maxWidth: .infinity)
            .background(backgroundColor.opacity(configuration.isPressed ? 0.7 : 1.0))
            .foregroundColor(.white)
            .cornerRadius(AppTheme.defaultCornerRadius)
            .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
            .padding(.horizontal, AppTheme.defaultPadding)
    }
}

struct PrimaryButtonStyle_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            Button("Primary Button") { }
                .buttonStyle(PrimaryButtonStyle())
            Button("Custom Color Button") { }
                .buttonStyle(PrimaryButtonStyle(backgroundColor: AppTheme.accentColor))
        }
        .padding()
        .background(AppTheme.backgroundGradient)
        .previewLayout(.sizeThatFits)
    }
}
