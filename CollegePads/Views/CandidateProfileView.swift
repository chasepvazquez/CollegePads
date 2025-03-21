//
//  CandidateProfileView.swift
//  CollegePads
//
//  Updated to use AppTheme for backgrounds and colors throughout.

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
            AppTheme.backgroundGradient.ignoresSafeArea()
            
            Group {
                if let candidate = viewModel.candidate {
                    ScrollView {
                        VStack(spacing: 20) {
                            // Profile Image Section
                            ZStack(alignment: .topTrailing) {
                                if let imageUrl = candidate.profileImageUrl, let url = URL(string: imageUrl) {
                                    AsyncImage(url: url) { phase in
                                        if let image = phase.image {
                                            image
                                                .resizable()
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
                                
                                if let verified = candidate.isVerified, verified {
                                    Text("✓ Verified")
                                        .font(.caption2)
                                        .foregroundColor(.white)
                                        .padding(4)
                                        .background(AppTheme.primaryColor.opacity(0.8))
                                        .clipShape(Capsule())
                                        .offset(x: -10, y: 10)
                                }
                            }
                            
                            // Candidate Details Card
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
                            .background(AppTheme.cardBackground)
                            .cornerRadius(15)
                            .shadow(radius: 5)
                            
                            Divider()
                            
                            // Additional Information Section
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
                            
                            // Common Interests Section
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
                                    .background(AppTheme.cardBackground.opacity(0.8)) 
                                    .cornerRadius(8)
                                    .shadow(radius: 3)
                                }
                            }
                            
                            Divider()
                            
                            // Action Buttons Section
                            VStack(spacing: 16) {
                                HStack(spacing: 16) {
                                    Button(action: { showCompatibilityBreakdown = true }) {
                                        Text("View Compatibility Breakdown")
                                    }
                                    .buttonStyle(PrimaryButtonStyle(backgroundColor: AppTheme.primaryColor))
                                    
                                    Button(action: { showQuiz = true }) {
                                        Text("Take Compatibility Quiz")
                                    }
                                    .buttonStyle(PrimaryButtonStyle(backgroundColor: AppTheme.primaryColor))
                                }
                                
                                Button(action: { showComparison = true }) {
                                    Text("Compare with My Profile")
                                }
                                .buttonStyle(PrimaryButtonStyle(backgroundColor: AppTheme.primaryColor))
                                
                                HStack(spacing: 16) {
                                    Button(action: { showReportSheet = true }) {
                                        Text("Report User")
                                    }
                                    .buttonStyle(PrimaryButtonStyle(backgroundColor: AppTheme.accentColor))
                                    
                                    Button(action: { showBlockAlert = true }) {
                                        Text("Block User")
                                    }
                                    .buttonStyle(PrimaryButtonStyle(backgroundColor: AppTheme.secondaryColor))
                                }
                                
                                Button(action: { showRatingSheet = true }) {
                                    Text("Rate Roommate")
                                }
                                .buttonStyle(PrimaryButtonStyle(backgroundColor: AppTheme.primaryColor))
                                
                                Button(action: { showAgreementSheet = true }) {
                                    Text("Create Roommate Agreement")
                                }
                                .buttonStyle(PrimaryButtonStyle(backgroundColor: AppTheme.primaryColor))
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
        .sheet(isPresented: $showQuiz) { QuizView() }
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
        NavigationView { CandidateProfileView(candidateID: "dummyCandidateID") }
    }
}
