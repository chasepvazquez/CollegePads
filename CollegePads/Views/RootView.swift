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
                AuthenticationView()
                    .environmentObject(authViewModel)
            } else {
                MainView()
                    .environmentObject(authViewModel)
            }
        }
        .onAppear {
            authViewModel.listenToAuthState()
            // Check if onboarding has been completed.
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
