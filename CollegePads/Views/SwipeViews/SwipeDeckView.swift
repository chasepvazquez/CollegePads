import SwiftUI
import CoreLocation

struct SwipeDeckView: View {
    @StateObject private var viewModel = MatchingViewModel()
    @State private var currentIndex: Int = 0
    @State private var showFilter: Bool = false

    // 🔹 Replace Bool with a three‑way enum
    private enum DeckFilter: String, CaseIterable, Identifiable {
        case personal  = "Personal"
        case lease     = "Lease"
        case together  = "Together"
        var id: String { rawValue }
    }
    @State private var deckFilter: DeckFilter = .personal

    // Only show the toggle if *you* are looking for Lease *or* Find‑Together
    private let myStatus = ProfileViewModel.shared.userProfile?.housingStatus

    var body: some View {
        ZStack {
            AppTheme.backgroundGradient.ignoresSafeArea()

            // ● Three‑way toggle
            if myStatus == PrimaryHousingPreference.lookingForLease.rawValue
               || myStatus == PrimaryHousingPreference.lookingToFindTogether.rawValue
            {
                VStack {
                    Picker("", selection: $deckFilter) {
                        ForEach(DeckFilter.allCases) { f in
                            Text(f.rawValue).tag(f)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal)
                    .padding(.top, 8)
                    Spacer()
                }
            }

            // ● Decide which subset to show
            let matches: [UserModel] = {
                switch deckFilter {
                case .personal:
                    // Everything your SmartMatchingEngine already returned
                    return viewModel.potentialMatches

                case .lease:
                    // Only show people looking for roommates
                    return viewModel.potentialMatches.filter {
                        $0.housingStatus == PrimaryHousingPreference.lookingForRoommate.rawValue
                    }

                case .together:
                    // Only show people in the “find together” pool
                    return viewModel.potentialMatches.filter {
                        let s = $0.housingStatus ?? ""
                        return s == PrimaryHousingPreference.lookingToFindTogether.rawValue
                            || s == PrimaryHousingPreference.lookingForLease.rawValue
                    }
                }
            }()

            if matches.isEmpty {
                Text("No more potential matches")
                    .font(AppTheme.titleFont)
                    .foregroundColor(.secondary)
            } else {
                ForEach(matches.indices.reversed(), id: \.self) { index in
                    if index >= currentIndex {
                        let candidate = matches[index]
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

            VStack {
                HStack {
                    Spacer()
                    Button(action: { showFilter = true }) {
                        Image(systemName: "line.horizontal.3.decrease.circle")
                            .font(.system(size: 24))
                            .padding()
                    }
                }
                Spacer()
            }
        }
        .onAppear { viewModel.fetchPotentialMatches() }
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
