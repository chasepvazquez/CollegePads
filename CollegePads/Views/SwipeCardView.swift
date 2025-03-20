//
//  SwipeCardView.swift
//  CollegePads
//
//  Updated to improve animations, accessibility, and modularity in swipe interactions
//

import SwiftUI

struct SwipeCardView: View {
    let user: UserModel
    var onSwipe: (_ user: UserModel, _ direction: SwipeDirection) -> Void
    
    @State private var offset: CGSize = .zero
    @State private var rotation: Double = 0
    @State private var showLikeOverlay: Bool = false
    @State private var showNopeOverlay: Bool = false
    @State private var isFavorite: Bool = false
    
    // Retrieve current user's profile from shared ProfileViewModel
    var currentUser: UserModel? {
        ProfileViewModel.shared.userProfile
    }
    
    // Compute compatibility score (optional)
    var compatibilityScore: Double? {
        if let current = currentUser {
            return CompatibilityCalculator.calculateUserCompatibility(between: current, and: user)
        }
        return nil
    }
    
    var body: some View {
        ZStack {
            // Background card with gradient and shadow for a polished look
            LinearGradient(gradient: Gradient(colors: [.white, Color(UIColor.systemGray6)]),
                           startPoint: .top, endPoint: .bottom)
                .cornerRadius(15)
                .shadow(color: .gray, radius: 5, x: 0, y: 5)
            
            VStack(spacing: 10) {
                // Profile image with overlays for favorite and verified status
                ZStack(alignment: .topTrailing) {
                    if let imageUrl = user.profileImageUrl, let url = URL(string: imageUrl) {
                        AsyncImage(url: url) { phase in
                            if let image = phase.image {
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 150, height: 150)
                                    .clipShape(Circle())
                                    .overlay(Circle().stroke(Color.blue, lineWidth: 4))
                            } else {
                                defaultPlaceholder(for: user)
                            }
                        }
                    } else {
                        defaultPlaceholder(for: user)
                    }
                    
                    // Verified badge overlay:
                    if let verified = user.isVerified, verified {
                        Text("✓ Verified")
                            .font(.caption2)
                            .foregroundColor(.white)
                            .padding(4)
                            .background(Color.blue.opacity(0.8))
                            .clipShape(Capsule())
                            .offset(x: -10, y: 10)
                    }
                    
                    // Heart icon for favorite
                    Button(action: toggleFavorite) {
                        Image(systemName: isFavorite ? "heart.fill" : "heart")
                            .font(.system(size: 24))
                            .foregroundColor(isFavorite ? .red : .gray)
                            .padding(8)
                    }
                    .accessibilityLabel(isFavorite ? "Remove from favorites" : "Add to favorites")
                }
                
                // Information Section
                VStack(spacing: 4) {
                    Text(user.email)
                        .font(.headline)
                    if let dorm = user.dormType {
                        Text("Dorm: \(dorm)")
                    }
                    if let budget = user.budgetRange {
                        Text("Budget: \(budget)")
                    }
                    if let schedule = user.sleepSchedule {
                        Text("Sleep: \(schedule)")
                    }
                    if let score = compatibilityScore {
                        Text("Compatibility: \(Int(score))%")
                            .font(.subheadline)
                            .foregroundColor(score > 70 ? .green : .orange)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 8)
            }
            .cornerRadius(15)
            
            // Like / Nope overlays
            if showLikeOverlay {
                Text("LIKE")
                    .font(.system(size: 48, weight: .heavy))
                    .foregroundColor(.green)
                    .rotationEffect(.degrees(-15))
                    .padding()
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.green, lineWidth: 4))
                    .transition(.scale)
                    .position(x: 100, y: 50)
            }
            if showNopeOverlay {
                Text("NOPE")
                    .font(.system(size: 48, weight: .heavy))
                    .foregroundColor(.red)
                    .rotationEffect(.degrees(15))
                    .padding()
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.red, lineWidth: 4))
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
            // Check if candidate is a favorite when the card appears
            FavoriteService().isFavorite(candidate: user) { fav in
                self.isFavorite = fav
            }
        }
        .accessibilityElement(children: .contain)
        .animation(.easeInOut, value: offset)
    }
    
    /// Provides a default circular placeholder with user initials.
    private func defaultPlaceholder(for candidate: UserModel) -> some View {
        let initials = candidate.email.components(separatedBy: "@").first?.prefix(2).uppercased() ?? "??"
        return Text(initials)
            .font(.headline)
            .frame(width: 150, height: 150)
            .background(Color.blue.opacity(0.5))
            .foregroundColor(.white)
            .clipShape(Circle())
    }
    
    /// Toggles the favorite state with haptic feedback.
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
