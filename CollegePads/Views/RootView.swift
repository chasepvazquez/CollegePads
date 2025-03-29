import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct RootView: View {
    @StateObject private var authViewModel = AuthViewModel()
    @StateObject private var profileViewModel = ProfileViewModel.shared
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
                        .environmentObject(profileViewModel)
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
                if authViewModel.userSession == nil {
                    showOnboarding = true
                } else {
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
            if authViewModel.userSession == nil {
                TutorialOnboardingView()
            } else {
                ProfileSetupOnboardingView()
            }
        }
    }
    
    /// Checks the current user's profile.
    /// If firstName, lastName, or dateOfBirth are missing, sets showOnboarding = true.
    private func checkUserProfile() {
        if profileViewModel.userProfile == nil {
            profileViewModel.loadUserProfile { userProfile in
                if let profile = userProfile {
                    let missingName = (profile.firstName?.isEmpty ?? true) || (profile.lastName?.isEmpty ?? true)
                    let missingDOB = (profile.dateOfBirth?.isEmpty ?? true)
                    showOnboarding = missingName || missingDOB
                } else {
                    showOnboarding = true
                }
            }
        } else {
            let profile = profileViewModel.userProfile!
            let missingName = (profile.firstName?.isEmpty ?? true) || (profile.lastName?.isEmpty ?? true)
            let missingDOB = (profile.dateOfBirth?.isEmpty ?? true)
            showOnboarding = missingName || missingDOB
        }
    }
}

struct RootView_Previews: PreviewProvider {
    static var previews: some View {
        RootView()
    }
}
