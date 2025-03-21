import SwiftUI

struct AppTheme {
    // MARK: - Colors
    static let primaryColor = Color("PrimaryColor")         // e.g., deep blue
    static let secondaryColor = Color("SecondaryColor")     // e.g., vibrant teal
    static let accentColor = Color("AccentColor")           // e.g., bright orange
    static let backgroundStart = Color("BackgroundStart")   // e.g., soft light gray
    static let backgroundEnd = Color("BackgroundEnd")       // e.g., slightly darker gray
    static let cardBackground = Color("CardBackground")     // e.g., light off-white (#F8F8F8 in light mode, #2C2C2E in dark mode)
    
    // New properties for reaction feedback overlays:
    static let likeColor = Color("LikeColor")               // e.g., a pleasant green
    static let nopeColor = Color("NopeColor")               // e.g., a noticeable red

    // MARK: - Gradient Background
    static var backgroundGradient: LinearGradient {
        LinearGradient(gradient: Gradient(colors: [backgroundStart, backgroundEnd]),
                       startPoint: .topLeading,
                       endPoint: .bottomTrailing)
    }
    
    // MARK: - Typography
    static let titleFont = Font.custom("AvenirNext-Bold", size: 24)
    static let subtitleFont = Font.custom("AvenirNext-Medium", size: 18)
    static let bodyFont = Font.custom("AvenirNext-Regular", size: 16)
    
    // MARK: - Spacing & Corner Radius
    static let defaultCornerRadius: CGFloat = 12
    static let defaultPadding: CGFloat = 16
}
