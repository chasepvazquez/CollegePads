//
//  SwipeDeckView.swift
//  CollegePads
//
//  Created by [Your Name] on [Date].
//

import SwiftUI

struct SwipeDeckView: View {
    @StateObject private var viewModel = MatchingViewModel()
    @State private var currentIndex: Int = 0

    var body: some View {
        ZStack {
            if viewModel.potentialMatches.isEmpty {
                Text("No more matches")
                    .font(.title)
            } else {
                ForEach(viewModel.potentialMatches.indices.reversed(), id: \.self) { index in
                    if index >= currentIndex {
                        let user = viewModel.potentialMatches[index]
                        SwipeCardView(user: user) { swipedUser, direction in
                            handleSwipe(user: swipedUser, direction: direction)
                        }
                        .scaleEffect(scale(for: index))
                        .offset(y: offset(for: index))
                        .allowsHitTesting(index == currentIndex)
                        .transition(.slide)
                        .animation(.spring(), value: currentIndex)
                    }
                }
            }
            
            // Bottom control buttons: Rewind & Super Like
            VStack {
                Spacer()
                HStack(spacing: 40) {
                    Button(action: rewindSwipe) {
                        Image(systemName: "gobackward")
                            .font(.system(size: 32))
                            .foregroundColor(currentIndex > 0 ? .blue : .gray)
                    }
                    .disabled(currentIndex == 0)
                    
                    Button(action: superLike) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 32))
                            .foregroundColor(.yellow)
                    }
                }
                .padding(.bottom, 30)
            }
        }
        .onAppear {
            viewModel.fetchPotentialMatches()
        }
    }
    
    private func handleSwipe(user: UserModel, direction: SwipeDirection) {
        if direction == .right {
            viewModel.swipeRight(on: user)
        } else {
            viewModel.swipeLeft(on: user)
        }
        withAnimation {
            currentIndex += 1
        }
    }
    
    private func rewindSwipe() {
        guard currentIndex > 0 else { return }
        withAnimation {
            currentIndex -= 1
        }
    }
    
    private func superLike() {
        if currentIndex < viewModel.potentialMatches.count {
            let user = viewModel.potentialMatches[currentIndex]
            viewModel.superLike(on: user)
            withAnimation {
                currentIndex += 1
            }
        }
    }
    
    private func scale(for index: Int) -> CGFloat {
        return index == currentIndex ? 1.0 : 0.95
    }
    
    private func offset(for index: Int) -> CGFloat {
        return CGFloat(index - currentIndex) * 10
    }
}

struct SwipeDeckView_Previews: PreviewProvider {
    static var previews: some View {
        SwipeDeckView()
    }
}
