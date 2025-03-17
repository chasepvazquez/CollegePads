//
//  CompatibilityBreakdownView.swift
//  CollegePads
//
//  Created by [Your Name] on [Date].
//

import SwiftUI

struct CompatibilityBreakdownView: View {
    let candidate: UserModel
    @State private var breakdown: [String: Double] = [:]
    @State private var overallScore: Double = 0.0
    
    // Retrieve current user's profile from shared instance
    var currentUser: UserModel? {
        ProfileViewModel.shared.userProfile
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Compatibility Breakdown")
                    .font(.largeTitle)
                    .padding(.top)
                
                if currentUser == nil {
                    Text("Current user profile not loaded.")
                } else {
                    // Display overall score
                    Text("Overall Compatibility: \(Int(overallScore))%")
                        .font(.title)
                        .foregroundColor(overallScore > 70 ? .green : .orange)
                    
                    Divider()
                    
                    // Display breakdown list
                    List {
                        ForEach(breakdown.keys.sorted(), id: \.self) { key in
                            HStack {
                                Text(key)
                                Spacer()
                                Text("\(Int(breakdown[key] ?? 0)) pts")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Compatibility")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        // Dismiss the view if presented modally
                        // (The parent view will dismiss it)
                    }
                }
            }
            .onAppear {
                computeCompatibility()
            }
        }
    }
    
    private func computeCompatibility() {
        guard let current = currentUser else { return }
        let result = CompatibilityCalculator.calculateCompatibilityBreakdown(between: current, and: candidate)
        overallScore = result.overall
        breakdown = result.breakdown
    }
}

struct CompatibilityBreakdownView_Previews: PreviewProvider {
    static var previews: some View {
        // Create dummy candidate profile for preview purposes
        let candidate = UserModel(
            email: "candidate@edu",
            isEmailVerified: true,
            gradeLevel: "Freshman",
            major: "Computer Science",
            collegeName: "Engineering",
            dormType: "On-Campus",
            preferredDorm: "Dorm A",
            budgetRange: "$500-$1000",
            cleanliness: 4,
            sleepSchedule: "Flexible",
            smoker: false,
            petFriendly: true,
            livingStyle: "Social",
            profileImageUrl: nil,
            latitude: 37.7749,
            longitude: -122.4194
        )
        // For preview, assume current user's profile is similar.
        ProfileViewModel.shared.userProfile = UserModel(
            email: "current@edu",
            isEmailVerified: true,
            gradeLevel: "Freshman",
            major: "Computer Science",
            collegeName: "Engineering",
            dormType: "On-Campus",
            budgetRange: "$500-$1000",
            cleanliness: 5,
            sleepSchedule: "Flexible",
            smoker: false,
            petFriendly: true,
            livingStyle: "Social",
            profileImageUrl: nil,
            latitude: 37.7749,
            longitude: -122.4194
        )
        return CompatibilityBreakdownView(candidate: candidate)
    }
}
