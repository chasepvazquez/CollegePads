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
            MatchingView()
                .tabItem {
                    Image(systemName: "flame.fill")
                    Text("Swipe")
                }
            
            MatchesDashboardView()
                .tabItem {
                    Image(systemName: "heart.fill")
                    Text("Matches")
                }
            
            ChatsListView()
                .tabItem {
                    Image(systemName: "bubble.left.and.bubble.right.fill")
                    Text("Chats")
                }
            
            ProfileSetupView()
                .tabItem {
                    Image(systemName: "person.crop.circle")
                    Text("Profile")
                }
        }
        .accentColor(.red)
    }
}

struct TabBarView_Previews: PreviewProvider {
    static var previews: some View {
        TabBarView()
    }
}
