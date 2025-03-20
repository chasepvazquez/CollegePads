//
//  TabBarView.swift
//  CollegePads
//
//  Created by [Your Name] on [Date]
//

import SwiftUI

struct TabBarView: View {
    var body: some View {
        TabView {
            // Swipe Tab remains.
            MatchingView()
                .tabItem {
                    Image(systemName: "flame.fill")
                    Text("Swipe")
                }
            
            // New Combined Matches & Chat Tab.
            CombinedMatchesChatView()
                .tabItem {
                    Image(systemName: "bubble.left.and.bubble.right.fill")
                    Text("Messages")
                }
            
            // Updated Home Tab (consolidated Home view).
            HomeView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
                }
        }
        .accentColor(.brandAccent)
    }
}

struct TabBarView_Previews: PreviewProvider {
    static var previews: some View {
        TabBarView()
    }
}
