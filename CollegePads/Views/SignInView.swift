//
//  SignInView.swift
//  CollegePads
//
//  Updated for improved form validation, button state management, and animated error feedback
//

import SwiftUI

struct SignInView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var showErrorAnimation = false

    var isFormValid: Bool {
        !authViewModel.email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !authViewModel.password.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Sign In")
                .font(.headline)
            
            TextField("Enter your email", text: $authViewModel.email)
                .autocapitalization(.none)
                .keyboardType(.emailAddress)
                .padding()
                .background(Color.gray.opacity(0.2))
                .cornerRadius(8)
                .accessibilityLabel("Email Field")
            
            SecureField("Enter password", text: $authViewModel.password)
                .padding()
                .background(Color.gray.opacity(0.2))
                .cornerRadius(8)
                .accessibilityLabel("Password Field")
            
            if let errorMessage = authViewModel.errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .transition(.opacity)
                    .animation(.easeInOut, value: authViewModel.errorMessage)
            }
            
            Button(action: {
                withAnimation { showErrorAnimation = true }
                authViewModel.signIn()
            }) {
                if authViewModel.isLoading {
                    ProgressView()
                } else {
                    Text("Sign In")
                        .frame(maxWidth: .infinity)
                }
            }
            .disabled(!isFormValid || authViewModel.isLoading)
            .buttonStyle(PrimaryButtonStyle(backgroundColor: Color.green))
            .accessibilityLabel("Sign In Button")
            
            Text("Don't have an account? Sign Up")
                .foregroundColor(.blue)
                .onTapGesture {
                    authViewModel.errorMessage = nil
                    authViewModel.email = ""
                    authViewModel.password = ""
                    // Navigation handled by AuthenticationView.
                }
        }
        .padding()
        .navigationTitle("Sign In")
    }
}

struct SignInView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            SignInView().environmentObject(AuthViewModel())
        }
    }
}
