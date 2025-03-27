import SwiftUI

struct CandidateProfileView: View {
    let candidateID: String
    @StateObject private var viewModel = CandidateProfileViewModel()
    @State private var showCompatibilityBreakdown = false
    @State private var showComparison = false
    @State private var showReportSheet = false
    @State private var showBlockAlert = false
    @State private var showRatingSheet = false
    @State private var showAgreementSheet = false

    @StateObject private var blockUserVM = BlockUserViewModel()
    
    var body: some View {
        ZStack {
            AppTheme.backgroundGradient.ignoresSafeArea()
            
            Group {
                if let candidate = viewModel.candidate {
                    ScrollView {
                        VStack(spacing: 20) {
                            // MARK: - Profile Image
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
                                                .shadow(radius: 4)
                                                .rotation3DEffect(.degrees(5), axis: (x: 0, y: 1, z: 0))
                                                .transition(.scale.combined(with: .opacity))
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
                                
                                // Verified badge
                                if let verified = candidate.isVerified, verified {
                                    Text("✓ Verified")
                                        .font(AppTheme.bodyFont)
                                        .foregroundColor(.white)
                                        .padding(4)
                                        .background(AppTheme.primaryColor.opacity(0.8))
                                        .clipShape(Capsule())
                                        .offset(x: -10, y: 10)
                                        .transition(.move(edge: .top).combined(with: .opacity))
                                }
                            }
                            .padding(.top, 20)
                            
                            // MARK: - ABOUT ME
                            if let aboutMe = candidate.aboutMe, !aboutMe.isEmpty {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("ABOUT ME")
                                        .font(.headline)
                                    Text(aboutMe)
                                        .font(AppTheme.bodyFont)
                                }
                                .padding()
                                .background(AppTheme.cardBackground)
                                .cornerRadius(AppTheme.defaultCornerRadius)
                                .shadow(radius: 5)
                            }
                            
                            // MARK: - BASICS
                            VStack(alignment: .leading, spacing: 8) {
                                Text("BASICS")
                                    .font(.headline)
                                
                                // Full Name
                                if let firstName = candidate.firstName,
                                   let lastName = candidate.lastName,
                                   !firstName.isEmpty, !lastName.isEmpty {
                                    Text("\(firstName) \(lastName)")
                                        .font(AppTheme.bodyFont)
                                }
                                
                                // DOB & Gender
                                if let dob = candidate.dateOfBirth, !dob.isEmpty {
                                    Text("DOB: \(dob)")
                                        .font(AppTheme.bodyFont)
                                }
                                if let g = candidate.gender, !g.isEmpty {
                                    Text("Gender: \(g)")
                                        .font(AppTheme.bodyFont)
                                }
                            }
                            .padding()
                            .background(AppTheme.cardBackground)
                            .cornerRadius(AppTheme.defaultCornerRadius)
                            .shadow(radius: 5)

                            // MARK: - ACADEMICS
                            VStack(alignment: .leading, spacing: 8) {
                                Text("ACADEMICS")
                                    .font(.headline)
                                
                                if let grade = candidate.gradeLevel, !grade.isEmpty {
                                    Text("Grade: \(grade)")
                                        .font(AppTheme.bodyFont)
                                }
                                if let major = candidate.major, !major.isEmpty {
                                    Text("Major: \(major)")
                                        .font(AppTheme.bodyFont)
                                }
                                if let college = candidate.collegeName, !college.isEmpty {
                                    Text("College: \(college)")
                                        .font(AppTheme.bodyFont)
                                }
                            }
                            .padding()
                            .background(AppTheme.cardBackground)
                            .cornerRadius(AppTheme.defaultCornerRadius)
                            .shadow(radius: 5)

                            // MARK: - HOUSING
                            VStack(alignment: .leading, spacing: 8) {
                                Text("HOUSING")
                                    .font(.headline)
                                
                                if let budget = candidate.budgetRange, !budget.isEmpty {
                                    Text("Budget Range: \(budget)")
                                        .font(AppTheme.bodyFont)
                                }
                                if let cleanliness = candidate.cleanliness {
                                    Text("Cleanliness: \(cleanliness)/5")
                                        .font(AppTheme.bodyFont)
                                }
                                if let sleep = candidate.sleepSchedule, !sleep.isEmpty {
                                    Text("Sleep Schedule: \(sleep)")
                                        .font(AppTheme.bodyFont)
                                }
                                if let smoker = candidate.smoker {
                                    Text("Smoker: \(smoker ? "Yes" : "No")")
                                        .font(AppTheme.bodyFont)
                                }
                                if let petFriendly = candidate.petFriendly {
                                    Text("Pet Friendly: \(petFriendly ? "Yes" : "No")")
                                        .font(AppTheme.bodyFont)
                                }
                                if let housing = candidate.housingStatus, !housing.isEmpty {
                                    Text("Housing Status: \(housing)")
                                        .font(AppTheme.bodyFont)
                                }
                                if let lease = candidate.leaseDuration, !lease.isEmpty {
                                    Text("Lease Duration: \(lease)")
                                        .font(AppTheme.bodyFont)
                                }
                            }
                            .padding()
                            .background(AppTheme.cardBackground)
                            .cornerRadius(AppTheme.defaultCornerRadius)
                            .shadow(radius: 5)
                            
                            // MARK: - INTERESTS
                            if let candidateInterests = candidate.interests, !candidateInterests.isEmpty {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("INTERESTS")
                                        .font(.headline)
                                    Text(candidateInterests.joined(separator: ", "))
                                        .font(AppTheme.bodyFont)
                                }
                                .padding()
                                .background(AppTheme.cardBackground)
                                .cornerRadius(AppTheme.defaultCornerRadius)
                                .shadow(radius: 5)
                            }
                            
                            // MARK: - Common Interests (Optional)
                            if let currentUser = ProfileViewModel.shared.userProfile,
                               let candidateInterests = candidate.interests,
                               let currentInterests = currentUser.interests {
                                let lowercasedCurrent = currentInterests.map { $0.lowercased() }
                                let common = candidateInterests.filter { lowercasedCurrent.contains($0.lowercased()) }
                                if !common.isEmpty {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Common Interests:")
                                            .font(AppTheme.subtitleFont)
                                        Text(common.joined(separator: ", "))
                                            .font(AppTheme.bodyFont)
                                            .foregroundColor(AppTheme.secondaryColor)
                                    }
                                    .padding()
                                    .background(AppTheme.cardBackground.opacity(0.8))
                                    .cornerRadius(AppTheme.defaultCornerRadius)
                                    .shadow(radius: 3)
                                }
                            }

                            // MARK: - Action Buttons
                            VStack(spacing: 16) {
                                Button(action: { showCompatibilityBreakdown = true }) {
                                    Text("View Compatibility Breakdown")
                                        .font(AppTheme.bodyFont)
                                }
                                .buttonStyle(PrimaryButtonStyle(backgroundColor: AppTheme.primaryColor))
                                
                                Button(action: { showComparison = true }) {
                                    Text("Compare with My Profile")
                                        .font(AppTheme.bodyFont)
                                }
                                .buttonStyle(PrimaryButtonStyle(backgroundColor: AppTheme.primaryColor))
                                
                                HStack(spacing: 16) {
                                    Button(action: { showReportSheet = true }) {
                                        Text("Report User")
                                            .font(AppTheme.bodyFont)
                                    }
                                    .buttonStyle(PrimaryButtonStyle(backgroundColor: AppTheme.accentColor))
                                    
                                    Button(action: { showBlockAlert = true }) {
                                        Text("Block User")
                                            .font(AppTheme.bodyFont)
                                    }
                                    .buttonStyle(PrimaryButtonStyle(backgroundColor: AppTheme.secondaryColor))
                                }
                                
                                Button(action: { showRatingSheet = true }) {
                                    Text("Rate Roommate")
                                        .font(AppTheme.bodyFont)
                                }
                                .buttonStyle(PrimaryButtonStyle(backgroundColor: AppTheme.primaryColor))
                                
                                Button(action: { showAgreementSheet = true }) {
                                    Text("Create Roommate Agreement")
                                        .font(AppTheme.bodyFont)
                                }
                                .buttonStyle(PrimaryButtonStyle(backgroundColor: AppTheme.primaryColor))
                            }
                            .padding(.bottom, 20)
                        }
                        .padding(.horizontal)
                    }
                } else {
                    ProgressView("Loading Profile...")
                        .font(AppTheme.bodyFont)
                        .onAppear {
                            viewModel.loadCandidate(with: candidateID)
                        }
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Candidate Profile")
                    .font(AppTheme.titleFont)
                    .foregroundColor(.primary)
            }
        }
        // Sheets & Alerts
        .sheet(isPresented: $showCompatibilityBreakdown) {
            if let candidate = viewModel.candidate {
                CompatibilityBreakdownView(candidate: candidate)
            }
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
