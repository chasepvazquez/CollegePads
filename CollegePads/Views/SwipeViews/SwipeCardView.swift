import SwiftUI
import FirebaseFirestore

/// A unified swipeable card view that supports two initialization modes:
/// 1. When full candidate data (UserModel) is available.
/// 2. When only a candidateID is provided (the view then loads candidate data from Firestore).
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
    @State private var isFavorite: Bool = false
    
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
        if let current = currentUser, let candidate = user {
            return CompatibilityCalculator.calculateUserCompatibility(between: current, and: candidate)
        }
        return nil
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
            // Card background.
            AppTheme.backgroundGradient
                .cornerRadius(AppTheme.defaultCornerRadius)
                .shadow(radius: 5)
            
            if let candidate = user {
                VStack(spacing: 10) {
                    // Profile image with overlays.
                    ZStack(alignment: .topTrailing) {
                        profileImage(for: candidate)
                        verifiedBadge(for: candidate)
                        favoriteButton(for: candidate)
                    }
                    userInfoSection(for: candidate)
                }
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
        }
        .frame(height: 450)
        .offset(x: offset.width, y: offset.height)
        .rotationEffect(Angle(degrees: rotation))
        .gesture(dragGesture)
        .onAppear {
            // If candidate data is not provided, load it from Firestore.
            if initialUser == nil, let candidateID = candidateID {
                loadCandidate(candidateID: candidateID)
            } else if let candidate = user {
                FavoriteService().isFavorite(candidate: candidate) { fav in
                    self.isFavorite = fav
                }
            }
        }
        .animation(.easeInOut, value: offset)
    }
}

// MARK: - Subviews & Helpers
extension SwipeCardView {
    
    /// Loads candidate details from Firestore using the candidateID.
    private func loadCandidate(candidateID: String) {
        let db = Firestore.firestore()
        db.collection("users").document(candidateID).getDocument { snapshot, error in
            if let error = error {
                print("SwipeCardView: Error loading candidate: \(error.localizedDescription)")
            } else if let snapshot = snapshot, snapshot.exists {
                do {
                    let candidate = try snapshot.data(as: UserModel.self)
                    DispatchQueue.main.async {
                        self.loadedUser = candidate
                        FavoriteService().isFavorite(candidate: candidate) { fav in
                            self.isFavorite = fav
                        }
                    }
                } catch {
                    print("SwipeCardView: Decoding error: \(error.localizedDescription)")
                }
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
    
    /// Returns a toggleable favorite button view.
    private func favoriteButton(for candidate: UserModel) -> some View {
        Button(action: {
            toggleFavorite(for: candidate)
        }) {
            Image(systemName: isFavorite ? "heart.fill" : "heart")
                .font(.system(size: 24))
                .foregroundColor(isFavorite ? AppTheme.nopeColor : AppTheme.cardBackground)
                .padding(8)
        }
    }
    
    /// Returns a view showing candidate info.
    private func userInfoSection(for candidate: UserModel) -> some View {
        VStack(spacing: 4) {
            if let firstName = candidate.firstName, let lastName = candidate.lastName,
               !firstName.isEmpty, !lastName.isEmpty {
                Text("\(firstName) \(lastName)")
                    .font(AppTheme.subtitleFont)
                    .foregroundColor(.primary)
            }
            if let dorm = candidate.dormType, !dorm.isEmpty {
                Text("Dorm: \(dorm)")
                    .font(AppTheme.bodyFont)
            }
            if let budget = candidate.budgetRange, !budget.isEmpty {
                Text("Budget: \(budget)")
                    .font(AppTheme.bodyFont)
            }
            if let schedule = candidate.sleepSchedule, !schedule.isEmpty {
                Text("Sleep: \(schedule)")
                    .font(AppTheme.bodyFont)
            }
            if let score = compatibilityScore {
                Text("Compatibility: \(Int(score))%")
                    .font(AppTheme.subtitleFont)
                    .foregroundColor(score > 70 ? AppTheme.likeColor : AppTheme.accentColor)
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
                updateOverlays(for: offset.width)
            }
            .onEnded { _ in
                finalizeSwipe()
            }
    }
    
    /// Updates overlays based on horizontal offset.
    private func updateOverlays(for horizontalOffset: CGFloat) {
        withAnimation {
            if horizontalOffset > 50 {
                showLikeOverlay = true
                showNopeOverlay = false
            } else if horizontalOffset < -50 {
                showNopeOverlay = true
                showLikeOverlay = false
            } else {
                showLikeOverlay = false
                showNopeOverlay = false
            }
        }
    }
    
    /// Finalizes the swipe if threshold is reached.
    private func finalizeSwipe() {
        if offset.width > 100 {
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
        }
    }
    
    /// Toggles the favorite status for the candidate.
    private func toggleFavorite(for candidate: UserModel) {
        if isFavorite {
            FavoriteService().removeFavorite(candidate: candidate) { result in
                switch result {
                case .success:
                    HapticFeedbackManager.shared.generateNotification(.warning)
                    isFavorite = false
                case .failure(let error):
                    print("Error removing favorite: \(error.localizedDescription)")
                }
            }
        } else {
            FavoriteService().addFavorite(candidate: candidate) { result in
                switch result {
                case .success:
                    HapticFeedbackManager.shared.generateNotification(.success)
                    isFavorite = true
                case .failure(let error):
                    print("Error adding favorite: \(error.localizedDescription)")
                }
            }
        }
    }
}

struct SwipeCardView_Previews: PreviewProvider {
    static var previews: some View {
        // Preview using the full user initializer.
        SwipeCardView(user: UserModel(
            email: "test@edu",
            isEmailVerified: true,
            firstName: "Taylor",
            lastName: "Johnson",
            dormType: "On-Campus",
            budgetRange: "$500-$1000",
            cleanliness: 4,
            sleepSchedule: "Flexible",
            smoker: false,
            petFriendly: true,
            isVerified: true
        )) { _, _ in }
        .padding()
        
        // Preview using the candidateID initializer.
        SwipeCardView(candidateID: "dummyCandidateID")
            .padding()
    }
}
