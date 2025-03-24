import SwiftUI

struct SwipeCardView: View {
    let user: UserModel
    var onSwipe: (_ user: UserModel, _ direction: SwipeDirection) -> Void
    
    @State private var offset: CGSize = .zero
    @State private var rotation: Double = 0
    @State private var showLikeOverlay: Bool = false
    @State private var showNopeOverlay: Bool = false
    @State private var isFavorite: Bool = false
    
    var currentUser: UserModel? {
        ProfileViewModel.shared.userProfile
    }
    
    var compatibilityScore: Double? {
        if let current = currentUser {
            return CompatibilityCalculator.calculateUserCompatibility(between: current, and: user)
        }
        return nil
    }
    
    var body: some View {
        ZStack {
            // Card background using the theme’s gradient.
            AppTheme.backgroundGradient
                .cornerRadius(AppTheme.defaultCornerRadius)
                .shadow(radius: 5)
            
            VStack(spacing: 10) {
                // Profile image with overlays.
                ZStack(alignment: .topTrailing) {
                    if let imageUrl = user.profileImageUrl, let url = URL(string: imageUrl) {
                        AsyncImage(url: url) { phase in
                            if let image = phase.image {
                                image.resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 150, height: 150)
                                    .clipShape(Circle())
                                    .overlay(Circle().stroke(AppTheme.primaryColor, lineWidth: 4))
                            } else {
                                Image(systemName: "person.crop.circle")
                                    .resizable()
                                    .frame(width: 150, height: 150)
                            }
                        }
                    } else {
                        Image(systemName: "person.crop.circle")
                            .resizable()
                            .frame(width: 150, height: 150)
                    }
                    
                    if let verified = user.isVerified, verified {
                        Text("✓ Verified")
                            .font(AppTheme.bodyFont)  // Using bodyFont instead of captionFont.
                            .foregroundColor(.white)
                            .padding(4)
                            .background(AppTheme.primaryColor.opacity(0.8))
                            .clipShape(Capsule())
                            .offset(x: -10, y: 10)
                    }
                    
                    Button(action: toggleFavorite) {
                        Image(systemName: isFavorite ? "heart.fill" : "heart")
                            .font(.system(size: 24))
                            .foregroundColor(isFavorite ? AppTheme.nopeColor : AppTheme.cardBackground)
                            .padding(8)
                    }
                }
                
                VStack(spacing: 4) {
                    Text(user.email)
                        .font(AppTheme.bodyFont)
                    if let dorm = user.dormType {
                        Text("Dorm: \(dorm)")
                            .font(AppTheme.bodyFont)
                    }
                    if let budget = user.budgetRange {
                        Text("Budget: \(budget)")
                            .font(AppTheme.bodyFont)
                    }
                    if let schedule = user.sleepSchedule {
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
            .cornerRadius(AppTheme.defaultCornerRadius)
            
            if showLikeOverlay {
                Text("LIKE")
                    .font(.system(size: 48, weight: .heavy))
                    .foregroundColor(AppTheme.likeColor)
                    .rotationEffect(.degrees(-15))
                    .padding()
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.defaultCornerRadius)
                            .stroke(AppTheme.likeColor, lineWidth: 4)
                    )
                    .transition(.scale)
                    .position(x: 100, y: 50)
            }
            if showNopeOverlay {
                Text("NOPE")
                    .font(.system(size: 48, weight: .heavy))
                    .foregroundColor(AppTheme.nopeColor)
                    .rotationEffect(.degrees(15))
                    .padding()
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.defaultCornerRadius)
                            .stroke(AppTheme.nopeColor, lineWidth: 4)
                    )
                    .transition(.scale)
                    .position(x: 300, y: 50)
            }
        }
        .frame(height: 450)
        .offset(x: offset.width, y: offset.height)
        .rotationEffect(Angle(degrees: rotation))
        .gesture(
            DragGesture()
                .onChanged { gesture in
                    offset = gesture.translation
                    rotation = Double(gesture.translation.width / 20)
                    
                    if offset.width > 50 {
                        withAnimation {
                            showLikeOverlay = true
                            showNopeOverlay = false
                        }
                    } else if offset.width < -50 {
                        withAnimation {
                            showNopeOverlay = true
                            showLikeOverlay = false
                        }
                    } else {
                        withAnimation {
                            showLikeOverlay = false
                            showNopeOverlay = false
                        }
                    }
                }
                .onEnded { _ in
                    if offset.width > 100 {
                        HapticFeedbackManager.shared.generateImpact(style: .heavy)
                        onSwipe(user, .right)
                    } else if offset.width < -100 {
                        HapticFeedbackManager.shared.generateImpact(style: .heavy)
                        onSwipe(user, .left)
                    }
                    withAnimation {
                        offset = .zero
                        rotation = 0
                        showLikeOverlay = false
                        showNopeOverlay = false
                    }
                }
        )
        .onAppear {
            FavoriteService().isFavorite(candidate: user) { fav in
                self.isFavorite = fav
            }
        }
        .animation(.easeInOut, value: offset)
    }
    
    private func toggleFavorite() {
        if isFavorite {
            FavoriteService().removeFavorite(candidate: user) { result in
                switch result {
                case .success:
                    HapticFeedbackManager.shared.generateNotification(.warning)
                    self.isFavorite = false
                case .failure(let error):
                    print("Error removing favorite: \(error.localizedDescription)")
                }
            }
        } else {
            FavoriteService().addFavorite(candidate: user) { result in
                switch result {
                case .success:
                    HapticFeedbackManager.shared.generateNotification(.success)
                    self.isFavorite = true
                case .failure(let error):
                    print("Error adding favorite: \(error.localizedDescription)")
                }
            }
        }
    }
}

struct SwipeCardView_Previews: PreviewProvider {
    static var previews: some View {
        SwipeCardView(user: UserModel(email: "test@edu", isEmailVerified: true, gradeLevel: "Freshman", major: "Computer Science", collegeName: "Engineering", dormType: "On-Campus", budgetRange: "$500-$1000", cleanliness: 4, sleepSchedule: "Flexible", smoker: false, petFriendly: true, livingStyle: "Social", profileImageUrl: nil, isVerified: true), onSwipe: { _, _ in })
            .padding()
    }
}
