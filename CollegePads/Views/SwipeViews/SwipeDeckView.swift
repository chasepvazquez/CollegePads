import SwiftUI
import CoreLocation

/// A deck of swipeable user cards with rewind and super-like buttons.
struct SwipeDeckView: View {
    @StateObject private var viewModel = MatchingViewModel()
    @State private var currentIndex: Int = 0
    @State private var showFilter: Bool = false
    
    var body: some View {
        ZStack {
            AppTheme.backgroundGradient.ignoresSafeArea()
            
            if viewModel.potentialMatches.isEmpty {
                Text("No more potential matches")
                    .font(AppTheme.titleFont)
                    .foregroundColor(.secondary)
            } else {
                ForEach(viewModel.potentialMatches.indices.reversed(), id: \.self) { index in
                    if index >= currentIndex {
                        let candidate = viewModel.potentialMatches[index]
                        SwipeCardView(user: candidate) { swipedUser, direction in
                            handleSwipe(user: swipedUser, direction: direction)
                        }
                        .scaleEffect(scale(for: index))
                        .offset(y: offset(for: index))
                        .allowsHitTesting(index == currentIndex)
                        .transition(.slide)
                        .animation(.interactiveSpring(response: 0.5,
                                                      dampingFraction: 0.7,
                                                      blendDuration: 0.3),
                                   value: currentIndex)
                    }
                }
            }
            
            bottomControls
            
            // Filter Icon Button overlay
            VStack {
                HStack {
                    Spacer()
                    Button(action: {
                        showFilter = true
                    }) {
                        Image(systemName: "line.horizontal.3.decrease.circle")
                            .font(.system(size: 24))
                            .padding()
                    }
                }
                Spacer()
            }
        }
        .onAppear {
            viewModel.fetchPotentialMatches()
        }
        .sheet(isPresented: $showFilter) {
            AdvancedFilterView()
        }
    }
    
    // MARK: - Bottom Controls
    private var bottomControls: some View {
        VStack {
            Spacer()
            HStack(spacing: 40) {
                // Rewind Button
                Button(action: rewindSwipe) {
                    Image(systemName: "gobackward")
                        .font(.system(size: 32))
                        .foregroundColor(currentIndex > 0 ? .blue : .gray)
                }
                .disabled(currentIndex == 0)
                
                // Super Like Button
                Button(action: superLike) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.yellow)
                }
            }
            .padding(.bottom, 30)
        }
    }
    
    // MARK: - Swipe Logic
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
    
    // MARK: - Visual Helpers
    private func scale(for index: Int) -> CGFloat {
        index == currentIndex ? 1.0 : 0.95
    }
    
    private func offset(for index: Int) -> CGFloat {
        CGFloat(index - currentIndex) * 10
    }
}

struct SwipeDeckView_Previews: PreviewProvider {
    static var previews: some View {
        SwipeDeckView()
    }
}
