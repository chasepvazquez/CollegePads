//
//  SwipeAnalyticsView.swift
//  CollegePads
//
//  Created by [Your Name] on [Date].
//

import SwiftUI

struct SwipeAnalyticsView: View {
    @StateObject private var viewModel = SwipeAnalyticsViewModel()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Swipe Analytics")
                    .font(.largeTitle)
                    .padding()
                
                List {
                    HStack {
                        Text("Total Right Swipes")
                        Spacer()
                        Text("\(viewModel.totalRightSwipes)")
                    }
                    HStack {
                        Text("Total Left Swipes")
                        Spacer()
                        Text("\(viewModel.totalLeftSwipes)")
                    }
                    HStack {
                        Text("Mutual Matches")
                        Spacer()
                        Text("\(viewModel.totalMutualMatches)")
                    }
                    if viewModel.totalRightSwipes + viewModel.totalLeftSwipes > 0 {
                        HStack {
                            Text("Right Swipe Ratio")
                            Spacer()
                            let ratio = Double(viewModel.totalRightSwipes) / Double(viewModel.totalRightSwipes + viewModel.totalLeftSwipes) * 100
                            Text("\(Int(ratio))%")
                        }
                    }
                }
            }
            .navigationTitle("Swipe Analytics")
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
                Alert(title: Text("Error"), message: Text(alertError.message), dismissButton: .default(Text("OK")))
            }
        }
    }
}

struct SwipeAnalyticsView_Previews: PreviewProvider {
    static var previews: some View {
        SwipeAnalyticsView()
    }
}
