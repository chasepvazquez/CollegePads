import SwiftUI
import FirebaseFirestore

struct SwipeCardView: View {
    // Internal storage: either a fully provided candidate or loaded from candidateID.
    private let initialUser: UserModel?
    private let candidateID: String?
    var onSwipe: (_ user: UserModel, _ direction: SwipeDirection) -> Void = { _, _ in }
    
    // State for loaded candidate if candidateID initializer is used.
    @State private var loadedUser: UserModel?
    
    @State private var offset: CGSize = .zero
    @State private var rotation: Double = 0
    @State private var showLikeOverlay: Bool = false
    @State private var showNopeOverlay: Bool = false
    @State private var showSuperLikeOverlay: Bool = false

    // 🔹 singletons for Firestore & favorites
    private let db = Firestore.firestore()
    
    // Pull the current user from a shared view model if needed.
    var currentUser: UserModel? {
        ProfileViewModel.shared.userProfile
    }
    
    // Use the provided candidate if available; otherwise, use the loaded candidate.
    var user: UserModel? {
        initialUser ?? loadedUser
    }
    
    // Example compatibility score.
    var compatibilityScore: Double? {
      guard let me = currentUser, let them = user else { return nil }
      return SmartMatchingEngine.calculateSmartMatchScore(between: me, and: them)
    }
    
    // MARK: - Initializers
    
    /// Initialize with a full UserModel.
    init(user: UserModel, onSwipe: @escaping (_ user: UserModel, _ direction: SwipeDirection) -> Void) {
        self.initialUser = user
        self.candidateID = nil
        self.onSwipe = onSwipe
    }
    
    /// Initialize with a candidateID; candidate data will be loaded from Firestore.
    init(candidateID: String) {
        self.candidateID = candidateID
        self.initialUser = nil
    }
    
    var body: some View {
        ZStack {
            AppTheme.backgroundGradient
                .cornerRadius(AppTheme.defaultCornerRadius)
                .shadow(radius: 5)
            
            if let candidate = user {
                // Determine if the candidate’s preview should be forced into lease mode.
                let currentUserStatus = ProfileViewModel.shared.userProfile?.housingStatus
                let forcedPreview: PreviewMode? = (currentUserStatus == PrimaryHousingPreference.lookingForLease.rawValue &&
                                                   candidate.housingStatus == PrimaryHousingPreference.lookingForRoommate.rawValue)
                                                  ? .lease : nil
                // Use the ProfilePreviewView as the card content.
                ProfilePreviewView(user: candidate, forcePreviewMode: forcedPreview)
                    .cornerRadius(AppTheme.defaultCornerRadius)
            } else {
                ProgressView()
            }
            
            // Overlays for "LIKE" and "NOPE".
            if showLikeOverlay {
                overlayText("LIKE", color: AppTheme.likeColor, rotation: -15, xPos: 100)
            }
            if showNopeOverlay {
                overlayText("NOPE", color: AppTheme.nopeColor, rotation: 15, xPos: 300)
            }
            if showSuperLikeOverlay {
                overlayText("SUPER LIKE", color: AppTheme.accentColor, rotation: 0, xPos: UIScreen.main.bounds.width / 2)
            }
        }
        // 🔹 make card fill the available space (Tinder‑style)
        .aspectRatio(3/4, contentMode: .fit)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .offset(x: offset.width, y: offset.height)
        .rotationEffect(Angle(degrees: rotation))
        .gesture(dragGesture)
        // 🔹 consolidated appearance logic
        .onAppear(perform: loadData)
        .animation(.easeInOut, value: offset)
    }
}

// MARK: - Subviews & Helpers
extension SwipeCardView {
    /// 1) Entry point for either “check favorite” or “load from Firestore”
    private func loadData() {
        if let id = candidateID {
            loadCandidate(id)
        }
    }
    
    /// 2) Loads candidate details from Firestore using the candidateID.
    private func loadCandidate(_ id: String) {
        db.collection("users").document(id).getDocument { snap, err in
            if let err = err {
                print("SwipeCardView load error:", err.localizedDescription)
                return
            }
            guard let doc = snap, doc.exists,
                  let candidate = try? doc.data(as: UserModel.self)
            else { return }

            DispatchQueue.main.async {
                self.loadedUser = candidate
            }
        }
    }
    
