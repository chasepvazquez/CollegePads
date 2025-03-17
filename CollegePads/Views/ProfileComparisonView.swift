//
//  ProfileComparisonView.swift
//  CollegePads
//
//  Created by [Your Name] on [Date].
//

import SwiftUI

struct ProfileComparisonView: View {
    let candidate: UserModel
    
    // Get the current user's profile from the shared ProfileViewModel.
    var currentUser: UserModel? {
        ProfileViewModel.shared.userProfile
    }
    
    var body: some View {
        NavigationView {
            if let current = currentUser {
                List {
                    ComparisonRow(field: "Grade", currentValue: current.gradeLevel, candidateValue: candidate.gradeLevel)
                    ComparisonRow(field: "Major", currentValue: current.major, candidateValue: candidate.major)
                    ComparisonRow(field: "College", currentValue: current.collegeName, candidateValue: candidate.collegeName)
                    ComparisonRow(field: "Dorm", currentValue: current.dormType, candidateValue: candidate.dormType)
                    ComparisonRow(field: "Budget", currentValue: current.budgetRange, candidateValue: candidate.budgetRange)
                    ComparisonRow(field: "Cleanliness", currentValue: current.cleanliness != nil ? "\(current.cleanliness!)" : nil, candidateValue: candidate.cleanliness != nil ? "\(candidate.cleanliness!)" : nil)
                    ComparisonRow(field: "Sleep", currentValue: current.sleepSchedule, candidateValue: candidate.sleepSchedule)
                    ComparisonRow(field: "Living Style", currentValue: current.livingStyle, candidateValue: candidate.livingStyle)
                    ComparisonRow(field: "Interests", currentValue: current.interests?.joined(separator: ", "), candidateValue: candidate.interests?.joined(separator: ", "))
                }
                .listStyle(InsetGroupedListStyle())
                .navigationTitle("Profile Comparison")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") {
                            // Dismiss if needed.
                        }
                    }
                }
            } else {
                ProgressView("Loading Your Profile...")
            }
        }
    }
}

struct ComparisonRow: View {
    let field: String
    let currentValue: String?
    let candidateValue: String?
    
    var body: some View {
        HStack {
            Text(field)
                .fontWeight(.bold)
                .frame(width: 120, alignment: .leading)
            Spacer()
            VStack(alignment: .leading) {
                Text("You: \(currentValue ?? "-")")
                    .foregroundColor(.blue)
                Text("Candidate: \(candidateValue ?? "-")")
                    .foregroundColor(.green)
            }
            if let current = currentValue, let candidate = candidateValue, current.lowercased() == candidate.lowercased() {
                Image(systemName: "checkmark.seal.fill")
                    .foregroundColor(.green)
            }
        }
        .padding(.vertical, 4)
    }
}

struct ProfileComparisonView_Previews: PreviewProvider {
    static var previews: some View {
        // Dummy profiles for preview.
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
            interests: ["music", "coding"]
        )
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
            interests: ["coding", "sports"]
        )
        return ProfileComparisonView(candidate: candidate)
    }
}
