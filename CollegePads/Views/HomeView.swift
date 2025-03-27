import SwiftUI
import FirebaseAuth

struct HomeView: View {
    @StateObject private var viewModel = ProfileViewModel.shared
    
    var body: some View {
        ZStack {
            AppTheme.backgroundGradient.ignoresSafeArea()
            
            VStack(spacing: 20) {
                // Title
                Text("Welcome to CollegePads!")
                    .font(AppTheme.titleFont)
                    .foregroundColor(.primary)
                
                // If we have a user profile, display a ring around their image showing profile completion
                if let profile = viewModel.userProfile {
                    let completion = ProfileCompletionCalculator.calculateCompletion(for: profile)
                    
                    // NavigationLink wraps the ring so it’s clickable
                    NavigationLink(destination: MyProfileView()) {
                        ProfileCompletionRingView(
                            completion: completion,
                            imageUrl: profile.profileImageUrl
                        )
                        .frame(width: 120, height: 120)
                    }
                    .padding()
                    
                } else {
                    // Fallback if profile is not loaded yet
                    Image(systemName: "person.crop.circle")
                        .resizable()
                        .frame(width: 70, height: 70)
                        .padding()
                }
                
                // Navigation to Advanced Search
                NavigationLink(destination: AdvancedFilterView()) {
                    Text("Advanced Search")
                        .font(AppTheme.bodyFont)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(AppTheme.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(AppTheme.defaultCornerRadius)
                }
                
                // Navigation to Settings
                NavigationLink(destination: SettingsView().environmentObject(AuthViewModel())) {
                    Text("Settings")
                        .font(AppTheme.bodyFont)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(AppTheme.secondaryColor)
                        .foregroundColor(.white)
                        .cornerRadius(AppTheme.defaultCornerRadius)
                }
                
                Spacer()
            }
            .padding()
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Home")
                    .font(AppTheme.titleFont)
                    .foregroundColor(.primary)
            }
        }
        .onAppear {
            // Ensure the user profile is loaded so we can show the ring & image
            viewModel.loadUserProfile()
        }
    }
}

/// A reusable ring view that displays the user’s image in the center
/// and a circular progress stroke around it representing profile completion (0–100).
struct ProfileCompletionRingView: View {
    let completion: Double      // 0..100
    let imageUrl: String?       // Optional image URL
    
    var body: some View {
        ZStack {
            // Trimmed circle stroke from 0..completion
            Circle()
                .trim(from: 0, to: CGFloat(completion / 100))
                .stroke(
                    AppTheme.primaryColor,
                    style: StrokeStyle(lineWidth: 8, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))  // Start from top
                .opacity(0.5)
            
            // Center circle for user’s image
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
                    // Fallback if no URL
                    Image(systemName: "person.crop.circle")
                        .resizable()
                }
            }
            .frame(width: 80, height: 80)
        }
    }
}
