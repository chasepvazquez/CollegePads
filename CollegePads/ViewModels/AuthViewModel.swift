//
//  AuthViewModel.swift
//  CollegePads
//
//  Created by [Your Name] on [Date].
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

class AuthViewModel: ObservableObject {
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var errorMessage: String?
    @Published var isLoading: Bool = false
    @Published var userSession: FirebaseAuth.User? = nil
    
    private let authService = FirebaseAuthService()
    
    init() {
        // Just set the current user; don't do the listener here.
        self.userSession = Auth.auth().currentUser
    }
    
    /// Call this in RootView’s onAppear to start listening for auth changes.
    func listenToAuthState() {
        _ = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            self?.userSession = user
        }
    }
    
    func signUp() {
        errorMessage = nil
        isLoading = true
        
        authService.signUpWithEmail(email: email, password: password) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success:
                    self?.userSession = Auth.auth().currentUser
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    func signIn() {
        errorMessage = nil
        isLoading = true
        
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] authResult, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                if let error = error {
                    self?.errorMessage = error.localizedDescription
                    return
                }
                self?.userSession = authResult?.user
            }
        }
    }
    
    func signOut() {
        do {
            try Auth.auth().signOut()
            userSession = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
