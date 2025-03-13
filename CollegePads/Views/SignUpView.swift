//
//  SignUpView.swift
//  CollegePads
//
//  Created by [Your Name] on [Date].
//

import SwiftUI

struct SignUpView: View {
    @StateObject private var viewModel = AuthViewModel()
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Create a .edu Account")
                .font(.headline)
            
            TextField("Enter .edu email", text: $viewModel.email)
                .autocapitalization(.none)
                .keyboardType(.emailAddress)
                .padding()
                .background(Color.gray.opacity(0.2))
                .cornerRadius(8)
            
            SecureField("Enter password", text: $viewModel.password)
                .padding()
                .background(Color.gray.opacity(0.2))
                .cornerRadius(8)
            
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
            }
            
            Button(action: {
                viewModel.signUp()
            }) {
                if viewModel.isLoading {
                    ProgressView()
                } else {
                    Text("Sign Up")
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(8)
                }
            }
            
            // Conditionally show success message or navigate to next screen
            if viewModel.signUpSuccess {
                Text("Sign-up complete! Please check your email to verify.")
                    .foregroundColor(.green)
            }
        }
        .padding()
        .navigationTitle("Sign Up")
    }
}

