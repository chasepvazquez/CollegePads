//
//  GenericAlertError.swift
//  CollegePads
//
//  Created by [Your Name] on [Date].
//

import Foundation

/// A simple, reusable alert error that conforms to Identifiable.
struct GenericAlertError: Identifiable {
    let id = UUID()
    let message: String
}
