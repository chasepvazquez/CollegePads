//
//  MatchingView.swift
//  CollegePads
//
//  Created by [Your Name] on [Date].
//

import SwiftUI

struct MatchingView: View {
    @StateObject private var viewModel = MatchingViewModel()
    @State private var currentIndex = 0
    
    var body: some View {
        ZStack {
            ForEach(viewModel.potentialMatches.indices.reversed(), id: \.self) { index in
                let user = viewModel.potentialMatches[index]
                SwipeCardView(user: user) { swipedUser, direction in
                    handleSwipe(user: swipedUser, direction: direction, index: index)
                }
                .padding(8)
                .offset(y: CGFloat(index - currentIndex) * 5)
                .allowsHitTesting(index == currentIndex)
            }
        }
        .onAppear {
            viewModel.fetchPotentialMatches()
        }
        .navigationTitle("Swipe to Match")
        .toolbar {
            // optional refresh or filter button
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    viewModel.fetchPotentialMatches()
                    currentIndex = 0
                }) {
                    Image(systemName: "arrow.clockwise")
                }
            }
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
    
    func handleSwipe(user: UserModel, direction: SwipeDirection, index: Int) {
        if direction == .right {
            viewModel.swipeRight(on: user)
        } else {
            viewModel.swipeLeft(on: user)
        }
        // Move to the next card
        withAnimation {
            currentIndex += 1
        }
    }
}
