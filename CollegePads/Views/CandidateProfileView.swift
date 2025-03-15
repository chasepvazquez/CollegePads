//
//  CandidateProfileView.swift
//  CollegePads
//
//  Created by [Your Name] on [Date].
//

import SwiftUI

struct CandidateProfileView: View {
    let candidate: UserModel
    // Assume current user's profile is available via ProfileViewModel.shared
    var currentUser: UserModel? {
        ProfileViewModel.shared.userProfile
    }
    
    // Calculate compatibility if possible.
    var compatibility: Double? {
        if let current = currentUser {
            return CompatibilityCalculator.calculateUserCompatibility(between: current, and: candidate)
        }
        return nil
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Profile image
                if let imageUrl = candidate.profileImageUrl, let url = URL(string: imageUrl) {
                    AsyncImage(url: url) { phase in
                        if let image = phase.image {
                            image.resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 150, height: 150)
                                .clipShape(Circle())
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
                
                // Basic Information
                Group {
                    Text(candidate.email)
                        .font(.headline)
                    if let grade = candidate.gradeLevel {
                        Text("Grade: \(grade)")
                    }
                    if let major = candidate.major {
                        Text("Major: \(major)")
                    }
                    if let college = candidate.collegeName {
                        Text("College: \(college)")
                    }
                }
                
                Divider()
                
                // Roommate Preferences
                Group {
                    if let dorm = candidate.dormType {
                        Text("Dorm Type: \(dorm)")
                    }
                    if let budget = candidate.budgetRange {
                        Text("Budget Range: \(budget)")
                    }
                    if let cleanliness = candidate.cleanliness {
                        Text("Cleanliness: \(cleanliness)/5")
                    }
                    if let sleep = candidate.sleepSchedule {
                        Text("Sleep Schedule: \(sleep)")
                    }
                    if let style = candidate.livingStyle {
                        Text("Living Style: \(style)")
                    }
                    if let smoker = candidate.smoker {
                        Text("Smoker: \(smoker ? "Yes" : "No")")
                    }
                    if let petFriendly = candidate.petFriendly {
                        Text("Pet Friendly: \(petFriendly ? "Yes" : "No")")
                    }
                }
                
                Divider()
                
                // Compatibility Score
                if let comp = compatibility {
                    Text("Compatibility: \(Int(comp))%")
                        .font(.title2)
                        .foregroundColor(comp > 70 ? .green : .orange)
                } else {
                    Text("Compatibility: N/A")
                }
                
                Spacer()
            }
            .padding()
        }
        .navigationTitle("Candidate Profile")
    }
}

struct CandidateProfileView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            CandidateProfileView(candidate: UserModel(
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
            ))
        }
    }
}
