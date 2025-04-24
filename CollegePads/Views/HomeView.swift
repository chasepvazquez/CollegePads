import SwiftUI
import FirebaseAuth

struct HomeView: View {
    @StateObject private var profileVM = ProfileViewModel.shared
    @StateObject private var matchingVM = MatchingViewModel()
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Welcome Title and Profile Completion Ring
                    Text("Welcome to CollegePads!")
                        .font(AppTheme.titleFont)
                        .foregroundColor(.primary)
                    
                    if let profile = profileVM.userProfile {
                        let completion = ProfileCompletionCalculator.calculateCompletion(for: profile)
                        NavigationLink(destination: MyProfileView()) {
                            ProfileCompletionRingView(
                                completion: completion,
                                imageUrl: profile.profileImageUrl
                            )
                            .frame(width: 120, height: 120)
                        }
                        .padding()
                    } else {
                        Image(systemName: "person.crop.circle")
                            .resizable()
                            .frame(width: 70, height: 70)
                            .padding()
                    }
                    
                    // Dashboard Section: Profile Completion Detail
                    if let profile = profileVM.userProfile {
                        let completion = ProfileCompletionCalculator.calculateCompletion(for: profile)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Profile Completion: \(Int(completion))%")
                                .font(AppTheme.titleFont)
                            ProgressView(value: completion, total: 100)
                                .progressViewStyle(LinearProgressViewStyle(tint: AppTheme.accentColor))
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(AppTheme.cardBackground)
                        .cornerRadius(10)
                        .shadow(radius: 2)
                    }
                    
                    // Dashboard Section: Matches Count
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Matches")
                            .font(AppTheme.titleFont)
                        Text("\(matchingVM.potentialMatches.count) matches")
                            .font(AppTheme.titleFont)
                            .foregroundColor(AppTheme.primaryColor)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(AppTheme.cardBackground)
                    .cornerRadius(10)
                    .shadow(radius: 2)
                    
                    // Dashboard Section: Matching Conversation Rate
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Matching Conversation Rate")
                            .font(AppTheme.titleFont)
                        if matchingVM.rightSwipesCount > 0 {
                            let rate = (Double(matchingVM.mutualMatchesCount) / Double(matchingVM.rightSwipesCount)) * 100
                            Text(String(format: "%.0f%%", rate))
                                .font(AppTheme.titleFont)
                                .foregroundColor(AppTheme.accentColor)
                            Text("You matched with \(matchingVM.mutualMatchesCount) out of \(matchingVM.rightSwipesCount) right swipes.")
                                .font(AppTheme.bodyFont)
                        } else {
                            Text("No right swipes yet")
                                .font(AppTheme.bodyFont)
                                .foregroundColor(.gray)
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(AppTheme.cardBackground)
                    .cornerRadius(10)
                    .shadow(radius: 2)
                    
                    // Dashboard Section: Average Compatibility
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Average Compatibility")
                            .font(AppTheme.titleFont)
                        Text("85%")
                            .font(AppTheme.titleFont)
                            .foregroundColor(AppTheme.accentColor)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(AppTheme.cardBackground)
                    .cornerRadius(10)
                    .shadow(radius: 2)
                    
                    Spacer()
                }
                .padding()
            }
            // Themed background
            .background(AppTheme.backgroundGradient.ignoresSafeArea())
            .onAppear {
                // ProfileViewModel.shared now auto-loads for us, so we only need to
                // kick off our matching pass here:
                matchingVM.fetchPotentialMatches()
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: SettingsView().environmentObject(AuthViewModel())) {
                        Image(systemName: "gearshape")
                    }
                }
            }
        }
    }
}

/// A reusable ring view that displays the user’s image in the center
/// and a circular progress stroke around it representing profile completion (0–100).
struct ProfileCompletionRingView: View {
    let completion: Double      // 0–100
    let imageUrl: String?       // Optional image URL
    
    var body: some View {
        ZStack {
            Circle()
                .trim(from: 0, to: CGFloat(completion / 100))
                .stroke(
                    AppTheme.primaryColor,
                    style: StrokeStyle(lineWidth: 8, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .opacity(0.5)
            ZStack {
                Circle()
                    .fill(AppTheme.cardBackground)
                if let urlStr = imageUrl, let url = URL(string: urlStr) {
                    AsyncImage(url: url) { phase in
                        if let image = phase.image {
                            image
                                .resizable()
                                .scaledToFill()
                        } else {
                            Image(systemName: "person.crop.circle")
                                .resizable()
                        }
                    }
                    .clipShape(Circle())
                } else {
                    Image(systemName: "person.crop.circle")
                        .resizable()
                }
            }
            .frame(width: 80, height: 80)
        }
    }
}
