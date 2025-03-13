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
        self.userSession = Auth.auth().currentUser
    }
    
    /// Listens for changes in the authentication state.
    func listenToAuthState() {
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            self?.userSession = user
        }
    }
    
    /// Signs up using the FirebaseAuthService.
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
    
    /// Signs in with email and password.
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
    
    /// Signs out the current user.
    func signOut() {
        do {
            try Auth.auth().signOut()
            userSession = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
