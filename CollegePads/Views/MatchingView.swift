//
//  MatchingView.swift
//  CollegePads
//
//  Created by [Your Name] on [Date].
//

import SwiftUI

struct MatchingView: View {
    @StateObject private var viewModel = MatchingViewModel()
    
    var body: some View {
        ZStack {
            if viewModel.potentialMatches.isEmpty {
                Text("No more matches")
                    .font(.title)
            } else {
                ForEach(viewModel.potentialMatches) { user in
                    SwipeCardView(user: user) { swipedUser, direction in
                        handleSwipe(user: swipedUser, direction: direction)
                    }
                }
            }
        }
        .onAppear {
            viewModel.fetchPotentialMatches()
        }
        .alert(item: Binding(
            get: {
                if let errorMessage = viewModel.errorMessage {
                    return AlertError(message: errorMessage)
                }
                return nil
            },
            set: { _ in viewModel.errorMessage = nil }
        )) { alertError in
            Alert(title: Text("Error"), message: Text(alertError.message), dismissButton: .default(Text("OK")))
        }
    }
    
    private func handleSwipe(user: UserModel, direction: SwipeDirection) {
        switch direction {
        case .right:
            viewModel.swipeRight(on: user)
        case .left:
            viewModel.swipeLeft(on: user)
        }
        if let index = viewModel.potentialMatches.firstIndex(where: { $0.id == user.id }) {
            viewModel.potentialMatches.remove(at: index)
        }
    }
}

struct AlertError: Identifiable {
    let id = UUID()
    let message: String
}

struct MatchingView_Previews: PreviewProvider {
    static var previews: some View {
        MatchingView()
    }
}
