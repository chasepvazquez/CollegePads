//
//  RootView.swift
//  CollegePads
//
//  Updated for improved theming and accessibility
//

import SwiftUI
import FirebaseAuth

struct RootView: View {
    @StateObject private var authViewModel = AuthViewModel()
    @State private var showOnboarding: Bool = false
    
    var body: some View {
        Group {
            if authViewModel.userSession == nil {
                // Authentication flow with consistent light mode (adjust as needed)
                AuthenticationView()
                    .environmentObject(authViewModel)
                    .preferredColorScheme(.light)
            } else {
                // Main app interface with custom tab bar
                TabBarView()
                    .environmentObject(authViewModel)
                    .preferredColorScheme(.light)
            }
        }
        .onAppear {
            authViewModel.listenToAuthState()
            // Show onboarding if not completed yet.
            let completed = UserDefaults.standard.bool(forKey: "onboardingCompleted")
            if !completed {
                showOnboarding = true
            }
        }
        .fullScreenCover(isPresented: $showOnboarding) {
            OnboardingView()
        }
        .accessibility(addTraits: .isHeader)
    }
}

struct RootView_Previews: PreviewProvider {
    static var previews: some View {
        RootView()
    }
}
