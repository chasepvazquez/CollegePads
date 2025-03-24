import SwiftUI

struct MatchingView: View {
    var body: some View {
        ZStack {
            AppTheme.backgroundGradient.ignoresSafeArea()
            SwipeDeckView()
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Swipe to Match")
                    .font(AppTheme.titleFont)
                    .foregroundColor(.primary)
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    // Optional refresh action.
                }) {
                    Image(systemName: "arrow.clockwise")
                }
                .font(AppTheme.bodyFont)
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