    /// Returns the profile image view for a candidate.
    private func profileImage(for candidate: UserModel) -> some View {
        Group {
            if let urlStr = candidate.profileImageUrl, let url = URL(string: urlStr) {
                AsyncImage(url: url) { phase in
                    if let image = phase.image {
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 150, height: 150)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(AppTheme.primaryColor, lineWidth: 4))
                    } else {
                        placeholderImage(for: candidate)
                    }
                }
            } else {
                placeholderImage(for: candidate)
            }
        }
    }
    
    
    /// Returns a circular placeholder view showing candidate initials.
    private func placeholderImage(for candidate: UserModel) -> some View {
        let initials = candidate.email.components(separatedBy: "@").first?.prefix(2).uppercased() ?? "??"
        return Text(initials)
            .font(AppTheme.bodyFont.weight(.bold))
            .frame(width: 150, height: 150)
            .background(AppTheme.primaryColor.opacity(0.5))
            .foregroundColor(.white)
            .clipShape(Circle())
    }
    
    /// Returns a verified badge view if the candidate is verified.
    private func verifiedBadge(for candidate: UserModel) -> some View {
        Group {
            if let verified = candidate.isVerified, verified {
                Text("✓ Verified")
                    .font(AppTheme.bodyFont)
                    .foregroundColor(.white)
                    .padding(4)
                    .background(AppTheme.primaryColor.opacity(0.8))
                    .clipShape(Capsule())
                    .offset(x: -10, y: 10)
            }
        }
    }
    
    /// Returns a view showing candidate info.
    private func userInfoSection(for candidate: UserModel) -> some View {
        VStack(spacing: 4) {
            // Name
            if let first = candidate.firstName, let last = candidate.lastName,
               !first.isEmpty, !last.isEmpty {
                Text("\(first) \(last)")
                    .font(AppTheme.subtitleFont)
                    .foregroundColor(.primary)
            }

            // Housing type
            if let housing = candidate.desiredLeaseHousingType ?? candidate.dormType,
               !housing.isEmpty {
                Text("Housing: \(housing)")
                    .font(AppTheme.bodyFont)
            }

            // Rent (roommate mode) vs. Budget (lease / find‑together)
            if candidate.housingStatus == PrimaryHousingPreference.lookingForRoommate.rawValue {
                let minRent = Int(candidate.monthlyRentMin ?? 0)
                let maxRent = Int(candidate.monthlyRentMax ?? 0)
                Text("Rent: \(minRent)–\(maxRent) USD")
                    .font(AppTheme.bodyFont)
            } else {
                let minB = Int(candidate.budgetMin ?? 0)
                let maxB = Int(candidate.budgetMax ?? 0)
                Text("Budget: \(minB)–\(maxB) USD")
                    .font(AppTheme.bodyFont)
            }

            // Sleep schedule
            if let schedule = candidate.sleepSchedule, !schedule.isEmpty {
                Text("Sleep: \(schedule)")
                    .font(AppTheme.bodyFont)
            }

            // Compatibility score
            if let score = compatibilityScore {
              Text("Compatibility: \(Int(score))%")
                .font(AppTheme.subtitleFont)
                .foregroundColor(score > 70
                   ? AppTheme.likeColor
                   : AppTheme.accentColor)
            }
        }
        .padding(.horizontal)
        .padding(.bottom, AppTheme.defaultPadding)
    }

    
    /// Displays overlay text (e.g., "LIKE" or "NOPE").
    private func overlayText(_ text: String, color: Color, rotation: Double, xPos: CGFloat) -> some View {
        Text(text)
            .font(.system(size: 48, weight: .heavy))
            .foregroundColor(color)
            .rotationEffect(.degrees(rotation))
            .padding()
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.defaultCornerRadius)
                    .stroke(color, lineWidth: 4)
            )
            .position(x: xPos, y: 50)
            .transition(.scale)
    }
    
    /// Drag gesture logic.
    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { gesture in
                offset = gesture.translation
                rotation = Double(gesture.translation.width / 20)
                updateOverlays()
            }
            .onEnded { _ in
                finalizeSwipe()
            }
    }
    
    /// Updates overlays based on horizontal offset.
    private func updateOverlays() {
        withAnimation {
            if offset.height < -50 && abs(offset.width) < 50 {
                showSuperLikeOverlay = true
                showLikeOverlay = false
                showNopeOverlay = false
            } else if offset.width > 50 {
                showLikeOverlay = true
                showNopeOverlay = false
                showSuperLikeOverlay = false
            } else if offset.width < -50 {
                showNopeOverlay = true
                showLikeOverlay = false
                showSuperLikeOverlay = false
            } else {
                showLikeOverlay = false
                showNopeOverlay = false
                showSuperLikeOverlay = false
            }
        }
    }
    
    /// Finalizes the swipe if threshold is reached.
    private func finalizeSwipe() {
        if offset.height < -100 {
            HapticFeedbackManager.shared.generateImpact(style: .heavy)
            if let candidate = user {
                onSwipe(candidate, .up)
            }
        } else if offset.width > 100 {
            HapticFeedbackManager.shared.generateImpact(style: .heavy)
            if let candidate = user {
                onSwipe(candidate, .right)
            }
        } else if offset.width < -100 {
            HapticFeedbackManager.shared.generateImpact(style: .heavy)
            if let candidate = user {
                onSwipe(candidate, .left)
            }
        }
        withAnimation {
            offset = .zero
            rotation = 0
            showLikeOverlay = false
            showNopeOverlay = false
            showSuperLikeOverlay = false
        }
    }
}

struct SwipeCardView_Previews: PreviewProvider {
    static var previews: some View {
        SwipeCardView(user: UserModel(
            email: "test@edu",
            isEmailVerified: true,
            firstName: "Taylor",
            lastName: "Johnson",
            // old `dormType` stays
            dormType: "On-Campus",
            // supply numeric rent & budget sliders
            monthlyRentMin: 600,
            monthlyRentMax: 900,
            budgetMin: 400,
            budgetMax: 1100,
            cleanliness: 4,
            sleepSchedule: "Flexible",
            smoker: false,
            petFriendly: true,
            isVerified: true
        )) { _, _ in }
        .padding()
        SwipeCardView(candidateID: "dummyCandidateID")
            .padding()
    }
}
