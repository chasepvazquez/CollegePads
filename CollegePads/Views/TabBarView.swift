import SwiftUI

struct TabBarView: View {
    var body: some View {
        TabView {
            // Swipe Tab.
            MatchingView()
                .tabItem {
                    Image(systemName: "flame.fill")
                    Text("Swipe")
                }
            
            // Messages Tab.
            CombinedMatchesChatView()
                .tabItem {
                    Image(systemName: "bubble.left.and.bubble.right.fill")
                    Text("Messages")
                }
            
            // Home Tab.
            HomeView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
                }
            
            // Global Search Tab.
            GlobalSearchView()
                .tabItem {
                    Image(systemName: "magnifyingglass")
                    Text("Search")
                }
        }
        .accentColor(AppTheme.accentColor)
    }
}

struct TabBarView_Previews: PreviewProvider {
    static var previews: some View {
        TabBarView()
    }
}
