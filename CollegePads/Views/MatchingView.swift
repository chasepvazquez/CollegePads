import SwiftUI

struct MatchingView: View {
    var body: some View {
        ZStack {
            // Global background gradient from your theme.
            AppTheme.backgroundGradient
                .ignoresSafeArea()
            
            SwipeDeckView()
        }
        .navigationTitle("Swipe to Match")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    // Optional refresh action
                }) {
                    Image(systemName: "arrow.clockwise")
                }
            }
        }
    }
}

struct MatchingView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            MatchingView()
        }
    }
}
