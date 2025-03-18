//
//  RootView.swift
//  CollegePads
//
//  Created by [Your Name] on [Date].
//

import SwiftUI
import FirebaseAuth

struct RootView: View {
    @StateObject private var authViewModel = AuthViewModel()
    @State private var showOnboarding: Bool = false
    
    var body: some View {
        Group {
            if authViewModel.userSession == nil {
                // Show authentication flow if not signed in
                AuthenticationView()
                    .environmentObject(authViewModel)
            } else {
                // Main app interface with custom tab bar
                TabBarView()
                    .environmentObject(authViewModel)
            }
        }
        .onAppear {
            authViewModel.listenToAuthState()
            // Show onboarding if not completed yet
            let completed = UserDefaults.standard.bool(forKey: "onboardingCompleted")
            if !completed {
                showOnboarding = true
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
