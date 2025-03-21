//
//  RootView.swift
//  CollegePads
//
//  Ensures global background gradient is used and references AppTheme for accent colors.
//

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
            // Global background gradient from AppTheme.
            .background(AppTheme.backgroundGradient.ignoresSafeArea())
        }
        .preferredColorScheme(isDarkMode ? .dark : .light)
        .onAppear {
            authViewModel.listenToAuthState()
            let completed = UserDefaults.standard.bool(forKey: "onboardingCompleted")
            if !completed { showOnboarding = true }
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
