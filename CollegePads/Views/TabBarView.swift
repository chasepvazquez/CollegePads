//
//  TabBarView.swift
//  CollegePads
//
//  Updated to include a dedicated Global Search tab.
//  The current tabs remain as Swipe, Messages, and Home—profile functionality is retained in Home per your preference.
//  Global Search is added as an extra tab for comprehensive, cross‑section searching.
//  Inline documentation provided for clarity.
//

import SwiftUI

struct TabBarView: View {
    var body: some View {
        TabView {
            // Swipe Tab: Remains unchanged (shows MatchingView)
            MatchingView()
                .tabItem {
                    Image(systemName: "flame.fill")
                    Text("Swipe")
                }
            
            // Messages Tab: Remains unchanged (shows CombinedMatchesChatView)
            CombinedMatchesChatView()
                .tabItem {
                    Image(systemName: "bubble.left.and.bubble.right.fill")
                    Text("Messages")
                }
            
            // Home Tab: Retains current HomeView which includes profile information and other home-related features.
            HomeView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
                }
            
            // Global Search Tab: New tab dedicated to the Global Search feature.
            // Tapping this tab presents the GlobalSearchView, which uses GlobalSearchViewModel for searching across users and listings.
            GlobalSearchView()
                .tabItem {
                    Image(systemName: "magnifyingglass")
                    Text("Search")
                }
        }
        .accentColor(AppTheme.accentColor)  // Use the global accent color from AppTheme.
    }
}

struct TabBarView_Previews: PreviewProvider {
    static var previews: some View {
        TabBarView()
    }
}
