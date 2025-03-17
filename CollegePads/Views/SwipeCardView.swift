//
//  SwipeCardView.swift
//  CollegePads
//
//  Created by [Your Name] on [Date].
//

import SwiftUI

struct SwipeCardView: View {
    let user: UserModel
    var onSwipe: (_ user: UserModel, _ direction: SwipeDirection) -> Void
    
    @State private var offset: CGSize = .zero
    @State private var rotation: Double = 0
    @State private var showLikeOverlay: Bool = false
    @State private var showNopeOverlay: Bool = false

    // Retrieve current user's profile from the shared ProfileViewModel
    var currentUser: UserModel? {
        ProfileViewModel.shared.userProfile
    }
    
    // Compute compatibility score if the current user's profile exists (optional).
    var compatibilityScore: Double? {
        if let current = currentUser {
            return CompatibilityCalculator.calculateUserCompatibility(between: current, and: user)
        }
        return nil
    }

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [.white, Color(UIColor.systemGray6)]),
                startPoint: .top,
                endPoint: .bottom
            )
            .cornerRadius(15)
            .shadow(radius: 5)

            // Main content
            VStack(spacing: 10) {
                // Profile image with gradient overlay
                ZStack {
                    if let imageUrl = user.profileImageUrl, let url = URL(string: imageUrl) {
                        AsyncImage(url: url) { phase in
                            if let image = phase.image {
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            } else {
                                Color.gray.opacity(0.4)
                            }
                        }
                    } else {
                        Color.gray.opacity(0.4)
                    }
                }
                .frame(height: 300)
                .clipped()
                .overlay(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.black.opacity(0.0), Color.black.opacity(0.5)]),
                        startPoint: .center,
                        endPoint: .bottom
                    )
                )
                .cornerRadius(15)
                
                // Info section
                VStack(spacing: 4) {
                    Text(user.email)
                        .font(.headline)
                    if let dorm = user.dormType {
                        Text("Dorm: \(dorm)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    if let budget = user.budgetRange {
                        Text("Budget: \(budget)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    // Optional: show compatibility if you want
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
            // We'll place them in the corners with a small animation.
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
                    
                    // Show overlays if swiping far enough
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
                        onSwipe(user, .right)
                    } else if offset.width < -100 {
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
        .animation(.easeInOut, value: offset)
    }
}
