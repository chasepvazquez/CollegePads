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
    
    // Retrieve current user's profile from the shared ProfileViewModel.
    var currentUser: UserModel? {
        ProfileViewModel.shared.userProfile
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Compatibility Breakdown")
                    .font(.largeTitle)
                    .bold()
                    .padding(.top)
                
                // Use a boolean check instead of binding to a variable that is never used.
                if currentUser != nil {
                    Text("Overall Compatibility: \(Int(overallScore))%")
                        .font(.title)
                        .foregroundColor(overallScore > 70 ? .green : .orange)
                    
                    // For each factor, show a progress bar out of 10 pts.
                    ForEach(breakdown.keys.sorted(), id: \.self) { key in
                        HStack {
                            Text(key)
                                .fontWeight(.semibold)
                                .frame(width: 100, alignment: .leading)
                            ProgressView(value: breakdown[key]!, total: 10)
                                .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                            Text("\(Int(breakdown[key]!)) pts")
                                .frame(width: 50, alignment: .trailing)
                        }
                        .padding(.vertical, 4)
                    }
                } else {
                    Text("Your profile is not loaded.")
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Compatibility")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        // Dismiss the view (the parent view should handle dismissal)
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
        // Dummy candidate for preview
        let candidate = UserModel(
            email: "candidate@edu",
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
            petFriendly: true,
            livingStyle: "Social",
            interests: ["music", "coding"],
            latitude: 37.7749,
            longitude: -122.4194
        )
        // For preview, set a dummy current user.
        ProfileViewModel.shared.userProfile = UserModel(
            email: "current@edu",
            isEmailVerified: true,
            gradeLevel: "Freshman",
            major: "Computer Science",
            collegeName: "Engineering",
            dormType: "On-Campus",
            preferredDorm: nil,
            budgetRange: "$500-$1000",
            cleanliness: 5,
            sleepSchedule: "Flexible",
            smoker: false,
            petFriendly: true,
            livingStyle: "Social",
            interests: ["coding", "sports"],
            latitude: 37.7749,
            longitude: -122.4194
        )
        return ProfileComparisonPreview(candidate: candidate)
    }
    
    // A simple wrapper to display CompatibilityBreakdownView.
    struct ProfileComparisonPreview: View {
        let candidate: UserModel
        var body: some View {
            CompatibilityBreakdownView(candidate: candidate)
        }
    }
}
