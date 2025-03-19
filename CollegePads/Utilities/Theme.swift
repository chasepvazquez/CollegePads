//
//  Theme.swift
//  CollegePads
//
//  Created by [Your Name] on [Date].
//
//  This file defines the global theme for CollegePads, including brand colors,
//  fonts, and custom button styles. All views should use these styles for a unified appearance.

import SwiftUI

// Global brand colors.
extension Color {
    static let brandPrimary = Color(red: 0.10, green: 0.60, blue: 0.90)   // A strong blue
    static let brandSecondary = Color(red: 0.95, green: 0.50, blue: 0.20) // A vibrant orange
    static let brandAccent = Color(red: 0.90, green: 0.20, blue: 0.20)    // A bold red (for alerts, etc.)
    static let brandBackground = Color(UIColor.systemGray6)
}

// Custom button style for primary actions.
struct PrimaryButtonStyle: ButtonStyle {
    var backgroundColor: Color = .brandPrimary
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(.white)
            .padding()
            .frame(maxWidth: .infinity)
            .background(backgroundColor)
            .cornerRadius(10)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
    }
}

// Custom button style for secondary actions (e.g., alerts, warnings).
struct SecondaryButtonStyle: ButtonStyle {
    var backgroundColor: Color = .brandSecondary
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(.white)
            .padding()
            .frame(maxWidth: .infinity)
            .background(backgroundColor)
            .cornerRadius(10)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
    }
}
