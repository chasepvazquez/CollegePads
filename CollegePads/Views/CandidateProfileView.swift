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
    @State private var showCompatibilityBreakdown = false
    @State private var showQuiz = false
    @State private var showComparison = false      // For profile comparison
    @State private var showReportSheet = false       // For reporting user
    @State private var showBlockAlert = false        // For blocking confirmation
    @State private var showRatingSheet = false         // For rating roommate (combined review view)
    @State private var showAgreementSheet = false      // For creating roommate agreement
    
    @StateObject private var blockUserVM = BlockUserViewModel()
    
    var body: some View {
        ZStack {
            // Use the global background color from the theme.
            Color.brandBackground
                .edgesIgnoringSafeArea(.all)
            
            Group {
                if let candidate = viewModel.candidate {
                    ScrollView {
                        VStack(spacing: 20) {
                            // MARK: - Profile Image Section
                            ZStack(alignment: .topTrailing) {
                                if let imageUrl = candidate.profileImageUrl, let url = URL(string: imageUrl) {
                                    AsyncImage(url: url) { phase in
                                        if let image = phase.image {
                                            image.resizable()
                                                .aspectRatio(contentMode: .fill)
                                                .frame(width: 150, height: 150)
                                                .clipShape(Circle())
                                                .overlay(Circle().stroke(Color.brandPrimary, lineWidth: 4))
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
                                
                                // Verified badge overlay using theme primary color.
                                if let verified = candidate.isVerified, verified {
                                    Text("✓ Verified")
                                        .font(.caption2)
                                        .foregroundColor(.white)
                                        .padding(4)
                                        .background(Color.brandPrimary.opacity(0.8))
                                        .clipShape(Capsule())
                                        .offset(x: -10, y: 10)
                                }
                            }
                            
                            // MARK: - Candidate Details Card
                            VStack(alignment: .leading, spacing: 10) {
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
                            .padding()
                            .background(Color.white)
                            .cornerRadius(15)
                            .shadow(radius: 5)
                            
                            Divider()
                            
                            // MARK: - Additional Information Section
                            VStack(alignment: .leading, spacing: 8) {
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
                            .padding()
                            
                            // MARK: - Common Interests Section
                            if let currentUser = ProfileViewModel.shared.userProfile,
                               let candidateInterests = candidate.interests,
                               let currentInterests = currentUser.interests {
                                let common = candidateInterests.filter { currentInterests.contains($0.lowercased()) }
                                if !common.isEmpty {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Common Interests:")
                                            .font(.headline)
                                        Text(common.joined(separator: ", "))
                                            .font(.body)
                                            .foregroundColor(.secondary)
                                    }
                                    .padding()
                                    .background(Color.white.opacity(0.8))
                                    .cornerRadius(8)
                                    .shadow(radius: 3)
                                }
                            }
                            
                            Divider()
                            
                            // MARK: - Action Buttons (using global PrimaryButtonStyle)
                            VStack(spacing: 16) {
                                HStack(spacing: 16) {
                                    Button(action: { showCompatibilityBreakdown = true }) {
                                        Text("View Compatibility Breakdown")
                                    }
                                    .buttonStyle(PrimaryButtonStyle(backgroundColor: .indigo))
                                    
                                    Button(action: { showQuiz = true }) {
                                        Text("Take Compatibility Quiz")
                                    }
                                    .buttonStyle(PrimaryButtonStyle(backgroundColor: .pink))
                                }
                                
                                Button(action: { showComparison = true }) {
                                    Text("Compare with My Profile")
                                }
                                .buttonStyle(PrimaryButtonStyle(backgroundColor: .blue))
                                
                                HStack(spacing: 16) {
                                    Button(action: { showReportSheet = true }) {
                                        Text("Report User")
                                    }
                                    .buttonStyle(PrimaryButtonStyle(backgroundColor: .brandAccent))
                                    
                                    Button(action: { showBlockAlert = true }) {
                                        Text("Block User")
                                    }
                                    .buttonStyle(PrimaryButtonStyle(backgroundColor: .gray))
                                }
                                
                                Button(action: { showRatingSheet = true }) {
                                    Text("Rate Roommate")
                                }
                                .buttonStyle(PrimaryButtonStyle(backgroundColor: .orange))
                                
                                Button(action: { showAgreementSheet = true }) {
                                    Text("Create Roommate Agreement")
                                }
                                .buttonStyle(PrimaryButtonStyle(backgroundColor: .purple))
                            }
                        }
                        .padding()
                    }
                } else {
                    ProgressView("Loading Profile...")
                        .onAppear {
                            viewModel.loadCandidate(with: candidateID)
                        }
                }
            }
        }
        .navigationTitle("Candidate Profile")
        .sheet(isPresented: $showCompatibilityBreakdown) {
            if let candidate = viewModel.candidate {
                CompatibilityBreakdownView(candidate: candidate)
            }
        }
        .sheet(isPresented: $showQuiz) {
            QuizView()
        }
        .sheet(isPresented: $showComparison) {
            if let candidate = viewModel.candidate {
                ProfileComparisonView(candidate: candidate)
            }
        }
        .sheet(isPresented: $showReportSheet) {
            if let candidate = viewModel.candidate {
                ReportUserView(reportedUserID: candidate.id ?? "unknown")
            }
        }
        .sheet(isPresented: $showRatingSheet) {
            if let candidate = viewModel.candidate, let candidateID = candidate.id {
                // Open the combined review view.
                RoommateReviewView(matchID: "matchID_example", ratedUserID: candidateID)
            }
        }
        .sheet(isPresented: $showAgreementSheet) {
            if let candidate = viewModel.candidate, let currentUserID = ProfileViewModel.shared.userProfile?.id {
                AgreementView(matchID: "matchID_example", userA: currentUserID, userB: candidate.id ?? "unknown")
            }
        }
        .alert(isPresented: $showBlockAlert) {
            Alert(
                title: Text("Block User"),
                message: Text("Are you sure you want to block this user? They will no longer appear in your matches."),
                primaryButton: .destructive(Text("Block")) {
                    if let candidate = viewModel.candidate, let candidateID = candidate.id {
                        blockUser(candidateID: candidateID)
                    }
                },
                secondaryButton: .cancel()
            )
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
    
    private func blockUser(candidateID: String) {
        BlockUserViewModel().blockUser(candidateID: candidateID) { result in
            switch result {
            case .success:
                print("User successfully blocked.")
                ProfileViewModel.shared.removeBlockedUser(with: candidateID)
            case .failure(let error):
                print("Error blocking user: \(error.localizedDescription)")
            }
        }
    }
}

struct CandidateProfileView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            CandidateProfileView(candidateID: "dummyCandidateID")
        }
    }
}
