//
//  TabBarView.swift
//  CollegePads
//
//  Created by [Your Name] on [Date].
//

import SwiftUI

struct TabBarView: View {
    var body: some View {
        TabView {
            // Home Tab: shows the swipe-based matching interface
            MainView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
                }
            
            // Matches Tab: shows the chats/matches (using ChatsListView)
            ChatsListView()
                .tabItem {
                    Image(systemName: "heart.circle.fill")
                    Text("Matches")
                }
            
            // Search Tab: Advanced filter view for searching candidates
            AdvancedFilterView()
                .tabItem {
                    Image(systemName: "magnifyingglass")
                    Text("Search")
                }
            
            // Profile Tab: Profile setup/update view
            ProfileSetupView()
                .tabItem {
                    Image(systemName: "person.crop.circle")
                    Text("Profile")
                }
            
            // Settings Tab: Global settings for the app
            SettingsView()
                .tabItem {
                    Image(systemName: "gearshape.fill")
                    Text("Settings")
                }
        }
    }
}

struct TabBarView_Previews: PreviewProvider {
    static var previews: some View {
        TabBarView()
    }
}
