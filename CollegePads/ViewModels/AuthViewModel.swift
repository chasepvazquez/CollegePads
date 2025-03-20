//
//  AuthViewModel.swift
//  CollegePads
//
//  Created by [Your Name] on [Date]
//  Updated for account management (delete account functionality)
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
        // Set the current user; listener can be started from RootView.
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

// MARK: - Account Management Extension

extension AuthViewModel {
    /// Deletes the currently authenticated user's account.
    /// This method calls Firebase Auth's delete method and returns the result via a completion handler.
    /// Optionally, you may add cleanup for Firestore user data here.
    func deleteAccount(completion: @escaping (Result<Void, Error>) -> Void) {
        guard let user = Auth.auth().currentUser else {
            completion(.failure(NSError(domain: "Auth", code: 401, userInfo: [NSLocalizedDescriptionKey: "No authenticated user found."])))
            return
        }
        user.delete { error in
            if let error = error {
                completion(.failure(error))
            } else {
                // Optionally, add Firestore data cleanup here.
                completion(.success(()))
            }
        }
    }
}
