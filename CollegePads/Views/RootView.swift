import SwiftUI
import FirebaseAuth

struct RootView: View {
    @StateObject private var authViewModel = AuthViewModel()
    @State private var showOnboarding: Bool = false
    @AppStorage("isDarkMode") private var isDarkMode: Bool = false

    var body: some View {
        NavigationView {
            Group {
                if authViewModel.userSession == nil {
                    AuthenticationView()
                        .environmentObject(authViewModel)
                } else {
                    TabBarView()
                        .environmentObject(authViewModel)
                }
            }
            .background(AppTheme.backgroundGradient.ignoresSafeArea())
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .preferredColorScheme(isDarkMode ? .dark : .light)
        .onAppear {
            authViewModel.listenToAuthState()
            // Check onboarding flag first.
            let completed = UserDefaults.standard.bool(forKey: "onboardingCompleted")
            if !completed {
                // If no user is signed in, show tutorial.
                if authViewModel.userSession == nil {
                    showOnboarding = true
                } else {
                    // If a user is signed in, check profile completeness.
                    checkUserProfile()
                }
            }
        }
        .onChange(of: authViewModel.userSession) { newSession in
            let completed = UserDefaults.standard.bool(forKey: "onboardingCompleted")
            if !completed {
                if newSession == nil {
                    showOnboarding = true
                } else {
                    checkUserProfile()
                }
            } else {
                showOnboarding = false
            }
        }
        .fullScreenCover(isPresented: $showOnboarding) {
            // Present the appropriate onboarding view based on authentication state.
            if authViewModel.userSession == nil {
                TutorialOnboardingView()
            } else {
                ProfileSetupOnboardingView()
            }
        }
    }
    
    /// Checks the current user's profile from Firestore.
    /// If firstName, lastName, or dateOfBirth are missing, sets showOnboarding = true.
    private func checkUserProfile() {
        ProfileViewModel.shared.loadUserProfile { userProfile in
            if let profile = userProfile {
                let missingName = (profile.firstName?.isEmpty ?? true) || (profile.lastName?.isEmpty ?? true)
                let missingDOB = (profile.dateOfBirth?.isEmpty ?? true)
                showOnboarding = missingName || missingDOB
            } else {
                showOnboarding = true
            }
        }
    }
}

struct RootView_Previews: PreviewProvider {
    static var previews: some View {
        RootView()
    }
}
