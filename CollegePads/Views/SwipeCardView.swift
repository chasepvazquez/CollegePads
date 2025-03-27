import SwiftUI

/// A single swipeable card representing a user profile.
/// The user can be swiped left or right, triggering `onSwipe`.
struct SwipeCardView: View {
    let user: UserModel
    var onSwipe: (_ user: UserModel, _ direction: SwipeDirection) -> Void
    
    @State private var offset: CGSize = .zero
    @State private var rotation: Double = 0
    @State private var showLikeOverlay: Bool = false
    @State private var showNopeOverlay: Bool = false
    @State private var isFavorite: Bool = false
    
    // Pull the current user from a shared view model if needed
    var currentUser: UserModel? {
        ProfileViewModel.shared.userProfile
    }
    
    // Example compatibility score
    var compatibilityScore: Double? {
        if let current = currentUser {
            return CompatibilityCalculator.calculateUserCompatibility(between: current, and: user)
        }
        return nil
    }
    
    var body: some View {
        ZStack {
            // Card background
            AppTheme.backgroundGradient
                .cornerRadius(AppTheme.defaultCornerRadius)
                .shadow(radius: 5)
            
            VStack(spacing: 10) {
                // Profile image with overlays
                ZStack(alignment: .topTrailing) {
                    profileImage
                    verifiedBadge
                    favoriteButton
                }
                
                userInfoSection
            }
            .cornerRadius(AppTheme.defaultCornerRadius)
            
            // Overlays for "LIKE" and "NOPE"
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
            FavoriteService().isFavorite(candidate: user) { fav in
                self.isFavorite = fav
            }
        }
        .animation(.easeInOut, value: offset)
    }
}

// MARK: - Subviews & Helpers
extension SwipeCardView {
    
    /// The user's profile image (circular).
    private var profileImage: some View {
        Group {
            if let urlStr = user.profileImageUrl, let url = URL(string: urlStr) {
                AsyncImage(url: url) { phase in
                    if let image = phase.image {
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 150, height: 150)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(AppTheme.primaryColor, lineWidth: 4))
                    } else {
                        placeholderImage
                    }
                }
            } else {
                placeholderImage
            }
        }
    }
    
    /// A fallback system image if no valid URL is found.
    private var placeholderImage: some View {
        Image(systemName: "person.crop.circle")
            .resizable()
            .frame(width: 150, height: 150)
    }
    
    /// Shows a verified badge if `user.isVerified` is true.
    private var verifiedBadge: some View {
        Group {
            if let verified = user.isVerified, verified {
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
    
    /// A toggleable favorite button in the top-right corner.
    private var favoriteButton: some View {
        Button(action: toggleFavorite) {
            Image(systemName: isFavorite ? "heart.fill" : "heart")
                .font(.system(size: 24))
                .foregroundColor(isFavorite ? AppTheme.nopeColor : AppTheme.cardBackground)
                .padding(8)
        }
    }
    
    /// Displays non-sensitive user info: name, dorm, budget, etc.
    private var userInfoSection: some View {
        VStack(spacing: 4) {
            if let firstName = user.firstName, let lastName = user.lastName,
               !firstName.isEmpty, !lastName.isEmpty {
                Text("\(firstName) \(lastName)")
                    .font(AppTheme.subtitleFont)
                    .foregroundColor(.primary)
            }
            if let dorm = user.dormType, !dorm.isEmpty {
                Text("Dorm Type: \(dorm)")
                    .font(AppTheme.bodyFont)
            }
            if let budget = user.budgetRange, !budget.isEmpty {
                Text("Budget Range: \(budget)")
                    .font(AppTheme.bodyFont)
            }
            if let schedule = user.sleepSchedule, !schedule.isEmpty {
                Text("Sleep Schedule: \(schedule)")
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
    
    /// Displays a big overlay text for "LIKE" or "NOPE" with styling.
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
    
    /// Drag gesture logic to detect left vs right swipes.
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
    
    /// Updates the like/nope overlays based on horizontal offset.
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
    
    /// Finalizes the swipe (left or right) if threshold is reached.
    private func finalizeSwipe() {
        if offset.width > 100 {
            HapticFeedbackManager.shared.generateImpact(style: .heavy)
            onSwipe(user, .right)
        } else if offset.width < -100 {
            HapticFeedbackManager.shared.generateImpact(style: .heavy)
            onSwipe(user, .left)
        }
        // Reset to center
        withAnimation {
            offset = .zero
            rotation = 0
            showLikeOverlay = false
            showNopeOverlay = false
        }
    }
    
    /// Toggles the favorite (heart) status for this user.
    private func toggleFavorite() {
        if isFavorite {
            FavoriteService().removeFavorite(candidate: user) { result in
                switch result {
                case .success:
                    HapticFeedbackManager.shared.generateNotification(.warning)
                    isFavorite = false
                case .failure(let error):
                    print("Error removing favorite: \(error.localizedDescription)")
                }
            }
        } else {
            FavoriteService().addFavorite(candidate: user) { result in
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
        SwipeCardView(
            user: UserModel(
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
            ),
            onSwipe: { _, _ in }
        )
        .padding()
    }
}
