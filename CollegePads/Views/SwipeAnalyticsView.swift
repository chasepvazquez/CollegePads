import SwiftUI

struct SwipeAnalyticsView: View {
    @StateObject private var viewModel = SwipeAnalyticsViewModel()
    @State private var isRefreshing: Bool = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Swipe Analytics")
                    .font(AppTheme.titleFont)
                    .padding()
                
                List {
                    HStack {
                        Text("Total Right Swipes")
                            .font(AppTheme.bodyFont)
                        Spacer()
                        Text("\(viewModel.totalRightSwipes)")
                            .font(AppTheme.bodyFont)
                    }
                    HStack {
                        Text("Total Left Swipes")
                            .font(AppTheme.bodyFont)
                        Spacer()
                        Text("\(viewModel.totalLeftSwipes)")
                            .font(AppTheme.bodyFont)
                    }
                    HStack {
                        Text("Mutual Matches")
                            .font(AppTheme.bodyFont)
                        Spacer()
                        Text("\(viewModel.totalMutualMatches)")
                            .font(AppTheme.bodyFont)
                    }
                    if viewModel.totalRightSwipes + viewModel.totalLeftSwipes > 0 {
                        HStack {
                            Text("Right Swipe Ratio")
                                .font(AppTheme.bodyFont)
                            Spacer()
                            let ratio = Double(viewModel.totalRightSwipes) / Double(viewModel.totalRightSwipes + viewModel.totalLeftSwipes) * 100
                            Text("\(Int(ratio))%")
                                .font(AppTheme.bodyFont)
                        }
                    }
                }
                .listStyle(PlainListStyle())
                .scrollContentBackground(.hidden)
                
                if isRefreshing {
                    ProgressView("Refreshing Analytics...")
                        .font(AppTheme.bodyFont)
                        .padding()
                }
            }
            .navigationTitle("Swipe Analytics")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: refreshAnalytics) {
                        Image(systemName: "arrow.clockwise")
                    }
                    .accessibilityLabel("Refresh Analytics")
                }
            }
            .onAppear {
                viewModel.loadSwipeAnalytics()
            }
            .alert(item: Binding(
                get: {
                    if let errorMessage = viewModel.errorMessage {
                        return GenericAlertError(message: errorMessage)
                    }
                    return nil
                },
                set: { _ in viewModel.errorMessage = nil }
            )) { alertError in
                Alert(title: Text("Error"),
                      message: Text(alertError.message),
                      dismissButton: .default(Text("OK")))
            }
        }
    }
    
    private func refreshAnalytics() {
        isRefreshing = true
        viewModel.loadSwipeAnalytics()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            isRefreshing = false
        }
    }
}

struct SwipeAnalyticsView_Previews: PreviewProvider {
    static var previews: some View {
        SwipeAnalyticsView()
    }
}
