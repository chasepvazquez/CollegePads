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

    // Retrieve current user's profile from the shared ProfileViewModel
    var currentUser: UserModel? {
        ProfileViewModel.shared.userProfile
    }
    
    // Compute compatibility score if the current user's profile exists
    var compatibilityScore: Double? {
        if let current = currentUser {
            return CompatibilityCalculator.calculateUserCompatibility(between: current, and: user)
        }
        return nil
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white)
                .shadow(radius: 5)
            
            VStack(spacing: 10) {
                // Profile Image
                if let imageUrl = user.profileImageUrl, let url = URL(string: imageUrl) {
                    AsyncImage(url: url) { phase in
                        if let image = phase.image {
                            image.resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 120, height: 120)
                                .clipShape(Circle())
                        } else if phase.error != nil {
                            Image(systemName: "person.crop.circle.badge.exclamationmark")
                                .resizable()
                                .frame(width: 120, height: 120)
                        } else {
                            Image(systemName: "person.crop.circle")
                                .resizable()
                                .frame(width: 120, height: 120)
                        }
                    }
                } else {
                    Image(systemName: "person.crop.circle")
                        .resizable()
                        .frame(width: 120, height: 120)
                }
                
                // Basic info
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
                
                // Compatibility Score
                if let score = compatibilityScore {
                    Text("Compatibility: \(Int(score))%")
                        .font(.subheadline)
                        .foregroundColor(score > 70 ? .green : .orange)
                }
            }
            .padding()
        }
        .frame(height: 450)
        .offset(x: offset.width, y: offset.height)
        .rotationEffect(Angle(degrees: rotation))
        .gesture(
            DragGesture()
                .onChanged { gesture in
                    offset = gesture.translation
                    rotation = Double(gesture.translation.width / 20)
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
                    }
                }
        )
        .animation(.easeInOut, value: offset)
    }
}

struct SwipeCardView_Previews: PreviewProvider {
    static var previews: some View {
        SwipeCardView(
            user: UserModel(
                email: "test@edu",
                isEmailVerified: true,
                gradeLevel: "Freshman",
                major: "Computer Science",
                collegeName: "Engineering",
                dormType: "On-Campus",
                preferredDorm: nil,
                budgetRange: "$500-$1000",
                cleanliness: 4,
                sleepSchedule: "Flexible",
                smoker: false,
                petFriendly: false,
                livingStyle: "Social",
                profileImageUrl: nil
            ),
            onSwipe: { _, _ in }
        )
        .padding()
    }
}
