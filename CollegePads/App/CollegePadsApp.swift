//
//  CollegePadsApp.swift
//  CollegePads
//
//  Created by Chase Vazquez on 3/6/25.
//

import SwiftUI
import SwiftData
import Firebase

@main
struct CollegePadsApp: App {
    // Initialize Firebase on app startup
    init() {
        FirebaseApp.configure()
    }
    
    // SwiftData container (if you plan to use it locally)
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    
    var body: some Scene {
        WindowGroup {
            // RootView determines which UI to display based on auth state
            RootView()
                .modelContainer(sharedModelContainer)
        }
    }
}
