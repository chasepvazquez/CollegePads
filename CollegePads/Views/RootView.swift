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
            // Show onboarding if it hasn't been completed yet.
            let completed = UserDefaults.standard.bool(forKey: "onboardingCompleted")
            if !completed {
                showOnboarding = true
            }
        }
        .onChange(of: authViewModel.userSession) { _ in
            // When user session changes, check onboarding status.
            let completed = UserDefaults.standard.bool(forKey: "onboardingCompleted")
            if !completed {
                showOnboarding = true
            } else {
                showOnboarding = false
            }
        }
        .fullScreenCover(isPresented: $showOnboarding) {
            OnboardingView()
        }
    }
}

struct RootView_Previews: PreviewProvider {
    static var previews: some View {
        RootView()
    }
}
