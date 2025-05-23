import SwiftUI
import CoreLocation

struct SwipeDeckView: View {
    @StateObject private var viewModel = MatchingViewModel()
    @State private var currentIndex: Int = 0
    @State private var showFilter: Bool = false
        #if DEBUG
        /// Debug‑only: show the Match Inspector
        @State private var showInspector: Bool = false
        #endif

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
                // 1️⃣ compute which tabs to show *once*, up here:
                let status = ProfileViewModel.shared.userProfile?.housingStatus
                let availableFilters: [DeckFilter] = {
                    switch status {
                    case PrimaryHousingPreference.lookingForLease.rawValue:
                        return [.personal, .lease]
                    // both roommate & together → personal only
                    case PrimaryHousingPreference.lookingForRoommate.rawValue,
                         PrimaryHousingPreference.lookingToFindTogether.rawValue:
                        return [.personal]
                    default:
                        return [.personal]
                    }
                }()

                VStack {
                    // 2️⃣ render only those segments
                    Picker("", selection: $deckFilter) {
                        ForEach(availableFilters) { f in
                            Text(f.rawValue).tag(f)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal)
                    .padding(.top, 8)

                    Spacer()
                }
                // 3️⃣ now it’s valid to attach modifiers to the VStack
                .onAppear {
                    if !availableFilters.contains(deckFilter) {
                        deckFilter = .personal
                    }
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
            VStack {
                HStack(spacing: 8) {
                    Spacer()
                    Button(action: refresh) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 24))
                    }
                    .padding(.horizontal, 8)
                    
                    Button(action: { showFilter = true }) {
                        Image(systemName: "line.horizontal.3.decrease.circle")
                            .font(.system(size: 24))
                    }
                    .padding(.horizontal, 8)
                }
                Spacer()
            }
            // Only one bottomControls now
            bottomControls
        }
        .navigationBarTitle("", displayMode: .inline)
        .navigationBarHidden(true)
        .onAppear { viewModel.fetchPotentialMatches() }
        .sheet(isPresented: $showFilter) {AdvancedFilterView() }
        .onChange(of: showFilter) { isPresented in
            // when filter sheet dismisses:
            if !isPresented {
                viewModel.fetchPotentialMatches()
                deckFilter = .personal
                currentIndex = 0
            }
        }
#if DEBUG
   .sheet(isPresented: $showInspector) {
       if let me = ProfileViewModel.shared.userProfile,
          let fs = me.filterSettings {
           DebugMatchInspectorView(
             vm: DebugInspectorViewModel(
                   filterSettings: fs,
                   currentUser: me
             )
           )
       } else {
           Text("No filter settings available")
               .padding()
       }
   }
   #endif
    }
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

                // Super Like Button (new icon, color, and disabled state)
                Button(action: superLike) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.pink)
                }
                .disabled(currentIndex >= viewModel.potentialMatches.count)
            }
            .padding(.bottom, 30)

                   #if DEBUG
                   Button("🔍 Inspect Matches") {
                       showInspector = true
                   }
                   .font(.system(size: 14, weight: .semibold))
                   .padding(.bottom, 16)
                   #endif
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
    /// Resets the deck and re‑fetches matches.
    private func refresh() {
        withAnimation { currentIndex = 0 }
        viewModel.fetchPotentialMatches()
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
