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
    // Initialize Firebase in the app's init
    init() {
        FirebaseApp.configure()
        // Any other one-time setup code can go here
    }

    // Your SwiftData container (if you plan to use SwiftData locally)
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
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
