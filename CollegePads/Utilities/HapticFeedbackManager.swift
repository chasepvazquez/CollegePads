//
//  HapticFeedbackManager.swift
//  CollegePads
//
//  Created by [Your Name] on [Date].
//

import UIKit

class HapticFeedbackManager {
    static let shared = HapticFeedbackManager()
    private init() {}
    
    /// Generates a basic impact feedback.
    func generateImpact(style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }
    
    /// Generates a notification feedback.
    func generateNotification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(type)
    }
}
