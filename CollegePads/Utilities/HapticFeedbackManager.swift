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
    
    func generateImpact(style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }
    
    func generateNotification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(type)
    }
}
