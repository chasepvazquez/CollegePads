//
//  RootView.swift
//  CollegePads
//
//  Created by Chase Vazquez on [Date].
//

import SwiftUI
import FirebaseAuth

struct RootView: View {
    @StateObject private var authViewModel = AuthViewModel()
    
    var body: some View {
        Group {
            if authViewModel.userSession == nil {
                // If not signed in, show the authentication flow
                AuthenticationView()
                    .environmentObject(authViewModel)
            } else {
                // If signed in, show the main app interface
                MainView()
                    .environmentObject(authViewModel)
            }
        }
        .onAppear {
            authViewModel.listenToAuthState()
        }
    }
}

struct RootView_Previews: PreviewProvider {
    static var previews: some View {
        RootView()
    }
}
