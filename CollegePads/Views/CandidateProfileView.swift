//
//  CandidateProfileView.swift
//  CollegePads
//
//  Created by [Your Name] on [Date].
//

import SwiftUI

struct CandidateProfileView: View {
    let candidateID: String
    
    @StateObject private var viewModel = CandidateProfileViewModel()
    
    var body: some View {
        Group {
            if let candidate = viewModel.candidate {
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
                        
                        // Compatibility Score placeholder (can compute if current user data is available)
                        Text("Compatibility: N/A")
                    }
                    .padding()
                }
                .navigationTitle("Candidate Profile")
            } else {
                ProgressView("Loading Profile...")
                    .onAppear {
                        viewModel.loadCandidate(with: candidateID)
                    }
            }
        }
        .alert(item: Binding(
            get: {
                if let errorMessage = viewModel.errorMessage {
                    return GenericAlertError(message: errorMessage)
                }
                return nil
            },
            set: { _ in viewModel.errorMessage = nil }
        )) { alertError in
            Alert(title: Text("Error"), message: Text(alertError.message), dismissButton: .default(Text("OK")))
        }
    }
}

struct GenericAlertError: Identifiable {
    let id = UUID()
    let message: String
}

struct CandidateProfileView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            CandidateProfileView(candidateID: "dummyCandidateID")
        }
    }
}
