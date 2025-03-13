//
//  AuthViewModel.swift
//  CollegePads
//
//  Created by [Your Name] on [Date].
//

import SwiftUI
import FirebaseAuth

class AuthViewModel: ObservableObject {
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var errorMessage: String?
    @Published var isLoading: Bool = false
    
    // If sign-up is successful, you might track whether the user can proceed in the app
    @Published var signUpSuccess: Bool = false
    
    private let authService = FirebaseAuthService()
    
    func signUp() {
        // Reset error
        errorMessage = nil
        isLoading = true
        
        authService.signUpWithEmail(email: email, password: password) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success:
                    // Mark sign-up as successful so the UI can react
                    self?.signUpSuccess = true
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
    }
}

